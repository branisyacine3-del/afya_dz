import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
        if (status == 'under_review') return const StatusScreen(title: "جاري المراجعة", message: "نراجع وثائقك...", icon: Icons.hourglass_top, color: Colors.orange);
        if (status == 'pending_payment') return const SubscriptionScreen();
        if (status == 'payment_review') return const StatusScreen(title: "تأكيد الدفع", message: "نراجع الدفع...", icon: Icons.payments, color: Colors.blue);
        if (status == 'active') return const ProviderDashboard();

        return const StatusScreen(title: "عذراً", message: "تم الرفض.", icon: Icons.block, color: Colors.red);
      },
    );
  }
}

// (VerificationScreen و SubscriptionScreen بنفس الكود السابق - لعدم الإطالة يمكنك نسخهم من الرد السابق، أو سأفترض أنهم موجودين)
// سأضع لك الـ Dashboard المطور فقط هنا:
// ... (افترض وجود VerificationScreen و SubscriptionScreen هنا) ...
// لتجنب الأخطاء سأضع الكود الكامل للكلاسين المختصرين للدمج

class VerificationScreen extends StatefulWidget { const VerificationScreen({super.key}); @override State<VerificationScreen> createState() => _VState(); }
class _VState extends State<VerificationScreen> {
  String? _id; String? _dp; String? _ph; bool _load=false;
  Future<void> _p(String t) async { final XFile? i = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 40); if(i!=null) { File f=File(i.path); String b=base64Encode(await f.readAsBytes()); setState((){ if(t=='id')_id=b; if(t=='diploma')_dp=b; if(t=='photo')_ph=b; }); }}
  Future<void> _sub() async { if(_id==null||_dp==null||_ph==null)return; setState(()=>_load=true); await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'status':'under_review','id_card_image':_id,'diploma_image':_dp,'personal_image':_ph}); setState(()=>_load=false); }
  @override Widget build(BuildContext context) => Scaffold(appBar:AppBar(title:const Text("رفع الوثائق")), body:Center(child:_load?const CircularProgressIndicator():Column(children:[ElevatedButton(onPressed:()=>_p('id'),child:Text(_id==null?"البطاقة":"تم")),ElevatedButton(onPressed:()=>_p('diploma'),child:Text(_dp==null?"الشهادة":"تم")),ElevatedButton(onPressed:()=>_p('photo'),child:Text(_ph==null?"صورة":"تم")),ElevatedButton(onPressed:_sub,child:const Text("إرسال"))]))); }

class SubscriptionScreen extends StatefulWidget { const SubscriptionScreen({super.key}); @override State<SubscriptionScreen> createState() => _SState(); }
class _SState extends State<SubscriptionScreen> {
  String? _rec; bool _load=false;
  @override Widget build(BuildContext context) => Scaffold(appBar:AppBar(title:const Text("الدفع")), body:Center(child:Column(children:[ElevatedButton(onPressed:()async{final XFile? i=await ImagePicker().pickImage(source: ImageSource.gallery,imageQuality:40); if(i!=null){String b=base64Encode(await File(i.path).readAsBytes());setState(()=>_rec=b);}},child:Text(_rec==null?"صورة الوصل":"تم")),ElevatedButton(onPressed:()async{if(_rec==null)return;setState(()=>_load=true);await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'status':'payment_review','receipt_image':_rec});setState(()=>_load=false);},child:const Text("تأكيد"))]))); }

// -----------------------------------------------------------------------------
// 3️⃣ لوحة العمل المطورة (مع تبويبات: العمل الحالي + السجل)
// -----------------------------------------------------------------------------
class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  // 1️⃣ إصلاح زر الاتصال: استخدام LaunchMode.externalApplication
  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication); // 👈 الحل
      } else {
        // محاولة احتياطية
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint("خطأ في الاتصال: $e");
    }
  }

  // 2️⃣ زر الخرائط: فتح جوجل مابس مباشرة
  void _openMap(String locationString) async {
    // locationString تأتي بصيغة "36.123, 3.456"
    // نحذف المسافات ونضعها في الرابط
    final cleanLoc = locationString.replaceAll(' ', '');
    // رابط الملاحة المباشر
    final googleUrl = Uri.parse('google.navigation:q=$cleanLoc&mode=d');
    
    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      } else {
        // إذا لم يكن التطبيق مثبتاً، نفتح في المتصفح
        final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$cleanLoc');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("خطأ في الخرائط: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام DefaultTabController لإضافة تبويبات (الرادار + السجل)
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("لوحة العمل 🚑"),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.radar), text: "العمل الحالي"),
              Tab(icon: Icon(Icons.history), text: "السجل"),
            ],
          ),
          actions: [IconButton(icon: const Icon(Icons.exit_to_app), onPressed: () => FirebaseAuth.instance.signOut())],
        ),
        body: const TabBarView(
          children: [
            _RadarAndActiveJobTab(), // التبويب 1: الرادار والعمل
            _HistoryTab(),           // التبويب 2: السجل
          ],
        ),
      ),
    );
  }
}

