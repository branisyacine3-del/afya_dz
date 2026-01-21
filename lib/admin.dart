import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart'; // ✅ صحيح

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("غرفة التحكم 👮‍♂️"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.teal,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt), text: "إدارة الطاقم"),
            Tab(icon: Icon(Icons.list_alt), text: "الطلبات الحية"),
            Tab(icon: Icon(Icons.settings), text: "الخدمات والأسعار"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StaffManagementTab(),
          _RequestsTab(),
          _ServicesTab(),
        ],
      ),
    );
  }
}

// (أبقي باقي الكود الخاص بـ Admin كما هو، فقط غير الاستيراد في الأعلى)
// ... انسخ الكود السابق لـ _StaffManagementTab و _RequestsTab و _ServicesTab هنا ...
// سأعيد كتابة الأجزاء السفلية لضمان النسخ الكامل:

class _StaffManagementTab extends StatelessWidget {
  const _StaffManagementTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'provider')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text("لا يوجد موظفين مسجلين"));

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';
            String uid = docs[index].id;

            Color cardColor = Colors.white;
            if (status == 'under_review') cardColor = Colors.orange.shade50;
            if (status == 'payment_review') cardColor = Colors.blue.shade50;
            if (status == 'active') cardColor = Colors.green.shade50;

            return Card(
              color: cardColor,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text(data['full_name'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                title: Text("${data['full_name']} (${data['specialty'] ?? 'غير محدد'})"),
                subtitle: Text("الولاية: ${data['wilaya']}\nالحالة: ${_translateStatus(status)}"),
                isThreeLine: true,
                trailing: _buildActionButtons(context, uid, status, data),
              ),
            );
          },
        );
      },
    );
  }

  String _translateStatus(String status) {
    if (status == 'pending_docs') return "بانتظار رفع الوثائق";
    if (status == 'under_review') return "⚠️ بانتظار مراجعة الوثائق";
    if (status == 'pending_payment') return "بانتظار الدفع";
    if (status == 'payment_review') return "💸 بانتظار تأكيد الدفع";
    if (status == 'active') return "✅ نشط";
    return status;
  }

  Widget? _buildActionButtons(BuildContext context, String uid, String status, Map<String, dynamic> data) {
    if (status == 'under_review') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        onPressed: () => _showDocsDialog(context, uid, data),
        child: const Text("فحص الوثائق", style: TextStyle(color: Colors.white)),
      );
    }
    if (status == 'payment_review') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        onPressed: () => _showPaymentDialog(context, uid),
        child: const Text("تأكيد الدفع", style: TextStyle(color: Colors.white)),
      );
    }
    return const Icon(Icons.more_vert);
  }

  void _showDocsDialog(BuildContext context, String uid, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("مراجعة الوثائق"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("هنا ستظهر صور الوثائق (البطاقة، الشهادة...)"),
            const SizedBox(height: 10),
            Container(height: 100, color: Colors.grey[300], child: const Center(child: Text("صورة البطاقة"))),
            const SizedBox(height: 5),
            Container(height: 100, color: Colors.grey[300], child: const Center(child: Text("صورة الشهادة"))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(uid).update({'status': 'rejected'});
              Navigator.pop(ctx);
            },
            child: const Text("رفض", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(uid).update({'status': 'pending_payment'});
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("قبول (تحويل للدفع)"),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("مراجعة وصل الدفع"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 150, color: Colors.blue[100], child: const Center(child: Text("صورة الوصل"))),
            const SizedBox(height: 10),
            const Text("هل وصل المبلغ (3500 دج) إلى حسابك؟"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              DateTime expiryDate = DateTime.now().add(const Duration(days: 30));
              FirebaseFirestore.instance.collection('users').doc(uid).update({
                'status': 'active',
                'subscription_expiry': Timestamp.fromDate(expiryDate),
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("نعم، تفعيل الاشتراك"),
          ),
        ],
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text("لا توجد طلبات حالياً"));

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.teal),
                title: Text(data['service'] ?? "خدمة"),
                subtitle: Text("${data['patient_name']} \n📍 ${data['location']}"),
                trailing: Text(data['status'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
            );
          },
        );
      },
    );
  }
}

class _ServicesTab extends StatefulWidget {
  const _ServicesTab();

  @override
  State<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<_ServicesTab> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void _addService() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;
    
    FirebaseFirestore.instance.collection('services').add({
      'name': _nameController.text,
      'price': int.tryParse(_priceController.text) ?? 0,
      'active': true,
    });
    
    _nameController.clear();
    _priceController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تمت إضافة الخدمة")));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _nameController, decoration: const InputDecoration(labelText: "اسم الخدمة (مثلاً: حقنة)"))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "السعر (دج)"))),
              IconButton(icon: const Icon(Icons.add_circle, color: Colors.teal, size: 40), onPressed: _addService),
            ],
          ),
        ),
        const Divider(thickness: 2),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('services').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index];
                  return ListTile(
                    title: Text(data['name']),
                    trailing: Text("${data['price']} دج", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    leading: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => data.reference.delete(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
 
