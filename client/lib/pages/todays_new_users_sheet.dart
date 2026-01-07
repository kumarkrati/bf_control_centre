import 'dart:async';

import 'package:bf_control_centre/core/server_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TodaysNewUsersSheet extends StatefulWidget {
  const TodaysNewUsersSheet({super.key});

  @override
  State<TodaysNewUsersSheet> createState() => _TodaysNewUsersSheetState();
}

class _TodaysNewUsersSheetState extends State<TodaysNewUsersSheet>
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
    final assignedToController =
        TextEditingController(text: user['assignedTo'] ?? '');
    final notesController = TextEditingController(text: user['notes'] ?? '');

    showDialog(
      context: context,
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
              child: const Icon(Icons.person_add, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Assign Sales Staff',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user['name'] ?? 'Not Provided',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text(user['mobile'] ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: assignedToController,
                decoration: InputDecoration(
                  labelText: 'Assigned To (Sales Staff Name)',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes / Feedback',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final assignedTo = assignedToController.text.trim();
              if (assignedTo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter the sales staff name'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              // Show loading
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Assigning...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              final success = await ServerUtils.assignSalesStaff(
                userId: user['id'] ?? user['mobile'],
                userName: user['name'] ?? '',
                userAddress: user['shop'] ?? '',
                assignedTo: assignedTo,
                notes: notesController.text.trim(),
              );

              Navigator.pop(Get.context!);

              if (success) {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Assigned to $assignedTo'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                _fetchUsers(); // Refresh the list
              } else {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('Failed to assign. Please try again.'),
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
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Assign'),
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
                  Icons.fiber_new,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Today's New Users",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172a43),
                  ),
                ),
              ),
              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isLoading ? null : _fetchUsers,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh now',
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Auto-refreshes every 30 seconds',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),

          // Results
          if (_users == null && _isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
            )
          else if (_users != null && _users!.isEmpty)
            Expanded(
              child: Center(
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (_users != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 18,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_users!.length} new user${_users!.length == 1 ? '' : 's'} today',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF172a43),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_users!.where((u) => u['isAssigned'] == true).length} assigned',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _users!.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = _users![index];
                        final isAssigned = user['isAssigned'] == true;
                        return _buildUserTile(user, isAssigned);
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, bool isAssigned) {
    final name = user['name'] ?? 'Not Provided';
    final shop = user['shop'] ?? 'Unnamed';
    final phone = user['mobile'] ?? 'N/A';
    final assignedTo = user['assignedTo'];
    final notes = user['notes'];

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final blinkColor = isAssigned
            ? Colors.transparent
            : Color.lerp(
                const Color(0xFFFEF3C7),
                Colors.white,
                _blinkController.value,
              );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: blinkColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isAssigned
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : const Color(0xFFF59E0B).withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isAssigned
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isAssigned ? Icons.check_circle : Icons.person,
                      color: isAssigned
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name == '' ? 'Not Provided' : name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF172a43),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.store,
                                size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shop == '' ? 'Unnamed' : shop,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF172a43),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: phone));
                      if (mounted) {
                        ScaffoldMessenger.of(Get.context!).showSnackBar(
                          SnackBar(
                            content: Text('Copied: $phone'),
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
                    icon: const Icon(Icons.copy, size: 16),
                    tooltip: 'Copy phone number',
                    color: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _showAssignDialog(user),
                    icon: Icon(
                      isAssigned ? Icons.edit : Icons.person_add,
                      size: 16,
                    ),
                    tooltip: isAssigned ? 'Edit assignment' : 'Assign staff',
                    color: isAssigned
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (isAssigned && (assignedTo != null || notes != null)) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.badge,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          assignedTo ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      if (notes != null && notes.toString().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            notes,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
