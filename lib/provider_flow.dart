import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_screens.dart'; // للعودة عند الخروج

// -----------------------------------------------------------------------------
// 🚦 البوابة الذكية (Gatekeeper)
// توجه الشريك حسب حالته (جديد، قيد المراجعة، يحتاج دفع، نشط)
// -----------------------------------------------------------------------------
class ProviderGate extends StatelessWidget {
  const ProviderGate({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        // إذا لم يكن المستند موجوداً (خطأ نادر)
        if (!snapshot.data!.exists) return const LoginScreen();

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'pending_docs';

        // 1. لم يرفع الوثائق بعد
        if (status == 'pending_docs') return const _DocsUploadScreen();
        
        // 2. الوثائق قيد المراجعة من الإدارة
        if (status == 'under_review') return const _StatusScreen(
          title: "جاري المراجعة 📄",
          msg: "يقوم فريق عافية بمراجعة وثائقك.\nستصلك الموافقة قريباً للمرور لمرحلة الدفع.",
          icon: Icons.hourglass_top, color: Colors.orange
        );

        // 3. تم القبول، يجب دفع الاشتراك
        if (status == 'pending_payment') return const _PaymentScreen();

        // 4. تم الدفع، في انتظار تفعيل الاشتراك
        if (status == 'payment_review') return const _StatusScreen(
          title: "جاري تأكيد الدفع 💸",
          msg: "وصلنا الإيصال. سيتم تفعيل حسابك خلال ساعات.\nاستعد للعمل!",
          icon: Icons.check_circle_outline, color: Colors.blue
        );

        // 5. الحساب نشط! (أهلاً بك في العمل)
        if (status == 'active') return const ProviderDashboard();

        // 6. مرفوض
        return const _StatusScreen(
          title: "عذراً",
          msg: "تم رفض الطلب لعدم تطابق الشروط.\nتواصل مع الدعم للمزيد.",
          icon: Icons.block, color: Colors.red
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 1️⃣ شاشة رفع الوثائق (المرحلة الأولى)
// -----------------------------------------------------------------------------
class _DocsUploadScreen extends StatefulWidget {
  const _DocsUploadScreen();
  @override
  State<_DocsUploadScreen> createState() => _DocsUploadScreenState();
}

class _DocsUploadScreenState extends State<_DocsUploadScreen> {
  String? _idImg, _dipImg, _photoImg;
  bool _loading = false;

  Future<void> _pick(String type) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 30); // ضغط قوي
    if (file != null) {
      String b64 = base64Encode(await File(file.path).readAsBytes());
      setState(() {
        if (type == 'id') _idImg = b64;
        if (type == 'dip') _dipImg = b64;
        if (type == 'photo') _photoImg = b64;
      });
    }
  }

  Future<void> _submit() async {
    if (_idImg == null || _dipImg == null || _photoImg == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يجب رفع جميع الوثائق!")));
      return;
    }
    setState(() => _loading = true);
    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
      'status': 'under_review',
      'id_card_image': _idImg,
      'diploma_image': _dipImg,
      'personal_image': _photoImg,
    });
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تفعيل الحساب (1/2)"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("يرجى رفع الوثائق لإثبات هويتك وكفاءتك", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            _DocButton("صورة شخصية", _photoImg != null, () => _pick('photo')),
            _DocButton("بطاقة التعريف", _idImg != null, () => _pick('id')),
            _DocButton("الشهادة / الدبلوم", _dipImg != null, () => _pick('dip')),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("إرسال للمراجعة"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2️⃣ شاشة الدفع (المرحلة الثانية)
// -----------------------------------------------------------------------------
class _PaymentScreen extends StatefulWidget {
  const _PaymentScreen();
  @override
  State<_PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<_PaymentScreen> {
  String? _receipt;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("اشتراك عافية (2/2)"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.workspace_premium, size: 60, color: Colors.orange),
            const SizedBox(height: 10),
            const Text("تم قبول وثائقك! 🎉", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("لتفعيل حسابك، يرجى دفع رسوم الاشتراك", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            
            // بطاقة المعلومات البريدية
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
              child: const Column(
                children: [
                  Text("مبلغ الاشتراك: 3500 دج / شهرياً", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)),
                  Divider(),
                  Text("CCP / BaridiMob", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  SelectableText("RIP: 00799999002893908197", style: TextStyle(fontSize: 18, letterSpacing: 1)),
                  Text("الاسم: BRANIS YACINE"),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _DocButton("إرفاق وصل الدفع", _receipt != null, () async {
              final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 30);
              if (f != null) setState(() async => _receipt = base64Encode(await File(f.path).readAsBytes()));
            }),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_receipt == null || _loading) ? null : () async {
                  setState(() => _loading = true);
                  await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
                    'status': 'payment_review',
                    'receipt_image': _receipt,
                  });
                  setState(() => _loading = false);
                },
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("تأكيد الدفع"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3️⃣ لوحة العمل الرئيسية (Dashboard)
// -----------------------------------------------------------------------------
class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _idx = 0;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _checkOnlineStatus();
  }

  void _checkOnlineStatus() async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    if (mounted && doc.exists) setState(() => _isOnline = doc['is_online'] ?? false);
  }

  void _toggleOnline(bool val) {
    setState(() => _isOnline = val);
    FirebaseFirestore.instance.collection('users').doc(_uid).update({'is_online': val});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(_idx == 0 ? "رادار العمل 📡" : "ملفي الشخصي"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_idx == 0)
            Switch(
              value: _isOnline,
              activeColor: Colors.teal,
              onChanged: _toggleOnline,
            )
        ],
      ),
      body: _idx == 0 ? _WorkTab(uid: _uid, isOnline: _isOnline) : _ProfileTab(uid: _uid),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: Colors.teal,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: "العمل"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "حسابي"),
        ],
      ),
    );
  }
}

