/// Centralized app configuration.
///
/// Values can be overridden at build time:
///   flutter run --dart-define=SUPABASE_URL=... \
///                --dart-define=SUPABASE_PUBLISHABLE_KEY=...
library;

class AppConfig {
  AppConfig._();

  static const String appName = 'FocusSaga XP';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rychyralxfvhljsmlmkp.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_6GZqCo2d6KGI4IKJHxN__Q_kUgGCDWl',
  );
}