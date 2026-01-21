import 'dart:convert'; // 👈 ضروري
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProviderGate extends StatelessWidget {
  const ProviderGate({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        if (!snapshot.data!.exists) return const Scaffold(body: Center(child: Text("حساب غير موجود")));

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'pending_docs';

        if (status == 'pending_docs') return const VerificationScreen();
        
        if (status == 'under_review') return const StatusScreen(
          title: "جاري مراجعة وثائقك 📄",
          message: "فريق عافية يتحقق من وثائقك حالياً. ستصلك رسالة قريباً للمرور لمرحلة الدفع.",
          icon: Icons.hourglass_top,
          color: Colors.orange,
        );

        if (status == 'pending_payment') return const SubscriptionScreen();

        if (status == 'payment_review') return const StatusScreen(
          title: "جاري تأكيد الدفع 💸",
          message: "وصلنا إيصال الدفع الخاص بك. سيتم تفعيل حسابك في أقل من 24 ساعة.",
          icon: Icons.payments,
          color: Colors.blue,
        );

        if (status == 'active') return const ProviderDashboard();

        return const StatusScreen(
          title: "عذراً",
          message: "تم رفض طلبك لعدم استيفاء الشروط. يرجى التواصل مع الإدارة.",
          icon: Icons.block,
          color: Colors.red,
        );
      },
    );
  }
}

// 1️⃣ شاشة رفع الوثائق
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // متغيرات النصوص المشفرة
  String? _idBase64;
  String? _diplomaBase64;
  String? _photoBase64;
  bool _isLoading = false;

  Future<void> _pickAndConvert(String type) async {
    final ImagePicker picker = ImagePicker();
    // ضغط الصورة مهم جداً
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    
    if (image != null) {
      File file = File(image.path);
      List<int> bytes = await file.readAsBytes();
      String base64Str = base64Encode(bytes);

      setState(() {
        if (type == 'id') _idBase64 = base64Str;
        if (type == 'diploma') _diplomaBase64 = base64Str;
        if (type == 'photo') _photoBase64 = base64Str;
      });
    }
  }

  Future<void> _submitDocs() async {
    if (_idBase64 == null || _diplomaBase64 == null || _photoBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى رفع جميع الوثائق المطلوبة")));
      return;
    }

    setState(() => _isLoading = true);
    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
      'status': 'under_review',
      'id_card_image': _idBase64,
      'diploma_image': _diplomaBase64,
      'personal_image': _photoBase64,
    });
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تفعيل الحساب (1/2)"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("يرجى رفع الوثائق التالية لإثبات هويتك", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            _buildUploadCard("بطاقة التعريف الوطنية", Icons.badge, _idBase64 != null, () => _pickAndConvert('id')),
            _buildUploadCard("الشهادة / الدبلوم", Icons.school, _diplomaBase64 != null, () => _pickAndConvert('diploma')),
            _buildUploadCard("صورة شخصية حديثة", Icons.person_pin, _photoBase64 != null, () => _pickAndConvert('photo')),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitDocs,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("إرسال للمراجعة", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(String title, IconData icon, bool isUploaded, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal, size: 30),
        title: Text(title),
        trailing: isUploaded 
            ? const Icon(Icons.check_circle, color: Colors.green) 
            : const Icon(Icons.upload_file, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// 2️⃣ شاشة الدفع
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? _receiptBase64;
  bool _isLoading = false;

  Future<void> _submitPayment() async {
    if (_receiptBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إرفاق صورة الوصل")));
      return;
    }
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
      'status': 'payment_review',
      'receipt_image': _receiptBase64,
    });
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("اشتراك عافية (2/2)"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.workspace_premium, size: 60, color: Colors.orange),
            const SizedBox(height: 10),
            const Text("تفعيل الاشتراك الشهري", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("مبلغ الاشتراك: 3500 دج / شهر", style: TextStyle(fontSize: 18, color: Colors.teal, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              child: const Column(
                children: [
                  Text("بيانات الدفع (BaridiMob)", style: TextStyle(fontWeight: FontWeight.bold)),
                  Divider(),
                  Text("RIP: 00799999002893908197", style: TextStyle(fontSize: 18, letterSpacing: 1.5)),
                  Text("الاسم: BRANIS YACINE"),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                 final ImagePicker picker = ImagePicker();
                 final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
                 if (image != null) {
                    File file = File(image.path);
                    String base64Str = base64Encode(await file.readAsBytes());
                    setState(() => _receiptBase64 = base64Str);
                 }
              },
              icon: Icon(_receiptBase64 != null ? Icons.check : Icons.camera_alt),
              label: Text(_receiptBase64 != null ? "تم إرفاق الوصل" : "إرفاق وصل الدفع"),
              style: ElevatedButton.styleFrom(backgroundColor: _receiptBase64 != null ? Colors.green : Colors.blue, foregroundColor: Colors.white),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text("تأكيد الدفع", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3️⃣ شاشة العمل
class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة العمل 🚑"),
        backgroundColor: _isAvailable ? Colors.teal : Colors.grey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: _isAvailable ? Colors.teal[50] : Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isAvailable ? "🟢 أنت متصل (تتلقى طلبات)" : "🔴 أنت غير متصل", style: const TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: _isAvailable,
                  activeColor: Colors.teal,
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    const Text("جاري البحث عن طلبات قريبة...", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat("رصيدك", "0 دج", Icons.account_balance_wallet, Colors.green),
                _buildStat("طلبات اليوم", "0", Icons.list_alt, Colors.blue),
                _buildStat("التقييم", "5.0", Icons.star, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class StatusScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const StatusScreen({super.key, required this.title, required this.message, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text("تسجيل الخروج", style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }
}
 
