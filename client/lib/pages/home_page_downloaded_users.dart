import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:bf_control_centre/core/server_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DownloadedUsersSheet extends StatefulWidget {
  const DownloadedUsersSheet({super.key});

  @override
  State<DownloadedUsersSheet> createState() => _DownloadedUsersSheetState();
}

class _DownloadedUsersSheetState extends State<DownloadedUsersSheet> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<dynamic>? _users;
  bool _isLoading = false;

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    final users = await ServerUtils.getDownloadedUsers(_startDate, _endDate);

    setState(() {
      _users = users;
      _isLoading = false;
    });

    if (users == null) {
      // Session expired
      if (mounted) {
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

  Future<void> _downloadAsCSV() async {
    if (_users == null || _users!.isEmpty) return;

    try {
      final csvData = StringBuffer();
      csvData.writeln('Name,Shop,Phone');

      for (var user in _users!) {
        csvData.writeln('${user['name']},${user['shop']},${user['mobile']}');
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now()
          .toIso8601String()
          .split('.')[0]
          .replaceAll(':', '-');
      final fileName = 'downloaded_users_$timestamp.csv';

      // Create blob and download for web
      final bytes = utf8.encode(csvData.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);

      // Trigger download
      anchor.click();

      // Cleanup
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('CSV file downloaded successfully!'),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(child: Text('Failed to download CSV file')),
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
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.cloud_download,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Downloaded Users',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172a43),
                  ),
                ),
              ),
              if (_users != null && _users!.isNotEmpty)
                IconButton.filled(
                  onPressed: _downloadAsCSV,
                  icon: const Icon(Icons.file_download),
                  tooltip: 'Download as CSV',
                  color: Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Date pickers
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'Start Date',
                  date: _startDate,
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  label: 'End Date',
                  date: _endDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: _startDate,
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fetch button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchUsers,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search, size: 20),
              label: Text(_isLoading ? 'Loading...' : 'Fetch Users'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Results
          if (_users != null) ...[
            if (_users!.isEmpty)
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
                        'No users found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No users downloaded the app in this timeline',
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
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          size: 18,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_users!.length} user${_users!.length == 1 ? '' : 's'} found (${_users?.where((e) => !e['mobile']!.toString().startsWith('+91')).length} international users)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF172a43),
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
                          if (user['name'] == null || user['name'] == "") {
                            user['name'] = 'Not Provided';
                          }
                          if (user['shop'] == null || user['shop'] == "") {
                            user['shop'] = 'Unnamed';
                          }
                          return _buildUserTile(
                            name: user['name'],
                            shop: user['shop'],
                            phone: user['mobile'] ?? 'N/A',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 14,
              color: Color(0xFF3B82F6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF172a43),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile({
    required String name,
    required String shop,
    required String phone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF3B82F6),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172a43),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.store, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop,
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
            "${phone} (${phone.substring(1).length} digits)",
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
        ],
      ),
    );
  }
}
