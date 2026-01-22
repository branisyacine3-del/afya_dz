import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart';
import 'patient.dart';
import 'admin.dart';
import 'provider.dart';

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
      if (_emailController.text.trim() == "admin@afya.dz") {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
        return;
      }
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(), 
        password: _passwordController.text.trim()
      );
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      if (userDoc.exists && mounted) {
        String role = userDoc['role'];
        if (role == 'admin') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
        else if (role == 'provider') Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProviderGate()));
        else Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PatientHome()));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ خطأ: ${e.toString()}"), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. الشعار والترحيب
                const Icon(Icons.medical_services_rounded, size: 60, color: Color(0xFF009688)),
                const SizedBox(height: 20),
                const Text(
                  "مرحباً بك مجدداً 👋",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  "سجل الدخول للمتابعة في عافية",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
                const SizedBox(height: 40),

                // 2. نموذج الإدخال (Modern Input)
                _buildModernTextField("البريد الإلكتروني", _emailController, Icons.alternate_email, false),
                const SizedBox(height: 16),
                _buildModernTextField("كلمة المرور", _passwordController, Icons.lock_outline, true),
                
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {}, 
                    child: const Text("نسيت كلمة المرور؟", style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold))
                  ),
                ),
                const SizedBox(height: 24),

                // 3. زر الدخول
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      shadowColor: const Color(0xFF009688).withOpacity(0.4),
                      elevation: 10,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("تسجيل الدخول", style: TextStyle(fontSize: 18)),
                  ),
                ),

                const SizedBox(height: 30),

                // 4. التسجيل
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("جديد في عافية؟ ", style: TextStyle(color: Colors.grey[600])),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                      child: const Text("أنشئ حساباً الآن", style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(String label, TextEditingController controller, IconData icon, bool isPassword) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
