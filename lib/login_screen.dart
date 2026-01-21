import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afya_dz/screens/signup_screen.dart'; // لفتح صفحة التسجيل
import 'package:afya_dz/patient.dart'; // صفحة المريض
import 'package:afya_dz/admin.dart';   // صفحة المدير
// import 'package:afya_dz/provider.dart'; // سننشئها لاحقاً للممرض

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 1. تسجيل الدخول في فايربيز
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(), 
        password: _passwordController.text.trim()
      );

      // 2. فحص نوع المستخدم (Role) لتوجيهه
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      
      if (userDoc.exists) {
        String role = userDoc['role'];
        // String status = userDoc['status']; // سنحتاجها لاحقاً لفحص حالة الممرض

        if (mounted) {
           if (role == 'admin') {
             // 👮‍♂️ توجيه المدير
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
           } else if (role == 'patient') {
             // 👤 توجيه المريض
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PatientHome()));
           } else if (role == 'provider') {
             // 🚑 توجيه الممرض (مؤقتاً نعرض رسالة حتى نبرمج لوحته)
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("أهلاً بك يا شريك العافية! (جاري تجهيز لوحتك)")));
             // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProviderDashboard()));
           }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ خطأ في الدخول: تأكد من البيانات")));
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               // 🟢 الشعار
               const Icon(Icons.medical_services_rounded, size: 80, color: Colors.teal),
               const SizedBox(height: 20),
               const Text("تسجيل الدخول", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
               const SizedBox(height: 10),
               const Text("مرحباً بعودتك لعائلة عافية", style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 40),
               
               // 📝 الخانات
               TextField(
                 controller: _emailController,
                 decoration: InputDecoration(
                   labelText: "البريد الإلكتروني",
                   prefixIcon: const Icon(Icons.email, color: Colors.teal),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                   filled: true,
                   fillColor: Colors.grey[50]
                 )
               ),
               const SizedBox(height: 15),
               TextField(
                 controller: _passwordController,
                 obscureText: true,
                 decoration: InputDecoration(
                   labelText: "كلمة المرور",
                   prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                   filled: true,
                   fillColor: Colors.grey[50]
                 )
               ),
               
               const SizedBox(height: 10),
               Align(
                 alignment: Alignment.centerLeft,
                 child: TextButton(onPressed: (){}, child: const Text("نسيت كلمة المرور؟", style: TextStyle(color: Colors.teal))),
               ),
               const SizedBox(height: 20),
               
               // 🚀 زر الدخول
               SizedBox(
                 width: double.infinity,
                 height: 55,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _login,
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                   child: _isLoading 
                     ? const CircularProgressIndicator(color: Colors.white) 
                     : const Text("دخول", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                 ),
               ),
               
               const SizedBox(height: 30),
               
               // 🔗 رابط إنشاء حساب
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Text("ليس لديك حساب؟"),
                   TextButton(
                     onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                     child: const Text("انضم إلينا الآن", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                   )
                 ],
               )
             ],
          ),
        ),
      ),
    );
  }
}
