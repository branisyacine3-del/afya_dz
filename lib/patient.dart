import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("عافية - خدمات طبية"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 🟢 بطاقة الترحيب
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Text("مرحباً بك ❤️", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text("اختر الخدمة التي تحتاجها وسنصلك فوراً", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 🏥 شبكة الخدمات
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  // 👇 هذا الزر الوحيد المفعل حالياً
                  _ServiceCard(
                    title: "ممرض منزلي",
                    icon: Icons.medical_services_outlined,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BookingScreen(serviceName: "ممرض منزلي")),
                      );
                    },
                  ),
                  _ServiceCard(
                    title: "طبيب عام",
                    icon: Icons.person,
                    color: Colors.blue,
                    onTap: () => _showComingSoon(context),
                  ),
                  _ServiceCard(
                    title: "سيارة إسعاف",
                    icon: Icons.local_hospital,
                    color: Colors.red,
                    onTap: () => _showComingSoon(context),
                  ),
                  _ServiceCard(
                    title: "رعاية مسنين",
                    icon: Icons.elderly,
                    color: Colors.orange,
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("هذه الخدمة ستتوفر قريباً!")),
    );
  }
}

// 🎨 تصميم الكارت
class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// 📝 صفحة الحجز (الاستمارة)
class BookingScreen extends StatefulWidget {
  final String serviceName;
  const BookingScreen({super.key, required this.serviceName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. الحصول على هوية المستخدم الحالي
      User? user = FirebaseAuth.instance.currentUser;
      
      // 2. تجهيز البيانات
      Map<String, dynamic> requestData = {
        "service": widget.serviceName,
        "patient_name": _nameController.text,
        "phone": _phoneController.text,
        "address": _addressController.text,
        "details": _detailsController.text,
        "status": "pending", // الحالة: قيد الانتظار
        "user_id": user?.uid ?? "anonymous",
        "created_at": FieldValue.serverTimestamp(),
      };

      // 3. الحفظ في فايربيز (Firestore)
      await FirebaseFirestore.instance.collection('requests').add(requestData);

      // 4. نجاح العملية
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم إرسال طلبك بنجاح! سيتصل بك الممرض قريباً."), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // العودة للصفحة الرئيسية
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ حدث خطأ: $e"), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("حجز ${widget.serviceName}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("املأ البيانات ليصلك الممرض", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 20),
              
              _buildTextField("الاسم الكامل", _nameController, icon: Icons.person),
              _buildTextField("رقم الهاتف", _phoneController, icon: Icons.phone, isNumber: true),
              _buildTextField("العنوان (الولاية/البلدية)", _addressController, icon: Icons.location_on),
              _buildTextField("تفاصيل (مثلاً: حقنة، تغيير ضمادة...)", _detailsController, icon: Icons.note, maxLines: 3),

              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("تأكيد الطلب", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        maxLines: maxLines,
        validator: (value) => value!.isEmpty ? "هذا الحقل مطلوب" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.teal) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
 
