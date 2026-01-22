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

// -------------------------------------------------------------------------
// 1️⃣ قسم إدارة الطاقم (تم إصلاح مشكلة التحميل)
// -------------------------------------------------------------------------
class _StaffManagementTab extends StatelessWidget {
  const _StaffManagementTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // 🔧 التعديل هنا: حذفنا orderBy لتظهر القائمة فوراً
      stream: FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'provider')
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
            if (status == 'pending_docs') cardColor = Colors.grey.shade100;
            if (status == 'under_review') cardColor = Colors.orange.shade50;
            if (status == 'active') cardColor = Colors.green.shade50;

            return Card(
              color: cardColor,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: status == 'active' ? Colors.green : Colors.grey,
                  child: Icon(
                    status == 'active' ? Icons.check : Icons.person, 
                    color: Colors.white
                  ),
                ),
                title: Text("${data['full_name']} (${data['specialty'] ?? 'غير محدد'})"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("الولاية: ${data['wilaya'] ?? 'غير محدد'}"),
                    Text(
                      "الحالة: ${_translateStatus(status)}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
                trailing: _buildActionButtons(context, uid, status, data),
              ),
            );
          },
        );
      },
    );
  }

  String _translateStatus(String status) {
    if (status == 'pending_docs') return "لم يرفع الوثائق";
    if (status == 'under_review') return "جاري المراجعة";
    if (status == 'payment_review') return "بانتظار تأكيد الدفع";
    if (status == 'active') return "نشط ✅";
    return status;
  }

  Widget? _buildActionButtons(BuildContext context, String uid, String status, Map<String, dynamic> data) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ⚡ زر التفعيل الفوري (يظهر دائماً إذا لم يكن نشطاً)
        if (status != 'active')
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.orange),
            tooltip: "تفعيل فوري",
            onPressed: () => _forceActivate(context, uid),
          ),
          
        // زر المراجعة (يظهر فقط إذا رفع وثائق)
        if (status == 'under_review')
          IconButton(
            icon: const Icon(Icons.assignment_turned_in, color: Colors.blue),
            onPressed: () => _showDocsDialog(context, uid, data),
          ),

        // زر الحذف
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            FirebaseFirestore.instance.collection('users').doc(uid).delete();
          },
        ),
      ],
    );
  }

  void _forceActivate(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تفعيل فوري ⚡"),
        content: const Text("هل تريد تفعيل هذا الممرض فوراً؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
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

  void _showDocsDialog(BuildContext context, String uid, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("مراجعة الوثائق"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("الوثائق المرفقة:"),
              _decodeImage(data['id_card_image']),
              _decodeImage(data['diploma_image']),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(uid).update({'status': 'pending_payment'});
              Navigator.pop(ctx);
            },
            child: const Text("قبول وتحويل للدفع"),
          ),
        ],
      ),
    );
  }

  Widget _decodeImage(String? base64String) {
    if (base64String == null) return Container(height: 50, width:50, color: Colors.grey[200], child: const Icon(Icons.broken_image));
    try {
      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: Image.memory(base64Decode(base64String), height: 100),
      );
    } catch (e) {
      return const SizedBox();
    }
  }
}

// -------------------------------------------------------------------------
// 2️⃣ قسم الطلبات (مع التفاصيل الكاملة)
// -------------------------------------------------------------------------
class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // هنا أيضاً يفضل حذف الترتيب مؤقتاً إذا لم يظهر شيء، لكن سنتركه لأنه غالباً يعمل
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
            String detailsText = (data['details'] == null || data['details'].toString().isEmpty) 
                ? "لا توجد تفاصيل إضافية." 
                : data['details'];

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  child: const Icon(Icons.medical_services, color: Colors.teal),
                ),
                title: Text(
                  data['service'] ?? "خدمة",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("المريض: ${data['patient_name']}"),
                    Text(
                      "الحالة: ${data['status']}",
                      style: TextStyle(
                        color: data['status'] == 'pending' ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    width: double.infinity,
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.phone, color: Colors.blue),
                          title: Text(data['phone'] ?? "لا يوجد رقم"),
                          contentPadding: EdgeInsets.zero,
                        ),
                        ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.red),
                          title: Text(data['wilaya'] ?? "الولاية غير محددة"),
                          subtitle: Text(data['location'] ?? "الموقع غير محدد"),
                          contentPadding: EdgeInsets.zero,
                        ),

                        const SizedBox(height: 10),
                        const Text("📝 تفاصيل الحالة:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(detailsText, style: const TextStyle(color: Colors.grey)),
                        
                        if (data['image_data'] != null) ...[
                          const SizedBox(height: 15),
                          const Text("📷 المرفقات:", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              base64Decode(data['image_data']),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => const Text("تعذر عرض الصورة"),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  FirebaseFirestore.instance.collection('requests').doc(docs[index].id).update({'status': 'accepted'});
                                },
                                icon: const Icon(Icons.check),
                                label: const Text("قبول"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  FirebaseFirestore.instance.collection('requests').doc(docs[index].id).update({'status': 'rejected'});
                                },
                                icon: const Icon(Icons.close),
                                label: const Text("رفض"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              ),
                            ),
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
    );
  }
}

// -------------------------------------------------------------------------
// 3️⃣ قسم الخدمات
// -------------------------------------------------------------------------
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
 
