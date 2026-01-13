import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:intl/intl.dart' as intl;

// إعدادات فايربيس
const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDlQHl2B8d_8nw8-N6_51MEH4j_KYqz7NA",
  authDomain: "afya-dz.firebaseapp.com",
  projectId: "afya-dz",
  storageBucket: "afya-dz.firebasestorage.app",
  messagingSenderId: "311376524644",
  appId: "1:311376524644:web:a3d9c77a53c0570a0eb671",
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    print("Error: $e");
  }
  runApp(const AfyaApp());
}

class AfyaApp extends StatelessWidget {
  const AfyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Afya DZ',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // خلفية رمادية فاتحة جداً
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688),
          primary: const Color(0xFF009688),
          secondary: const Color(0xFF2196F3),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// 1. شاشة البداية
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (FirebaseAuth.instance.currentUser != null) {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      } else {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF009688), Color(0xFF80CBC4)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.local_hospital_rounded, size: 120, color: Colors.white),
          SizedBox(height: 30),
          Text("Afya DZ", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text("رعايتك الصحية.. في بيتك", style: TextStyle(color: Colors.white70, fontSize: 18)),
        ])),
      ),
    );
  }
}

// 2. شاشة الدخول والتسجيل
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    } catch (e) {
      _showError("خطأ في الدخول: تأكد من البيانات");
    }
    setState(() => _loading = false);
  }

  Future<void> _doRegister() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameInputScreen()));
    } catch (e) {
      _showError("خطأ في التسجيل: ${e.toString()}");
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_person_outlined, size: 80, color: Color(0xFF009688)),
              const SizedBox(height: 20),
              const Text("مرحباً بك", textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
              const SizedBox(height: 40),
              TextField(controller: _email, decoration: InputDecoration(labelText: "البريد الإلكتروني", prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 20),
              TextField(controller: _pass, obscureText: true, decoration: InputDecoration(labelText: "كلمة المرور", prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 30),
              _loading ? const Center(child: CircularProgressIndicator()) : Column(
                children: [
                  ElevatedButton(onPressed: _doLogin, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: const Color(0xFF009688)), child: const Text("تسجيل الدخول", style: TextStyle(color: Colors.white, fontSize: 18))),
                  const SizedBox(height: 15),
                  TextButton(onPressed: _doRegister, child: const Text("إنشاء حساب جديد", style: TextStyle(fontSize: 16))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});
  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}
class _NameInputScreenState extends State<NameInputScreen> {
  final _nameController = TextEditingController();
  Future<void> _saveName() async {
    if (_nameController.text.isEmpty) return;
    await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text);
    if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بياناتك")),
      body: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("تشرفنا! ما هو اسمك؟", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        TextField(controller: _nameController, decoration: InputDecoration(labelText: "الاسم الكامل", prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 30),
        ElevatedButton(onPressed: _saveName, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: const Color(0xFF009688)), child: const Text("بدء الاستخدام", style: TextStyle(color: Colors.white, fontSize: 18))),
      ])),
    );
  }
}

// 3. الشاشة الرئيسية (التعديل المطلوب: الاسم في الوسط + أزرار فخمة)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () async { await FirebaseAuth.instance.signOut(); if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); })],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الترحيب في الوسط كما طلبت
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20)]),
              child: Column(
                children: [
                  const CircleAvatar(radius: 35, backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.person, size: 40, color: Color(0xFF009688))),
                  const SizedBox(height: 15),
                  const Text("أهلاً بك يا بطل", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Text(user?.displayName ?? "المستخدم", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // الأزرار الفخمة (3D Style)
            _buildBigButton(context, "أنا مريض", "أبحث عن ممرض", Icons.medical_services_outlined, const Color(0xFF2196F3), const PatientHomeScreen()),
            const SizedBox(height: 20),
            _buildBigButton(context, "أنا ممرض", "لوحة التحكم", Icons.assignment_ind_outlined, const Color(0xFF009688), const NurseDashboard()),
          ],
        ),
      ),
    );
  }

  Widget _buildBigButton(BuildContext context, String title, String sub, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(width: 8, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)))),
            const SizedBox(width: 25),
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ]),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300]),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}

// 4. لوحة المريض (تصميم الشبكة المحسن)
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text("خدماتي"), bottom: const TabBar(labelColor: Color(0xFF009688), indicatorColor: Color(0xFF009688), tabs: [Tab(text: "طلب جديد"), Tab(text: "طلباتي")])),
        body: const TabBarView(children: [PatientNewOrder(), PatientMyOrders()]),
      ),
    );
  }
}

class PatientNewOrder extends StatelessWidget {
  const PatientNewOrder({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, padding: const EdgeInsets.all(20), crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.9,
      children: [
        _item(context, "حقن", "800 دج", Icons.vaccines, Colors.orange),
        _item(context, "سيروم", "2500 دج", Icons.water_drop, Colors.blue),
        _item(context, "ضماد", "1200 دج", Icons.healing, Colors.purple),
        _item(context, "ضغط", "500 دج", Icons.monitor_heart, Colors.red),
        InkWell(
          onTap: () => _customOrder(context),
          child: Container(
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300, width: 2)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, size: 50, color: Colors.grey[600]), const SizedBox(height: 10), Text("طلب خاص", style: TextStyle(fontSize: 18, color: Colors.grey[800], fontWeight: FontWeight.bold))]),
          ),
        ),
      ],
    );
  }
  void _customOrder(BuildContext context) {
    final c = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("طلب خاص"), content: TextField(controller: c, decoration: const InputDecoration(hintText: "ماذا تحتاج؟")),
      actions: [ElevatedButton(onPressed: () {Navigator.pop(context); if(c.text.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: c.text, price: "حسب الاتفاق")));}, child: const Text("متابعة"))],
    ));
  }
  Widget _item(BuildContext context, String t, String p, IconData i, Color c) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: t, price: p))),
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(i, size: 35, color: c)), const SizedBox(height: 15), Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 5), Text(p, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
    ),
  );
}

