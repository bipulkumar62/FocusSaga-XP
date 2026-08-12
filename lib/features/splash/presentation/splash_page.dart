import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/global_background_scaffold.dart';

/// Holds the screen while the app bootstraps: restores an existing session or
/// signs in as an anonymous guest, then loads/creates the profile.
/// Shows a retry button if bootstrap or profile loading fails.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  static const String routeName = 'splash';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);

    if (user == null) {
      // No session yet: restore one or create an anonymous guest.
      final bootstrap = ref.watch(ensureSessionProvider);
      return _Body(
        error: bootstrap.hasError ? '${bootstrap.error}' : null,
        onRetry: () => ref.invalidate(ensureSessionProvider),
      );
    }

    final profileAsync = ref.watch(currentProfileProvider);
    return _Body(
      error: profileAsync.hasError ? '${profileAsync.error}' : null,
      onRetry: () {
        ref.invalidate(currentProfileProvider);
        ref.invalidate(termsStatusProvider);
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({this.error, this.onRetry});

  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: GlobalBackgroundScaffold(
        child: Center(
        child: error != null
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text('Could not start FocusSaga XP',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        error!,
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
