import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_screens.dart'; // للعودة عند تسجيل الخروج

// -----------------------------------------------------------------------------
// 🏠 الواجهة الرئيسية للمريض (Bottom Nav)
// -----------------------------------------------------------------------------
class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const _HomeTab(),      // 1. الرئيسية
    const _MyRequestsTab(), // 2. طلباتي
    const _SettingsTab(),   // 3. الإعدادات
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF009688),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "الرئيسية"),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: "طلباتي"),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "الإعدادات"),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1️⃣ التبويب الأول: الرئيسية (الخدمات والعروض)
// -----------------------------------------------------------------------------
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("مرحباً، ${user?.email?.split('@')[0] ?? 'زائر'}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Text("بماذا تشعر اليوم؟", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        actions: [
          // 🔔 زر الإشعارات
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.notifications_none, color: Color(0xFF009688)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📢 البانر الإعلاني (يأتي من الأدمن لاحقاً، حالياً ثابت كمثال)
            _GlassCard(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF009688), Color(0xFF4DB6AC)]),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🎉 عروض 50%", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("بمناسبة إطلاق التطبيق للشهر الأول!", style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            
            const Text("الخدمات المتاحة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // 🏥 شبكة الخدمات (تأتي من الفايربيز)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').where('active', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var services = snapshot.data!.docs;

                if (services.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("لا توجد خدمات متاحة حالياً")));
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    var service = services[index].data() as Map<String, dynamic>;
                    return _ServiceItem(
                      title: service['name'],
                      price: service['price'],
                      // منطق بسيط للأيقونات حسب الاسم
                      icon: service['name'].toString().contains("طبيب") ? Icons.local_hospital : 
                            service['name'].toString().contains("سائق") ? Icons.directions_car : Icons.medical_services,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen(serviceName: service['name'], price: service['price']))),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2️⃣ التبويب الثاني: طلباتي (التتبع المباشر)