class PatientMyOrders extends StatelessWidget {
  const PatientMyOrders({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('patient_id', isEqualTo: uid).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات سابقة", style: TextStyle(fontSize: 18, color: Colors.grey)));
        return ListView(
          padding: const EdgeInsets.all(15),
          children: snap.data!.docs.map((d) {
            var data = d.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';
            Color color = status == 'pending' ? Colors.orange : (status == 'accepted' ? Colors.blue : Colors.green);
            String txt = status == 'pending' ? "جاري البحث..." : (status == 'accepted' ? "تم القبول" : "منتهية");
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(Icons.history, color: color)),
                title: Text(data['service'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("السعر: ${data['price']}"),
                trailing: Chip(label: Text(txt, style: const TextStyle(color: Colors.white)), backgroundColor: color),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// 5. شاشة تأكيد الطلب (تصميم احترافي للموقع)
class OrderScreen extends StatefulWidget {
  final String title; final String price;
  const OrderScreen({super.key, required this.title, required this.price});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  final _phone = TextEditingController();
  double? _lat, _lng;
  bool _gettingLoc = false;
  bool _locSuccess = false;

  Future<void> _loc() async {
    setState(() => _gettingLoc = true);
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      Position pos = await Geolocator.getCurrentPosition();
      setState(() { _lat = pos.latitude; _lng = pos.longitude; _gettingLoc = false; _locSuccess = true; });
    } catch (e) { setState(() => _gettingLoc = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
              child: Column(children: [
                const Icon(Icons.receipt_long, size: 50, color: Color(0xFF009688)),
                const SizedBox(height: 10),
                Text("تأكيد طلب ${widget.title}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(widget.price, style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 30),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "رقم هاتفك للتواصل", prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            // زر الموقع الاحترافي
            InkWell(
              onTap: _loc,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _locSuccess ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _locSuccess ? Colors.green : Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: _locSuccess ? Colors.green : Colors.blue, shape: BoxShape.circle),
                      child: _gettingLoc ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.location_on, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Expanded(child: Text(_locSuccess ? "تم تحديد موقع المنزل بنجاح" : "اضغط هنا لتحديد موقعك", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _locSuccess ? Colors.green[800] : Colors.blue[800]))),
                    if (_locSuccess) const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if(_lat != null && _phone.text.isNotEmpty) {
                   FirebaseFirestore.instance.collection('requests').add({
                     'service': widget.title, 'price': widget.price, 'phone': _phone.text, 
                     'lat': _lat, 'lng': _lng, 'status': 'pending', 'timestamp': FieldValue.serverTimestamp(),
                     'patient_id': FirebaseAuth.instance.currentUser?.uid
                   });
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الإرسال بنجاح!"), backgroundColor: Colors.green));
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إكمال البيانات"), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: const Color(0xFF009688)),
              child: const Text("إرسال الطلب الآن", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// 6. لوحة الممرض (تصميم البطاقات الواضحة لمنع التداخل)
class NurseDashboard extends StatelessWidget {
  const NurseDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text("لوحة التحكم"), bottom: const TabBar(labelColor: Color(0xFF009688), indicatorColor: Color(0xFF009688), tabs: [Tab(text: "طلبات جديدة"), Tab(text: "مهامي")])),
        body: const TabBarView(children: [NurseMarket(), NurseMyTasks()]),
      ),
    );
  }
}

class NurseMarket extends StatelessWidget {
  const NurseMarket({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline, size: 80, color: Colors.grey), SizedBox(height: 10), Text("لا توجد طلبات جديدة")]));
        
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, index) {
            var d = snap.data!.docs[index];
            var data = d.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.person, color: Color(0xFF009688))),
                      const SizedBox(width: 15),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(data['service'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(data['price'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ]),
                    ]),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)), child: const Text("جديد", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => d.reference.update({'status': 'accepted', 'nurse_id': FirebaseAuth.instance.currentUser?.uid}),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("قبول المهمة", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

class NurseMyTasks extends StatelessWidget {
  const NurseMyTasks({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('nurse_id', isEqualTo: uid).where('status', isEqualTo: 'accepted').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) return const Center(child: Text("ليس لديك مهام جارية"));
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, index) {
            var d = snap.data!.docs[index];
            var data = d.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withOpacity(0.2)), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 15)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(data['service'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text(data['price'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 5), Text(data['phone'], style: const TextStyle(fontSize: 16))]),
                  const Divider(height: 30),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse("tel:${data['phone']}")), icon: const Icon(Icons.call, size: 18), label: const Text("اتصال"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${data['lat']},${data['lng']}")), icon: const Icon(Icons.location_on, size: 18), label: const Text("الموقع"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(child: TextButton.icon(onPressed: () => d.reference.update({'status': 'completed'}), icon: const Icon(Icons.check_circle_outline, color: Colors.grey), label: const Text("اضغط عند الانتهاء", style: TextStyle(color: Colors.grey))))
                ],
              ),
            );
          },
        );
      },
    );
  }
}
