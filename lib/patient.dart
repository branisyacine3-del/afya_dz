import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  // 📞 دالة فتح واتساب الدعم
  Future<void> _contactSupport() async {
    // رقمك (0562898252) بصيغة دولية
    final Uri url = Uri.parse("https://wa.me/213562898252?text=أحتاج مساعدة في تطبيق عافية.");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("لا يمكن فتح الواتساب");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("عافية - خدمات طبية"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // ✅ زر الدعم العائم (واتساب)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _contactSupport,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.chat),
        label: const Text("الدعم الفني"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 👋 بطاقة الترحيب
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      "مرحباً بك ❤️\nاختر الخدمة التي تحتاجها وسنصلك فوراً.",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Icon(Icons.health_and_safety, color: Colors.white, size: 40),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // 🏥 شبكة الخدمات (بدون صور لتجنب الشاشة الرمادية)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _serviceCard(context, "ممرض منزلي", Icons.medical_services, Colors.teal),
                  _serviceCard(context, "طبيب عام", Icons.person, Colors.blue),
                  _serviceCard(context, "سيارة إسعاف", Icons.emergency, Colors.red), // أيقونة آمنة
                  _serviceCard(context, "رعاية مسنين", Icons.elderly, Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تصميم كرت الخدمة
  Widget _serviceCard(BuildContext context, String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // هنا سنضيف كود الحجز لاحقاً
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("اخترت خدمة: $title (سيتم التفعيل قريباً)")),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
 
