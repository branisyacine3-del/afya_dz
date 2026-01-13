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
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688),
          primary: const Color(0xFF009688),
          secondary: const Color(0xFF1976D2),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.black87),
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
          gradient: LinearGradient(colors: [Color(0xFF009688), Color(0xFF4DB6AC)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.health_and_safety_rounded, size: 100, color: Colors.white),
          SizedBox(height: 20),
          Text("Afya DZ", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        ])),
      ),
    );
  }
}

// 2. شاشة الدخول
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
      _showError("تأكد من البيانات");
    }
    setState(() => _loading = false);
  }

  Future<void> _doRegister() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameInputScreen()));
    } catch (e) {
      _showError("خطأ: ${e.toString()}");
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
            children: [
              const Icon(Icons.person_pin, size: 80, color: Color(0xFF009688)),
              const SizedBox(height: 20),
              const Text("مرحباً بك", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
              const SizedBox(height: 40),
              TextField(controller: _email, decoration: InputDecoration(labelText: "البريد الإلكتروني", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
              const SizedBox(height: 20),
              TextField(controller: _pass, obscureText: true, decoration: InputDecoration(labelText: "كلمة المرور", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
              const SizedBox(height: 30),
              _loading ? const CircularProgressIndicator() : Column(
                children: [
                  ElevatedButton(onPressed: _doLogin, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: const Color(0xFF009688)), child: const Text("دخول", style: TextStyle(color: Colors.white))),
                  TextButton(onPressed: _doRegister, child: const Text("إنشاء حساب جديد"))
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
      appBar: AppBar(title: const Text("الاسم")),
      body: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("الاسم الكامل", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: _nameController, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _saveName, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: const Color(0xFF009688)), child: const Text("حفظ", style: TextStyle(color: Colors.white)))
      ])),
    );
  }
}

// 3. الشاشة الرئيسية
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () async { await FirebaseAuth.instance.signOut(); if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); })]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
              child: Column(children: [
                const CircleAvatar(radius: 40, backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.person, size: 50, color: Color(0xFF009688))),
                const SizedBox(height: 10),
                Text("أهلاً، ${user?.displayName ?? 'د. ياسين'}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 40),
            _btn(context, "أنا مريض", Icons.person, const Color(0xFF1976D2), const PatientHomeScreen()),
            const SizedBox(height: 20),
            _btn(context, "أنا ممرض", Icons.medical_services, const Color(0xFF009688), const NurseDashboard()),
          ],
        ),
      ),
    );
  }
  Widget _btn(BuildContext context, String t, IconData i, Color c, Widget p) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
    child: Container(
      height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.2)), boxShadow: [BoxShadow(color: c.withOpacity(0.1), blurRadius: 10)]),
      child: Row(children: [Container(width: 10, decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)))), const SizedBox(width: 20), Icon(i, size: 40, color: c), const SizedBox(width: 20), Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const Spacer(), const Icon(Icons.arrow_forward_ios, color: Colors.grey), const SizedBox(width: 20)]),
    ),
  );
}

// 4. واجهة المريض
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("خدماتي"), bottom: const TabBar(tabs: [Tab(text: "طلب جديد"), Tab(text: "طلباتي")])),
      body: const TabBarView(children: [PatientNewOrder(), PatientMyOrders()]),
    ));
  }
}

class PatientNewOrder extends StatelessWidget {
  const PatientNewOrder({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(20), crossAxisSpacing: 15, mainAxisSpacing: 15, children: [
      _item(context, "حقن", "800 دج", Icons.vaccines, Colors.orange),
      _item(context, "سيروم", "2500 دج", Icons.water_drop, Colors.blue),
      _item(context, "ضماد", "1200 دج", Icons.healing, Colors.purple),
      _item(context, "ضغط", "500 دج", Icons.monitor_heart, Colors.red),
      InkWell(onTap: () => _custom(context), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, size: 40), Text("طلب خاص")]))),
    ]);
  }
  void _custom(BuildContext context) {
    final c = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text("طلب خاص"), content: TextField(controller: c), actions: [ElevatedButton(onPressed: () {Navigator.pop(context); if(c.text.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: c.text, price: "حسب الاتفاق")));}, child: const Text("تم"))]));
  }
  Widget _item(BuildContext context, String t, String p, IconData i, Color c) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: t, price: p))),
    child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 35, color: c), const SizedBox(height: 10), Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), Text(p, style: const TextStyle(color: Colors.green))])),
  );
}

