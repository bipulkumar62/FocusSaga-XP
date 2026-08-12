import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../progress/domain/progress_rules.dart';

enum FocusTimerStatus { idle, running, paused, completed }

/// Countdown state. All durations are derived from [elapsed] (wall-clock
/// seconds actually studied), so background time is accounted for correctly.
class FocusTimerState {
  const FocusTimerState({
    this.status = FocusTimerStatus.idle,
    this.total = const Duration(minutes: 25),
    this.elapsed = Duration.zero,
    this.completedFully = false,
    this.startedAt,
    this.pausedCount = 0,
    this.sessionSaved = false,
  });

  final FocusTimerStatus status;

  /// Session length chosen by the user.
  final Duration total;

  /// Actual studied time so far (pauses do not count).
  final Duration elapsed;

  /// True only when the timer reached zero naturally.
  final bool completedFully;

  /// When the session (re)started — persisted to `study_sessions`.
  final DateTime? startedAt;

  /// How many times the user paused, for stats.
  final int pausedCount;

  /// True once the session was successfully saved to Supabase.
  final bool sessionSaved;

  bool get isIdle => status == FocusTimerStatus.idle;
  bool get isRunning => status == FocusTimerStatus.running;
  bool get isPaused => status == FocusTimerStatus.paused;
  bool get isCompleted => status == FocusTimerStatus.completed;

  /// Time left to study.
  Duration get remaining {
    final rem = total - elapsed;
    return rem.isNegative ? Duration.zero : rem;
  }

  /// Actual studied time, clamped to the session length.
  Duration get studied => elapsed > total ? total : elapsed;

  /// 0.0 -> 1.0 of the session completed.
  double get progress => total.inSeconds == 0
      ? 0
      : (elapsed.inSeconds / total.inSeconds).clamp(0.0, 1.0);

  /// Preview XP for a full session: 1 XP/min + 20% completion bonus.
  int get xpPreview => XpRules
      .xpForSession(actualMinutes: total.inMinutes, completed: true)
      .clamp(0, 9999);

  /// XP for what was actually studied (no bonus — early finish).
  int get xpEarned => XpRules
      .xpForSession(actualMinutes: studied.inMinutes, completed: false)
      .clamp(0, 9999);

  FocusTimerState copyWith({
    FocusTimerStatus? status,
    Duration? total,
    Duration? elapsed,
    bool? completedFully,
    DateTime? startedAt,
    int? pausedCount,
    bool? sessionSaved,
  }) {
    return FocusTimerState(
      status: status ?? this.status,
      total: total ?? this.total,
      elapsed: elapsed ?? this.elapsed,
      completedFully: completedFully ?? this.completedFully,
      startedAt: startedAt ?? this.startedAt,
      pausedCount: pausedCount ?? this.pausedCount,
      sessionSaved: sessionSaved ?? this.sessionSaved,
    );
  }

  /// Fresh idle state for the same duration (also clears session metadata).
  FocusTimerState withDuration(Duration duration) {
    return FocusTimerState(total: duration);
  }
}

/// Real countdown engine.
///
/// Time is measured in wall-clock timestamps: every tick (and on every app
/// resume) the elapsed seconds are recomputed from `DateTime.now()` against
/// the last tick timestamp. This keeps the countdown accurate across app
/// background/resume cycles and delayed ticks.
class FocusTimerNotifier extends Notifier<FocusTimerState> {
  static const Duration maxSession = Duration(hours: 3);

  Timer? _ticker;
  DateTime? _lastTick;
  AppLifecycleListener? _lifecycleListener;

  @override
  FocusTimerState build() {
    // Re-sync immediately when the app returns from the background, before
    // the next tick fires.
    _lifecycleListener = AppLifecycleListener(onResume: _catchUp);
    ref.onDispose(() {
      _lifecycleListener?.dispose();
      _ticker?.cancel();
    });
    return const FocusTimerState();
  }

  void selectDuration(Duration duration) {
    if (!state.isIdle) return;
    if (duration <= Duration.zero || duration > maxSession) return;
    state = state.withDuration(duration);
  }

  void start() {
    if (!state.isIdle) return;
    _lastTick = DateTime.now();
    state = state.copyWith(
      status: FocusTimerStatus.running,
      startedAt: DateTime.now(),
    );
    _startTicker();
  }

  void pause() {
    if (!state.isRunning) return;
    _ticker?.cancel();
    _lastTick = null;
    state = state.copyWith(
      status: FocusTimerStatus.paused,
      pausedCount: state.pausedCount + 1,
    );
  }

  void resume() {
    if (!state.isPaused) return;
    _lastTick = DateTime.now();
    state = state.copyWith(status: FocusTimerStatus.running);
    _startTicker();
  }

  /// Ends the session early: only the actually studied time counts.
  void finish() {
    if (!state.isRunning && !state.isPaused) return;
    _ticker?.cancel();
    _lastTick = null;
    state = state.copyWith(
      status: FocusTimerStatus.completed,
      completedFully: false,
    );
  }

  void reset() {
    _ticker?.cancel();
    _lastTick = null;
    state = state.withDuration(state.total);
  }

  /// Marks the completed session as persisted (prevents double saves).
  void markSessionSaved() {
    if (!state.isCompleted) return;
    state = state.copyWith(sessionSaved: true);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _catchUp());
  }

  /// Adds the wall-clock time since [_lastTick] to [FocusTimerState.elapsed].
  /// Called every tick and on app resume, so the countdown never drifts and
  /// survives backgrounding.
  void _catchUp() {
    if (!state.isRunning) return;
    final now = DateTime.now();
    final delta = _lastTick == null ? Duration.zero : now.difference(_lastTick!);
    _lastTick = now;

    if (delta <= Duration.zero) return;

    final newElapsed = state.elapsed + delta;

    if (newElapsed >= state.total) {
      _ticker?.cancel();
      _lastTick = null;
      state = state.copyWith(
        status: FocusTimerStatus.completed,
        elapsed: state.total,
        completedFully: true,
      );
    } else {
      state = state.copyWith(elapsed: newElapsed);
    }
  }
}

final focusTimerProvider =
    NotifierProvider<FocusTimerNotifier, FocusTimerState>(FocusTimerNotifier.new);