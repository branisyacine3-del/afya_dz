import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // 👈 استيراد الملف الجديد
import 'auth.dart';
import 'patient.dart';
import 'provider.dart';
import 'admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 تهيئة فايربيز باستخدام الكود المباشر (تجاوز مشاكل Gradle)
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
        primarySwatch: Colors.teal,
        useMaterial3: false,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const AuthGate(),
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
        // في حالة الانتظار
        if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // إذا كان هناك خطأ في الاتصال
        if (snapshot.hasError) {
             return Scaffold(
              body: Center(
                child: Text("حدث خطأ: ${snapshot.error}"),
              )
            );
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
           // قد يكون المستخدم جديداً ولم يُحفظ دوره بعد
           return const AuthScreen(); 
        }
        
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
 
