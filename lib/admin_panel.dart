import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screens.dart'; // للخروج

// -----------------------------------------------------------------------------
// 👮‍♂️ لوحة التحكم الرئيسية (Dashboard Grid)
// -----------------------------------------------------------------------------
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text("غرفة القيادة 👮‍♂️"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          )
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _AdminCard("طلبات الانضمام", Icons.person_add, Colors.orange, () => _nav(context, const _JoinRequestsScreen())),
          _AdminCard("مراجعة الدفع", Icons.payments, Colors.blue, () => _nav(context, const _PaymentReviewScreen())),
          _AdminCard("إدارة الطاقم", Icons.people_alt, Colors.teal, () => _nav(context, const _ActiveStaffScreen())),
          _AdminCard("الخدمات والأسعار", Icons.medical_services, Colors.purple, () => _nav(context, const _ServicesManager())),
          _AdminCard("بث الإشعارات", Icons.notifications_active, Colors.red, () => _nav(context, const _NotificationSender())),
          _AdminCard("المراقبة الحية", Icons.radar, Colors.green, () => _nav(context, const _LiveMonitor())),
        ],
      ),
    );
  }

  void _nav(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}

// -----------------------------------------------------------------------------
// 1️⃣ طلبات الانضمام (مراجعة الوثائق)
// -----------------------------------------------------------------------------
class _JoinRequestsScreen extends StatelessWidget {
  const _JoinRequestsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مراجعة الوثائق")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'under_review').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("لا توجد طلبات جديدة"));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  leading: CircleAvatar(backgroundImage: data['personal_image'] != null ? MemoryImage(base64Decode(data['personal_image'])) : null),
                  title: Text(data['full_name']),
                  subtitle: Text("${data['specialty']} - ${data['wilaya']}"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ZoomableImage(data['id_card_image'], "البطاقة"),
                              _ZoomableImage(data['diploma_image'], "الشهادة"),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(child: ElevatedButton(onPressed: () => _updateStatus(docs[index].id, 'pending_payment'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("قبول (تحويل للدفع)"))),
                              const SizedBox(width: 10),
                              Expanded(child: ElevatedButton(onPressed: () => _reject(context, docs[index].id), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("رفض"))),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateStatus(String uid, String status) => FirebaseFirestore.instance.collection('users').doc(uid).update({'status': status});
  
  void _reject(BuildContext context, String uid) {
    TextEditingController reason = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("سبب الرفض"),
      content: TextField(controller: reason, decoration: const InputDecoration(hintText: "مثلاً: الصورة غير واضحة")),
      actions: [
        TextButton(onPressed: (){ _updateStatus(uid, 'pending_docs'); Navigator.pop(ctx); }, child: const Text("إرسال"))
      ],
    ));
  }
}

