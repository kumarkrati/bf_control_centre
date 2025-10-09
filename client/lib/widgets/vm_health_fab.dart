import 'package:bf_control_centre/core/server_utils.dart';
import 'package:flutter/material.dart';

class VMHealthFAB extends StatefulWidget {
  const VMHealthFAB({super.key});

  @override
  State<VMHealthFAB> createState() => _VMHealthFABState();
}

class _VMHealthFABState extends State<VMHealthFAB> {
  bool _isLoading = false;

  Future<void> _fetchVMHealth() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ServerUtils.getVMHealth();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Handle all return cases
    if (result == null) {
      // Case 1: 400 status or error occurred
      _showErrorDialog(
        'Failed to Fetch VM Health',
        'Bad request or network error occurred. Please try again.',
      );
    } else if (result == "error") {
      // Case 2: 500 server error
      _showErrorDialog(
        'Server Error',
        'Internal server error (500). The health server is experiencing issues.',
      );
    } else if (result is Map<String, dynamic>) {
      // Case 3: 200 success - show health data
      _showHealthSheet(result);
    } else {
      // Unexpected case
      _showErrorDialog(
        'Unexpected Response',
        'Received unexpected data format from server.',
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHealthSheet(Map<String, dynamic> healthData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthSheet(healthData: healthData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _StylishHealthButton(
      onPressed: _isLoading ? null : _fetchVMHealth,
      isLoading: _isLoading,
    );
  }
}

class _StylishHealthButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _StylishHealthButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  State<_StylishHealthButton> createState() => _StylishHealthButtonState();
}

class _StylishHealthButtonState extends State<_StylishHealthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981)
                          .withOpacity(_glowAnimation.value),
                      blurRadius: 20 * _scaleAnimation.value,
                      spreadRadius: 5 * _scaleAnimation.value,
                    ),
                  ],
                ),
              ),
              // Animated pulse ring
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF10B981)
                          .withOpacity(0.3 * _glowAnimation.value),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Main button with gradient
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    borderRadius: BorderRadius.circular(30),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                // Icon with subtle animation
                                Transform.scale(
                                  scale: 1.1,
                                  child: const Icon(
                                    Icons.monitor_heart_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                // Small pulse dot
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white
                                              .withOpacity(_glowAnimation.value),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HealthSheet extends StatefulWidget {
  final Map<String, dynamic> healthData;

  const _HealthSheet({required this.healthData});

  @override
  State<_HealthSheet> createState() => _HealthSheetState();
}

class _HealthSheetState extends State<_HealthSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _parseMemoryValue(String? memStr) {
    if (memStr == null) return 0;
    final numStr = memStr.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(numStr) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.healthData['status'] ?? 'unknown';
    final timestamp = widget.healthData['timestamp'] ?? 'N/A';
    final hostname = widget.healthData['hostname'] ?? 'N/A';
    final uptime = widget.healthData['uptime'] ?? 0;
    final servers = widget.healthData['servers'] as List<dynamic>? ?? [];
    final memory = widget.healthData['memory'] as Map<String, dynamic>? ?? {};

    final aliveServers = servers.where((s) => s['alive'] == true).length;
    final totalServers = servers.length;

    // Parse memory values
    final memoryData = memory['memory'] as Map<String, dynamic>?;
    final swapData = memory['swap'] as Map<String, dynamic>?;

    final ramTotal = _parseMemoryValue(memoryData?['total']);
    final ramUsed = _parseMemoryValue(memoryData?['used']);

    final swapTotal = _parseMemoryValue(swapData?['total']);
    final swapUsed = _parseMemoryValue(swapData?['used']);

    final ramUsagePercent = ramTotal > 0 ? (ramUsed / ramTotal).toDouble() : 0.0;
    final swapUsagePercent = swapTotal > 0 ? (swapUsed / swapTotal).toDouble() : 0.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    status == 'ok' ? Icons.check_circle : Icons.error,
                    color: status == 'ok' ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VM Health Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: status == 'ok' ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Info Cards
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCard(
                              icon: Icons.dns,
                              label: 'Hostname',
                              value: hostname,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoCard(
                              icon: Icons.access_time,
                              label: 'Uptime',
                              value: '${(uptime / 86400).toStringAsFixed(1)}d',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.schedule,
                        label: 'Timestamp',
                        value: timestamp,
                      ),
                      const SizedBox(height: 24),
                      // Memory Section
                      _AnimatedMemoryBar(
                        title: 'RAM Usage',
                        used: memoryData?['used'] ?? 'N/A',
                        total: memoryData?['total'] ?? 'N/A',
                        available: memoryData?['available'] ?? 'N/A',
                        percentage: ramUsagePercent,
                        color: ramUsagePercent > 0.8
                            ? Colors.red
                            : ramUsagePercent > 0.6
                                ? Colors.orange
                                : Colors.green,
                        animationController: _animationController,
                      ),
                      const SizedBox(height: 16),
                      _AnimatedMemoryBar(
                        title: 'Swap Usage',
                        used: swapData?['used'] ?? 'N/A',
                        total: swapData?['total'] ?? 'N/A',
                        percentage: swapUsagePercent,
                        color: swapUsagePercent > 0.8
                            ? Colors.red
                            : swapUsagePercent > 0.5
                                ? Colors.orange
                                : Colors.blue,
                        animationController: _animationController,
                      ),
                      const SizedBox(height: 24),
                      // Servers Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Server Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$aliveServers/$totalServers alive',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...servers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final server = entry.value;
                        return _AnimatedServerTile(
                          server: server,
                          delay: index * 50,
                          animationController: _animationController,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AnimatedMemoryBar extends StatelessWidget {
  final String title;
  final String used;
  final String total;
  final String? available;
  final double percentage;
  final Color color;
  final AnimationController animationController;

  const _AnimatedMemoryBar({
    required this.title,
    required this.used,
    required this.total,
    this.available,
    required this.percentage,
    required this.color,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: percentage * animationController.value,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 24,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Used: $used',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Total: $total',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          if (available != null)
            Text(
              'Available: $available',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }
}

class _AnimatedServerTile extends StatelessWidget {
  final Map<String, dynamic> server;
  final int delay;
  final AnimationController animationController;

  const _AnimatedServerTile({
    required this.server,
    required this.delay,
    required this.animationController,
  });

  static const Map<String, String> _serverDescriptions = {
    "verify-user.ts": "Responsible for sending OTPs and password logins.",
    "authorize.ts": "Responsible for validating OTP and preventing misuse of Identity Platform.",
    "update-auth.ts": "Handles JWT refreshes every hour.",
    "monitor-indexer.sh": "Restarts typesense document indexer if in case it crashes.",
    "indexer.ts": "Resposible for backfill data into typesense, listens supabase continously.",
    "pdf-server.js": "Responsible for Server Side Invoice Rendering",
    "subscriptions-server.ts": "Manages razorpay payments and app subscriptions.",
    "control-centre-server.ts": "Powers this control centre.",
    "store-server.ts": "Handles order checkout and product requests coming from online store",
    "sms-and-maps-server.js": "Serves multiple functions: fetches geographical distance using ola maps, sends otp, send online order notification to host shop and auto-adds logged in users to BillingFast.",
    "integrity-server.js": "Prevents bot attacks does evaluation on various parameters.",
    "stock-server.js": "Handles stock transfer requests.",
    "dashboard_server.js": "Servers complete business tally.",
    "summary-server.js": "Handles ledger calculations.",
    "order-pooling-server.js": "Prevents duplicate invoices and manages concurrency.",
    "gsp-server.js": "Serves details by GSTIN number.",
    "reports-server.js": "Responsible for providing all sorts of reports in the app.",
    "ai-server.js": "Handles all AI features.",
    "icici-payments-server.js": "Currently dormant, until integration is complete.",
    "health-server.js": "Provides this health stat.",
  };

  @override
  Widget build(BuildContext context) {
    final isAlive = server['alive'] == true;
    final name = server['name'] ?? 'unknown';
    final pid = server['pid']?.toString() ?? 'N/A';
    final description = _serverDescriptions[name] ?? 'No description available';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAlive
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAlive ? Colors.green : Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: (isAlive ? Colors.green : Colors.red)
                        .withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PID: $pid',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isAlive ? Icons.check_circle : Icons.cancel,
              size: 20,
              color: isAlive ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
