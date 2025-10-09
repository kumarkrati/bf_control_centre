import 'dart:convert';
import 'package:bf_control_centre/core/app_storage.dart';
import 'package:bf_control_centre/core/encryption/key_compiler.dart';
import 'package:bf_control_centre/core/enums.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ViewPasswordResult {
  final ViewPasswordStatus status;
  final String? password;

  ViewPasswordResult(this.status, this.password);
}

class ServerUtils {
  ServerUtils._();

  static const _api = 'https://apis.billingfast.com:8001/v1/';
  static String get _key => createKey().value;
  static String get _accessToken => AppStorage.get<String>('accessToken')!;
  static get _credentials => {
    "username": AppStorage.get<String>('username'),
    "token": _accessToken,
  };

  static Future<LoginStatus> login(String username, String password) async {
    try {
      final Map<String, dynamic> reqBody = {
        "key": _key,
        "username": username,
        "password": password,
      };
      final response = await http.post(
        Uri.parse('${_api}authorize'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      debugPrint("[login]StatusCode: ${response.statusCode}");
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await AppStorage.set('name', responseData['name']);
        await AppStorage.set('username', username);
        await AppStorage.set('accessToken', responseData['token']);
        await AppStorage.set('role', responseData['role']);
        return LoginStatus.success;
      } else if (response.statusCode == 401) {
        return LoginStatus.invalid;
      } else if (response.statusCode == 400) {
        return LoginStatus.denied;
      }
      return LoginStatus.error;
    } catch (e) {
      debugPrint("[login] Error: $e ");
      return LoginStatus.error;
    }
  }

  static Future<InvoiceNumberStatus> reassignInvoice(String id) async {
    try {
      final Map<String, dynamic> reqBody = {
        "key": _key,
        "credentials": _credentials,
        "id": id,
      };
      final response = await http.post(
        Uri.parse('${_api}reassing-invoice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 400) {
        return InvoiceNumberStatus.unauthorized;
      }
      return InvoiceNumberStatus.success;
    } catch (e) {
      debugPrint("[login] Error: $e ");
      return InvoiceNumberStatus.fail;
    }
  }

  static Future<RestoreProdStatus> restoreProducts(String id) async {
    try {
      final Map<String, dynamic> reqBody = {
        "key": _key,
        "credentials": _credentials,
        "id": id,
      };
      final response = await http.post(
        Uri.parse('${_api}restore-product'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 400) {
        return RestoreProdStatus.unauthorized;
      } else if (response.statusCode == 200) {
        return RestoreProdStatus.values[jsonDecode(response.body)['message']];
      }
      return RestoreProdStatus.failed;
    } catch (e) {
      debugPrint("[login] Error: $e ");
      return RestoreProdStatus.failed;
    }
  }

  static Future<ViewPasswordResult> viewPassword(String mobile) async {
    try {
      final Map<String, dynamic> reqBody = {
        "id": mobile,
        "key": _key,
        "credentials": _credentials,
      };
      final response = await http.post(
        Uri.parse('${_api}view-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 400) {
        return ViewPasswordResult(ViewPasswordStatus.unauthorized, null);
      } else if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['messsage'] == "User is not registered") {
          return ViewPasswordResult(ViewPasswordStatus.noRef, null);
        } else if (responseData['messsage'] == "No password has been set yet") {
          return ViewPasswordResult(ViewPasswordStatus.noPasswordSet, null);
        } else {
          return ViewPasswordResult(
            ViewPasswordStatus.success,
            responseData['password']
                .toString()
                .split("\$")
                .map((e) => String.fromCharCode(int.parse(e)))
                .join(),
          );
        }
      }
      return ViewPasswordResult(ViewPasswordStatus.failed, null);
    } catch (e) {
      debugPrint("[viewPassword] Error: $e ");
      return ViewPasswordResult(ViewPasswordStatus.failed, null);
    }
  }

  static Future<SetPasswordStatus> setPassword(String mobile) async {
    try {
      final Map<String, dynamic> reqBody = {
        "id": mobile,
        "key": _key,
        "credentials": _credentials,
      };
      final response = await http.post(
        Uri.parse('${_api}set-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 400) {
        return SetPasswordStatus.unauthorized;
      } else if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'];
        return SetPasswordStatus.values[message];
      } else {
        return SetPasswordStatus.failed;
      }
    } catch (e) {
      debugPrint("[setPassword] Error: $e ");
      return SetPasswordStatus.failed;
    }
  }

  static Future<UpdateSubscriptionStatus> updateSubscription({
    required String id,
    required String planType,
    required int planDuration,
    required DateTime startDate,
  }) async {
    try {
      final Map<String, dynamic> reqBody = {
        'key': _key,
        'credentials': _credentials,
        'id': id,
        'subPlan': planType,
        'subDays': planDuration,
        'updatedBy': AppStorage.get<String>('username'),
        'subStartedDate': startDate.toIso8601String(),
      };
      final response = await http.post(
        Uri.parse('${_api}subscription'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 400) {
        return UpdateSubscriptionStatus.unauthorized;
      } else if (response.statusCode == 200) {
        return UpdateSubscriptionStatus.success;
      } else if (response.statusCode == 404) {
        return UpdateSubscriptionStatus.noRef;
      }
      return UpdateSubscriptionStatus.failed;
    } catch (e) {
      debugPrint("[updateSubscription] Error: $e ");
      return UpdateSubscriptionStatus.failed;
    }
  }

  static Future<CreateAccountStatus> createAccount({
    required String id,
    required String mobile,
  }) async {
    try {
      final Map<String, dynamic> reqBody = {
        'key': _key,
        'credentials': _credentials,
        'id': id,
        'mobile': mobile,
      };
      final response = await http.post(
        Uri.parse('${_api}create-account'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 400) {
        return CreateAccountStatus.unauthorized;
      } else if (response.statusCode == 200) {
        return CreateAccountStatus.success;
      } else if (response.statusCode == 404) {
        return CreateAccountStatus.alreadyRegistered;
      }
      return CreateAccountStatus.failed;
    } catch (e) {
      debugPrint("[updateSubscription] Error: $e ");
      return CreateAccountStatus.failed;
    }
  }

  static Future<List<dynamic>?> getDownloadedUsers(
    DateTime start,
    DateTime end,
  ) async {
    try {
      start = DateTime(start.year, start.month, start.day, 0, 0, 0);
      end = DateTime(end.year, end.month, end.day, 23, 59, 59);
      final Map<String, dynamic> reqBody = {
        'key': _key,
        'credentials': _credentials,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };
      final response = await http.post(
        Uri.parse('${_api}download-users'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 400) {
        return null;
      } else if (response.statusCode == 500) {
        return [];
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'];
      }
      return null;
    } catch (e) {
      debugPrint("[updateSubscription] Error: $e ");
      return null;
    }
  }

  static Future<dynamic> getVMHealth() async {
    try {
      final response = await http.get(
        Uri.parse('https://apis.billingfast.com:9870/full-health'),
        headers: {
          "Content-Type": "application/json",
          "x-api-key": "6vx1ATV4zV5gEX6yG2S5T74A3uE523e2fL1ibrYp6Hl96Bx2p0",
        },
      );
      if (response.statusCode == 400) {
        return null;
      } else if (response.statusCode == 500) {
        return "error";
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // a sample response is available at client\sample-health-response.json
      }
      return null;
    } catch (e) {
      debugPrint("[getVMHealth] Error: $e ");
      return null;
    }
  }
}
