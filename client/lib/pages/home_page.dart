import 'dart:convert';

import 'package:bf_control_centre/core/app_storage.dart';
import 'package:bf_control_centre/core/enums.dart';
import 'package:bf_control_centre/core/login_utils.dart';
import 'package:bf_control_centre/core/server_utils.dart';
import 'package:bf_control_centre/core/utils/convert_to_days.dart';
import 'package:bf_control_centre/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() {
      _showLoginButton = _mobileController.text.trim().isNotEmpty;
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
      builder: (context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "BillingFast Control Centre",
              style: GoogleFonts.poppins(fontSize: 20),
            ),
            Text("v1.0.3+13", style: GoogleFonts.poppins(fontSize: 14)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Here's a list of active features:",
                style: GoogleFonts.poppins(fontSize: 15),
              ),
            ),
            SizedBox(
              height: 300,
              child: ListView(
                children: [
                  ListTile(title: Text("• View Password.")),
                  ListTile(title: Text("• Reset Password.")),
                  ListTile(title: Text("• Restore Products.")),
                  ListTile(title: Text("• Repair Orders.")),
                  ListTile(title: Text("• Create New Account for ADMIN role.")),
                  ListTile(
                    title: Text("• Activate Subscriptions for ADMIN role."),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('BillingFast Control Centre'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
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
                                    ScaffoldMessenger.of(Get.context!).showSnackBar(
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
                        if (LoginUtils.isAdmin) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _createNewAccount,
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text('Create Account'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
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
  String _selectedPlan = 'PREMIUM';
  String _selectedDuration = '1 month';
  DateTime _startDate = DateTime.now();

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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.8,
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
          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputSection(
                    'Plan Type',
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
                            (plan) => DropdownMenuItem(
                              value: plan,
                              child: Text(plan),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedPlan = value!),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInputSection(
                    'Plan Duration',
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
                    'Start Date',
                    Icons.calendar_today,
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) setState(() => _startDate = date);
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
                              _startDate.toString().split(' ')[0],
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final mobile = _mobileController.text.trim();
                if (mobile.isEmpty) {
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter customer mobile number'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: Get.context!,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Row(
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
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Update Subscription'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Are you sure you want to update subscription for:',
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                mobile,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Plan: $_selectedPlan\nDuration: $_selectedDuration\nStart Date: ${_startDate.toString().split(' ')[0]}',
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Updating Subscription...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait while we update the subscription',
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
                debugPrint(
                  'sub plan days ${convertToDays(int.parse(_selectedDuration.split(" ")[0]), _selectedDuration.split(" ")[1])}',
                );
                final result = await ServerUtils.updateSubscription(
                  id: mobile,
                  planType: _selectedPlan,
                  planDuration: convertToDays(
                    int.parse(_selectedDuration.split(" ")[0]),
                    _selectedDuration.split(" ")[1],
                  ),
                  startDate: _startDate,
                );

                Navigator.pop(Get.context!);
                await Future.delayed(const Duration(milliseconds: 500));

                if (result == UpdateSubscriptionStatus.success) {
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
                } else if (result == UpdateSubscriptionStatus.unauthorized) {
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
                } else if (result == UpdateSubscriptionStatus.noRef) {
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('User not registered.')),
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
                          const Text(
                            'Failed to update subscription. Please try again.',
                          ),
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
              },
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
      ),
    );
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
