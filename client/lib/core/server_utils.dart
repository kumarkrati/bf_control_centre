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

  static Future<List<dynamic>?> getTodaysNewUsers() async {
    try {
      final Map<String, dynamic> reqBody = {
        'key': _key,
        'credentials': _credentials,
      };
      final response = await http.post(
        Uri.parse('${_api}live-new-users'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 400) {
        return null; // Unauthorized
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint("[getTodaysNewUsers] Error: $e");
      return [];
    }
  }

  static Future<bool> assignSalesStaff({
    required String userId,
    required String userName,
    required String userAddress,
    required String assignedTo,
    required String notes,
  }) async {
    try {
      final Map<String, dynamic> reqBody = {
        'key': _key,
        'credentials': _credentials,
        'userId': userId,
        'userName': userName,
        'userAddress': userAddress,
        'assignedTo': assignedTo,
        'notes': notes,
      };
      final response = await http.post(
        Uri.parse('${_api}assign-sales-staff'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("[assignSalesStaff] Error: $e");
      return false;
    }
  }

  static Future<GenerateInvoiceResult> generateInvoice({
    required String phone,
    required String planType,
    required int planDuration,
    required DateTime invoiceDate,
    required int amount, // Final amount in paisa
    String? gstin,
    String? address,
    String? businessName,
  }) async {
    try {
      final Map<String, dynamic> reqBody = {
        'key': _key,
        'credentials': _credentials,
        'phone': phone,
        'planType': planType,
        'planDuration': planDuration,
        'invoiceDate': invoiceDate.toIso8601String(),
        'amount': amount,
        'gstin': gstin,
        'address': address,
        'businessName': businessName,
      };
      final response = await http.post(
        Uri.parse('${_api}generate-invoice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 400) {
        return GenerateInvoiceResult(GenerateInvoiceStatus.unauthorized, null);
      } else if (response.statusCode == 404) {
        return GenerateInvoiceResult(GenerateInvoiceStatus.noRef, null);
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GenerateInvoiceResult(
          GenerateInvoiceStatus.success,
          data['invoice'],
        );
      }
      return GenerateInvoiceResult(GenerateInvoiceStatus.failed, null);
    } catch (e) {
      debugPrint("[generateInvoice] Error: $e");
      return GenerateInvoiceResult(GenerateInvoiceStatus.failed, null);
    }
  }

  static Future<FetchInvoicesResult> fetchInvoices({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final start = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
      );
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      final Map<String, dynamic> reqBody = {
        'key': _key,
        'credentials': _credentials,
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
      };
      final response = await http.post(
        Uri.parse('${_api}fetch-invoices'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 400) {
        return FetchInvoicesResult(FetchInvoicesStatus.unauthorized, []);
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FetchInvoicesResult(
          FetchInvoicesStatus.success,
          List<Map<String, dynamic>>.from(data['invoices'] ?? []),
        );
      }
      return FetchInvoicesResult(FetchInvoicesStatus.failed, []);
    } catch (e) {
      debugPrint("[fetchInvoices] Error: $e");
      return FetchInvoicesResult(FetchInvoicesStatus.failed, []);
    }
  }
}

class GenerateInvoiceResult {
  final GenerateInvoiceStatus status;
  final Map<String, dynamic>? invoice;

  GenerateInvoiceResult(this.status, this.invoice);
}

class FetchInvoicesResult {
  final FetchInvoicesStatus status;
  final List<Map<String, dynamic>> invoices;

  FetchInvoicesResult(this.status, this.invoices);
}
