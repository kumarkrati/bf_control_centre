
enum LoginStatus {
  error,
  invalid,
  denied,
  success,
}

class ServerUtils {
  ServerUtils._();

  static Future<LoginStatus> login(String username, String password) async {
    // TODO: Implement later
    return LoginStatus.success;
  }
}
