import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // 📞 للاتصال

// 🚦 البوابة الذكية للممرض
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

// -----------------------------------------------------------------------------
// 1️⃣ شاشة رفع الوثائق (الكود الأصلي السليم)
// -----------------------------------------------------------------------------
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String? _idBase64;
  String? _diplomaBase64;
  String? _photoBase64;
  bool _isLoading = false;

  Future<void> _pickAndConvert(String type) async {
    final ImagePicker picker = ImagePicker();
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

// -----------------------------------------------------------------------------
// 2️⃣ شاشة الدفع (الكود الأصلي السليم)
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// 3️⃣ لوحة العمل المطورة (Dashboard) - بدون أخطاء
// -----------------------------------------------------------------------------
class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  bool _isAvailable = true;
  final String _myUid = FirebaseAuth.instance.currentUser!.uid;

  // 📞 دالة الاتصال
  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة العمل 🚑"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.exit_to_app), onPressed: () => FirebaseAuth.instance.signOut())],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1️⃣ أولاً: هل لدي عمل حالي؟ (مقبول أو في الطريق)
        stream: FirebaseFirestore.instance.collection('requests')
            .where('provider_id', isEqualTo: _myUid)
            .where('status', whereIn: ['accepted', 'on_way'])
            .snapshots(),
        builder: (context, activeJobSnapshot) {
          if (!activeJobSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          // 🚑 حالة 1: لدي عمل نشط -> اعرض التفاصيل فوراً
          if (activeJobSnapshot.data!.docs.isNotEmpty) {
            var job = activeJobSnapshot.data!.docs.first;
            return _buildActiveJobScreen(job);
          }

          // 📡 حالة 2: أنا حر -> شغل الرادار
          return _buildRadarScreen();
        },
      ),
    );
  }

  // 📋 شاشة تفاصيل العمل الحالي
  Widget _buildActiveJobScreen(DocumentSnapshot jobDoc) {
    var job = jobDoc.data() as Map<String, dynamic>;
    String status = job['status'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.green)),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 40),
                const SizedBox(width: 15),
                const Expanded(child: Text("لديك مهمة نشطة!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Text("${job['price']} دج", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(job['patient_name'] ?? "المريض"),
                    subtitle: Text(job['service'] ?? "الخدمة"),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(job['wilaya'] ?? ""),
                    subtitle: Text(job['location'] ?? "الموقع"),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.blue),
                    title: Text(job['phone'] ?? ""),
                    trailing: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(job['phone'] ?? ""),
                      icon: const Icon(Icons.call),
                      label: const Text("اتصال"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
          // 🕹️ أزرار التحكم في الحالة
          if (status == 'accepted')
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  jobDoc.reference.update({'status': 'on_way'});
                },
                icon: const Icon(Icons.directions_car),
                label: const Text("أنا في الطريق 🚗", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
            ),

          if (status == 'on_way')
            Column(
              children: [
                const Text("🚗 أنت الآن في الطريق للمريض...", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      jobDoc.reference.update({'status': 'completed'});
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text("تمت المهمة ✅", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            
          const SizedBox(height: 20),
          TextButton(
             onPressed: () {
               jobDoc.reference.update({'status': 'pending', 'provider_id': null});
             },
             child: const Text("إلغاء المهمة (طوارئ)", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  // 📡 شاشة الرادار
  Widget _buildRadarScreen() {
    return Column(
      children: [
        Container(
          color: _isAvailable ? Colors.teal[50] : Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isAvailable ? "🟢 متصل (تلقي طلبات)" : "🔴 غير متصل", style: const TextStyle(fontWeight: FontWeight.bold)),
              Switch(
                value: _isAvailable,
                activeColor: Colors.teal,
                onChanged: (val) => setState(() => _isAvailable = val),
              ),
            ],
          ),
        ),
        
        Expanded(
            child: _isAvailable 
            ? StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(_myUid).snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                  String myWilaya = userSnapshot.data!['wilaya'] ?? "";

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('requests')
                        .where('status', isEqualTo: 'pending')
                        .where('wilaya', isEqualTo: myWilaya) 
                        .snapshots(),
                    builder: (context, requestSnapshot) {
                      if (!requestSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                      var docs = requestSnapshot.data!.docs;

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.radar, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 20),
                              Text("لا توجد طلبات في ولاية ($myWilaya)", style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 5),
                              const Text("جاري البحث...", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var req = docs[index].data() as Map<String, dynamic>;
                          return Card(
                            elevation: 5,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("🔥 طلب جديد!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      Text("${req['price']} دج", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                  const Divider(),
                                  ListTile(
                                    title: Text(req['patient_name'] ?? "مريض"),
                                    subtitle: Text(req['service'] ?? "خدمة"),
                                    leading: const CircleAvatar(child: Icon(Icons.person)),
                                  ),
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        FirebaseFirestore.instance.collection('requests').doc(docs[index].id).update({
                                          'status': 'accepted',
                                          'provider_id': _myUid,
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      child: const Text("قبول الطلب ✅", style: TextStyle(fontSize: 18)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              )
            : const Center(child: Text("أنت غير متصل"))
        ),
      ],
    );
  }
}

class StatusScreen extends StatelessWidget {
  final String title; final String message; final IconData icon; final Color color;
  const StatusScreen({super.key, required this.title, required this.message, required this.icon, required this.color});
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon,size:80,color:color),Text(title,style:const TextStyle(fontSize:24)),Text(message),TextButton(onPressed:()=>FirebaseAuth.instance.signOut(),child:const Text("خروج"))]))); 
}
