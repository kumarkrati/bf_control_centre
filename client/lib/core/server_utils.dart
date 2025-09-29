import 'dart:convert';
import 'package:bf_control_centre/core/app_storage.dart';
import 'package:bf_control_centre/core/encryption/key_compiler.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum LoginStatus { error, invalid, denied, success }

enum InvoiceNumberStatus { success, fail }

enum RestoreProdStatus { restored, failed }

class ServerUtils {
  ServerUtils._();

  static const _api = 'http://localhost:8001/v1/';
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
        await AppStorage.set('roles', responseData['role']);
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

  static Future<InvoiceNumberStatus> reassignInvoice(
    String username,
    String id,
  ) async {
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
      if (response.statusCode == 401) {
        return InvoiceNumberStatus.fail;
      } else if (response.statusCode == 400) {
        return InvoiceNumberStatus.fail;
      }
      return InvoiceNumberStatus.success;
    } catch (e) {
      debugPrint("[login] Error: $e ");
      return InvoiceNumberStatus.fail;
    }
  }

  static Future<RestoreProdStatus> restoreProducts(
    String username,
    String id,
  ) async {
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

      if (response.statusCode == 201) {
        return RestoreProdStatus.restored;
      }
      return RestoreProdStatus.failed;
    } catch (e) {
      debugPrint("[login] Error: $e ");
      return RestoreProdStatus.failed;
    }
  }
}