// --- التبويب الأول: الرادار والعمل الحالي ---
class _RadarAndActiveJobTab extends StatefulWidget {
  const _RadarAndActiveJobTab();

  @override
  State<_RadarAndActiveJobTab> createState() => _RadarAndActiveJobTabState();
}

class _RadarAndActiveJobTabState extends State<_RadarAndActiveJobTab> {
  bool _isAvailable = true;
  final String _myUid = FirebaseAuth.instance.currentUser!.uid;

  // نسخ الدوال هنا للوصول إليها
  void _makePhoneCall(String ph) { context.findAncestorStateOfType<_ProviderDashboardState>()?._makePhoneCall(ph); }
  void _openMap(String loc) { context.findAncestorStateOfType<_ProviderDashboardState>()?._openMap(loc); }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests')
            .where('provider_id', isEqualTo: _myUid)
            .where('status', whereIn: ['accepted', 'on_way'])
            .snapshots(),
        builder: (context, activeJobSnapshot) {
          if (!activeJobSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (activeJobSnapshot.data!.docs.isNotEmpty) {
            return _buildActiveJobScreen(activeJobSnapshot.data!.docs.first);
          }
          return _buildRadarScreen();
        },
    );
  }

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
                    // زر التتبع المباشر
                    trailing: IconButton(
                      icon: const Icon(Icons.directions, color: Colors.blue, size: 30),
                      onPressed: () => _openMap(job['location'] ?? ""),
                      tooltip: "تتبع المسار",
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.blue),
                    title: Text(job['phone'] ?? ""),
                    // زر الاتصال
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
          if (status == 'accepted')
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // فتح الخريطة تلقائياً عند الضغط على "في الطريق"
                  _openMap(job['location'] ?? "");
                  jobDoc.reference.update({'status': 'on_way'});
                },
                icon: const Icon(Icons.directions_car),
                label: const Text("أنا في الطريق (فتح الخريطة) 🚗", style: TextStyle(fontSize: 18)),
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

  Widget _buildRadarScreen() {
    return Column(
      children: [
        Container(
          color: _isAvailable ? Colors.teal[50] : Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isAvailable ? "🟢 متصل" : "🔴 غير متصل", style: const TextStyle(fontWeight: FontWeight.bold)),
              Switch(value: _isAvailable, activeColor: Colors.teal, onChanged: (val) => setState(() => _isAvailable = val)),
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

                      if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.radar, size: 80, color: Colors.grey[300]), const SizedBox(height: 20), Text("لا طلبات في $myWilaya", style: const TextStyle(color: Colors.grey)), const Text("جاري البحث...", style: TextStyle(color: Colors.teal))]));

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
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("🔥 طلب جديد!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), Text("${req['price']} دج", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green))]),
                                  const Divider(),
                                  ListTile(title: Text(req['patient_name'] ?? "مريض"), subtitle: Text(req['service'] ?? "خدمة"), leading: const CircleAvatar(child: Icon(Icons.person))),
                                  const SizedBox(height: 15),
                                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () { FirebaseFirestore.instance.collection('requests').doc(docs[index].id).update({'status': 'accepted', 'provider_id': _myUid}); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text("قبول الطلب ✅", style: TextStyle(fontSize: 18))))
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

// --- التبويب الثاني: السجل (History) ---
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final String myUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests')
          .where('provider_id', isEqualTo: myUid)
          .where('status', isEqualTo: 'completed') // الطلبات المكتملة فقط
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 80, color: Colors.grey), SizedBox(height: 10), Text("لا يوجد سجل طلبات مكتملة")]));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(data['service'] ?? "خدمة"),
                subtitle: Text("${data['patient_name']} \n${data['location']}"),
                trailing: Text("${data['price']} دج", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class StatusScreen extends StatelessWidget { final String title; final String message; final IconData icon; final Color color; const StatusScreen({super.key, required this.title, required this.message, required this.icon, required this.color}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon,size:80,color:color),Text(title,style:const TextStyle(fontSize:24)),Text(message),TextButton(onPressed:()=>FirebaseAuth.instance.signOut(),child:const Text("خروج"))]))); }
 