// --- تبويب العمل (الرادار + المهام النشطة) ---
class _WorkTab extends StatelessWidget {
  final String uid;
  final bool isOnline;
  const _WorkTab({required this.uid, required this.isOnline});

  // دوال مساعدة
  void _call(String ph) async => await launchUrl(Uri.parse("tel:$ph"));
  void _map(String loc) async => await launchUrl(Uri.parse("google.navigation:q=${loc.replaceAll(' ', '')}&mode=d"), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    if (!isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.power_off, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text("أنت غير متصل", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("فعّل وضع العمل لاستقبال الطلبات", style: TextStyle(color: Colors.grey)),
            Switch(value: false, onChanged: (v) => FirebaseFirestore.instance.collection('users').doc(uid).update({'is_online': true})),
          ],
        ),
      );
    }

    // 1. فحص هل هناك مهمة نشطة حالياً؟
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests')
          .where('provider_id', isEqualTo: uid)
          .where('status', whereIn: ['accepted', 'on_way'])
          .snapshots(),
      builder: (context, activeSnap) {
        if (!activeSnap.hasData) return const Center(child: CircularProgressIndicator());
        
        // 🔥 حالة 1: يوجد مهمة نشطة -> عرض تفاصيل المريض الكاملة
        if (activeSnap.data!.docs.isNotEmpty) {
          var job = activeSnap.data!.docs.first;
          var data = job.data() as Map<String, dynamic>;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green)),
                  child: Row(children: [
                    const Icon(Icons.directions_run, color: Colors.green, size: 40),
                    const SizedBox(width: 15),
                    Expanded(child: Text(data['status'] == 'accepted' ? "مهمة جديدة! استعد" : "أنت في الطريق للمريض", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                  ]),
                ),
                const SizedBox(height: 20),
                
                // كارت تفاصيل المريض
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.person, color: Colors.white)),
                        title: Text(data['patient_name'] ?? "المريض"),
                        subtitle: Text(data['service']),
                        trailing: Text("${data['price']} دج", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 18)),
                      ),
                      const Divider(),
                      if (data['image_data'] != null)
                         ElevatedButton.icon(
                           icon: const Icon(Icons.image), 
                           label: const Text("عرض صورة الحالة"),
                           onPressed: () => showDialog(context: context, builder: (_) => Dialog(child: Image.memory(base64Decode(data['image_data'])))),
                         ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: ElevatedButton.icon(onPressed: () => _call(data['phone']), icon: const Icon(Icons.call), label: const Text("اتصال"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green))),
                          const SizedBox(width: 10),
                          Expanded(child: ElevatedButton.icon(onPressed: () => _map(data['location']), icon: const Icon(Icons.map), label: const Text("الموقع"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue))),
                        ],
                      ),
                      if(data['details'] != null && data['details'].isNotEmpty)
                         Padding(padding: const EdgeInsets.only(top: 10), child: Text("ملاحظة: ${data['details']}", style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // أزرار التحكم في الحالة
                if (data['status'] == 'accepted')
                  SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
                    onPressed: () { _map(data['location']); job.reference.update({'status': 'on_way'}); },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text("أنا في الطريق (فتح الخريطة) 🚗"),
                  )),
                
                if (data['status'] == 'on_way')
                  SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
                    onPressed: () => job.reference.update({'status': 'completed'}),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text("إتمام المهمة واستلام المبلغ ✅"),
                  )),
                
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                    title: const Text("إلغاء المهمة؟"), 
                    content: const Text("يرجى الاتصال بالمريض أولاً."), 
                    actions: [
                      TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("تراجع")),
                      TextButton(onPressed: (){ job.reference.update({'status': 'pending', 'provider_id': null}); Navigator.pop(ctx); }, child: const Text("إلغاء", style: TextStyle(color: Colors.red))),
                    ]
                  )),
                  child: const Text("إلغاء المهمة (طوارئ)", style: TextStyle(color: Colors.red)),
                )
              ],
            ),
          );
        }

        // 📡 حالة 2: لا توجد مهمة -> شغل الرادار (بحث في نفس الولاية)
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnap) {
            if(!userSnap.hasData) return const SizedBox();
            String myWilaya = userSnap.data!['wilaya'] ?? "";

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('requests')
                  .where('status', isEqualTo: 'pending')
                  .where('wilaya', isEqualTo: myWilaya) // فلترة جغرافية صارمة
                  .snapshots(),
              builder: (context, reqSnap) {
                if (!reqSnap.hasData) return const Center(child: CircularProgressIndicator());
                var docs = reqSnap.data!.docs;

                if (docs.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.radar, size: 100, color: Colors.teal.withOpacity(0.2)),
                    const SizedBox(height: 20),
                    Text("جاري البحث في $myWilaya...", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ]));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var req = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text("🔥 طلب جديد", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              Text("${req['price']} دج", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                            ]),
                            const Divider(),
                            ListTile(
                              title: Text(req['service']),
                              subtitle: Text("يبعد عنك مسافة قصيرة"), // يمكن حسابها بـ Geolocator لاحقاً
                              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: const Icon(Icons.medical_services, color: Colors.orange)),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(width: double.infinity, child: ElevatedButton(
                              onPressed: () => docs[index].reference.update({'status': 'accepted', 'provider_id': uid}),
                              child: const Text("قبول الطلب"),
                            ))
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// --- تبويب الحساب (Profile & Stats) ---
class _ProfileTab extends StatelessWidget {
  final String uid;
  const _ProfileTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var data = snapshot.data!.data() as Map<String, dynamic>;

