import 'package:bf_control_centre/core/app_storage.dart';

class LoginUtils {
  LoginUtils._();

  static bool get isLoggedIn {
    final credentials = AppStorage.get<Map>('credentials');
    if (credentials == null) return false;
    return credentials['token'] != null;
  }
}
