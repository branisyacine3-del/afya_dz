import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
    print("خطأ في تهيئة فايربيس: $e");
  }
  runApp(const AfyaApp());
}

class AfyaApp extends StatelessWidget {
  const AfyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afya DZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.health_and_safety, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text("عافية - Afya DZ", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
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

  Future<void> _auth() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
    } catch (e) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
        setState(() => _loading = false);
        return;
      }
    }
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Color(0xFF0D47A1)),
            const SizedBox(height: 20),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 10),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة السر', border: OutlineInputBorder(), prefixIcon: Icon(Icons.key))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _auth,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), minimumSize: const Size(double.infinity, 50)),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('دخول / تسجيل', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. شاشة الاختيار
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _checkNurseAccess(BuildContext context) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("دخول الممرضين"),
        content: TextField(controller: passController, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(hintText: "كود الممرض (2024)")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              if (passController.text == "2024") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseDashboard()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الكود خاطئ!')));
              }
            },
            child: const Text("تحقق"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مرحباً بك"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () async { await FirebaseAuth.instance.signOut(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); })]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientHomeScreen())), icon: const Icon(Icons.person), label: const Text('أنا مريض'), style: ElevatedButton.styleFrom(minimumSize: const Size(200, 60))),
            const SizedBox(height: 20),
            OutlinedButton.icon(onPressed: () => _checkNurseAccess(context), icon: const Icon(Icons.medical_services), label: const Text('أنا ممرض'), style: OutlinedButton.styleFrom(minimumSize: const Size(200, 60))),
          ],
        ),
      ),
    );
  }
}

// 4. شاشة المريض
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب خدمة'), backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
      body: GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(20), crossAxisSpacing: 10, mainAxisSpacing: 10, children: [
        _card(context, 'حقن', 800, Icons.vaccines),
        _card(context, 'ضمادة', 1200, Icons.healing),
        _card(context, 'سيروم', 2500, Icons.water_drop),
        _card(context, 'ضغط/سكر', 500, Icons.monitor_heart),
      ]),
    );
  }
  Widget _card(BuildContext context, String t, int p, IconData i) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: t, price: p))),
    child: Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 40, color: Colors.blue[900]), Text(t), Text('$p دج', style: const TextStyle(color: Colors.green))])),
  );
}

// 5. تفاصيل الطلب والموقع
class OrderScreen extends StatefulWidget {
  final String title; final int price;
  const OrderScreen({super.key, required this.title, required this.price});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  final _phone = TextEditingController();
  String _locStatus = "حدد موقعك";
  double? _lat, _lng;
  
  Future<void> _getLoc() async {
    setState(() => _locStatus = "جاري التحديد...");
    try {
      Position p = await Geolocator.getCurrentPosition();
      setState(() { _lat = p.latitude; _lng = p.longitude; _locStatus = "✅ تم"; });
    } catch (e) { setState(() => _locStatus = "❌ خطأ GPS"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: _phone, decoration: const InputDecoration(labelText: "رقم الهاتف", border: OutlineInputBorder())),
        const SizedBox(height: 20),
        ListTile(title: Text(_locStatus), trailing: IconButton(icon: const Icon(Icons.my_location), onPressed: _getLoc)),
        const Spacer(),
        ElevatedButton(
          onPressed: () async {
            if (_lat == null) return;
            await FirebaseFirestore.instance.collection('requests').add({
              'service': widget.title, 'price': widget.price, 'phone': _phone.text,
              'lat': _lat, 'lng': _lng, 'status': 'pending', 'nurse_id': null
            });
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green),
          child: const Text("إرسال الطلب", style: TextStyle(color: Colors.white)),
        )
      ])),
    );
  }
}

// 6. لوحة الممرض
class NurseDashboard extends StatelessWidget {
  const NurseDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("لوحة الممرض"), bottom: const TabBar(tabs: [Tab(text: "جديد"), Tab(text: "مهامي")])),
      body: const TabBarView(children: [NewOrders(), MyTasks()]),
    ));
  }
}

class NewOrders extends StatelessWidget {
  const NewOrders({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(children: snap.data!.docs.map((d) => ListTile(
          title: Text(d['service']), subtitle: Text("${d['price']} دج"),
          trailing: ElevatedButton(onPressed: () => d.reference.update({'status': 'accepted', 'nurse_id': FirebaseAuth.instance.currentUser?.uid}), child: const Text("قبول")),
        )).toList());
      },
    );
  }
}

class MyTasks extends StatelessWidget {
  const MyTasks({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('nurse_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(children: snap.data!.docs.map((d) => ListTile(
          title: Text(d['service']),
          trailing: IconButton(icon: const Icon(Icons.map, color: Colors.blue), onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=$${d['lat']},${d['lng']}"))),
        )).toList());
      },
    );
  }
}
