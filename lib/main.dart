import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:afya_dz/screens/splash_screen.dart'; // 👈 استدعاء الشاشة الجديدة

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        fontFamily: 'Cairo', // سنجعل الخط موحداً
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const SplashScreen(), // 👈 البداية من هنا
    );
  }
}
 
