import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// 💰 شاشة الدفع (تظهر في حالتين: حساب جديد أو اشتراك منتهي)
class ProviderPaymentScreen extends StatelessWidget {
  final String status; // 'pending' (جديد) أو 'expired' (منتهي)
  const ProviderPaymentScreen({super.key, required this.status});

  // دالة فتح الواتساب لإرسال الوصل
  Future<void> _contactAdmin() async {
    // رقمك بصيغة دولية (بدون 0)
    final Uri url = Uri.parse("https://wa.me/213562898252?text=السلام عليكم، أرسلت لك وصل دفع الاشتراك.");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("لا يمكن فتح الواتساب");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isExpired = status == 'expired';

    return Scaffold(
      appBar: AppBar(
        title: Text(isExpired ? "تجديد الاشتراك" : "تفعيل الحساب"),
        backgroundColor: Colors.indigo,
        actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(isExpired ? Icons.history_toggle_off : Icons.verified_user, size: 80, color: isExpired ? Colors.red : Colors.orange),
            const SizedBox(height: 20),
            Text(
              isExpired ? "انتهت فترة اشتراكك 🛑" : "مرحباً بك في فريق عافية 👋",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isExpired 
                ? "لقد تجاوزت 30 يوماً. يرجى تجديد الاشتراك لاستقبال الطلبات مجدداً."
                : "حسابك قيد الانتظار. لتفعيل الحساب وبدء العمل، يرجى دفع اشتراك الشهر الأول.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // 💳 بطاقة معلومات الدفع
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.indigo.shade100),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text("معلومات الدفع (CCP)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                  const Divider(),
                  _infoRow("الاسم:", "Branis Yacine"),
                  _infoRow("CCP:", "0028939081"),
                  _infoRow("Clé:", "97"),
                  const Divider(),
                  _infoRow("BaridiMob:", "00799999002893908197"),
                  const Divider(),
                  const Text("قيمة الاشتراك: 3500 دج / شهر", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // زر الواتساب
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _contactAdmin,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.chat),
                label: const Text("أرسل وصل الدفع عبر الواتساب", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          SelectableText(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

// 🚑 لوحة التحكم (للممرض المفعل فقط)
class ProviderDashboard extends StatelessWidget {
  const ProviderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مساحة العمل"),
        backgroundColor: Colors.indigo,
        actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radar, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            const Text("جاري البحث عن طلبات قريبة...", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
            const SizedBox(height: 30),
            const Text("اشتراكك ساري ✅", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
 
