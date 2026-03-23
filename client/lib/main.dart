import 'package:bf_control_centre/config/app_icons.dart';
import 'package:bf_control_centre/core/app_storage.dart';
import 'package:bf_control_centre/core/login_utils.dart';
import 'package:bf_control_centre/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Splash());
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  void _initEngine() async {
    await AppStorage.init();
    // delay
    await Future.delayed(Duration(seconds: 2));
    if (LoginUtils.isLoggedIn) {
      Get.off(() => HomePage());
    } else {
      Get.off(() => LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Control Centre v6",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4FF),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF111827),
          background: const Color(0xFF0A0E1A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0F1629),
          foregroundColor: const Color(0xFFE2E8F0),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE2E8F0),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF111827),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E293B)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E293B)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF0F1629),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
          hintStyle: const TextStyle(color: Color(0xFF475569)),
          prefixIconColor: const Color(0xFF00D4FF),
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF00D4FF).withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SizedBox.square(
                      dimension: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(AppIcons.appIcon, width: 120),
                      ),
                    ),
                  )
                  .animate(onComplete: (e) => e.repeat())
                  .shimmer(
                    duration: const Duration(seconds: 2),
                    color: const Color(0xFF00D4FF).withOpacity(0.3),
                  ),
              const Gap(24),
              Text(
                "BillingFast Control Centre",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE2E8F0),
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                "Swiss knife for quick actions",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
