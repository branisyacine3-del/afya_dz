import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'login_screen.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("عافية - خدمات طبية"),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('user_id', isEqualTo: user!.uid)
            .where('status', whereIn: ['pending', 'accepted', 'on_way'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (snapshot.data!.docs.isNotEmpty) {
            var request = snapshot.data!.docs.first;
            return _buildTrackingScreen(request);
          }

          return _buildServicesList(context, user);
        },
      ),
    );
  }

  Widget _buildTrackingScreen(DocumentSnapshot request) {
    var data = request.data() as Map<String, dynamic>;
    String status = data['status'];

    String statusText = "جاري البحث عن ممرض...";
    IconData statusIcon = Icons.radar;
    Color statusColor = Colors.orange;

    if (status == 'accepted') {
      statusText = "تم قبول طلبك! الممرض يجهز نفسه.";
      statusIcon = Icons.check_circle;
      statusColor = Colors.blue;
    } else if (status == 'on_way') {
      statusText = "الممرض في الطريق إليك 🚑";
      statusIcon = Icons.directions_car;
      statusColor = Colors.green;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.circle, size: 200, color: statusColor.withOpacity(0.1)),
                Icon(Icons.circle, size: 150, color: statusColor.withOpacity(0.2)),
                Icon(statusIcon, size: 80, color: statusColor),
              ],
            ),
            const SizedBox(height: 30),
            Text(statusText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("الخدمة: ${data['service']} (${data['price']} دج)", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            
            if (status == 'pending')
              OutlinedButton.icon(
                onPressed: () {
                  request.reference.delete();
                },
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text("إلغاء الطلب", style: TextStyle(color: Colors.red)),
              ),
              
            if (status != 'pending')
               const Text("لا يمكن الإلغاء، الممرض قادم.", style: TextStyle(color: Colors.grey))
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList(BuildContext context, User user) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.teal.shade50,
          child: Column(
            children: [
              Text("مرحباً بك يا ${user.email!.split('@')[0]}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              const Text("اختر الخدمة التي تحتاجها الآن", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('services').where('active', isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var services = snapshot.data!.docs;

              if (services.isEmpty) {
                return const Center(child: Text("لا توجد خدمات متاحة حالياً\n(اطلب من المدير إضافة خدمات)", textAlign: TextAlign.center));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  var service = services[index].data() as Map<String, dynamic>;
                  return _ServiceCard(
                    title: service['name'],
                    price: service['price'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BookingScreen(
                          serviceName: service['name'],
                          price: service['price'],
                        )),
                      );
                    },
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

class _ServiceCard extends StatelessWidget {
  final String title;
  final int price;
  final VoidCallback onTap;

  const _ServiceCard({required this.title, required this.price, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.medical_services, size: 30, color: Colors.teal),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("$price دج", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class BookingScreen extends StatefulWidget {
  final String serviceName;
  final int price;

  const BookingScreen({super.key, required this.serviceName, required this.price});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _detailsController = TextEditingController();
  
  bool _isLoading = false;
  String? _location; // "36.75, 3.05"
  String? _base64Image;

  // 1️⃣ هذه الدالة تسحب البيانات تلقائياً عند فتح الشاشة
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _nameController.text = doc['full_name'] ?? "";
          _phoneController.text = doc['phone'] ?? "";
        });
      }
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _location = "${position.latitude}, ${position.longitude}");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تعذر تحديد الموقع، يرجى تفعيل GPS")));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndConvertImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    
    if (image != null) {
      File file = File(image.path);
      List<int> imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);
      
      setState(() {
        _base64Image = base64String;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 2️⃣ شرط الموقع الإجباري
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("📍 الموقع مطلوب! يرجى الضغط على زر تحديد الموقع."),
        backgroundColor: Colors.red,
      ));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String wilaya = userDoc.exists ? (userDoc['wilaya'] ?? "غير محدد") : "غير محدد";

      await FirebaseFirestore.instance.collection('requests').add({
        'user_id': user.uid,
        'patient_name': _nameController.text,
        'phone': _phoneController.text,
        'details': _detailsController.text,
        'service': widget.serviceName,
        'price': widget.price,
        'location': _location, // لن يكون null أبداً بسبب الشرط
        'wilaya': wilaya,
        'status': 'pending',
        'image_data': _base64Image,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال الطلب!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("حجز ${widget.serviceName}"), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("السعر التقديري: ${widget.price} دج", style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nameController, // مملوء تلقائياً
                decoration: const InputDecoration(labelText: "اسم المريض", border: OutlineInputBorder()), 
                validator: (v) => v!.isEmpty ? "مطلوب" : null
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _phoneController, // مملوء تلقائياً
                keyboardType: TextInputType.phone, 
                decoration: const InputDecoration(labelText: "رقم الهاتف", border: OutlineInputBorder()), 
                validator: (v) => v!.isEmpty ? "مطلوب" : null
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _detailsController, 
                maxLines: 3, 
                decoration: const InputDecoration(labelText: "تفاصيل الحالة", border: OutlineInputBorder())
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickAndConvertImage,
                      icon: Icon(_base64Image != null ? Icons.check : Icons.camera_alt),
                      label: Text(_base64Image != null ? "تم التصوير" : "صورة (اختياري)"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _getLocation,
                      icon: const Icon(Icons.location_on),
                      // تغيير اللون والنص حسب الحالة
                      label: Text(_location == null ? "تحديد الموقع *" : "تم التحديد ✅"),
                      style: ElevatedButton.styleFrom(backgroundColor: _location == null ? Colors.red : Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("تأكيد وحجز", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
