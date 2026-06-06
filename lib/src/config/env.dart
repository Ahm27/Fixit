class EnvConfig {
  static const bool forceDemoMode = bool.fromEnvironment(
    'FIXIT_DEMO_MODE',
    defaultValue: false,
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const String oauthRedirectUrl = String.fromEnvironment(
    'SUPABASE_REDIRECT_URL',
    defaultValue: 'com.fixit.app://login-callback/',
  );

  static bool get hasSupabase =>
      !forceDemoMode && supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
