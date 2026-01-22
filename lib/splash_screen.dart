import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'patient.dart';
import 'admin.dart';
import 'provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // 🕵️‍♂️ الفحص الذكي: بدلاً من الانتظار الأعمى، نفحص المستخدم
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    // نعطي وقتاً للشعار ليظهر (3 ثواني)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 1. هل هناك مستخدم مسجل في الهاتف؟
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // ❌ لا يوجد مستخدم -> اذهب للترحيب ثم التسجيل
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OnboardingScreen()));
    } else {
      // ✅ يوجد مستخدم -> اكتشف من هو ووجهه
      _navigateToHome(user);
    }
  }

  Future<void> _navigateToHome(User user) async {
    try {
      // 🔑 المفتاح الماستر للأدمن (كما فعلنا في تسجيل الدخول)
      if (user.email == "admin@afya.dz") {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
         return;
      }

      // جلب بيانات المستخدم لمعرفة دوره
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        String role = userDoc['role'];

        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
        } else if (role == 'provider') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProviderGate()));
        } else {
          // الباقي مرضى
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PatientHome()));
        }
      } else {
        // حالة نادرة: مسجل في Auth لكن ليس في Firestore -> يذهب للتسجيل
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    } catch (e) {
      // في حالة حدوث خطأ (انترنت مقطوع مثلاً)، نعيده للتسجيل كإجراء احتياطي
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medical_services_rounded, size: 80, color: Colors.teal),
              ),
              const SizedBox(height: 20),
              const Text(
                "عافية",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "عافيتك.. في منزلك ❤️",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
 
