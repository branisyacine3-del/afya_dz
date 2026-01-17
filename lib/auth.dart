import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔐 شاشة تسجيل الدخول (إدخال الهاتف)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendCode() async {
    String phone = _phoneCtrl.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("رقم الهاتف قصير جداً")));
      return;
    }

    // تنسيق الرقم للجزائر (+213)
    if (phone.startsWith('0')) phone = phone.substring(1);
    if (!phone.startsWith('+')) phone = '+213$phone';

    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل التحقق: ${e.message}")));
      },
      codeSent: (verificationId, resendToken) {
        setState(() => _isLoading = false);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OtpScreen(verificationId: verificationId, phone: phone),
        ));
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text("تسجيل الدخول", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "رقم الهاتف",
                prefixText: "+213 ",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendCode,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("إرسال الرمز 📩"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔢 شاشة إدخال الرمز (OTP)
class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phone;
  const OtpScreen({super.key, required this.verificationId, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _verify() async {
    setState(() => _isLoading = true);
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpCtrl.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(cred);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرمز خاطئ")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد الرقم"), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text("أدخل الرمز المرسل إلى ${widget.phone}"),
            const SizedBox(height: 20),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: "123456", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text("تأكيد ودخول"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🆕 شاشة اختيار الدور (مستخدم جديد)
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'phone': user.phoneNumber,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        // إذا كان ممرضاً، نجعله "غير موثق" ليتم توثيقه في الملف الخاص به
        if (role == 'provider') 'verification_status': 'pending_registration',
      });
      // لا نحتاج للانتقال يدوياً، الـ main.dart سيلاحظ التغيير
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("مرحباً بك في عافية ❤️", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("اختر نوع حسابك للمتابعة", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            _roleBtn(context, "أنا مريض (أبحث عن رعاية)", Icons.sick, Colors.teal, 'patient'),
            const SizedBox(height: 20),
            _roleBtn(context, "أنا ممرض / سائق", Icons.medical_services, Colors.orange, 'provider'),
          ],
        ),
      ),
    );
  }

  Widget _roleBtn(BuildContext context, String txt, IconData icon, Color color, String role) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(txt, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: () => _selectRole(context, role),
      ),
    );
  }
}
