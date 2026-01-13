import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:intl/intl.dart' as intl; // للتنسيق التاريخ إن لزم

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688),
          primary: const Color(0xFF009688),
          secondary: const Color(0xFFFF9800),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
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
          gradient: LinearGradient(colors: [Color(0xFF009688), Color(0xFF4DB6AC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.local_hospital_rounded, size: 100, color: Colors.white),
          SizedBox(height: 20),
          Text("Afya DZ", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        ])),
      ),
    );
  }
}

// 2. شاشة الدخول والتسجيل (إصلاح الأخطاء)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating)
    );
  }

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') _showError("حساب غير موجود أو كلمة مرور خاطئة");
      else if (e.code == 'wrong-password') _showError("كلمة المرور غير صحيحة ❌");
      else _showError("خطأ: ${e.message}");
    }
    setState(() => _loading = false);
  }

  Future<void> _doRegister() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameInputScreen()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showError("هذا البريد مسجل بالفعل! يرجى تسجيل الدخول.");
      } else if (e.code == 'weak-password') {
        _showError("كلمة المرور ضعيفة جداً");
      } else {
        _showError("حدث خطأ: ${e.message}");
      }
    } catch (e) {
      _showError("خطأ غير متوقع: $e");
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text("مرحباً بك 👋", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
            const SizedBox(height: 40),
            TextField(controller: _email, decoration: const InputDecoration(labelText: "البريد الإلكتروني", prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 20),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "كلمة المرور", prefixIcon: Icon(Icons.lock_outlined))),
            const SizedBox(height: 30),
            _loading ? const CircularProgressIndicator() : Column(
              children: [
                ElevatedButton(onPressed: _doLogin, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: const Color(0xFF009688)), child: const Text("تسجيل الدخول", style: TextStyle(color: Colors.white, fontSize: 18))),
                const SizedBox(height: 15),
                OutlinedButton(onPressed: _doRegister, style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55)), child: const Text("إنشاء حساب جديد")),
              ],
            ),
          ],
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
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        const Text("ما هو اسمك الكامل؟", style: TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: "الاسم", prefixIcon: Icon(Icons.person))),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _saveName, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF009688)), child: const Text("حفظ ومتابعة", style: TextStyle(color: Colors.white))),
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
      appBar: AppBar(
        title: Text("أهلاً، ${user?.displayName ?? ''}"),
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () async { await FirebaseAuth.instance.signOut(); if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); })],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _card(context, "أنا مريض", "طلب خدمة + متابعة طلباتي", Icons.person_search, const Color(0xFF2196F3), const PatientHomeScreen()),
            const SizedBox(height: 20),
            _card(context, "أنا ممرض", "استقبال الطلبات", Icons.medical_services, const Color(0xFF009688), const NurseDashboard()),
          ],
        ),
      ),
    );
  }
  Widget _card(BuildContext context, String t, String s, IconData i, Color c, Widget p) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: c.withOpacity(0.2), blurRadius: 10)], border: Border.all(color: c.withOpacity(0.1))),
      child: Row(children: [Icon(i, size: 40, color: c), const SizedBox(width: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(s, style: TextStyle(color: Colors.grey[600]))])]),
    ),
  );
}

// 4. قسم المريض (طلب + متابعة)
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("خدماتي"),
          bottom: const TabBar(tabs: [Tab(text: "طلب جديد"), Tab(text: "طلباتي السابقة")]),
        ),
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
      crossAxisCount: 2, padding: const EdgeInsets.all(16), crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
      children: [
        _item(context, "حقن", "800 دج", Icons.vaccines, Colors.orange),
        _item(context, "سيروم", "2500 دج", Icons.water_drop, Colors.blue),
        _item(context, "تغيير ضماد", "1200 دج", Icons.healing, Colors.purple),
        _item(context, "قياس ضغط", "500 دج", Icons.monitor_heart, Colors.red),
        InkWell(
          onTap: () => _customOrder(context),
          child: Container(
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, size: 40), Text("طلب خاص")]),
          ),
        ),
      ],
    );
  }
  void _customOrder(BuildContext context) {
    final c = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("اكتب طلبك"), content: TextField(controller: c),
      actions: [ElevatedButton(onPressed: () {Navigator.pop(context); if(c.text.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: c.text, price: "حسب الاتفاق")));}, child: const Text("تم"))],
    ));
  }
  Widget _item(BuildContext context, String t, String p, IconData i, Color c) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: t, price: p))),
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 35, color: c), const SizedBox(height: 10), Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), Text(p, style: const TextStyle(color: Colors.green))]),
    ),
  );
}

