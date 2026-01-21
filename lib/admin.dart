import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

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
        onPressed: () => _showPaymentDialog(context, uid, data),
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("بطاقة التعريف:"),
              _decodeImage(data['id_card_image']),
              const SizedBox(height: 10),
              const Text("الدبلوم:"),
              _decodeImage(data['diploma_image']),
            ],
          ),
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
            child: const Text("قبول"),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, String uid, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("مراجعة وصل الدفع"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("وصل الدفع:"),
            _decodeImage(data['receipt_image']),
            const SizedBox(height: 10),
            const Text("هل وصل المبلغ (3500 دج)؟"),
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
            child: const Text("تفعيل"),
          ),
        ],
      ),
    );
  }

  Widget _decodeImage(String? base64String) {
    if (base64String == null) return Container(height: 100, color: Colors.grey, child: const Center(child: Text("لا توجد صورة")));
    try {
      return Image.memory(base64Decode(base64String), height: 150, fit: BoxFit.cover);
    } catch (e) {
      return const Text("خطأ في عرض الصورة");
    }
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
              child: ExpansionTile(
                leading: const Icon(Icons.medical_services, color: Colors.teal),
                title: Text(data['service'] ?? "خدمة"),
                subtitle: Text("${data['patient_name']} - ${data['status']}"),
                children: [
                   if (data['image_data'] != null)
                     Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: Image.memory(base64Decode(data['image_data']), height: 200),
                     ),
                   Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Text("تفاصيل: ${data['details'] ?? 'لا يوجد'}"),
                   )
                ],
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
              Expanded(child: TextField(controller: _nameController, decoration: const InputDecoration(labelText: "اسم الخدمة"))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "السعر"))),
              IconButton(icon: const Icon(Icons.add_circle, color: Colors.teal), onPressed: _addService),
            ],
          ),
        ),
        const Divider(),
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
                    trailing: Text("${data['price']} دج"),
                    leading: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => data.reference.delete()),
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
 
