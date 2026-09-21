/// Berikan melalui --dart-define agar URL tunnel/deployment tidak masuk Git.
/// Contoh: --dart-define=API_BASE_URL=https://103.93.129.187/api/v1
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://103.93.129.187/api/v1',
);
const String apiTimeout = '30000'; // ms
const int connectionTimeout = 30000;
const int receiveTimeout = 30000;
