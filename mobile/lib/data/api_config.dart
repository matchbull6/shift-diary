/// Backend base URL. Override at build/run time, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   (Android emulator)
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000  (physical device)
/// Defaults to localhost, which works for `flutter run -d windows` / `-d chrome`
/// against a backend started on the same machine.
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
