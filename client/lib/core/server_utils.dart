import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum LoginStatus { error, invalid, denied, success }

enum InvoiceNumberStatus { success, fail }

class ServerUtils {
  ServerUtils._();

  static const _api = 'http://0.0.0.0:8001/v1/';
  static String? _accessToken;

  static Future<LoginStatus> login(String username, String password) async {
    try {
      final Map<String, dynamic> reqBody = {
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
        _accessToken = responseData['token'];
        debugPrint("[login] $_accessToken");
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
        "id": id,
        "key": "",
        "credentials": {"username": username, "token": _accessToken},
      };
      final response = await http.post(
        Uri.parse('$_api/reassing-invoice'),
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
}
