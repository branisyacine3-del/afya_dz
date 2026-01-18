import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // مكتبة الاتصال ضرورية هنا

// 🏠 الشاشة الرئيسية للمريض
class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  // ✅ دالة الاتصال بالدعم (كما طلبتها)
  void _callSupport() async {
    final Uri url = Uri.parse('tel:0562898252'); // رقم الدعم المباشر
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("عافية - خدمات طبية"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientHistory())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // ✅ زر عائم للاتصال بالدعم في أي وقت
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _callSupport,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.phone),
        label: const Text("اتصل بالدعم"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // بنر ترحيبي
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      "مرحباً بك ❤️\nاختر الخدمة التي تحتاجها وسنصلك فوراً.",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Icon(Icons.favorite, color: Colors.white, size: 40),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // شبكة الخدمات
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _srvBtn(context, "تمريض منزلي", Icons.medical_services, Colors.teal, 'nurse'),
                  _srvBtn(context, "طبيب عام", Icons.person, Colors.blue, 'doctor'),
                  // ✅ تم تصحيح الأيقونة لتجنب الخطأ السابق
                  _srvBtn(context, "سيارة إسعاف", Icons.local_shipping, Colors.red, 'ambulance'),
                  _srvBtn(context, "رعاية مسنين", Icons.elderly, Colors.orange, 'elderly'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _srvBtn(BuildContext context, String title, IconData icon, Color color, String type) {
    return InkWell(
      onTap: () => _showServicesSheet(context, type, title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // قائمة الأسعار المنبثقة
  void _showServicesSheet(BuildContext context, String type, String title) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ServiceSelectionSheet(type: type, title: title),
    );
  }
}

// 📄 قائمة اختيار الخدمة الفرعية والأسعار
class ServiceSelectionSheet extends StatelessWidget {
  final String type;
  final String title;
  const ServiceSelectionSheet({super.key, required this.type, required this.title});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('app_settings').doc('prices').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // جلب الأسعار من الأدمن (مع حماية ضد القيم الفارغة)
        Map<String, dynamic> prices = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        
        List<Map<String, dynamic>> list = [];
        if (type == 'nurse') {
          list = [
            {'name': 'حقن (Injection)', 'price': prices['nurse_injection'] ?? 500},
            {'name': 'سيروم (Sérum)', 'price': prices['nurse_serum'] ?? 1500},
            {'name': 'تغيير ضمادات', 'price': prices['nurse_change'] ?? 800},
          ];
        } else if (type == 'doctor') {
          list = [{'name': 'زيارة منزلية', 'price': prices['doctor_visit'] ?? 3000}];
        } else if (type == 'ambulance') {
          list = [
            {'name': 'نقل داخل الولاية', 'price': prices['ambulance_local'] ?? 2000},
            {'name': 'نقل خارج الولاية', 'price': prices['ambulance_out'] ?? 10000},
          ];
        } else if (type == 'elderly') {
           list = [{'name': 'رعاية يومية', 'price': prices['elderly_care'] ?? 2500}];
        }

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => Card(
                    child: ListTile(
                      title: Text(list[i]['name']),
                      trailing: Text("${list[i]['price']} دج", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => OrderForm(service: list[i]['name'], price: list[i]['price'])));
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 📝 شاشة تأكيد الطلب
class OrderForm extends StatefulWidget {
  final String service;
  final int price;
  const OrderForm({super.key, required this.service, required this.price});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _addressCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى كتابة العنوان")));
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'patientId': user!.uid,
        'patientPhone': user.phoneNumber,
        'service': widget.service,
        'price': widget.price,
        'address': _addressCtrl.text,
        'status': 'pending', // حالة الانتظار
        'created_at': FieldValue.serverTimestamp(),
        'location': const GeoPoint(36.7, 3.0), // موقع افتراضي (يمكن تطويره لاحقاً)
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال الطلب بنجاح! 🚑")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد الحجز")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("الخدمة: ${widget.service}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("السعر: ${widget.price} دج", style: const TextStyle(fontSize: 24, color: Colors.teal, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: "العنوان بالتفصيل (الحي، رقم المنزل..)", prefixIcon: Icon(Icons.location_on)),
              maxLines: 2,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("تأكيد وإرسال الطلب ✅"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 📜 سجل الطلبات
class PatientHistory extends StatelessWidget {
  const PatientHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text("طلباتي السابقة")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests').where('patientId', isEqualTo: uid).orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات سابقة"));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, i) {
              var data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
              String status = data['status'];
              // تلوين الحالة
              Color color = status == 'pending' ? Colors.orange : (status == 'accepted' ? Colors.blue : Colors.green);
              String statusText = status == 'pending' ? 'قيد الانتظار' : (status == 'accepted' ? 'تم القبول (الممرض قادم)' : 'مكتملة');

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: color, child: const Icon(Icons.history, color: Colors.white)),
                  title: Text(data['service']),
                  subtitle: Text("${data['price']} دج • $statusText"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
