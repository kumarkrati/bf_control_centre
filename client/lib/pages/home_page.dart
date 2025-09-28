import 'package:bf_control_centre/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _mobileController = TextEditingController();
  bool _showLoginButton = false;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_onMobileNumberChanged);
  }

  @override
  void dispose() {
    _mobileController.removeListener(_onMobileNumberChanged);
    _mobileController.dispose();
    super.dispose();
  }

  void _onMobileNumberChanged() {
    setState(() {
      _showLoginButton = _mobileController.text.trim().isNotEmpty;
    });
  }

  void _loginToBillingFast() {
    final phoneNumber = _mobileController.text.trim();
    if (phoneNumber.isNotEmpty) {
      // TODO: Implement BillingFast login with phone number
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logging into BillingFast with $phoneNumber'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _createNewAccount() {
    final phoneNumber = _mobileController.text.trim();
    if (phoneNumber.isNotEmpty) {
      // TODO: Implement BillingFast account creation with phone number
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Creating new account for $phoneNumber'),
          backgroundColor: const Color(0xFF3B82F6),
        ),
      );
    }
  }

  void _showPasswordManagement() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const PasswordManagementSheet(),
    );
  }

  void _showSubscriptionManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SubscriptionManagementSheet(),
    );
  }

  void _showShopManagement() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ShopManagementSheet(),
    );
  }

  void _showCustomerRetention() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const CustomerRetentionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('BillingFast Control Centre'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
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
            const SizedBox(height: 16),
            _buildManagementCard(
              title: 'Customer Retention',
              subtitle: 'See new unsubscribed customers from last 5 days or expiring plans',
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
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
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

class PasswordManagementSheet extends StatelessWidget {
  const PasswordManagementSheet({super.key});

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
            onTap: () {
              // TODO: Implement view current password
            },
          ),
          const SizedBox(height: 12),
          _buildPasswordOption(
            icon: Icons.refresh_rounded,
            title: 'Reset Password',
            subtitle: 'Generate a new password',
            color: const Color(0xFFEF4444),
            onTap: () {
              // TODO: Implement reset password
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
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
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
  State<SubscriptionManagementSheet> createState() => _SubscriptionManagementSheetState();
}

class _SubscriptionManagementSheetState extends State<SubscriptionManagementSheet> {
  String _selectedPlan = 'PREMIUM';
  String _selectedDuration = '1 month';
  DateTime _startDate = DateTime.now();

  final List<String> _planTypes = ['PREMIUM', 'ULTRA', 'LITE'];
  final List<String> _durations = [
    '1 day', '2 day', '3 days', '4 days', '5 days', '6 days', '7 days',
    '14 days', '15 days', '1 month', '1 year', '13 months', '2 years', '5 years'
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _planTypes.map((plan) => DropdownMenuItem(
                        value: plan,
                        child: Text(plan),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedPlan = value!),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _durations.map((duration) => DropdownMenuItem(
                        value: duration,
                        child: Text(duration),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedDuration = value!),
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
                          lastDate: DateTime.now().add(const Duration(days: 365)),
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
                            const Icon(Icons.calendar_today, color: Color(0xFF10B981)),
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
              onPressed: () {
                // TODO: Implement subscription update
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
                // TODO: Implement view shops
              },
            ),
            const SizedBox(height: 12),

            _buildShopOption(
              icon: Icons.restore,
              title: 'Restore Products',
              subtitle: 'Recover deleted products',
              color: const Color(0xFFF59E0B),
              onTap: () {
                // TODO: Implement restore products
              },
            ),
            const SizedBox(height: 12),

            _buildShopOption(
              icon: Icons.settings,
              title: 'Change Settings',
              subtitle: 'Configure shop preferences',
              color: const Color(0xFF6B7280),
              onTap: () {
                // TODO: Implement change settings
              },
            ),
            const SizedBox(height: 12),

            _buildShopOption(
              icon: Icons.wifi,
              title: 'Check Online Store Connectivity',
              subtitle: 'Test connection status',
              color: const Color(0xFF10B981),
              onTap: () {
                // TODO: Implement connectivity check
              },
            ),
            const SizedBox(height: 12),

            _buildShopOption(
              icon: Icons.apps,
              title: 'See Installed App Versions',
              subtitle: 'View app information',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                // TODO: Implement app versions view
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
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
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
              // TODO: Implement view new customers
            },
          ),
          const SizedBox(height: 12),
          _buildRetentionOption(
            icon: Icons.schedule_outlined,
            title: 'See Expiring Subscriptions',
            subtitle: 'Check subscriptions ending soon',
            color: const Color(0xFFEF4444),
            onTap: () {
              // TODO: Implement see expiring subscriptions
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
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}