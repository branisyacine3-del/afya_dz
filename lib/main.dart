import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ صحيح: الملف بجانبنا
import 'splash_screen.dart';    // ✅ تم التصحيح: حذفنا كلمة screens/ لأن الملف بجانبنا

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة فايربيز
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const AfyaApp());
}

class AfyaApp extends StatelessWidget {
  const AfyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Afya DZ',
      theme: ThemeData(
        fontFamily: 'Cairo', // توحيد الخط
        primarySwatch: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      // نقطة البداية هي شاشة السبلاش
      home: const SplashScreen(),
    );
  }
}
