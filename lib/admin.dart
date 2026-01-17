import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("غرفة القيادة 👮‍♂️"),
        backgroundColor: Colors.blueGrey.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("أدوات التحكم", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // شبكة الأزرار
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _adminBtn(context, "💰 الأسعار", Icons.price_change, Colors.teal, const AdminPriceSettings()),
                _adminBtn(context, "🚑 الطلبات", Icons.monitor_heart, Colors.indigo, const AdminRequestsMonitor()),
                _adminBtn(context, "✅ تفعيل الممرضين", Icons.verified_user, Colors.orange, const AdminProviderApproval()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminBtn(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// 💰 1. شاشة إدارة الأسعار
class AdminPriceSettings extends StatefulWidget {
  const AdminPriceSettings({super.key});

  @override
  State<AdminPriceSettings> createState() => _AdminPriceSettingsState();
}

class _AdminPriceSettingsState extends State<AdminPriceSettings> {
  // الأسعار الافتراضية
  Map<String, dynamic> prices = {
    'nurse_injection': 500, 'nurse_serum': 1500, 'nurse_change': 800,
    'doctor_visit': 3000, 'ambulance_local': 2000, 'ambulance_out': 10000,
  };

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    final doc = await FirebaseFirestore.instance.collection('app_settings').doc('prices').get();
    if (doc.exists) setState(() => prices.addAll(doc.data()!));
  }

  Future<void> _updatePrice(String key, int newPrice) async {
    setState(() => prices[key] = newPrice);
    await FirebaseFirestore.instance.collection('app_settings').doc('prices').set(prices, SetOptions(merge: true));
  }

  void _edit(String title, String key) {
    TextEditingController ctrl = TextEditingController(text: prices[key].toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تعديل: $title"),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number),
        actions: [
          ElevatedButton(
            onPressed: () {
              _updatePrice(key, int.parse(ctrl.text));
              Navigator.pop(ctx);
            },
            child: const Text("حفظ"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إدارة الأسعار")),
      body: ListView(
        children: prices.keys.map((key) {
          return ListTile(
            title: Text(key),
            trailing: Text("${prices[key]} دج", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            onTap: () => _edit(key, key),
          );
        }).toList(),
      ),
    );
  }
}

// 🚑 2. شاشة مراقبة الطلبات
class AdminRequestsMonitor extends StatelessWidget {
  const AdminRequestsMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مراقبة الطلبات")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests').orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, i) {
              var data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['service'] ?? ''),
                  subtitle: Text(data['status']),
                  trailing: Text("${data['price']} دج"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ✅ 3. شاشة الموافقة على الممرضين (هام جداً)
class AdminProviderApproval extends StatelessWidget {
  const AdminProviderApproval({super.key});

  Future<void> _approve(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'verification_status': 'approved'});
  }

  Future<void> _reject(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'verification_status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("طلبات الانضمام")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'provider')
            .where('verification_status', isEqualTo: 'pending') // فقط المعلقين
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات جديدة"));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, i) {
              var user = snapshot.data!.docs[i];
              var data = user.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person, size: 40),
                      title: Text(data['name'] ?? 'بدون اسم'),
                      subtitle: Text("CCP: ${data['ccp_number']}\nTel: ${data['phone']}"),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => _reject(user.id), child: const Text("رفض", style: TextStyle(color: Colors.red))),
                        ElevatedButton(onPressed: () => _approve(user.id), child: const Text("قبول وتفعيل")),
                        const SizedBox(width: 10),
                      ],
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
