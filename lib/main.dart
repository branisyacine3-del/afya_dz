import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ملاحظة: قمنا بتعطيل فايربيز مؤقتاً ليعمل التطبيق فوراً
void main() {
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
        primarySwatch: Colors.teal,
        useMaterial3: false,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const LoginPage(),
    );
  }
}

// 🔐 صفحة الدخول (واجهة فقط)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;

  void _fakeLogin() async {
    setState(() => _loading = true);
    // محاكاة وقت التحميل
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _loading = false);
    
    // الانتقال للصفحة الرئيسية مباشرة
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services_outlined, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text("عافية - Afya DZ", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            const TextField(decoration: InputDecoration(filled: true, fillColor: Colors.white, hintText: "البريد الإلكتروني", prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 10),
            const TextField(obscureText: true, decoration: InputDecoration(filled: true, fillColor: Colors.white, hintText: "كلمة المرور", prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 20),
            _loading 
              ? const CircularProgressIndicator(color: Colors.white)
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _fakeLogin,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.teal),
                    child: const Text("دخول (تجريبي)"),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// 🏠 الصفحة الرئيسية
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _contactSupport() async {
    final Uri url = Uri.parse("https://wa.me/213562898252");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch WhatsApp");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الخدمات الطبية")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _contactSupport,
        label: const Text("واتساب المدير"),
        icon: const Icon(Icons.chat),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text("مرحباً بك في النسخة التجريبية", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("التطبيق يعمل الآن بدون مشاكل! 🎉", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
 
