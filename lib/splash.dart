import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_2666/login.dart';
import 'package:lottie/lottie.dart';
// تأكد من استيراد صفحة الـ AuthPage الخاصة بك
// import 'package:your_project_name/auth_page.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // الانتقال بعد 4 ثوانٍ إلى صفحة التسجيل
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // خلفية تتناسب مع تصميم تطبيقك الغامق
      backgroundColor: const Color.fromARGB(255, 59, 59, 59), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // عرض انيميشن Lottie من الملفات
            Lottie.asset(
              'images/Fingerprint Scanning (3).json',
              width: 250,
              height: 250,
              fit: BoxFit.fill,
            ),
            const SizedBox(height: 20),
            // نص اختياري تحت الانيميشن
            const Text(
              "",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}