class AppConfig {
  static const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const isProd = env == 'prod';
  static const isDev = !isProd;

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dolunch-api.kyuhan-lee.workers.dev',
  );

  static const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  static const appName = '점심어때';
  static const appVersion = '1.0.0';
}
