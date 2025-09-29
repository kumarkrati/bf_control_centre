import 'package:bf_control_centre/core/app_storage.dart';

class LoginUtils {
  LoginUtils._();

  static bool get isLoggedIn {
    final token = AppStorage.get<String>('accessToken');
    return token != null && token.length > 10;
  }
}
