import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

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
      theme: _buildTheme(), // 🎨 استدعاء الثيم الاحترافي
      home: const SplashScreen(),
    );
  }

  // 🎨 بناء هوية بصرية احترافية
  ThemeData _buildTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      primaryColor: const Color(0xFF009688), // لون عافية الرئيسي
      scaffoldBackgroundColor: const Color(0xFFF8F9FA), // خلفية رمادية فاتحة جداً (مريحة للعين)
      
      // تحسين النصوص
      textTheme: base.textTheme.apply(fontFamily: 'Cairo'),
      
      // تحسين الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF009688),
          foregroundColor: Colors.white,
          elevation: 0, // إلغاء الظل القوي ليكون مسطحاً وعصرياً
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
      ),
      
      // تحسين حقول الكتابة
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // بدون حدود سوداء
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF009688), width: 1.5),
        ),
      ),
      
      // تحسين الكروت
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0, // نستخدم الظل اليدوي لاحقاً ليكون أنعم
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
