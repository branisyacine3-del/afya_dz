import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afya_dz/screens/login_screen.dart'; // سننشئها الخطوة القادمة
import 'package:afya_dz/patient.dart'; // الصفحة الرئيسية للمريض

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // 🎭 نوع الحساب: هل هو مريض أم شريك؟
  bool _isProvider = false; // false = مريض, true = شريك (عائلة عافية)

  // 📝 البيانات
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // 📍 القوائم المنسدلة
  String? _selectedWilaya;
  String? _selectedSpecialty;

  // 🇩🇿 قائمة الـ 58 ولاية (ثابتة)
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

  // 🩺 التخصصات (تظهر فقط للشركاء)
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

      // 2. تحديد الدور والحالة
      String role = _isProvider ? 'provider' : 'patient';
      // المريض مفعل فوراً، الشريك معلق (pending)
      String status = _isProvider ? 'pending_docs' : 'active'; 

      // 3. حفظ البيانات في Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'wilaya': _selectedWilaya,
        'role': role, // patient OR provider
        'status': status, // active OR pending_docs
        'specialty': _isProvider ? _selectedSpecialty : null, // فقط للشركاء
        'created_at': FieldValue.serverTimestamp(),
        'subscription_expiry': null, // سيتم تفعيله لاحقاً للشركاء
      });

      if (mounted) {
        // التوجيه حسب الدور
        if (_isProvider) {
          // الشريك يذهب لصفحة رفع الوثائق (سننشئها لاحقاً)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إنشاء الحساب! يرجى تجهيز وثائقك.")));
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const VerificationScreen())); 
        } else {
          // المريض يدخل مباشرة
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("إنشاء حساب جديد"), centerTitle: true, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 🟢 الشعار
                const Icon(Icons.security, size: 60, color: Colors.teal),
                const SizedBox(height: 10),
                const Text("انضم لعائلة عافية", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                const SizedBox(height: 30),

                // 🔘 زر التبديل (مريض / شريك)
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    children: [
                      _buildToggleButton("مريض", !_isProvider),
                      _buildToggleButton("انضم كشريك (VIP)", _isProvider),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 📝 الخانات الأساسية
                _buildTextField("الاسم الكامل", _nameController, Icons.person),
                const SizedBox(height: 15),
                _buildTextField("رقم الهاتف", _phoneController, Icons.phone, isPhone: true),
                const SizedBox(height: 15),
                _buildTextField("البريد الإلكتروني", _emailController, Icons.email),
                const SizedBox(height: 15),
                _buildTextField("كلمة المرور", _passwordController, Icons.lock, isPassword: true),
                const SizedBox(height: 15),

                // 📍 قائمة الولايات
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "الولاية (إلزامي)",
                    prefixIcon: const Icon(Icons.location_on, color: Colors.teal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _wilayas.map((String wilaya) {
                    return DropdownMenuItem<String>(value: wilaya, child: Text(wilaya));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedWilaya = val),
                ),
                const SizedBox(height: 15),

                // 🩺 قائمة التخصصات (تظهر فقط إذا اخترت شريك)
                if (_isProvider) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "تخصصك (إلزامي)",
                        prefixIcon: const Icon(Icons.work, color: Colors.orange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.orange[50],
                      ),
                      items: _specialties.map((String spec) {
                        return DropdownMenuItem<String>(value: spec, child: Text(spec));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSpecialty = val),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("⚠️ الشركاء يخضعون للمراجعة قبل التفعيل", style: TextStyle(color: Colors.orange, fontSize: 12)),
                  const SizedBox(height: 15),
                ],

                // 🚀 زر التسجيل
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("إنشاء الحساب", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                  },
                  child: const Text("لديك حساب بالفعل؟ سجل الدخول", style: TextStyle(color: Colors.teal)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // تصميم زر التبديل
  Widget _buildToggleButton(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isProvider = (text.contains("VIP"))),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false, bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      validator: (val) => val!.isEmpty ? "مطلوب" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