// شاشة "طلباتي" للمريض (لتأكيد الإنجاز)
class PatientMyOrders extends StatelessWidget {
  const PatientMyOrders({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('patient_id', isEqualTo: uid).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات سابقة"));
        return ListView(
          padding: const EdgeInsets.all(15),
          children: snap.data!.docs.map((d) {
            var data = d.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';
            Color stColor = status == 'pending' ? Colors.orange : (status == 'accepted' ? Colors.blue : Colors.green);
            String stText = status == 'pending' ? "جاري البحث عن ممرض..." : (status == 'accepted' ? "الممرض قادم إليك" : "تم الإنجاز ✅");

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(data['service'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: stColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(stText, style: TextStyle(color: stColor, fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 10),
                    // زر التأكيد يظهر فقط إذا كان الطلب "مقبول" ولم ينتهِ بعد
                    if (status == 'accepted')
                      ElevatedButton.icon(
                        onPressed: () => d.reference.update({'status': 'completed'}),
                        icon: const Icon(Icons.check_circle),
                        label: const Text("اضغط هنا لتأكيد أن الممرض أنهى عمله"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                      )
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// شاشة الطلب (حفظنا فيها ID المريض)
class OrderScreen extends StatefulWidget {
  final String title; final String price;
  const OrderScreen({super.key, required this.title, required this.price});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  final _phone = TextEditingController();
  double? _lat, _lng;
  String _status = "اضغط لتحديد الموقع";
  
  Future<void> _loc() async {
    setState(() => _status = "جاري التحديد...");
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      Position pos = await Geolocator.getCurrentPosition();
      setState(() { _lat = pos.latitude; _lng = pos.longitude; _status = "تم ✅"; });
    } catch (e) { setState(() => _status = "فشل GPS"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "رقم الهاتف")),
        const SizedBox(height: 20),
        ListTile(title: Text(_status), trailing: const Icon(Icons.location_on), onTap: _loc, tileColor: Colors.blue[50], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        const Spacer(),
        ElevatedButton(onPressed: () {
          if(_lat != null && _phone.text.isNotEmpty) {
             FirebaseFirestore.instance.collection('requests').add({
               'service': widget.title, 'price': widget.price, 'phone': _phone.text, 
               'lat': _lat, 'lng': _lng, 'status': 'pending', 
               'timestamp': FieldValue.serverTimestamp(),
               'patient_id': FirebaseAuth.instance.currentUser?.uid // هام جداً للمتابعة
             });
             Navigator.pop(context);
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الإرسال، تابع حالته في 'طلباتي'"), backgroundColor: Colors.green));
          }
        }, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF009688)), child: const Text("تأكيد الطلب", style: TextStyle(color: Colors.white)))
      ])),
    );
  }
}

// 5. لوحة الممرض (تابات: جديد / مهامي)
class NurseDashboard extends StatelessWidget {
  const NurseDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("لوحة الممرض"),
          bottom: const TabBar(tabs: [Tab(text: "طلبات متاحة"), Tab(text: "مهامي الحالية")]),
        ),
        body: const TabBarView(children: [NurseMarket(), NurseMyTasks()]),
      ),
    );
  }
}

// التاب الأول: الطلبات الجديدة (تختفي بمجرد القبول)
class NurseMarket extends StatelessWidget {
  const NurseMarket({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // نجلب فقط الطلبات المعلقة pending
      stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات جديدة"));
        return ListView(padding: const EdgeInsets.all(10), children: snap.data!.docs.map((d) {
           var data = d.data() as Map<String, dynamic>;
           return Card(
             child: ListTile(
               leading: const CircleAvatar(child: Icon(Icons.person)),
               title: Text(data['service']),
               subtitle: Text(data['price']),
               trailing: ElevatedButton(
                 onPressed: () {
                   // عند القبول: نغير الحالة ونضع اسم الممرض
                   d.reference.update({
                     'status': 'accepted', 
                     'nurse_id': FirebaseAuth.instance.currentUser?.uid
                   });
                 }, 
                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
                 child: const Text("قبول", style: TextStyle(color: Colors.white))
               ),
             ),
           );
        }).toList());
      },
    );
  }
}

// التاب الثاني: مهام الممرض (التي قبلها)
class NurseMyTasks extends StatelessWidget {
  const NurseMyTasks({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      // نجلب الطلبات التي قبلها هذا الممرض تحديداً
      stream: FirebaseFirestore.instance.collection('requests').where('nurse_id', isEqualTo: uid).where('status', isEqualTo: 'accepted').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) return const Center(child: Text("ليس لديك مهام جارية"));
        return ListView(padding: const EdgeInsets.all(10), children: snap.data!.docs.map((d) {
           var data = d.data() as Map<String, dynamic>;
           return Card(
             color: Colors.blue[50],
             child: Column(
               children: [
                 ListTile(title: Text(data['service']), subtitle: Text("الهاتف: ${data['phone']}"), trailing: Text(data['price'])),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                     ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse("tel:${data['phone']}")), icon: const Icon(Icons.call), label: const Text("اتصال")),
                     ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${data['lat']},${data['lng']}")), icon: const Icon(Icons.map), label: const Text("الخريطة")),
                   ],
                 ),
                 const SizedBox(height: 10),
                 const Text("انتظر تأكيد المريض عند النهاية", style: TextStyle(color: Colors.grey, fontSize: 12)),
                 const SizedBox(height: 10),
               ],
             ),
           );
        }).toList());
      },
    );
  }
}
