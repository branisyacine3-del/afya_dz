import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth.dart';
import 'patient.dart';
import 'provider.dart';
import 'admin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        useMaterial3: false, // تصميم كلاسيكي سريع
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const AppInitializer(),
    );
  }
}

// 🚀 وحدة التهيئة (لتجنب الشاشة الرمادية)
class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  Future<FirebaseApp> _init() async {
    return await Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init(),
      builder: (context, snapshot) {
        // 🛑 في حالة الخطأ: اعرض رسالة واضحة بدلاً من الرمادي
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 20),
                    const Text("تعذر الاتصال بقاعدة البيانات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }

        // ✅ تم الاتصال: اعرض التطبيق
        if (snapshot.connectionState == ConnectionState.done) {
          return const AuthGate();
        }

        // ⏳ جاري التحميل
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

// 👮‍♂️ بواب الدخول
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return RoleCheckWrapper(uid: snapshot.data!.uid);
        }
        return const AuthScreen();
      },
    );
  }
}

// 🎭 فحص الصلاحيات والاشتراك
class RoleCheckWrapper extends StatelessWidget {
  final String uid;
  const RoleCheckWrapper({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'patient';

        if (role == 'admin') return const AdminDashboard();
        if (role == 'patient') return const PatientHome();
        
        if (role == 'provider') {
          String status = data['status'] ?? 'pending';
          Timestamp? expiry = data['subscription_expiry'];
          bool expired = expiry != null && DateTime.now().isAfter(expiry.toDate());
          
          if (status == 'pending' || status == 'expired' || expired) {
            return ProviderPaymentScreen(status: expired ? 'expired' : 'pending');
          }
          return const ProviderDashboard();
        }
        
        return const AuthScreen();
      },
    );
  }
}
 
