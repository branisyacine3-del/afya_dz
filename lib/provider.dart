import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // للاتصال بالدعم

// 🛡️ البوابة الرئيسية للممرض
class ProviderDashboard extends StatelessWidget {
  const ProviderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        var data = snapshot.data!.data() as Map<String, dynamic>?;
        String status = data != null && data.containsKey('verification_status') 
            ? data['verification_status'] 
            : 'pending_registration';

        // 1. لم يسجل بياناته بعد
        if (status == 'pending_registration') return const ProviderRegistrationScreen();

        // 2. بانتظار موافقة الإدارة على الوثائق
        if (status == 'pending') return const PendingApprovalScreen();

        // 3. 💰 مرحلة الدفع (جديد): الوثائق مقبولة لكن يجب دفع الاشتراك
        if (status == 'pending_payment') return const SubscriptionPaymentScreen();

        // 4. تم الرفض
        if (status == 'rejected') return const RejectedScreen();

        // 5. حساب مفعل (Active) -> يدخل للعمل
        return const ProviderWorkspace();
      },
    );
  }
}

// 💰 شاشة دفع الاشتراك (مع معلوماتك)
class SubscriptionPaymentScreen extends StatelessWidget {
  const SubscriptionPaymentScreen({super.key});

  void _callSupport() async {
    final Uri url = Uri.parse('tel:0562898252'); // رقمك للدعم
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تفعيل الاشتراك"), backgroundColor: Colors.indigo),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.green),
            const SizedBox(height: 10),
            const Text("مبروك! تمت الموافقة على وثائقك 🎉", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  const Text("لتفعيل حسابك وبدء استقبال الطلبات، يجب دفع اشتراك الشهر الأول.", textAlign: TextAlign.center),
                  const Divider(),
                  const Text("قيمة الاشتراك: 3500 دج / شهرياً", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // معلومات الـ CCP الخاصة بك
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("معلومات الدفع (CCP):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _rowInfo("الاسم:", "Branis Yacine"),
                    _rowInfo("CCP:", "0028939081"),
                    _rowInfo("Clé:", "97"),
                    const Divider(),
                    const Text("BaridiMob (RIP):", style: TextStyle(fontWeight: FontWeight.bold)),
                    SelectableText("00799999002893908197", style: TextStyle(fontSize: 16, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text("بعد الدفع، اتصل بالدعم لإرسال الوصل وتفعيل الحساب فوراً.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _callSupport,
                icon: const Icon(Icons.call),
                label: const Text("اتصل لتأكيد الدفع (0562898252)"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          SelectableText(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

// ... (باقي الشاشات: التسجيل، الانتظار، الرفض)
class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});
  @override
  State<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends State<ProviderRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': _nameCtrl.text,
      'phone_contact': _phoneCtrl.text,
      'verification_status': 'pending', 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("التسجيل")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("سجل بياناتك للانضمام", style: TextStyle(fontSize: 20)),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "الاسم الكامل")),
            const SizedBox(height: 20),
            // زر وهمي لرفع الوثائق
            Container(height: 100, color: Colors.grey.shade200, child: const Center(child: Text("رفع صورة الدبلوم + البطاقة"))),
            const Spacer(),
            ElevatedButton(onPressed: _isLoading ? null : _submit, child: const Text("إرسال للمراجعة")),
          ],
        ),
      ),
    );
  }
}

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text("جاري مراجعة الوثائق...", style: TextStyle(fontSize: 20)),
            TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("خروج")),
          ],
        ),
      ),
    );
  }
}

class RejectedScreen extends StatelessWidget {
  const RejectedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("تم رفض الطلب. اتصل بالدعم.")),
    );
  }
}

// 🚑 مساحة العمل (تعمل فقط بعد الدفع والتفعيل)
class ProviderWorkspace extends StatelessWidget {
  const ProviderWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مساحة العمل"),
        actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))],
      ),
      body: const Center(
        child: Text("أهلاً بك! اشتراكك مفعل ✅\nاستقبل الطلبات الآن.", textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
