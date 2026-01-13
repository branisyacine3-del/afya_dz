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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009688)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
      backgroundColor: const Color(0xFF009688),
      body: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.medical_services, size: 80, color: Colors.white),
        Text("Afya DZ", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
      ])),
    );
  }
}

// 2. شاشة الدخول والتسجيل (المحسنة)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _showError("المستخدم غير موجود، يمكنك إنشاء حساب جديد");
      } else if (e.code == 'wrong-password') {
        _showError("كلمة المرور غير صحيحة ❌");
      } else {
        _showError("خطأ: ${e.message}");
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _doRegister() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      // توجيه لصفحة الاسم بعد التسجيل الناجح
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameInputScreen()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showError("هذا البريد مسجل بالفعل، حاول تسجيل الدخول");
      } else if (e.code == 'weak-password') {
        _showError("كلمة المرور ضعيفة جداً");
      } else {
        _showError("خطأ: ${e.message}");
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("أهلاً بك", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(controller: _email, decoration: const InputDecoration(labelText: "البريد الإلكتروني", prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 15),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "كلمة المرور", prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 30),
            _loading ? const CircularProgressIndicator() : Column(
              children: [
                ElevatedButton(
                  onPressed: _doLogin, 
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF009688), foregroundColor: Colors.white),
                  child: const Text("تسجيل الدخول")
                ),
                TextButton(onPressed: _doRegister, child: const Text("ليس لديك حساب؟ إنشاء حساب جديد"))
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 3. شاشة إدخال الاسم (جديدة)
class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});
  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}
class _NameInputScreenState extends State<NameInputScreen> {
  final _nameController = TextEditingController();

  Future<void> _saveName() async {
    if (_nameController.text.isEmpty) return;
    // حفظ الاسم في ملف المستخدم
    await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text);
    if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بياناتك")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("تم إنشاء الحساب بنجاح! 🎉", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 10),
            const Text("ما هو اسمك الكامل؟"),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "الاسم الكامل", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveName, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("متابعة"))
          ],
        ),
      ),
    );
  }
}

// 4. الشاشة الرئيسية
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text("مرحباً, ${user?.displayName ?? 'يا بطل'}"),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        })]
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _btn(context, "أنا مريض (طلب خدمة)", Icons.person, Colors.blue, const PatientScreen()),
            const SizedBox(height: 20),
            _btn(context, "أنا ممرض (لوحة التحكم)", Icons.medical_services, Colors.teal, const NurseScreen()),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, String txt, IconData i, Color c, Widget p) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
      icon: Icon(i, size: 30),
      label: Text(txt, style: const TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white, padding: const EdgeInsets.all(20), minimumSize: const Size(280, 80)),
    );
  }
}

// 5. شاشة الخدمات والطلب
class PatientScreen extends StatelessWidget {
  const PatientScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الخدمات")),
      body: GridView.count(
        crossAxisCount: 2, padding: const EdgeInsets.all(16), crossAxisSpacing: 10, mainAxisSpacing: 10,
        children: [
          _srv(context, "حقن", 800), _srv(context, "سيروم", 2500), _srv(context, "ضماد", 1200), _srv(context, "ضغط", 500)
        ],
      ),
    );
  }
  Widget _srv(BuildContext context, String t, int p) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: t, price: p))),
    child: Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text("$p دج", style: const TextStyle(color: Colors.green))])),
  );
}

class OrderScreen extends StatefulWidget {
  final String title; final int price;
  const OrderScreen({super.key, required this.title, required this.price});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  final _phone = TextEditingController();
  String _status = "📍 اضغط لتحديد موقعك";
  double? _lat, _lng;
  bool _loading = false;

  Future<void> _getLocation() async {
    setState(() { _loading = true; _status = "جاري الاتصال بـ GPS..."; });
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.deniedForever) {
        setState(() { _status = "⚠️ يجب تفعيل الموقع من الإعدادات"; _loading = false; });
        return;
      }
      Position pos = await Geolocator.getCurrentPosition();
      setState(() { _lat = pos.latitude; _lng = pos.longitude; _status = "✅ تم تحديد الموقع"; _loading = false; });
    } catch (e) {
      setState(() { _status = "❌ فشل تحديد الموقع، تأكد من تشغيل GPS"; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "رقم الهاتف", prefixIcon: Icon(Icons.phone))),
        const SizedBox(height: 20),
        InkWell(
          onTap: _getLocation,
          child: Container(
            padding: const EdgeInsets.all(15),
            color: Colors.blue[50],
            child: Row(children: [
              _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.location_on, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(child: Text(_status)),
            ]),
          ),
        ),
        const Spacer(),
        ElevatedButton(onPressed: () {
          if(_lat != null && _phone.text.isNotEmpty) {
             FirebaseFirestore.instance.collection('requests').add({'service': widget.title, 'price': widget.price, 'phone': _phone.text, 'lat': _lat, 'lng': _lng, 'timestamp': FieldValue.serverTimestamp()});
             Navigator.pop(context);
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الطلب!"), backgroundColor: Colors.green));
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("البيانات ناقصة")));
          }
        }, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("تأكيد الطلب"))
      ])),
    );
  }
}

// 6. لوحة الممرض
class NurseScreen extends StatelessWidget {
  const NurseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("طلبات المرضى")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات"));
          return ListView(children: snap.data!.docs.map((d) {
             var data = d.data() as Map<String, dynamic>;
             return Card(child: ListTile(
               title: Text(data['service']),
               subtitle: Text(data['phone']),
               trailing: IconButton(icon: const Icon(Icons.map, color: Colors.blue), onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${data['lat']},${data['lng']}"))),
             ));
          }).toList());
        },
      ),
    );
  }
}
