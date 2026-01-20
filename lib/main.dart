import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth.dart';
import 'patient.dart';
import 'provider.dart';
import 'admin.dart';

void main() {
  // 🚀 نلغي الانتظار هنا لتفادي الشاشة الرمادية
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AfyaApp());
}

class AfyaApp extends StatefulWidget {
  const AfyaApp({super.key});

  @override
  State<AfyaApp> createState() => _AfyaAppState();
}

class _AfyaAppState extends State<AfyaApp> {
  // متغير لتخزين حالة الاتصال والخطأ
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

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
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          // 🛑 حالة الخطأ: اعرض المشكلة بدلاً من الشاشة الرمادية
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.red),
                      const SizedBox(height: 20),
                      const Text("حدث خطأ في تشغيل التطبيق", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text("الخطأ: ${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      const Text("تأكد من ملف google-services.json واسم الحزمة (Package Name).", textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          }

          // ⏳ حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // ✅ تم الاتصال بنجاح: اعرض التطبيق
          return const AuthGate();
        },
      ),
    );
  }
}

// 👮‍♂️ الموجه الذكي (كما هو)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return RoleCheckWrapper(uid: snapshot.data!.uid);
        }
        return const AuthScreen(); 
      },
    );
  }
}

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
          return const AuthScreen(); 
        }
        var data = snapshot.data!.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'patient'; 
        
        if (role == 'admin') return const AdminDashboard();
        if (role == 'patient') return const PatientHome();
        if (role == 'provider') {
          String status = data['status'] ?? 'pending'; 
          Timestamp? expiryTimestamp = data['subscription_expiry'];
          bool isExpired = false;
          if (expiryTimestamp != null) {
            if (DateTime.now().isAfter(expiryTimestamp.toDate())) isExpired = true;
          }
          if (status == 'pending') return const ProviderPaymentScreen(status: 'pending');
          if (isExpired || status == 'expired') return const ProviderPaymentScreen(status: 'expired');
          return const ProviderDashboard();
        }
        return const AuthScreen();
      },
    );
  }
}
