import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // لإسم المستخدم
  final _phoneCtrl = TextEditingController(); // للهاتف

  bool _isLogin = true; // هل نحن في وضع تسجيل الدخول أم حساب جديد؟
  bool _isLoading = false;
  
  // الاختيار الافتراضي: مريض
  String _selectedRole = 'patient'; 

  // دالة الإرسال
  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى ملء جميع الحقول")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // 🔐 تسجيل الدخول
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        // 🆕 إنشاء حساب جديد
        if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
          throw FirebaseAuthException(code: 'missing-info', message: 'الاسم والهاتف مطلوبان للتسجيل');
        }

        // 1. إنشاء الحساب في Authentication
        UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

        // 2. تحديد حالة الحساب بناءً على الدور
        // المريض: مفعل فوراً (active)
        // الممرض: معلق (pending) حتى يدفع الاشتراك
        String status = (_selectedRole == 'patient') ? 'active' : 'pending';

        // 3. حفظ البيانات في Firestore (هنا يتم تحديد الدور)
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'email': _emailCtrl.text.trim(),
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'role': _selectedRole, // patient أو provider
          'status': status,
          'created_at': FieldValue.serverTimestamp(),
          // حقول خاصة بالممرض
          if (_selectedRole == 'provider') ...{
             'verification_status': 'pending', // لم يرفع الوثائق بعد
             'wallet_balance': 0, // الرصيد
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? "حدث خطأ ما";
      if (e.code == 'email-already-in-use') msg = "البريد الإلكتروني مسجل مسبقاً";
      if (e.code == 'wrong-password') msg = "كلمة المرور خاطئة";
      if (e.code == 'user-not-found') msg = "المستخدم غير موجود";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الأيقونة (بدل الصورة لتفادي المشاكل)
                  Icon(_isLogin ? Icons.lock_open : Icons.person_add, size: 60, color: Colors.teal),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin ? "تسجيل الدخول" : "إنشاء حساب جديد",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 20),

                  // حقول الإدخال
                  if (!_isLogin) ...[
                    TextField(controller: _nameCtrl, decoration: _inputDec("الاسم الكامل", Icons.person)),
                    const SizedBox(height: 10),
                    TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: _inputDec("رقم الهاتف", Icons.phone)),
                    const SizedBox(height: 10),
                    
                    // 🔘 اختيار الدور (مريض أو ممرض)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("أريد التسجيل بصفة:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile(
                                  title: const Text("مريض", style: TextStyle(fontSize: 14)),
                                  value: 'patient',
                                  groupValue: _selectedRole,
                                  onChanged: (v) => setState(() => _selectedRole = v.toString()),
                                  activeColor: Colors.teal,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile(
                                  title: const Text("ممرض", style: TextStyle(fontSize: 14)),
                                  value: 'provider',
                                  groupValue: _selectedRole,
                                  onChanged: (v) => setState(() => _selectedRole = v.toString()),
                                  activeColor: Colors.orange,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: _inputDec("البريد الإلكتروني", Icons.email)),
                  const SizedBox(height: 10),
                  TextField(controller: _passCtrl, obscureText: true, decoration: _inputDec("كلمة المرور", Icons.lock)),
                  
                  const SizedBox(height: 30),

                  // زر الإرسال
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isLogin ? Colors.teal : Colors.orange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              _isLogin ? "دخول" : "تسجيل",
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                  
                  const SizedBox(height: 10),
                  
                  // التبديل بين الدخول والتسجيل
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? "ليس لديك حساب؟ سجل الآن" : "لديك حساب؟ سجل دخولك"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }
}
 
