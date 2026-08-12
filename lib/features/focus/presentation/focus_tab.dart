import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/character_idle_widget.dart';
import '../../progress/presentation/reward_summary_screen.dart';
import '../application/focus_timer_controller.dart';
import '../../characters/domain/owned_character.dart';

/// Focus tab — countdown timer with presets, custom duration, character and
/// background placeholders and an XP preview. Completed sessions are saved to
/// Supabase via `save_study_session` and a reward recap is shown.
class FocusTab extends ConsumerStatefulWidget {
  const FocusTab({super.key});

  static const List<Duration> _presets = [
    Duration(minutes: 25),
    Duration(minutes: 50),
    Duration(hours: 2),
  ];

  static const int _maxMinutes = 180;

  @override
  ConsumerState<FocusTab> createState() => _FocusTabState();
}

class _FocusTabState extends ConsumerState<FocusTab> {
  bool _saving = false;

  /// When non-null, the character plays its level-up animation until this
  /// moment (triggered when the selected character gains a level).
  DateTime? _levelUpUntil;
  Timer? _levelUpTimer;

  @override
  void dispose() {
    _levelUpTimer?.cancel();
    super.dispose();
  }

  /// Plays the level-up celebration when the equipped character's level
  /// increases (e.g. right after a session is saved).
  void _celebrateLevelUp() {
    final until = DateTime.now().add(const Duration(seconds: 3));
    setState(() => _levelUpUntil = until);
    _levelUpTimer?.cancel();
    _levelUpTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _levelUpUntil = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timer = ref.watch(focusTimerProvider);
    final controller = ref.read(focusTimerProvider.notifier);

    // Save automatically whenever an active session reaches the completed
    // state — whether the user pressed Finish or the timer hit zero (also
    // when that happened in the background and the app just resumed).
    ref.listen(focusTimerProvider, (previous, next) {
      final wasActive = previous?.isRunning == true || previous?.isPaused == true;
      if (wasActive && next.isCompleted && !next.sessionSaved) {
        _saveSession();
      }
    });

    // Celebrate when the equipped character levels up (skipping the very
    // first load, which goes from null → a character).
    ref.listen<AsyncValue<OwnedCharacter?>>(selectedCharacterProvider,
        (previous, next) {
      final before = previous?.value;
      final after = next.value;
      if (before == null || after == null) return;
      if (after.level > before.level) _celebrateLevelUp();
    });
    final selected = ref.watch(selectedCharacterProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          children: [
            // ---------- branding header ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icon/app_logo.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'FocusSaga XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ---------- big countdown ----------
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Shrink the ring on short viewports (small browser
                  // windows, landscape phones) instead of overflowing.
                  final maxRing = constraints.maxHeight - 96;
                  final ring = maxRing.clamp(150.0, 280.0);
                  final fontScale = ring / 280;
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TimerRing(
                            size: ring,
                            progress: timer.progress,
                            child: Text(
                              _format(timer.remaining),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                fontSize: (theme.textTheme.displayLarge
                                            ?.fontSize ??
                                        57) *
                                    fontScale,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusLabel(timer),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // ---------- animated character companion ----------
                          RepaintBoundary(
                            child: SizedBox(
                              width: 108,
                              height: 108,
                              child: selected.when(
                                loading: () => CharacterIdleWidget(
                                  characterName: 'companion',
                                  width: 104,
                                  height: 104,
                                ),
                                error: (_, _) => CharacterIdleWidget(
                                  characterName: 'companion',
                                  width: 104,
                                  height: 104,
                                ),
                                data: (character) {
                                  if (character == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      CharacterIdleWidget(
                                        characterName: character.name,
                                        width: 104,
                                        height: 104,
                                      ),
                                      if (_isLevelUpCelebrating)
                                        Positioned(
                                          top: -6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Level up!',
                                              style: theme.textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          if (timer.isCompleted) ...[
                            const SizedBox(height: 8),
                            Text(
                              'You studied ${_format(timer.studied)}'
                              '${timer.completedFully ? ' — full session!' : ' — finished early'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!timer.completedFully) ...[
                              const SizedBox(height: 4),
                              Text(
                                '≈ ${timer.xpEarned} XP counted for this time',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ---------- presets ----------
            Row(
              children: [
                for (final preset in FocusTab._presets) ...[
                  Expanded(
                    child: ChoiceChip(
                      label: Text(_presetLabel(preset)),
                      selected: timer.isIdle && timer.total == preset,
                      onSelected: (_) => controller.selectDuration(preset),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Custom'),
                    selected: timer.isIdle && !FocusTab._presets.contains(timer.total),
                    onSelected: (_) => _pickCustomDuration(context, controller),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---------- character + background placeholders ----------
            Row(
              children: [
                Expanded(
                  child: _SlotCard(
                    icon: Icons.sports_martial_arts_rounded,
                    label: 'Character',
                    value: selected.asData?.value?.name ?? 'Default companion',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SlotCard(
                    icon: Icons.wallpaper_rounded,
                    label: 'Background',
                    value: 'Default space',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---------- XP preview (before start only) ----------
            if (timer.isIdle)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      '≈ ${timer.xpPreview} XP on completion',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 12),

            // ---------- controls ----------
            const SizedBox(height: 12),
            Row(
              children: [
                if (timer.isRunning || timer.isPaused)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.finish,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Finish'),
                    ),
                  ),
                if (timer.isRunning || timer.isPaused) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: switch (timer.status) {
                      FocusTimerStatus.idle => controller.start,
                      FocusTimerStatus.running => controller.pause,
                      FocusTimerStatus.paused => controller.resume,
                      FocusTimerStatus.completed => _saveSession,
                    },
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(switch (timer.status) {
                            FocusTimerStatus.idle => Icons.play_arrow_rounded,
                            FocusTimerStatus.running => Icons.pause_rounded,
                            FocusTimerStatus.paused => Icons.play_arrow_rounded,
                            FocusTimerStatus.completed => Icons.refresh_rounded,
                          }),
                    label: Text(switch (timer.status) {
                      FocusTimerStatus.idle => 'Start',
                      FocusTimerStatus.running => 'Pause',
                      FocusTimerStatus.paused => 'Resume',
                      FocusTimerStatus.completed =>
                        timer.sessionSaved ? 'Done' : 'Save & done',
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// True while the level-up celebration window is active.
  bool get _isLevelUpCelebrating {
    final until = _levelUpUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  static String _presetLabel(Duration d) {
    if (d.inHours > 0) return '${d.inHours} h';
    return '${d.inMinutes} min';
  }

  static String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  static String _statusLabel(FocusTimerState timer) {
    return switch (timer.status) {
      FocusTimerStatus.idle => 'Ready to focus',
      FocusTimerStatus.running => 'Stay focused...',
      FocusTimerStatus.paused => 'Paused — ${_format(timer.studied)} studied',
      FocusTimerStatus.completed =>
        timer.completedFully ? 'Session complete!' : 'Session ended',
    };
  }

  Future<void> _pickCustomDuration(BuildContext context, FocusTimerNotifier controller) async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => const _CustomDurationDialog(maxMinutes: FocusTab._maxMinutes),
    );
    if (minutes != null && minutes >= 1 && minutes <= FocusTab._maxMinutes) {
      controller.selectDuration(Duration(minutes: minutes));
    }
  }

  /// Persists the finished session via the `save_study_session` RPC, then
  /// shows the reward recap. Also the retry path when a save failed.
  Future<void> _saveSession() async {
    if (_saving) return;
    final timer = ref.read(focusTimerProvider);
    final controller = ref.read(focusTimerProvider.notifier);

    // Nothing studied, nothing to save.
    if (timer.studied == Duration.zero) {
      controller.reset();
      return;
    }
    // Already persisted (e.g. reward screen shown) — just reset.
    if (timer.sessionSaved) {
      controller.reset();
      return;
    }

    setState(() => _saving = true);
    try {
      final summary = await ref.read(progressRepositoryProvider).saveSession(
            plannedMinutes: timer.total.inMinutes,
            actualMinutes: timer.studied.inMinutes,
            completed: timer.completedFully,
            pausedCount: timer.pausedCount,
            startedAt: timer.startedAt ?? DateTime.now(),
            endedAt: DateTime.now(),
          );
      if (!mounted) return;
      controller.markSessionSaved();
      ref.invalidate(currentProfileProvider);
      ref.invalidate(ownedCharactersProvider);
      ref.invalidate(dailyChallengesProvider);
      ref.invalidate(totalFocusedMinutesProvider);
      ref.invalidate(currentStreakProvider);
      ref.invalidate(dailyLeaderboardProvider);
      ref.invalidate(weeklyLeaderboardProvider);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RewardSummaryScreen(summary: summary),
        ),
      );
      if (!mounted) return;
      controller.reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save session: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Circular progress ring around the countdown.
class _TimerRing extends StatelessWidget {
  const _TimerRing({
    required this.size,
    required this.progress,
    required this.child,
  });

  final double size;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              trackColor: theme.colorScheme.surfaceContainerHighest,
              progressColor: theme.colorScheme.primary,
            ),
          ),
          Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.trackColor, required this.progressColor});

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress > 0) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = progressColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708,
        6.2832 * progress,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.progressColor != progressColor;
}

/// Small card slot for character / background.
class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Number input dialog for a custom session length (1..maxMinutes).
class _CustomDurationDialog extends StatefulWidget {
  const _CustomDurationDialog({required this.maxMinutes});

  final int maxMinutes;

  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final minutes = int.tryParse(_controller.text.trim());
    if (minutes == null || minutes < 1 || minutes > widget.maxMinutes) {
      setState(() => _error = 'Enter a value between 1 and ${widget.maxMinutes} minutes');
      return;
    }
    Navigator.of(context).pop(minutes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Minutes',
              helperText: 'Up to ${widget.maxMinutes} minutes (3 h)',
              errorText: _error,
              suffixText: 'min',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Set timer')),
      ],
    );
  }
}