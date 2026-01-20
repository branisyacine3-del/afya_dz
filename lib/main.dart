import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// استيراد الملفات التي سنصنعها في الخطوات القادمة
// (لا تقلق من الخطوط الحمراء هنا مؤقتاً)
import 'auth.dart';      // ملف الدخول
import 'patient.dart';   // ملف المريض
import 'provider.dart';  // ملف الممرض (فيه شاشة الدفع)
import 'admin.dart';     // ملف الأدمن

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print("✅ تم الاتصال بفايربيز بنجاح");
  } catch (e) {
    print("❌ خطأ في فايربيز: $e");
  }
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
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // خلفية رمادية فاتحة مريحة
      ),
      // نقطة البداية: الموجه الذكي
      home: const AuthGate(),
    );
  }
}

// 👮‍♂️ الموجه الذكي: يفحص هل أنت مسجل أم لا
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. إذا كان التطبيق يحمل البيانات
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. إذا كان المستخدم مسجلاً للدخول -> نفحص دوره واشتراكه
        if (snapshot.hasData && snapshot.data != null) {
          return RoleCheckWrapper(uid: snapshot.data!.uid);
        }

        // 3. غير مسجل -> يذهب لصفحة الدخول
        return const AuthScreen(); 
      },
    );
  }
}

// 🕵️‍♂️ فحص الدور والاشتراك (نظام الـ 30 يوم)
class RoleCheckWrapper extends StatelessWidget {
  final String uid;
  const RoleCheckWrapper({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // حساب غير موجود في قاعدة البيانات (حالة نادرة)
          return const AuthScreen(); 
        }

        // جلب البيانات
        var data = snapshot.data!.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'patient'; // الافتراضي مريض
        
        // 👑 إذا كان المدير
        if (role == 'admin') return const AdminDashboard();

        // 🚑 إذا كان مريضاً (يدخل مباشرة)
        if (role == 'patient') return const PatientHome();

        // 👨‍⚕️ إذا كان ممرضاً (هنا نطبق نظام الـ 30 يوم)
        if (role == 'provider') {
          // فحص حالة الحساب
          String status = data['status'] ?? 'pending'; // pending, active, expired
          
          // فحص تاريخ انتهاء الاشتراك
          Timestamp? expiryTimestamp = data['subscription_expiry'];
          bool isExpired = false;
          
          if (expiryTimestamp != null) {
            DateTime expiryDate = expiryTimestamp.toDate();
            if (DateTime.now().isAfter(expiryDate)) {
              isExpired = true;
            }
          }

          // 🛑 1. الحساب جديد ولم يتم تفعيله من طرفك
          if (status == 'pending') {
            return const ProviderPaymentScreen(status: 'pending');
          }

          // 🛑 2. الاشتراك انتهى (فاتت 30 يوم)
          if (isExpired || status == 'expired') {
            return const ProviderPaymentScreen(status: 'expired');
          }

          // ✅ 3. الحساب مفعل والاشتراك ساري
          return const ProviderDashboard();
        }

        // أي حالة أخرى
        return const AuthScreen();
      },
    );
  }
}
 