        // حساب الأيام المتبقية
        DateTime? expiry = (data['subscription_expiry'] as Timestamp?)?.toDate();
        int daysLeft = expiry != null ? expiry.difference(DateTime.now()).inDays : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // كارت المعلومات الشخصية
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40, 
                      backgroundImage: data['personal_image'] != null ? MemoryImage(base64Decode(data['personal_image'])) : null,
                      child: data['personal_image'] == null ? const Icon(Icons.person, size: 40) : null,
                    ),
                    const SizedBox(width: 20),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(data['full_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(data['specialty'] ?? "شريك", style: const TextStyle(color: Colors.grey)),
                      Text(data['wilaya'] ?? "", style: const TextStyle(color: Colors.teal)),
                    ])
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // الإحصائيات (أرباح وهمية للمثال، يمكن حسابها حقيقية بـ cloud functions)
              Row(
                children: [
                  _StatCard("الأرباح", "0 دج", Icons.attach_money, Colors.green),
                  const SizedBox(width: 15),
                  _StatCard("الاشتراك", "$daysLeft يوم", Icons.timer, daysLeft < 5 ? Colors.red : Colors.blue),
                ],
              ),
              const SizedBox(height: 20),

              // زر الدعم
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                leading: const Icon(Icons.support_agent, color: Colors.teal),
                title: const Text("تواصل مع الإدارة"),
                onTap: () => launchUrl(Uri.parse("https://wa.me/213562898252")),
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("تسجيل الخروج"),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _StatCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}

// أدوات مساعدة
class _DocButton extends StatelessWidget {
  final String text; final bool isDone; final VoidCallback onTap;
  const _DocButton(this.text, this.isDone, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(isDone ? Icons.check_circle : Icons.upload_file, color: isDone ? Colors.green : Colors.grey),
        title: Text(text),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _StatusScreen extends StatelessWidget {
  final String title; final String msg; final IconData icon; final Color color;
  const _StatusScreen({required this.title, required this.msg, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: color),
            const SizedBox(height: 30),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 50),
            TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("تسجيل الخروج"))
          ],
        ),
      ),
    );
  }
}
