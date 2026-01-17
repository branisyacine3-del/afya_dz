import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🛡️ البوابة الرئيسية للممرض (تفحص حالته قبل الدخول)
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
        // الحالة الافتراضية إذا لم تكن موجودة
        String status = data != null && data.containsKey('verification_status') 
            ? data['verification_status'] 
            : 'pending_registration';

        // 1. لم يسجل بياناته بعد
        if (status == 'pending_registration') return const ProviderRegistrationScreen();

        // 2. بانتظار موافقة الإدارة (أنت)
        if (status == 'pending') {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
                    const SizedBox(height: 20),
                    const Text("الحساب قيد المراجعة", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text("نحن نراجع وثائقك حالياً. سيتم تفعيل حسابك قريباً.", textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    ElevatedButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("خروج")),
                  ],
                ),
              ),
            ),
          );
        }

        // 3. تم الرفض
        if (status == 'rejected') {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 80, color: Colors.red),
                  const Text("عذراً، تم رفض الطلب."),
                  TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("خروج")),
                ],
              ),
            ),
          );
        }

        // 4. مقبول (Approved) -> يدخل للعمل
        return const ProviderWorkspace();
      },
    );
  }
}

// 📝 شاشة التسجيل ورفع الوثائق
class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends State<ProviderRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _ccpCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _ccpCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': _nameCtrl.text,
      'ccp_number': _ccpCtrl.text,
      'verification_status': 'pending', // يذهب للمراجعة
      'wallet_balance': 0.0,
      'total_earnings': 0.0,
    });
    // StreamBuilder سيعيد تحميل الصفحة تلقائياً
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("توثيق الحساب")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("أكمل بياناتك لنبدأ العمل 🚑", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "الاسم الكامل")),
            const SizedBox(height: 15),
            TextField(controller: _ccpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "رقم CCP")),
            const SizedBox(height: 30),
            // محاكاة زر رفع الصورة
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [Icon(Icons.upload_file), SizedBox(width: 10), Text("رفع صورة الدبلوم + البطاقة")]),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator() : const Text("إرسال للمراجعة 🚀"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🚑 مساحة العمل (الرادار والمهام)
class ProviderWorkspace extends StatefulWidget {
  const ProviderWorkspace({super.key});

  @override
  State<ProviderWorkspace> createState() => _ProviderWorkspaceState();
}

class _ProviderWorkspaceState extends State<ProviderWorkspace> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  int _tabIndex = 0;

  // قبول الطلب
  Future<void> _accept(String reqId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference ref = FirebaseFirestore.instance.collection('requests').doc(reqId);
        DocumentSnapshot snap = await transaction.get(ref);
        
        if (!snap.exists || snap['status'] != 'pending') throw Exception("راح عليك الطلب!");
        
        transaction.update(ref, {
          'status': 'accepted',
          'providerId': uid,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم القبول! انطلق 🚑")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("سبقك إليها ممرض آخر")));
    }
  }

  // إنهاء واحتساب العمولة
  Future<void> _complete(String reqId, int price) async {
    double commission = price * 0.20; // 20% عمولة
    double profit = price - commission;

    await FirebaseFirestore.instance.collection('requests').doc(reqId).update({'status': 'completed'});
    
    // تحديث المحفظة
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'wallet_balance': FieldValue.increment(profit),
      'total_earnings': FieldValue.increment(profit),
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("مبروك! ربحت $profit دج")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مساحة العمل"),
        backgroundColor: Colors.indigo,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const SizedBox();
              var balance = snap.data!['wallet_balance'] ?? 0;
              return Center(child: Padding(padding: const EdgeInsets.all(10), child: Text("رصيدك: $balance دج")));
            },
          ),
          IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: "الرادار"),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: "مهامي"),
        ],
      ),
      body: _tabIndex == 0 ? _buildRadar() : _buildMyTasks(),
    );
  }

  // الرادار: طلبات الانتظار
  Widget _buildRadar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("جاري البحث عن طلبات... 📡"));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (ctx, i) {
            var data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
            return Card(
              color: Colors.orange.shade50,
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text(data['service']),
                subtitle: Text("${data['address']} • ${data['price']} دج"),
                trailing: ElevatedButton(
                  onPressed: () => _accept(snapshot.data!.docs[i].id),
                  child: const Text("قبول"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // مهامي: المقبولة
  Widget _buildMyTasks() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('providerId', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("ليس لديك مهام حالياً"));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (ctx, i) {
            var data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
            return Card(
              color: Colors.green.shade50,
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text(data['service']),
                subtitle: Text(data['address']),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => _complete(snapshot.data!.docs[i].id, data['price']),
                  child: const Text("إنهاء"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
