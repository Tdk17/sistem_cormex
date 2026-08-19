abstract final class AppConfig {
  static const parseServerUrl = String.fromEnvironment(
    'PARSE_SERVER_URL',
    defaultValue: 'https://parseapi.back4app.com',
  );

  static const parseApplicationId = String.fromEnvironment(
    'PARSE_APPLICATION_ID',
  );

  static const parseJavaScriptKey = String.fromEnvironment(
    'PARSE_JAVASCRIPT_KEY',
  );

  static const parseRestApiKey = String.fromEnvironment(
    'PARSE_REST_API_KEY',
  );

  static bool get hasApplicationId => parseApplicationId.trim().isNotEmpty;

  static bool get hasJavaScriptKey => parseJavaScriptKey.trim().isNotEmpty;

  static bool get hasRestApiKey => parseRestApiKey.trim().isNotEmpty;

  static void ensureDatabaseConfigured({required bool isWeb}) {
    if (!hasApplicationId) {
      throw const FormatException(
        'Configure PARSE_APPLICATION_ID no arquivo config/dev.json.',
      );
    }

    if (isWeb && !hasJavaScriptKey) {
      throw const FormatException(
        'Configure PARSE_JAVASCRIPT_KEY no arquivo config/dev.json.',
      );
    }

    if (!isWeb && !hasRestApiKey) {
      throw const FormatException(
        'Configure PARSE_REST_API_KEY no arquivo config/dev.json.',
      );
    }
  }
}
