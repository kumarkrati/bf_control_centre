import 'package:bf_control_centre/core/enums.dart';
import 'package:bf_control_centre/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:bf_control_centre/core/server_utils.dart';
import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const _accentCyan = Color(0xFF00D4FF);
  static const _accentPurple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final loginStatus = await ServerUtils.login(
          _usernameController.text,
          _passwordController.text,
        );
        debugPrint("[login] $loginStatus");

        _handleLoginStatus(loginStatus);
      } catch (e) {
        _showSnackBar('An unexpected error occurred', const Color(0xFFFF4757));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleLoginStatus(LoginStatus status) {
    switch (status) {
      case LoginStatus.success:
        _showSnackBar('Login successful!', const Color(0xFF00F5A0));
        Get.off(() => HomePage());
        break;
      case LoginStatus.invalid:
        _showSnackBar('Invalid username or password', const Color(0xFFFF4757));
        break;
      case LoginStatus.denied:
        _showSnackBar('Access denied', const Color(0xFFFF4757));
        break;
      case LoginStatus.error:
        _showSnackBar('Server error occurred', const Color(0xFFFF4757));
        break;
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFF00F5A0)
                  ? Icons.check_circle
                  : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _accentCyan.withOpacity(0.7)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0F1629),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentCyan, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF4757)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF4757), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      hintStyle: const TextStyle(color: Color(0xFF475569)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E1A),
              Color(0xFF0F1629),
              Color(0xFF0A0E1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 420 : double.infinity,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo & Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _accentCyan.withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _accentCyan.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentCyan.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              size: 48,
                              color: _accentCyan,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE2E8F0),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to access your control panel',
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(0xFF94A3B8).withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Login Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF1E293B),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _accentCyan.withOpacity(0.05),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Enter your credentials to continue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Username Field
                                TextFormField(
                                  controller: _usernameController,
                                  focusNode: _usernameFocus,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  onFieldSubmitted: (_) {
                                    _passwordFocus.requestFocus();
                                  },
                                  decoration: _buildInputDecoration(
                                    label: 'Username',
                                    hint: 'Enter your username',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Username cannot be empty';
                                    }
                                    if (value.length < 3) {
                                      return 'Username must be at least 3 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: _buildInputDecoration(
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    icon: Icons.lock_outline_rounded,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: const Color(0xFF94A3B8),
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password cannot be empty';
                                    }
                                    if (value.length <= 5) {
                                      return 'Password must be more than 5 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),

                                // Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: const LinearGradient(
                                        colors: [_accentCyan, _accentPurple],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accentCyan.withOpacity(0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            Colors.transparent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Sign In',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                    Icons
                                                        .arrow_forward_rounded,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Footer
                        Text(
                          'BillingFast Control Centre v6.0',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                const Color(0xFF94A3B8).withOpacity(0.6),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