class PatientMyOrders extends StatelessWidget {
  const PatientMyOrders({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      // التعديل: أزلنا ترتيب الوقت مؤقتاً لتفادي مشكلة الاختفاء بسبب السيرفر
      stream: FirebaseFirestore.instance.collection('requests').where('patient_id', isEqualTo: uid).snapshots(),
      builder: (context, snap) {
        // الإصلاح الجذري: لا تظهر الدائرة إذا كان هناك خطأ، ولا تظهرها إذا كانت هناك بيانات بالفعل
        if (snap.hasError) return const Center(child: Text("حدث خطأ بسيط"));
        if (snap.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات سابقة"));
        
        return ListView(padding: const EdgeInsets.all(15), children: snap.data!.docs.map((d) {
          var data = d.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'pending';
          return Card(
            child: ListTile(
              leading: Icon(status == 'pending' ? Icons.access_time : Icons.check_circle, color: status == 'pending' ? Colors.orange : Colors.green),
              title: Text(data['service']),
              subtitle: Text(status == 'pending' ? "انتظار..." : "تم القبول"),
            ),
          );
        }).toList());
      },
    );
  }
}

// 5. شاشة الطلب
class OrderScreen extends StatefulWidget {
  final String title; final String price;
  const OrderScreen({super.key, required this.title, required this.price});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  final _phone = TextEditingController();
  double? _lat, _lng;
  bool _locSuccess = false;
  bool _loading = false;

  Future<void> _loc() async {
    setState(() => _loading = true);
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      Position pos = await Geolocator.getCurrentPosition();
      setState(() { _lat = pos.latitude; _lng = pos.longitude; _locSuccess = true; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "رقم الهاتف", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())),
        const SizedBox(height: 20),
        ListTile(
          onTap: _loc,
          tileColor: _locSuccess ? Colors.green[50] : Colors.blue[50],
          leading: _loading ? const CircularProgressIndicator() : Icon(Icons.location_on, color: _locSuccess ? Colors.green : Colors.blue),
          title: Text(_locSuccess ? "تم تحديد الموقع" : "اضغط لتحديد الموقع"),
        ),
        const Spacer(),
        ElevatedButton(onPressed: () {
          if(_lat != null && _phone.text.isNotEmpty) {
             FirebaseFirestore.instance.collection('requests').add({
               'service': widget.title, 'price': widget.price, 'phone': _phone.text, 
               'lat': _lat, 'lng': _lng, 'status': 'pending', 'patient_id': FirebaseAuth.instance.currentUser?.uid,
               // أضفنا هذا لضمان عدم اختفاء الطلب
               'timestamp': DateTime.now().toIso8601String() 
             });
             Navigator.pop(context);
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الإرسال"), backgroundColor: Colors.green));
          }
        }, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF009688)), child: const Text("تأكيد", style: TextStyle(color: Colors.white)))
      ])),
    );
  }
}

// 6. لوحة الممرض (إصلاح الاختفاء والوميض)
class NurseDashboard extends StatelessWidget {
  const NurseDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("لوحة التحكم"), bottom: const TabBar(tabs: [Tab(text: "طلبات جديدة"), Tab(text: "مهامي")])),
      body: const TabBarView(children: [NurseMarket(), NurseMyTasks()]),
    ));
  }
}

class NurseMarket extends StatelessWidget {
  const NurseMarket({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // استخدمنا استعلام بسيط وثابت لتفادي المشاكل
      stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snap) {
        // الحل السحري: لا تظهر الدائرة إذا كانت هناك بيانات، حتى لو كان الاتصال ينتظر
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, index) {
              var d = snap.data!.docs[index];
              var data = d.data() as Map<String, dynamic>;
              return Card(
                elevation: 3, margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(data['service'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['price'], style: const TextStyle(color: Colors.green)),
                  trailing: ElevatedButton(
                    onPressed: () => d.reference.update({'status': 'accepted', 'nurse_id': FirebaseAuth.instance.currentUser?.uid}),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
                    child: const Text("قبول", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        }
        
        // فقط إذا لم تكن هناك بيانات نهائياً ونحن ننتظر، نظهر الدائرة
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return const Center(child: Text("لا توجد طلبات جديدة"));
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
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, index) {
              var d = snap.data!.docs[index];
              var data = d.data() as Map<String, dynamic>;
              return Card(
                color: Colors.white,
                elevation: 3, margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(children: [
                    Text(data['service'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(children: [const Icon(Icons.phone, size: 16), const SizedBox(width: 5), Text(data['phone'])]),
                    const Divider(height: 20),
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse("tel:${data['phone']}")), icon: const Icon(Icons.call), label: const Text("اتصال"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${data['lat']},${data['lng']}")), icon: const Icon(Icons.location_on), label: const Text("موقع"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white))),
                    ]),
                    const SizedBox(height: 10),
                    TextButton(onPressed: () => d.reference.update({'status': 'completed'}), child: const Text("إنهاء المهمة"))
                  ]),
                ),
              );
            },
          );
        }
        
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        return const Center(child: Text("ليس لديك مهام جارية"));
      },
    );
  }
}
