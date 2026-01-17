import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// استيراد الملفات الأخرى (ستعمل لاحقاً عند إنشائها)
import 'auth.dart';     // ملف الدخول
import 'admin.dart';    // ملف الإدارة
import 'patient.dart';  // ملف المريض
import 'provider.dart'; // ملف الممرض

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print("✅ Firebase Connected");
  } catch (e) {
    print("❌ Firebase Error: $e");
  }
  runApp(const AfyaApp());
}

// 🎨 الألوان والتصميم العام
class AppColors {
  static const primary = Color(0xFF009688); // Teal
  static const secondary = Color(0xFFFF9800); // Orange
  static const bg = Color(0xFFF5F7FA);
}

class AfyaApp extends StatelessWidget {
  const AfyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Afya Pro',
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
      // نقطة البداية: الموجه الذكي
      home: const AuthWrapper(),
    );
  }
}

// 🛡️ البواب الذكي (يوجه المستخدم حسب دوره)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. حالة الانتظار
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. مستخدم مسجل -> افحص دوره
        if (snapshot.hasData && snapshot.data != null) {
          return UserRoleDispatcher(uid: snapshot.data!.uid);
        }

        // 3. غير مسجل -> اذهب للدخول (موجودة في ملف auth.dart)
        return const LoginScreen();
      },
    );
  }
}

// 🔀 موزع الأدوار (يفحص هل أنت مدير، مريض، أم ممرض)
class UserRoleDispatcher extends StatefulWidget {
  final String uid;
  const UserRoleDispatcher({super.key, required this.uid});

  @override
  State<UserRoleDispatcher> createState() => _UserRoleDispatcherState();
}

class _UserRoleDispatcherState extends State<UserRoleDispatcher> {
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (doc.exists) {
        setState(() {
          role = doc['role'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // التوجيه للصفحات (ستعمل عند إنشاء الملفات القادمة)
    if (role == 'admin') return const AdminDashboard();
    if (role == 'provider') return const ProviderDashboard(); // تم تحديثها لتشمل التحقق
    if (role == 'patient') return const PatientHome();

    // مستخدم جديد ليس له دور
    return const RoleSelectionScreen();
  }
}