// -----------------------------------------------------------------------------
// 2️⃣ مراجعة الدفع (وتفعيل الاشتراك 30 يوم)
// -----------------------------------------------------------------------------
class _PaymentReviewScreen extends StatelessWidget {
  const _PaymentReviewScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مراجعة الدفع")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'payment_review').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("لا توجد مدفوعات للمراجعة"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Card(
                child: Column(
                  children: [
                    ListTile(title: Text(data['full_name']), subtitle: Text(data['phone'])),
                    SizedBox(
                      height: 200,
                      child: _ZoomableImage(data['receipt_image'], "وصل الدفع"),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 50)),
                        onPressed: () {
                          // تفعيل لمدة 30 يوم
                          DateTime expiry = DateTime.now().add(const Duration(days: 30));
                          FirebaseFirestore.instance.collection('users').doc(docs[index].id).update({
                            'status': 'active',
                            'subscription_expiry': Timestamp.fromDate(expiry),
                          });
                        }, 
                        child: const Text("تفعيل الاشتراك (30 يوم) ✅"),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3️⃣ إدارة الطاقم النشط (Active Staff)
// -----------------------------------------------------------------------------
class _ActiveStaffScreen extends StatelessWidget {
  const _ActiveStaffScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الطاقم النشط")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'active').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              DateTime? expiry = (data['subscription_expiry'] as Timestamp?)?.toDate();
              int days = expiry != null ? expiry.difference(DateTime.now()).inDays : 0;

              return ListTile(
                leading: CircleAvatar(backgroundImage: data['personal_image'] != null ? MemoryImage(base64Decode(data['personal_image'])) : null),
                title: Text(data['full_name']),
                subtitle: Text("باقي: $days يوم | ${data['wilaya']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.block, color: Colors.red),
                  onPressed: () => FirebaseFirestore.instance.collection('users').doc(snapshot.data!.docs[index].id).update({'status': 'banned'}),
                ),
                onTap: () {
                  // عرض التفاصيل الكاملة
                  showModalBottomSheet(context: context, builder: (_) => Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Text("التفاصيل الكاملة", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(height: 20),
                      _ZoomableImage(data['id_card_image'], "البطاقة"),
                      const SizedBox(height: 10),
                      Text("الهاتف: ${data['phone']}"),
                      Text("التخصص: ${data['specialty']}"),
                    ]),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4️⃣ إدارة الخدمات (Services)
// -----------------------------------------------------------------------------
class _ServicesManager extends StatefulWidget {
  const _ServicesManager();
  @override
  State<_ServicesManager> createState() => _ServicesManagerState();
}
class _ServicesManagerState extends State<_ServicesManager> {
  final _name = TextEditingController();
  final _price = TextEditingController();

  void _add() {
    if(_name.text.isEmpty) return;
    FirebaseFirestore.instance.collection('services').add({
      'name': _name.text, 'price': int.tryParse(_price.text) ?? 0, 'active': true
    });
    _name.clear(); _price.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الخدمات")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Expanded(flex: 2, child: TextField(controller: _name, decoration: const InputDecoration(labelText: "اسم الخدمة"))),
              const SizedBox(width: 10),
              Expanded(flex: 1, child: TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "السعر"))),
              IconButton(icon: const Icon(Icons.add_circle, color: Colors.teal), onPressed: _add)
            ]),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if(!snapshot.hasData) return const SizedBox();
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var d = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(d['name']),
                      trailing: Text("${d['price']} دج"),
                      leading: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => d.reference.delete()),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5️⃣ بث الإشعارات (Notification Sender)
// -----------------------------------------------------------------------------
class _NotificationSender extends StatefulWidget {
  const _NotificationSender();
  @override
  State<_NotificationSender> createState() => _NS();
}
class _NS extends State<_NotificationSender> {
  final _title = TextEditingController(); final _body = TextEditingController(); final _link = TextEditingController(); final _img = TextEditingController();
  
  void _send() {
    if(_title.text.isEmpty) return;
    FirebaseFirestore.instance.collection('notifications').add({
      'title': _title.text, 'body': _body.text, 'link': _link.text, 'image_url': _img.text, 'created_at': FieldValue.serverTimestamp()
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الإرسال للجميع")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إرسال إشعار")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: "عنوان الإشعار", icon: Icon(Icons.title))),
            TextField(controller: _body, decoration: const InputDecoration(labelText: "نص الإشعار", icon: Icon(Icons.message))),
            TextField(controller: _img, decoration: const InputDecoration(labelText: "رابط صورة (اختياري)", icon: Icon(Icons.image))),
            TextField(controller: _link, decoration: const InputDecoration(labelText: "رابط خارجي (اختياري)", icon: Icon(Icons.link))),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _send, child: const Text("إرسال للجميع 🚀"))
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 6️⃣ المراقبة الحية (Live Monitor)
// -----------------------------------------------------------------------------
class _LiveMonitor extends StatelessWidget {
  const _LiveMonitor();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الطلبات الحية")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests').orderBy('created_at', descending: true).limit(50).snapshots(),
        builder: (context, snapshot) {
          if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var d = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              Color c = d['status'] == 'pending' ? Colors.orange : (d['status'] == 'completed' ? Colors.grey : Colors.green);
              return Card(
                color: c.withOpacity(0.1),
                child: ListTile(
                  title: Text(d['service']),
                  subtitle: Text("${d['patient_name']} -> ${d['wilaya']}"),
                  trailing: Text(d['status']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// أدوات
class _AdminCard extends StatelessWidget {
  final String title; final IconData icon; final Color color; final VoidCallback onTap;
  const _AdminCard(this.title, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatelessWidget {
  final String? base64Str; final String label;
  const _ZoomableImage(this.base64Str, this.label);
  @override
  Widget build(BuildContext context) {
    if(base64Str == null) return const Text("لا توجد صورة");
    return GestureDetector(
      onTap: () => showDialog(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: Image.memory(base64Decode(base64Str!))))),
      child: Column(children: [
        Container(height: 80, width: 80, decoration: BoxDecoration(border: Border.all(color: Colors.grey), image: DecorationImage(image: MemoryImage(base64Decode(base64Str!)), fit: BoxFit.cover))),
        Text(label, style: const TextStyle(fontSize: 10))
      ]),
    );
  }
}
