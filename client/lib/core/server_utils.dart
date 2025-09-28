
enum LoginStatus {
  error,
  invalid,
  denied,
  success,
}

class ServerUtils {
  ServerUtils._();

  static const _api = 'http://localhost:8001/v1/';

  static Future<LoginStatus> login(String username, String password) async {
    // TODO: Implement later
    return LoginStatus.success;
  }
}
