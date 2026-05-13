class Env {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');

  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
}
