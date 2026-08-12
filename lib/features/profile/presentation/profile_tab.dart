import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../characters/presentation/widgets/character_avatar.dart';
import 'profile_setup_page.dart';

/// Profile tab — account info, lifetime stats, the equipped
/// companion and logout.
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentProfileProvider).value;
    final user = ref.watch(authUserProvider);
    final needsName = profile != null &&
        ProfileSetupPage.needsNameSetup(profile.displayName);
    final displayName = profile?.displayName ?? user?.email ?? 'Guest Learner';
    final email = profile?.email ?? user?.email ?? 'Guest account';
    final minutes = switch (ref.watch(totalFocusedMinutesProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final streak = switch (ref.watch(currentStreakProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentProfileProvider);
          ref.invalidate(totalFocusedMinutesProvider);
          ref.invalidate(currentStreakProvider);
          ref.invalidate(ownedCharactersProvider);
          await ref.read(currentProfileProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 44,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: profile?.avatarUrl != null
                  ? NetworkImage(profile!.avatarUrl!)
                  : null,
              child: profile?.avatarUrl == null
                  ? Icon(Icons.person_rounded,
                      size: 52, color: theme.colorScheme.onPrimaryContainer)
                  : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.push('/profile-setup'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (needsName)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Set your name to appear on the leaderboard',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.military_tech_rounded,
                    label: 'Level',
                    value: '${profile?.profileLevel ?? 1}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.monetization_on_rounded,
                    label: 'Coins',
                    value: '${profile?.coins ?? 0}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.timer_outlined,
                    label: 'Focused',
                    value: minutes == null ? '—' : _formatMinutes(minutes),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak',
                    value: streak == null ? '—' : '$streak day${streak == 1 ? '' : 's'}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Companion',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _SelectedCharacterCard(),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Terms & Privacy'),
                subtitle: const Text('Accepted v1.0'),
                onTap: () => context.push('/legal'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }
}

class _SelectedCharacterCard extends ConsumerWidget {
  const _SelectedCharacterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCharacterProvider);

    return selected.when(
      loading: () => const Card(
        child: SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline_rounded),
          title: const Text('Could not load companion'),
          subtitle: Text('$e'),
          trailing: IconButton(
            tooltip: 'Retry',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(ownedCharactersProvider),
          ),
        ),
      ),
      data: (character) {
        if (character == null) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.sports_martial_arts_outlined),
              title: const Text('No companion yet'),
              subtitle: const Text('Pick one in the Characters tab'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/characters'),
            ),
          );
        }
        final form = character.currentForm;
        return Card(
          child: ListTile(
            leading: CharacterAvatar(
              imagePath: form?.imageUrl ?? character.imagePath,
              characterName: character.name,
              size: 44,
              paused: true,
            ),
            title: Text(
              form?.formName ?? character.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${character.name} · Lv ${character.level}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go('/characters'),
          ),
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
