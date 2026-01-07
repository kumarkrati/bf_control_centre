import 'dart:async';

import 'package:bf_control_centre/core/server_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TodaysNewUsersPage extends StatefulWidget {
  const TodaysNewUsersPage({super.key});

  @override
  State<TodaysNewUsersPage> createState() => _TodaysNewUsersPageState();
}

class _TodaysNewUsersPageState extends State<TodaysNewUsersPage>
    with SingleTickerProviderStateMixin {
  List<dynamic>? _users;
  Timer? _pollTimer;
  bool _isLoading = false;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _fetchUsers();

    // Poll every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _fetchUsers();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final users = await ServerUtils.getTodaysNewUsers();

    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });

      if (users == null) {
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
      }
    }
  }

  void _showAssignDialog(Map<String, dynamic> user) {
    final isEditing = user['isAssigned'] == true;
    final assignedToController = TextEditingController(
      text: user['assignedTo'] ?? '',
    );
    final notesController = TextEditingController(text: user['notes'] ?? '');
    final name = user['name'] ?? '';
    final shop = user['shop'] ?? '';
    final mobile = user['mobile'] ?? 'N/A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isEditing
                          ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                          : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit : Icons.person_add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Assignment' : 'Assign Sales Staff',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEditing
                                  ? 'Update staff assignment & notes'
                                  : 'Assign a sales staff to this customer',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Customer info card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Customer Details',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.badge_outlined,
                          'Name',
                          name.isEmpty ? 'Not Provided' : name,
                          name.isEmpty,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.store_outlined,
                          'Shop',
                          shop.isEmpty ? 'Unnamed' : shop,
                          shop.isEmpty,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'Mobile',
                          mobile,
                          false,
                        ),
                      ],
                    ),
                  ),
                ),

                // Form fields
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assignment Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: assignedToController,
                        decoration: InputDecoration(
                          labelText: 'Sales Staff Name',
                          hintText: 'Enter staff name',
                          prefixIcon: Icon(
                            Icons.support_agent,
                            color: isEditing
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFF59E0B),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isEditing
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFF59E0B),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Notes / Feedback',
                          hintText: 'Add call notes or feedback...',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 48),
                            child: Icon(
                              Icons.note_alt_outlined,
                              color: isEditing
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isEditing
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFF59E0B),
                              width: 2,
                            ),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleAssign(
                            context,
                            user,
                            assignedToController.text.trim(),
                            notesController.text.trim(),
                            isEditing,
                          ),
                          icon: Icon(isEditing ? Icons.save : Icons.check),
                          label: Text(isEditing ? 'Save Changes' : 'Assign'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEditing
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, bool isEmpty) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isEmpty ? Colors.grey.shade500 : const Color(0xFF172a43),
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAssign(
    BuildContext dialogContext,
    Map<String, dynamic> user,
    String assignedTo,
    String notes,
    bool isEditing,
  ) async {
    if (assignedTo.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Please enter the sales staff name'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    Navigator.pop(dialogContext);

    // Show loading overlay
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isEditing
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEditing ? 'Saving...' : 'Assigning...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF172a43),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final success = await ServerUtils.assignSalesStaff(
      userId: user['id'] ?? user['mobile'],
      userName: user['name'] ?? '',
      userAddress: user['shop'] ?? '',
      assignedTo: assignedTo,
      notes: notes,
    );

    Navigator.pop(Get.context!);

    if (success) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                isEditing
                    ? 'Assignment updated successfully'
                    : 'Assigned to $assignedTo',
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      _fetchUsers();
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                isEditing
                    ? 'Failed to update. Please try again.'
                    : 'Failed to assign. Please try again.',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Today's New Users"),
        actions: [
          // Live indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _blinkController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFF10B981),
                          const Color(0xFF10B981).withOpacity(0.3),
                          _blinkController.value,
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _fetchUsers,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
                      ),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh now',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.people, size: 20, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  _users != null
                      ? '${_users!.length} new user${_users!.length == 1 ? '' : 's'} today'
                      : 'Loading...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF172a43),
                  ),
                ),
                const Spacer(),
                if (_users != null)
                  Text(
                    '${_users!.where((u) => u['isAssigned'] == true).length} assigned',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                const SizedBox(width: 16),
                Text(
                  'Auto-refresh: 30s',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table content
          Expanded(child: _buildTableContent()),
        ],
      ),
    );
  }

  Widget _buildTableContent() {
    if (_users == null && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
        ),
      );
    }

    if (_users != null && _users!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No new users today',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New users who sign up today will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_users == null) {
      return const Center(child: Text('Failed to load users'));
    }

    return Column(
      children: [
        // Table header
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 50,
                child: Text(
                  '#',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                width: 90,
                child: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Name',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Shop',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(
                width: 150,
                child: Text(
                  'Mobile',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Assigned To',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Notes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(
                width: 100,
                child: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Table rows with lazy loading
        Expanded(
          child: ListView.separated(
            itemCount: _users!.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final user = _users![index];
              return _buildTableRow(user, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(Map<String, dynamic> user, int rowNumber) {
    final isAssigned = user['isAssigned'] == true;
    final name = user['name'] ?? '';
    final shop = user['shop'] ?? '';
    final mobile = user['mobile'] ?? 'N/A';
    final assignedTo = user['assignedTo'] ?? '';
    final notes = user['notes'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      color: Colors.white,
      child: Row(
        children: [
          // Row number
          SizedBox(
            width: 50,
            child: Text(
              '$rowNumber',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Status
          SizedBox(
            width: 90,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAssigned
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAssigned ? Icons.check_circle : Icons.pending_outlined,
                    size: 14,
                    color: isAssigned
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAssigned ? 'Assigned' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isAssigned
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Name
          Expanded(
            flex: 2,
            child: Text(
              name.isEmpty ? 'Not Provided' : name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: name.isEmpty
                    ? Colors.grey.shade500
                    : const Color(0xFF172a43),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Shop
          Expanded(
            flex: 2,
            child: Text(
              shop.isEmpty ? 'Unnamed' : shop,
              style: TextStyle(
                color: shop.isEmpty
                    ? Colors.grey.shade500
                    : const Color(0xFF172a43),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Mobile with blink animation for unassigned
          SizedBox(
            width: 150,
            child: isAssigned
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          mobile,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF172a43),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: mobile));
                          if (mounted) {
                            ScaffoldMessenger.of(Get.context!).showSnackBar(
                              SnackBar(
                                content: Text('Copied: $mobile'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        },
                        child: const Icon(
                          Icons.copy,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  )
                : AnimatedBuilder(
                    animation: _blinkController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            const Color(0xFFFEF3C7),
                            Colors.white,
                            _blinkController.value,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                mobile,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF59E0B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: mobile));
                                if (mounted) {
                                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                                    SnackBar(
                                      content: Text('Copied: $mobile'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF10B981),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Icon(
                                Icons.copy,
                                size: 16,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Assigned To
          Expanded(
            flex: 2,
            child: Text(
              assignedTo.isEmpty ? '-' : assignedTo,
              style: TextStyle(
                color: assignedTo.isEmpty
                    ? Colors.grey.shade400
                    : const Color(0xFF10B981),
                fontWeight: assignedTo.isEmpty
                    ? FontWeight.normal
                    : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Notes
          Expanded(
            flex: 2,
            child: Text(
              notes.isEmpty ? '-' : notes,
              style: TextStyle(
                color: notes.isEmpty
                    ? Colors.grey.shade400
                    : Colors.grey.shade700,
                fontStyle: notes.isEmpty ? FontStyle.normal : FontStyle.italic,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // Actions
          SizedBox(
            width: 100,
            child: Center(
              child: ElevatedButton(
                onPressed: () => _showAssignDialog(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAssigned
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isAssigned ? 'Edit' : 'Assign',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
