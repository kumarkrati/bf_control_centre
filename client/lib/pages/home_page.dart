import 'dart:convert';

import 'package:bf_control_centre/core/app_storage.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:bf_control_centre/core/enums.dart';
import 'package:bf_control_centre/core/login_utils.dart';
import 'package:bf_control_centre/core/server_utils.dart';
import 'package:bf_control_centre/core/utils/convert_to_days.dart';
import 'package:bf_control_centre/core/utils/subscription_receipt_template_1.dart';
import 'package:bf_control_centre/pages/home_page_downloaded_users.dart';
import 'package:bf_control_centre/pages/todays_new_users_page.dart';
import 'package:bf_control_centre/pages/login_page.dart';
import 'package:bf_control_centre/widgets/vm_health_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

final _mobileController = TextEditingController();

class _HomePageState extends State<HomePage> {
  bool _showLoginButton = false;
  bool _showRecentMobiles = false;
  List<String> _recentMobiles = [];
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_onMobileNumberChanged);
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadRecentMobiles();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadRecentMobiles() {
    setState(() {
      _recentMobiles = AppStorage.getRecentMobiles();
    });
  }

  void _onMobileNumberChanged() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        setState(() {
          _showLoginButton = _mobileController.text.trim().isNotEmpty;
        });
      }
    });
  }

  Future<void> _saveMobileNumber(String mobile) async {
    if (mobile.trim().isNotEmpty) {
      await AppStorage.addRecentMobile(mobile);
      _loadRecentMobiles();
    }
  }

  void _loginToBillingFast() {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _createNewAccount() async {
    final mobile = _mobileController.text.trim();

    // Save to recent entries
    if (mobile.isNotEmpty) {
      await _saveMobileNumber(mobile);
    }

    if (mobile.isEmpty) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          content: Text('Please enter customer mobile number'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(width: 12),
            const Text('Create New Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to create a new account for:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Color(0xFF3B82F6), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    mobile,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Creating Account...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we create the account',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    final result = await ServerUtils.createAccount(id: mobile, mobile: mobile);

    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 500));

    if (result == CreateAccountStatus.success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Account has been successfully created for $mobile',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else if (result == CreateAccountStatus.unauthorized) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.security, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Your session has expired, relogin is required.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF660011),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (result == CreateAccountStatus.alreadyRegistered) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(child: Text('User is already registered.')),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Failed to create account. Please try again.'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showPasswordManagement() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isNotEmpty) {
      await _saveMobileNumber(mobile);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => const PasswordManagementSheet(),
    );
  }

  void _showSubscriptionManagement() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isNotEmpty) {
      await _saveMobileNumber(mobile);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => const SubscriptionManagementSheet(),
    );
  }

  void _showShopManagement() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isNotEmpty) {
      await _saveMobileNumber(mobile);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => const ShopManagementSheet(),
    );
  }

  void _showCustomerRetention() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isNotEmpty) {
      await _saveMobileNumber(mobile);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => const CustomerRetentionSheet(),
    );
  }

  void _showFeaturesList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BillingFast Control Centre',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF172a43),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: Text(
                        'All requests are being recorded under name "${AppStorage.get('name')}", keep your login secure.',
                        maxLines: 2,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF172a43),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'v4.0.0+400',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Here's a list of active features:",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF172a43),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFeatureItem('Password Management'),
                    _buildFeatureItem('Shop Management > Restore Products'),
                    _buildFeatureItem('Shop Management > Repair Orders'),
                    _buildFeatureItem('Customer Retention > Download users'),
                    _buildFeatureItem('Create New Account (Admin)'),
                    _buildFeatureItem('Update Subscription (Admin)'),
                    _buildFeatureItem('Server Health (Admin)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 14, color: Color(0xFF172a43)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: LoginUtils.isAdmin ? const VMHealthFAB() : null,
      appBar: AppBar(
        title: const Text('BillingFast Control Centre'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Info',
          onPressed: _showFeaturesList,
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(12),
          child: Text(
            "Logged in as ${AppStorage.get('name')}",
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              AppStorage.set('accessToken', '');
              Get.off(LoginPage());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer Search Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Customer Lookup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF172a43),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mobileController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Customer Mobile Number',
                      prefixIcon: Icon(Icons.phone),
                      hintText: '+91 XXXXX XXXXX',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  if (_recentMobiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showRecentMobiles = !_showRecentMobiles;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Recent mobile numbers (${_recentMobiles.length})',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _showRecentMobiles
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_showRecentMobiles && _recentMobiles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _recentMobiles.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final mobile = _recentMobiles[index];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.phone,
                                size: 16,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            title: Text(
                              mobile,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  color: Colors.grey.shade600,
                                  tooltip: 'Copy',
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: mobile),
                                    );
                                    ScaffoldMessenger.of(
                                      Get.context!,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text('Copied: $mobile'),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  color: Colors.red.shade400,
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    setState(() {
                                      _recentMobiles.removeAt(index);
                                    });
                                    await _prefs.setString(
                                      'recent_mobile_numbers',
                                      jsonEncode(_recentMobiles),
                                    );
                                    _loadRecentMobiles();
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              _mobileController.text = mobile;
                              setState(() {
                                _showRecentMobiles = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  if (_showLoginButton) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loginToBillingFast,
                            icon: const Icon(Icons.login, size: 18),
                            label: const Text('Login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _createNewAccount,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Create Account'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Management Tools',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172a43),
              ),
            ),
            const SizedBox(height: 16),

            // Management Cards Grid
            _buildManagementCard(
              title: 'Password Management',
              subtitle: 'View and reset customer passwords',
              icon: Icons.security,
              color: const Color(0xFFEF4444),
              onTap: _showPasswordManagement,
            ),
            if (AppStorage.get<String>('role') == 'ADMIN') ...[
              const SizedBox(height: 16),
              _buildManagementCard(
                title: 'Subscription Management',
                subtitle: 'Manage plans and billing cycles',
                icon: Icons.credit_card,
                color: const Color(0xFF10B981),
                onTap: _showSubscriptionManagement,
              ),
              const SizedBox(height: 16),
              _buildManagementCard(
                title: 'Shop Management',
                subtitle: 'Configure stores and products',
                icon: Icons.storefront,
                color: const Color(0xFF8B5CF6),
                onTap: _showShopManagement,
              ),
            ],
            const SizedBox(height: 16),
            _buildManagementCard(
              title: 'Customer Retention',
              subtitle:
                  'See new unsubscribed customers from last 5 days or expiring plans',
              icon: Icons.people_alt,
              color: const Color(0xFFF59E0B),
              onTap: _showCustomerRetention,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF172a43),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordManagementSheet extends StatefulWidget {
  const PasswordManagementSheet({super.key});

  @override
  State<PasswordManagementSheet> createState() =>
      _PasswordManagementSheetState();
}

class _PasswordManagementSheetState extends State<PasswordManagementSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Password Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF172a43),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildPasswordOption(
            icon: Icons.visibility_outlined,
            title: 'View Current Password',
            subtitle: 'Display the current password',
            color: const Color(0xFF3B82F6),
            onTap: () async {
              final mobile = _mobileController.text.trim();
              if (mobile.isEmpty) {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(content: Text('Please enter customer ID')),
                );
                return;
              }

              final result = await ServerUtils.viewPassword(mobile);
              Navigator.pop(context);
              await Future.delayed(Duration(milliseconds: 500));
              if (result.status == ViewPasswordStatus.success) {
                showDialog(
                  context: Get.context!,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.password}',
                          style: GoogleFonts.poppins(fontSize: 28),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: result.password!),
                          );
                        },
                        child: const Text('Copy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              } else if (result.status == ViewPasswordStatus.unauthorized) {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.security, color: Colors.white),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Your session has expired, relogin is required.',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF660011),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else if (result.status == ViewPasswordStatus.noRef) {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(content: Text('User is not registered')),
                );
              } else if (result.status == ViewPasswordStatus.noPasswordSet) {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(content: Text('No password has been set yet')),
                );
              } else {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(content: Text('Failed to retrieve password')),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _buildPasswordOption(
            icon: Icons.refresh_rounded,
            title: 'Reset Password',
            subtitle: 'Generate a new password',
            color: const Color(0xFFEF4444),
            onTap: () async {
              final mobile = _mobileController.text.trim();
              if (mobile.isEmpty) {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(content: Text('Please enter customer ID')),
                );
                return;
              }

              Navigator.pop(context);

              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Password Reset'),
                  content: Text(
                    'Are you sure you want to reset password for customer $mobile?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              final result = await ServerUtils.setPassword(mobile);

              if (result == SetPasswordStatus.success) {
                showDialog(
                  context: Get.context!,
                  builder: (context) => AlertDialog(
                    title: const Text('Password Reset Complete'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Password has been reset for customer: $mobile'),
                        const SizedBox(height: 8),
                        const Text('New password: shop@123'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              } else if (result == SetPasswordStatus.unauthorized) {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.security, color: Colors.white),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Your session has expired, relogin is required.',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF660011),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to reset password'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF172a43),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SubscriptionManagementSheet extends StatefulWidget {
  const SubscriptionManagementSheet({super.key});

  @override
  State<SubscriptionManagementSheet> createState() =>
      _SubscriptionManagementSheetState();
}

class _SubscriptionManagementSheetState
    extends State<SubscriptionManagementSheet> {
  int _selectedOption =
      0; // 0 = Update Subscription, 1 = Generate Invoice, 2 = View Invoices, 3 = Pending Receipts

  // Update Subscription fields
  String _subSelectedPlan = 'PREMIUM';
  String _subSelectedDuration = '1 month';
  DateTime _subStartDate = DateTime.now();
  bool _generateReceiptAfterUpdate = true;

  // Generate Invoice fields
  String _selectedPlan = 'PREMIUM';
  String _selectedDuration = '1 month';
  DateTime _invoiceDate = DateTime.now();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();

  // View Invoices fields
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoadingInvoices = false;
  final TextEditingController _invoiceSearchController = TextEditingController();
  String _invoiceSearchQuery = '';

  // Pending Receipts fields
  DateTime _pendingReceiptsStartDate = DateTime.now().subtract(
    const Duration(days: 30),
  );
  DateTime _pendingReceiptsEndDate = DateTime.now();
  List<Map<String, dynamic>> _pendingReceiptsUsers = [];
  bool _isLoadingPendingReceipts = false;
  final TextEditingController _pendingSearchController = TextEditingController();
  String _pendingSearchQuery = '';

  final List<String> _planTypes = ['PREMIUM', 'ULTRA', 'LITE'];
  final List<String> _durations = [
    '1 day',
    '2 day',
    '3 days',
    '4 days',
    '5 days',
    '6 days',
    '7 days',
    '14 days',
    '15 days',
    '1 month',
    '1 year',
    '13 months',
    '2 years',
    '5 years',
  ];

  @override
  void initState() {
    super.initState();
    // Autofill phone number from home page
    _phoneController.text = _mobileController.text.trim();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    _businessNameController.dispose();
    _invoiceSearchController.dispose();
    _pendingSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoadingInvoices = true);
    final result = await ServerUtils.fetchInvoices(
      startDate: _startDate,
      endDate: _endDate,
    );
    setState(() {
      _isLoadingInvoices = false;
      if (result.status == FetchInvoicesStatus.success) {
        _invoices = result.invoices;
      } else if (result.status == FetchInvoicesStatus.unauthorized) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.security, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Your session has expired, relogin is required.'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF660011),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to fetch invoices.'),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  Future<void> _fetchPendingReceipts() async {
    setState(() => _isLoadingPendingReceipts = true);
    final result = await ServerUtils.fetchPendingReceipts(
      startDate: _pendingReceiptsStartDate,
      endDate: _pendingReceiptsEndDate,
    );
    setState(() {
      _isLoadingPendingReceipts = false;
      if (result.status == FetchPendingReceiptsStatus.success) {
        _pendingReceiptsUsers = result.users;
      } else if (result.status == FetchPendingReceiptsStatus.unauthorized) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.security, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Your session has expired, relogin is required.'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF660011),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to fetch pending receipts.'),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    final amountInRupees =
        (amount is int ? amount : (amount as num).toInt()) / 100;
    return amountInRupees.toStringAsFixed(2);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Subscription Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF172a43),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tab selector
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedOption = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedOption == 0
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedOption == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card,
                            size: 18,
                            color: _selectedOption == 0
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Update',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedOption == 0
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedOption = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedOption == 1
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedOption == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 18,
                            color: _selectedOption == 1
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Generate',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedOption == 1
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedOption = 2);
                      if (_invoices.isEmpty) {
                        _fetchInvoices();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedOption == 2
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedOption == 2
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list_alt,
                            size: 18,
                            color: _selectedOption == 2
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedOption == 2
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedOption = 3);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedOption == 3
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedOption == 3
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pending_actions,
                            size: 18,
                            color: _selectedOption == 3
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pending',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedOption == 3
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: _selectedOption == 0
                ? _buildUpdateSubscriptionForm()
                : _selectedOption == 1
                ? _buildGenerateInvoiceForm()
                : _selectedOption == 2
                ? _buildViewInvoicesTable()
                : _buildPendingReceiptsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSubscriptionForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputSection(
                  'Plan Type',
                  Icons.workspace_premium,
                  DropdownButtonFormField<String>(
                    value: _subSelectedPlan,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: _planTypes
                        .map(
                          (plan) =>
                              DropdownMenuItem(value: plan, child: Text(plan)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _subSelectedPlan = value!),
                  ),
                ),
                const SizedBox(height: 20),

                _buildInputSection(
                  'Plan Duration',
                  Icons.schedule,
                  DropdownButtonFormField<String>(
                    value: _subSelectedDuration,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: _durations
                        .map(
                          (duration) => DropdownMenuItem(
                            value: duration,
                            child: Text(duration),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _subSelectedDuration = value!),
                  ),
                ),
                const SizedBox(height: 20),

                _buildInputSection(
                  'Start Date',
                  Icons.calendar_today,
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _subStartDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _subStartDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _subStartDate.toString().split(' ')[0],
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Generate Receipt checkbox
                InkWell(
                  onTap: () => setState(
                    () => _generateReceiptAfterUpdate =
                        !_generateReceiptAfterUpdate,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _generateReceiptAfterUpdate
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _generateReceiptAfterUpdate
                            ? const Color(0xFF10B981)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _generateReceiptAfterUpdate
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: _generateReceiptAfterUpdate
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade400,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Generate Receipt',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF172a43),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Shows a dialog to generate receipt after successful update',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _handleUpdateSubscription,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Update Subscription'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpdateSubscription() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(content: Text('Please enter customer mobile number')),
      );
      return;
    }

    Navigator.pop(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: Get.context!,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.credit_card, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 12),
            const Text('Update Subscription'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to update subscription for:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    mobile,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Plan: $_subSelectedPlan\nDuration: $_subSelectedDuration\nStart Date: ${_subStartDate.toString().split(' ')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Updating Subscription...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we update the subscription',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    final result = await ServerUtils.updateSubscription(
      id: mobile,
      planType: _subSelectedPlan,
      planDuration: convertToDays(
        int.parse(_subSelectedDuration.split(" ")[0]),
        _subSelectedDuration.split(" ")[1],
      ),
      startDate: _subStartDate,
    );

    Navigator.pop(Get.context!);
    await Future.delayed(const Duration(milliseconds: 500));

    if (result == UpdateSubscriptionStatus.success) {
      if (_generateReceiptAfterUpdate) {
        // Show dialog to collect amount and optional details for receipt generation
        await _showGenerateReceiptDialog(
          mobile: mobile,
          planType: _subSelectedPlan,
          planDuration: _subSelectedDuration,
          invoiceDate: _subStartDate,
        );
      } else {
        showDialog(
          context: Get.context!,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Success!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Subscription has been successfully updated for customer $mobile',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } else if (result == UpdateSubscriptionStatus.unauthorized) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.security, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Your session has expired, relogin is required.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF660011),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (result == UpdateSubscriptionStatus.noRef) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('User not registered.')),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to update subscription. Please try again.'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _showGenerateReceiptDialog({
    required String mobile,
    required String planType,
    required String planDuration,
    required DateTime invoiceDate,
  }) async {
    final amountController = TextEditingController();
    final gstinController = TextEditingController();
    final addressController = TextEditingController();
    final businessNameController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>?>(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Generate Receipt', style: TextStyle(fontSize: 18)),
                  Text(
                    'Subscription updated successfully!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDialogDetailRow('Phone', mobile),
                    _buildDialogDetailRow('Plan', planType),
                    _buildDialogDetailRow('Duration', planDuration),
                    _buildDialogDetailRow(
                      'Date',
                      invoiceDate.toString().split(' ')[0],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount field (required)
              const Text(
                'Amount Paid (in Rupees) *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g., 299.00',
                  prefixText: '\u20B9 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  helperText: '18% GST auto-calculated for Indian numbers',
                  helperStyle: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Optional fields section
              ExpansionTile(
                title: Text(
                  'Optional Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                children: [
                  TextField(
                    controller: gstinController,
                    decoration: InputDecoration(
                      labelText: 'GSTIN',
                      hintText: 'Enter GSTIN',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: businessNameController,
                    decoration: InputDecoration(
                      labelText: 'Business Name',
                      hintText: 'Enter business name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text('Skip'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final amountText = amountController.text.trim();
              if (amountText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter the amount')),
                );
                return;
              }
              final amount = double.tryParse(amountText);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              Navigator.pop(context, {
                'amount': (amount * 100).round(), // Convert to paisa
                'gstin': gstinController.text.trim(),
                'address': addressController.text.trim(),
                'businessName': businessNameController.text.trim(),
              });
            },
            icon: const Icon(Icons.receipt_long, size: 18),
            label: const Text('Generate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    // Dispose controllers
    amountController.dispose();
    gstinController.dispose();
    addressController.dispose();
    businessNameController.dispose();

    if (result == null) {
      // User skipped receipt generation
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Subscription updated successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Generating Receipt...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );

    // Generate the invoice
    final invoiceResult = await ServerUtils.generateInvoice(
      phone: mobile,
      planType: planType,
      planDuration: convertToDays(
        int.parse(planDuration.split(" ")[0]),
        planDuration.split(" ")[1],
      ),
      invoiceDate: invoiceDate,
      amount: result['amount'] as int,
      gstin: result['gstin']?.isNotEmpty == true ? result['gstin'] : null,
      address: result['address']?.isNotEmpty == true ? result['address'] : null,
      businessName: result['businessName']?.isNotEmpty == true
          ? result['businessName']
          : null,
    );

    Navigator.pop(Get.context!); // Close loading dialog

    if (invoiceResult.status == GenerateInvoiceStatus.success) {
      showDialog(
        context: Get.context!,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'All Done!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Subscription updated and Receipt #${invoiceResult.invoice?['invoiceNo'] ?? 'N/A'} generated for $mobile',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else if (invoiceResult.status == GenerateInvoiceStatus.unauthorized) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.security, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Session expired. Subscription was updated but receipt generation failed.',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF660011),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Subscription updated but receipt generation failed.',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildDialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateInvoiceForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputSection(
                  'Phone Number *',
                  Icons.phone,
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter customer phone number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildInputSection(
                  'Plan Type *',
                  Icons.workspace_premium,
                  DropdownButtonFormField<String>(
                    value: _selectedPlan,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: _planTypes
                        .map(
                          (plan) =>
                              DropdownMenuItem(value: plan, child: Text(plan)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedPlan = value!),
                  ),
                ),
                const SizedBox(height: 20),

                _buildInputSection(
                  'Plan Duration *',
                  Icons.schedule,
                  DropdownButtonFormField<String>(
                    value: _selectedDuration,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: _durations
                        .map(
                          (duration) => DropdownMenuItem(
                            value: duration,
                            child: Text(duration),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedDuration = value!),
                  ),
                ),
                const SizedBox(height: 20),

                _buildInputSection(
                  'Invoice Date *',
                  Icons.calendar_today,
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _invoiceDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _invoiceDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _invoiceDate.toString().split(' ')[0],
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildInputSection(
                  'Amount Paid by Customer (in Rupees) *',
                  Icons.currency_rupee,
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter amount (e.g., 299.00)',
                      prefixText: '\u20B9 ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      helperText:
                          'For Indian numbers, 18% GST will be calculated automatically',
                      helperStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Optional fields section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Optional Fields',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildInputSection(
                        'GSTIN',
                        Icons.business,
                        TextFormField(
                          controller: _gstinController,
                          decoration: InputDecoration(
                            hintText: 'Enter GSTIN (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildInputSection(
                        'Business Name',
                        Icons.store,
                        TextFormField(
                          controller: _businessNameController,
                          decoration: InputDecoration(
                            hintText: 'Enter business name (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildInputSection(
                        'Address',
                        Icons.location_on,
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Enter address (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _handleGenerateInvoice,
            icon: const Icon(Icons.receipt_long, size: 20),
            label: const Text('Generate Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGenerateInvoice() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(content: Text('Please enter customer phone number')),
      );
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(
        Get.context!,
      ).showSnackBar(const SnackBar(content: Text('Please enter the amount')));
      return;
    }

    final amountInRupees = double.tryParse(amountText);
    if (amountInRupees == null || amountInRupees <= 0) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Convert to paisa (smallest currency unit)
    final amountInPaisa = (amountInRupees * 100).round();

    Navigator.pop(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: Get.context!,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 12),
            const Text('Generate Invoice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generate invoice with the following details:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Phone', phone),
                  _buildDetailRow('Plan', _selectedPlan),
                  _buildDetailRow('Duration', _selectedDuration),
                  _buildDetailRow(
                    'Date',
                    _invoiceDate.toString().split(' ')[0],
                  ),
                  _buildDetailRow('Amount', '\u20B9 $amountText'),
                  if (_gstinController.text.isNotEmpty)
                    _buildDetailRow('GSTIN', _gstinController.text),
                  if (_businessNameController.text.isNotEmpty)
                    _buildDetailRow('Business', _businessNameController.text),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Generate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Generating Invoice...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );

    final result = await ServerUtils.generateInvoice(
      phone: phone,
      planType: _selectedPlan,
      planDuration: convertToDays(
        int.parse(_selectedDuration.split(" ")[0]),
        _selectedDuration.split(" ")[1],
      ),
      invoiceDate: _invoiceDate,
      amount: amountInPaisa,
      gstin: _gstinController.text.isNotEmpty ? _gstinController.text : null,
      address: _addressController.text.isNotEmpty
          ? _addressController.text
          : null,
      businessName: _businessNameController.text.isNotEmpty
          ? _businessNameController.text
          : null,
    );

    Navigator.pop(Get.context!);
    await Future.delayed(const Duration(milliseconds: 300));

    if (result.status == GenerateInvoiceStatus.success) {
      showDialog(
        context: Get.context!,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Invoice Generated!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Invoice #${result.invoice?['invoiceNo'] ?? 'N/A'} has been generated for $phone',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else if (result.status == GenerateInvoiceStatus.noRef) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('User not registered.')),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (result.status == GenerateInvoiceStatus.unauthorized) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.security, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Your session has expired, relogin is required.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF660011),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to generate invoice. Please try again.'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewInvoicesTable() {
    return Column(
      children: [
        // Date filter row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _startDate.toString().split(' ')[0],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('to'),
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _endDate.toString().split(' ')[0],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _fetchInvoices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.search, size: 20),
              ),
              if (_invoices.isNotEmpty) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _downloadAllReceipts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download All'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Search by phone field and Export button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _invoiceSearchController,
                decoration: InputDecoration(
                  hintText: 'Search by phone number',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981), size: 20),
                  suffixIcon: _invoiceSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _invoiceSearchController.clear();
                            setState(() => _invoiceSearchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => setState(() => _invoiceSearchQuery = value.trim()),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _invoices.isEmpty ? null : _exportInvoicesToCsv,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Inv #',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF172a43),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Phone',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF172a43),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF172a43),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Days',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF172a43),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF172a43),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Date',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF172a43),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF172a43),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Table body
        Expanded(
          child: _isLoadingInvoices
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                  ),
                )
              : _invoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No invoices found',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting the date filter',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : Builder(
                  builder: (context) {
                    final filteredInvoices = _invoiceSearchQuery.isEmpty
                        ? _invoices
                        : _invoices.where((invoice) {
                            final phone = (invoice['phone'] ?? '').toString().toLowerCase();
                            return phone.contains(_invoiceSearchQuery.toLowerCase());
                          }).toList();

                    if (filteredInvoices.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No matching invoices',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different phone number',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: ListView.separated(
                        itemCount: filteredInvoices.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final invoice = filteredInvoices[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: index % 2 == 0
                            ? Colors.white
                            : Colors.grey.shade50,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                '#${invoice['invoiceNo'] ?? '-'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                invoice['phone'] ?? '-',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPlanColor(
                                    invoice['plan'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  invoice['plan'] ?? '-',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: _getPlanColor(invoice['plan']),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${invoice['days'] ?? '-'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${invoice['currency'] ?? 'INR'} ${_formatAmount(invoice['amount'])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatDate(invoice['time']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _showReceiptPreview(invoice),
                                    icon: const Icon(
                                      Icons.visibility,
                                      size: 18,
                                    ),
                                    tooltip: 'Preview',
                                    color: const Color(0xFF3B82F6),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _downloadSingleReceipt(invoice),
                                    icon: const Icon(Icons.download, size: 18),
                                    tooltip: 'Download',
                                    color: const Color(0xFF10B981),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
                  },
                ),
        ),

        // Summary row
        if (_invoices.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Invoices: ${_invoices.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF172a43),
                  ),
                ),
                Text(
                  'Total: INR ${_formatAmount(_invoices.fold<int>(0, (sum, inv) => sum + ((inv['amount'] ?? 0) as int)))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getPlanColor(String? plan) {
    switch (plan) {
      case 'ULTRA':
        return const Color(0xFF8B5CF6);
      case 'PREMIUM':
        return const Color(0xFF3B82F6);
      case 'LITE':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  Future<Uint8List> _generateReceiptPdf(dynamic invoice) async {
    final pdf = pw.Document();
    final logo = (await rootBundle.load('assets/images/logo.png'));
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) => [
          buildSubscriptionReceiptTemplate1(invoice, logo.buffer.asUint8List()),
        ],
      ),
    );
    return pdf.save();
  }

  void _showReceiptPreview(dynamic invoice) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice #${invoice['invoiceNo'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172a43),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _downloadSingleReceipt(invoice),
                        icon: const Icon(Icons.download),
                        tooltip: 'Download PDF',
                        color: const Color(0xFF10B981),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: PdfPreview(
                  initialPageFormat: PdfPageFormat.a4,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  canDebug: false,
                  pdfFileName:
                      'BillingFast Receipt ${invoice['invoiceNo'] ?? invoice['id']}.pdf',
                  build: (format) => _generateReceiptPdf(invoice),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadSingleReceipt(dynamic invoice) async {
    try {
      final pdfBytes = await _generateReceiptPdf(invoice);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'BillingFast Receipt ${invoice['invoiceNo'] ?? invoice['id']}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadAllReceipts() async {
    if (_invoices.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
            const SizedBox(height: 16),
            Text(
              'Generating ${_invoices.length} receipts...',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );

    try {
      final pdf = pw.Document();
      final logo = (await rootBundle.load('assets/images/logo.png'));

      for (final invoice in _invoices) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(16),
            build: (pw.Context context) => [
              buildSubscriptionReceiptTemplate1(
                invoice,
                logo.buffer.asUint8List(),
              ),
            ],
          ),
        );
      }

      final pdfBytes = await pdf.save();

      if (mounted) {
        Navigator.of(context).pop();
      }

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'BillingFast Receipts ${_startDate.toString().split(' ')[0]} to ${_endDate.toString().split(' ')[0]}.pdf',
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate receipts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportInvoicesToCsv() async {
    if (_invoices.isEmpty) return;

    try {
      // Apply current search filter
      final filteredInvoices = _invoiceSearchQuery.isEmpty
          ? _invoices
          : _invoices.where((invoice) {
              final phone = (invoice['phone'] ?? '').toString().toLowerCase();
              return phone.contains(_invoiceSearchQuery.toLowerCase());
            }).toList();

      if (filteredInvoices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No invoices to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // CSV Headers
      final List<List<dynamic>> rows = [
        ['Invoice No', 'Phone', 'Plan', 'Days', 'Amount (INR)', 'Date', 'GSTIN', 'Business Name', 'Address'],
      ];

      // Add data rows
      for (final invoice in filteredInvoices) {
        final amount = invoice['amount'];
        final formattedAmount = amount != null ? (amount / 100).toStringAsFixed(2) : '0.00';
        final date = invoice['time'] != null
            ? DateTime.tryParse(invoice['time'].toString())?.toLocal().toString().split(' ')[0] ?? '-'
            : '-';

        rows.add([
          invoice['invoiceNo'] ?? invoice['id'] ?? '-',
          invoice['phone'] ?? '-',
          invoice['plan'] ?? '-',
          invoice['days']?.toString() ?? '-',
          formattedAmount,
          date,
          invoice['gstin'] ?? '-',
          invoice['businessName'] ?? '-',
          invoice['address'] ?? '-',
        ]);
      }

      // Convert to CSV
      final csvData = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(utf8.encode(csvData));

      // Generate filename with date range
      final startStr = _startDate.toString().split(' ')[0];
      final endStr = _endDate.toString().split(' ')[0];
      final filename = 'BillingFast_Invoices_${startStr}_to_$endStr.csv';

      // Save file
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        mimeType: MimeType.csv,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${filteredInvoices.length} invoices to $filename'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPendingReceiptsTable() {
    return Column(
      children: [
        // Date filter row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _pendingReceiptsStartDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _pendingReceiptsStartDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _pendingReceiptsStartDate.toString().split(' ')[0],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'to',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _pendingReceiptsEndDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _pendingReceiptsEndDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _pendingReceiptsEndDate.toString().split(' ')[0],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoadingPendingReceipts
                    ? null
                    : _fetchPendingReceipts,
                icon: _isLoadingPendingReceipts
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.search, size: 18),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Search by phone field
        TextField(
          controller: _pendingSearchController,
          decoration: InputDecoration(
            hintText: 'Search by phone number',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981), size: 20),
            suffixIcon: _pendingSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _pendingSearchController.clear();
                      setState(() => _pendingSearchQuery = '');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF10B981)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) => setState(() => _pendingSearchQuery = value.trim()),
        ),
        const SizedBox(height: 16),

        // Results info
        if (_pendingReceiptsUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final filteredCount = _pendingSearchQuery.isEmpty
                        ? _pendingReceiptsUsers.length
                        : _pendingReceiptsUsers.where((user) {
                            final phone = (user['phone'] ?? '').toString().toLowerCase();
                            return phone.contains(_pendingSearchQuery.toLowerCase());
                          }).length;
                    return Text(
                      '$filteredCount user(s) with pending receipts',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    );
                  },
                ),
              ],
            ),
          ),

        // Table
        Expanded(
          child: _isLoadingPendingReceipts
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                  ),
                )
              : _pendingReceiptsUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending receipts found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a date and click Search',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : Builder(
                  builder: (context) {
                    final filteredUsers = _pendingSearchQuery.isEmpty
                        ? _pendingReceiptsUsers
                        : _pendingReceiptsUsers.where((user) {
                            final phone = (user['phone'] ?? '').toString().toLowerCase();
                            return phone.contains(_pendingSearchQuery.toLowerCase());
                          }).toList();

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No matching users',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different phone number',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // Table header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Phone',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Plan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Days',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(width: 80),
                            ],
                          ),
                        ),
                        // Table rows
                        ..._pendingReceiptsUsers.map((user) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    user['phone'] ?? '-',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    user['name'] ?? '-',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    user['subplan'] ?? '-',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${user['subdays'] ?? '-'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _prefillAndSwitchToGenerate(user),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Generate',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
                  },
                ),
        ),
      ],
    );
  }

  void _prefillAndSwitchToGenerate(Map<String, dynamic> user) {
    // Prefill the Generate Invoice form fields
    _phoneController.text = user['phone'] ?? '';
    _selectedPlan = user['subplan'] ?? 'PREMIUM';

    // Convert subdays to duration string
    final subdays = user['subdays'] as int? ?? 30;
    _selectedDuration = _convertDaysToDuration(subdays);

    // Set invoice date to substartedat
    if (user['substartedat'] != null) {
      try {
        _invoiceDate = DateTime.parse(user['substartedat']);
      } catch (e) {
        _invoiceDate = DateTime.now();
      }
    } else {
      _invoiceDate = DateTime.now();
    }

    // Clear amount and optional fields
    _amountController.clear();
    _gstinController.clear();
    _addressController.clear();
    _businessNameController.clear();

    // Switch to Generate tab
    setState(() => _selectedOption = 1);
  }

  String _convertDaysToDuration(int days) {
    if (days == 1) return '1 day';
    if (days == 2) return '2 day';
    if (days == 3) return '3 days';
    if (days == 4) return '4 days';
    if (days == 5) return '5 days';
    if (days == 6) return '6 days';
    if (days == 7) return '7 days';
    if (days == 14) return '14 days';
    if (days == 15) return '15 days';
    if (days == 30 || days == 31) return '1 month';
    if (days == 365) return '1 year';
    if (days == 395 || days == 396) return '13 months';
    if (days == 730) return '2 years';
    if (days == 1825 || days == 1826) return '5 years';
    // Default fallback
    return '1 month';
  }

  Widget _buildInputSection(String label, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF172a43),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class ShopManagementSheet extends StatelessWidget {
  const ShopManagementSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Shop Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172a43),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildShopOption(
              icon: Icons.store_outlined,
              title: 'View Shops',
              subtitle: 'See store listings',
              color: const Color(0xFF3B82F6),
              onTap: () {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(
                    content: Text('Coming soon'),
                    backgroundColor: Color(0xFF3B82F6),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildShopOption(
              icon: Icons.restore,
              title: 'Restore Products',
              subtitle: 'Recover deleted products',
              color: const Color(0xFFF59E0B),
              onTap: () async {
                final mobile = _mobileController.text.trim();
                if (mobile.isEmpty) {
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text('Please enter customer mobile number first'),
                        ],
                      ),
                      backgroundColor: Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  return;
                }

                // Close loading dialog
                Navigator.pop(context);

                // Beautiful confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: Get.context!,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.restore, color: Color(0xFFF59E0B)),
                        ),
                        SizedBox(width: 12),
                        Text('Restore Products'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Are you sure you want to restore deleted products for:',
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Color(0xFFF59E0B),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                mobile,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'This will recover all previously deleted products for this customer.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                        ),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: Icon(Icons.restore, size: 18),
                        label: Text('Restore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                // Beautiful loading dialog with animation
                showDialog(
                  context: Get.context!,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Restoring Products...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please wait while we recover deleted products',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
                await Future.delayed(Duration(seconds: 2));

                final result = await ServerUtils.restoreProducts(mobile);
                Navigator.pop(Get.context!);
                await Future.delayed(Duration(milliseconds: 500));

                // Beautiful success/error messages
                if (result == RestoreProdStatus.restored) {
                  showDialog(
                    context: Get.context!,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Color(0xFF10B981).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Color(0xFF10B981),
                              size: 30,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Success!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Products have been successfully restored for customer $mobile',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Done'),
                        ),
                      ],
                    ),
                  );
                } else if (result == RestoreProdStatus.unauthorized) {
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.security, color: Colors.white),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Your session has expired, relogin is required.',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF660011),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else if (result == RestoreProdStatus.noRef) {
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(child: Text('User not registered.')),
                        ],
                      ),
                      backgroundColor: Color(0xFFF59E0B),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Failed to restore products. Please try again.'),
                        ],
                      ),
                      backgroundColor: Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),

            _buildShopOption(
              icon: Icons.settings,
              title: 'Change Settings',
              subtitle: 'Configure shop preferences',
              color: const Color(0xFF6B7280),
              onTap: () {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(
                    content: Text('Coming soon'),
                    backgroundColor: Color(0xFF3B82F6),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildShopOption(
              icon: Icons.wifi,
              title: 'Check Online Store Connectivity',
              subtitle: 'Test connection status',
              color: const Color(0xFF10B981),
              onTap: () {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(
                    content: Text('Coming soon'),
                    backgroundColor: Color(0xFF3B82F6),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildShopOption(
              icon: Icons.apps,
              title: 'See Installed App Versions',
              subtitle: 'View app information',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(
                    content: Text('Coming soon'),
                    backgroundColor: Color(0xFF3B82F6),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildShopOption(
              icon: Icons.receipt_long,
              title: 'Repair Order Invoices',
              subtitle: 'Click to fix invoice nos of this shop',
              color: const Color(0xFFEF4444),
              onTap: () async {
                final mobile = _mobileController.text.trim();
                if (mobile.isEmpty) {
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text('Please enter customer mobile number first'),
                        ],
                      ),
                      backgroundColor: Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(Get.context!);

                // Beautiful confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: Get.context!,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.restore, color: Color(0xFFF59E0B)),
                        ),
                        SizedBox(width: 12),
                        Text('Repair Orders'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Are you sure you want to repair invoice nos for:',
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Color(0xFFF59E0B),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                mobile,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'This will realign invoice no for all orders of this customer.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                        ),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: Icon(Icons.restore, size: 18),
                        label: Text('Repair'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                // Beautiful loading dialog with animation
                showDialog(
                  context: Get.context!,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Repair Products...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please wait while we repair orders',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
                await Future.delayed(Duration(seconds: 2));

                final result = await ServerUtils.reassignInvoice(mobile);

                // Close loading dialog
                Navigator.pop(Get.context!);
                await Future.delayed(Duration(milliseconds: 500));

                // Beautiful success/error messages
                if (result == InvoiceNumberStatus.success) {
                  showDialog(
                    context: Get.context!,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Color(0xFF10B981).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Color(0xFF10B981),
                              size: 30,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Success!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Orders have been successfully processed for customer $mobile',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Done'),
                        ),
                      ],
                    ),
                  );
                } else if (result == InvoiceNumberStatus.unauthorized) {
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.security, color: Colors.white),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Your session has expired, relogin is required.',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF660011),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else if (result == InvoiceNumberStatus.noRef) {
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(child: Text('User not registered.')),
                        ],
                      ),
                      backgroundColor: Color(0xFFF59E0B),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Failed to repair orders. Please try again.'),
                        ],
                      ),
                      backgroundColor: Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF172a43),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomerRetentionSheet extends StatelessWidget {
  const CustomerRetentionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_alt,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Customer Retention',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF172a43),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildRetentionOption(
            icon: Icons.fiber_new_outlined,
            title: "Today's New Users",
            subtitle: 'Live view of users who signed up today',
            color: const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const TodaysNewUsersPage());
            },
          ),
          const SizedBox(height: 12),
          _buildRetentionOption(
            icon: Icons.person_add_outlined,
            title: 'View New Customers',
            subtitle: 'See recently joined customers',
            color: const Color(0xFF10B981),
            onTap: () {
              ScaffoldMessenger.of(Get.context!).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon'),
                  backgroundColor: Color(0xFF3B82F6),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildRetentionOption(
            icon: Icons.schedule_outlined,
            title: 'See Expiring Subscriptions',
            subtitle: 'Check subscriptions ending soon',
            color: const Color(0xFFEF4444),
            onTap: () {
              ScaffoldMessenger.of(Get.context!).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon'),
                  backgroundColor: Color(0xFF3B82F6),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildRetentionOption(
            icon: Icons.cloud_download_outlined,
            title: 'Get a list of download users',
            subtitle: 'View users who downloaded the app',
            color: const Color(0xFF3B82F6),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: Get.context!,
                backgroundColor: Colors.white,
                isScrollControlled: true,
                builder: (context) => const DownloadedUsersSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF172a43),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