// -----------------------------------------------------------------------------
class _MyRequestsTab extends StatelessWidget {
  const _MyRequestsTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("طلباتي"), centerTitle: true, elevation: 0, backgroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests')
            .where('user_id', isEqualTo: user!.uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 80, color: Colors.grey[300]), const Text("لا يوجد سجل طلبات")]));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String status = data['status'];
              
              // تحديد لون وحالة البطاقة
              Color statusColor = Colors.orange;
              String statusText = "جاري البحث...";
              if (status == 'accepted') { statusColor = Colors.blue; statusText = "تم القبول! يجهز نفسه"; }
              if (status == 'on_way') { statusColor = Colors.green; statusText = "الممرض في الطريق 🚑"; }
              if (status == 'completed') { statusColor = Colors.grey; statusText = "مكتملة ✅"; }
              if (status == 'rejected') { statusColor = Colors.red; statusText = "ملغاة ❌"; }

              return _GlassCard(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['service'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.teal, size: 20),
                          Text("${data['price']} دج"),
                          const Spacer(),
                          Text(data['created_at'] != null ? "منذ قليل" : "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      
                      // أزرار التحكم (للحالات النشطة فقط)
                      if (status == 'pending') ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => docs[index].reference.delete(),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("إلغاء الطلب"),
                          ),
                        )
                      ],

                      if (status == 'accepted' || status == 'on_way') ...[
                        const SizedBox(height: 15),
                        // هنا نأتي بمعلومات الممرض (في المستقبل يمكن ربطها بجدول users)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.support_agent, color: Colors.blue),
                              const SizedBox(width: 10),
                              const Expanded(child: Text("الممرض قبل طلبك!", style: TextStyle(fontWeight: FontWeight.bold))),
                              // زر الاتصال بالممرض (إذا توفر رقمه - سنضيفه لاحقاً في الـ update)
                              IconButton(
                                icon: const Icon(Icons.phone, color: Colors.green),
                                onPressed: () {
                                  // يمكننا إضافة حقل phone_provider في الطلب عند القبول
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("سيتم تفعيل الاتصال قريباً")));
                                }, 
                              )
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
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
// 3️⃣ التبويب الثالث: الإعدادات (الملف الشخصي)
// -----------------------------------------------------------------------------
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _nameController = TextEditingController();
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _fetchName();
  }

  void _fetchName() async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
    if(mounted && doc.exists) setState(() => _nameController.text = doc['full_name']);
  }

  void _updateName() async {
    if(_nameController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'full_name': _nameController.text});
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث الاسم")));
  }

  void _contactSupport() async {
    final Uri url = Uri.parse("https://wa.me/213562898252"); // رقم الدعم
    if (!await launchUrl(url)) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تعذر فتح واتساب")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الإعدادات"), centerTitle: true, elevation: 0, backgroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // صورة البروفايل (أول حرف)
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF009688),
              child: Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : "A", style: const TextStyle(fontSize: 30, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            
            // تعديل الاسم
            _GlassCard(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: TextField(controller: _nameController, decoration: const InputDecoration(border: InputBorder.none, hintText: "اسمك الكامل")),
                trailing: IconButton(icon: const Icon(Icons.save, color: Colors.teal), onPressed: _updateName),
              ),
            ),
            const SizedBox(height: 10),

            // باقي الإعدادات
            _GlassCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("الوضع المظلم"),
                    secondary: const Icon(Icons.dark_mode),
                    value: _isDark,
                    activeColor: const Color(0xFF009688),
                    onChanged: (val) => setState(() => _isDark = val),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text("اللغة"),
                    trailing: const Text("العربية", style: TextStyle(color: Colors.grey)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // زر الدعم
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _contactSupport,
                icon: const Icon(Icons.support_agent),
                label: const Text("تواصل مع الدعم (WhatsApp)"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
            const SizedBox(height: 20),
            
            // تسجيل الخروج
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              child: const Text("تسجيل الخروج", style: TextStyle(color: Colors.red)),
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 📅 شاشة الحجز الذكي (Booking Screen)
// -----------------------------------------------------------------------------
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
  String? _location;
  String? _base64Image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoFillData();
  }

  void _autoFillData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists) {
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
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _location = "${pos.latitude}, ${pos.longitude}");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى تفعيل GPS")));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _getImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 40);
    if (file != null) {
      String base64 = base64Encode(await File(file.path).readAsBytes());
      setState(() => _base64Image = base64);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📍 الموقع إجباري لتسهيل الوصول إليك"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      await FirebaseFirestore.instance.collection('requests').add({
        'user_id': user.uid,
        'patient_name': _nameController.text,
        'phone': _phoneController.text,
        'details': _detailsController.text,
        'service': widget.serviceName,
        'price': widget.price,
        'location': _location,
        'wilaya': doc['wilaya'] ?? 'غير محدد',
        'status': 'pending',
        'image_data': _base64Image,
        'created_at': FieldValue.serverTimestamp(),
      });

      if(mounted) {
        Navigator.pop(context);
        showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("تم بنجاح!"), content: const Text("طلبك قيد البحث عن أقرب ممرض."), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("حسناً"))]));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceName), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // الفاتورة الزجاجية
              _GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("إجمالي السعر:", style: TextStyle(fontSize: 18)),
                      Text("${widget.price} دج", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "اسم المريض", prefixIcon: Icon(Icons.person)), validator: (v)=>v!.isEmpty?"مطلوب":null),
              const SizedBox(height: 15),
              TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "رقم الهاتف", prefixIcon: Icon(Icons.phone)), validator: (v)=>v!.isEmpty?"مطلوب":null),
              const SizedBox(height: 15),
              TextFormField(controller: _detailsController, maxLines: 3, decoration: const InputDecoration(labelText: "ملاحظات (اختياري)", prefixIcon: Icon(Icons.note_alt_outlined))),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _getImage,
                      icon: Icon(_base64Image == null ? Icons.camera_alt : Icons.check),
                      label: Text(_base64Image == null ? "صورة (وصفة/جرح)" : "تمت الإضافة"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _getLocation,
                      icon: const Icon(Icons.location_on),
                      label: Text(_location == null ? "تحديد موقعي *" : "تم التحديد ✅"),
                      style: ElevatedButton.styleFrom(backgroundColor: _location == null ? Colors.red : Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("تأكيد الطلب"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🔔 شاشة الإشعارات (Notifications)
// -----------------------------------------------------------------------------
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الإشعارات"), backgroundColor: Colors.white, elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notifications').orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("لا توجد إشعارات"));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return _GlassCard(
                margin: const EdgeInsets.only(bottom: 15),
                child: Column(
                  children: [
                    if(data['image_url'] != null && data['image_url'].toString().isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.network(data['image_url'], height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,o,s)=>const SizedBox()),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? "إشعار", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 5),
                          Text(data['body'] ?? "", style: const TextStyle(color: Colors.grey)),
                          if(data['link'] != null && data['link'].toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            TextButton(onPressed: () => launchUrl(Uri.parse(data['link'])), child: const Text("اضغط هنا للتفاصيل"))
                          ]
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
}

// -----------------------------------------------------------------------------
// 🎨 أدوات التصميم (Glass UI Components)
// -----------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const _GlassCard({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 2)],
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final String title;
  final int price;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceItem({required this.title, required this.price, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: const Color(0xFF009688)),
            ),
            const SizedBox(height: 15),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text("$price دج", style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
