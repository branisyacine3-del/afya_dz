import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_flow.dart'; // الملف 3
import 'provider_flow.dart'; // الملف 4
import 'admin_panel.dart';   // الملف 5

// -----------------------------------------------------------------------------
// 🔐 شاشة تسجيل الدخول (The Glassy Login)
// -----------------------------------------------------------------------------
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
      // 🔑 المفتاح الماستر للأدمن
      if (_emailController.text.trim() == "admin@afya.dz") {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
        return;
      }

      // الدخول العادي
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(), 
        password: _passwordController.text.trim()
      );

      // توجيه حسب الدور
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      
      if (userDoc.exists && mounted) {
        String role = userDoc['role'];
        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
        } else if (role == 'provider') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProviderGate()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PatientHome()));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ خطأ: تأكد من البيانات"), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.jpg'), // يمكنك وضع خلفية طبية هنا لاحقاً
            fit: BoxFit.cover,
            opacity: 0.05, // شفافية خفيفة
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_rounded, size: 80, color: Color(0xFF009688)),
                const SizedBox(height: 20),
                const Text("مرحباً بك مجدداً", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text("سجل الدخول لمتابعة حالتك الصحية", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),

                // حقول الإدخال الزجاجية
                _GlassTextField(controller: _emailController, hint: "البريد الإلكتروني", icon: Icons.email_outlined),
                const SizedBox(height: 15),
                _GlassTextField(controller: _passwordController, hint: "كلمة المرور", icon: Icons.lock_outline, isPassword: true),
                
                const SizedBox(height: 30),
                
                // زر الدخول
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("تسجيل الدخول"),
                  ),
                ),

                const SizedBox(height: 20),
                
                // زر إنشاء حساب
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("ليس لديك حساب؟ "),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                      child: const Text("انضم لعائلة عافية", style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 📝 شاشة إنشاء الحساب (مريض + شريك VIP)
// -----------------------------------------------------------------------------
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isProvider = false; // هل هو شريك (ممرض/طبيب)؟
  bool _isLoading = false;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _selectedWilaya;
  String? _selectedSpecialty;

  // قائمة الولايات (58 ولاية) للفلترة الدقيقة
  final List<String> _wilayas = [
    "01. أدرار", "02. الشلف", "03. الأغواط", "04. أم البواقي", "05. باتنة", "06. بجاية",
    "07. بسكرة", "08. بشار", "09. البليدة", "10. البويرة", "11. تمنراست", "12. تبسة",
    "13. تلمسان", "14. تيارت", "15. تيزي وزو", "16. الجزائر", "17. الجلفة", "18. جيجل",
    "19. سطيف", "20. سعيدة", "21. سكيكدة", "22. سيدي بلعباس", "23. عنابة", "24. قالمة",
    "25. قسنطينة", "26. المدية", "27. مستغانم", "28. المسيلة", "29. معسكر", "30. ورقلة",
    "31. وهران", "32. البيض", "33. إليزي", "34. برج بوعريريج", "35. بومرداس", "36. الطارف",
    "37. تيندوف", "38. تيسمسيلت", "39. الوادي", "40. خنشلة", "41. سوق أهراس", "42. تيبازة",
    "43. ميلة", "44. عين الدفلى", "45. النعامة", "46. عين تموشنت", "47. غرداية", "48. غليزان",
    "49. تيميمون", "50. برج باجي مختار", "51. أولاد جلال", "52. بني عباس", "53. عين صالح",
    "54. عين قزام", "55. تقرت", "56. جانت", "57. المغير", "58. المنيعة"
  ];

  final List<String> _specialties = ["ممرض منزلي", "طبيب عام", "سائق إسعاف", "نقل صحي"];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWilaya == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى اختيار الولاية")));
      return;
    }
    if (_isProvider && _selectedSpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى اختيار التخصص")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. إنشاء الحساب في Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. تحديد البيانات حسب النوع
      String role = _isProvider ? 'provider' : 'patient';
      // المريض نشط فوراً، الشريك يجب أن يرفع الوثائق (pending_docs)
      String status = _isProvider ? 'pending_docs' : 'active'; 

      // 3. الحفظ في Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'wilaya': _selectedWilaya,
        'role': role,
        'status': status, // مهم جداً للتحكم
        'specialty': _isProvider ? _selectedSpecialty : null, // فقط للشركاء
        'created_at': FieldValue.serverTimestamp(),
        'subscription_expiry': null,
        'is_online': false, // للممرضين
      });

      if (mounted) {
        if (_isProvider) {
          // الشريك يذهب لرفع الوثائق
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProviderGate()));
        } else {
          // المريض يذهب للرئيسية
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PatientHome()));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("حساب جديد"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // زر التبديل (مريض / شريك VIP)
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    children: [
                      _buildToggleButton("مريض", !_isProvider),
                      _buildToggleButton("شريك VIP 🚑", _isProvider),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                _GlassTextField(controller: _nameController, hint: "الاسم الكامل", icon: Icons.person),
                const SizedBox(height: 15),
                _GlassTextField(controller: _phoneController, hint: "رقم الهاتف", icon: Icons.phone, isNumber: true),
                const SizedBox(height: 15),
                _GlassTextField(controller: _emailController, hint: "البريد الإلكتروني", icon: Icons.email),
                const SizedBox(height: 15),
                _GlassTextField(controller: _passwordController, hint: "كلمة المرور", icon: Icons.lock, isPassword: true),
                const SizedBox(height: 15),

                // قائمة الولايات (Dropdown)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("اختر ولايتك"),
                      value: _selectedWilaya,
                      items: _wilayas.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (val) => setState(() => _selectedWilaya = val),
                    ),
                  ),
                ),

                // حقول إضافية للشريك فقط
                if (_isProvider) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("تخصصك (شريك)"),
                        value: _selectedSpecialty,
                        items: _specialties.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                        onChanged: (val) => setState(() => _selectedSpecialty = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("⚠️ الشركاء يخضعون للمراجعة ورفع الوثائق", style: TextStyle(color: Colors.orange, fontSize: 12)),
                ],

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProvider ? Colors.orange : const Color(0xFF009688),
                    ),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isProvider ? "انضمام كشريك" : "إنشاء حساب"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isProvider = text.contains("VIP")),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (_isProvider ? Colors.orange : const Color(0xFF009688)) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// 🎨 ويدجت حقل النص الزجاجي (لإعادة الاستخدام)
class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool isNumber;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      validator: (val) => val!.isEmpty ? "مطلوب" : null,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}
