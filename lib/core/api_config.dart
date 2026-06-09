class ApiConfig {
  static const String productionBaseUrl = 'https://www.myguanzhu.com';
  static const String localBaseUrl = 'http://192.168.3.60:8080';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: localBaseUrl,
  );
}
