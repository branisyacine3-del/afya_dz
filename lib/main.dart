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
      title: 'عافية',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          primary: const Color(0xFF00897B),
          secondary: const Color(0xFF4DB6AC),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Color(0xFF004D40), fontSize: 24, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Color(0xFF004D40)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
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
          gradient: LinearGradient(
            colors: [Color(0xFF00897B), Color(0xFF80CBC4)], 
            begin: Alignment.topCenter, 
            end: Alignment.bottomCenter
          ),
        ),
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.health_and_safety, size: 100, color: Colors.white),
          SizedBox(height: 20),
          Text("عافية", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text("رعايتك في منزلك", style: TextStyle(color: Colors.white70, fontSize: 18)),
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
      _showError("خطأ في البيانات، حاول مجدداً");
    }
    setState(() => _loading = false);
  }

  Future<void> _doRegister() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameInputScreen()));
    } catch (e) {
      _showError("البريد مستخدم أو كلمة المرور ضعيفة");
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.lock_open_rounded, size: 80, color: Color(0xFF00897B)),
              const SizedBox(height: 20),
              const Text("تسجيل الدخول", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
              const SizedBox(height: 40),
              TextField(controller: _email, decoration: InputDecoration(labelText: "البريد الإلكتروني", prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
              const SizedBox(height: 20),
              TextField(controller: _pass, obscureText: true, decoration: InputDecoration(labelText: "كلمة المرور", prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
              const SizedBox(height: 30),
              _loading ? const CircularProgressIndicator() : Column(
                children: [
                  ElevatedButton(onPressed: _doLogin, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)), child: const Text("دخول", style: TextStyle(fontSize: 18))),
                  TextButton(onPressed: _doRegister, child: const Text("مستخدم جديد؟ إنشاء حساب"))
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
        const Text("الرجاء كتابة اسمك الحقيقي", style: TextStyle(fontSize: 20, color: Colors.grey)),
        const SizedBox(height: 30),
        TextField(controller: _nameController, decoration: InputDecoration(labelText: "الاسم الكامل", prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
        const SizedBox(height: 30),
        ElevatedButton(onPressed: _saveName, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)), child: const Text("حفظ ومتابعة"))
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
        title: const Text("عافية"), 
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.grey), onPressed: () async { await FirebaseAuth.instance.signOut(); if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); })],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.05), blurRadius: 20)]),
              child: Row(children: [
                const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.person, size: 35, color: Color(0xFF00897B))),
                const SizedBox(width: 15),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("مرحباً بك", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(user?.displayName ?? "يا بطل", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                ]),
              ]),
            ),
            const SizedBox(height: 50),
            _mainBtn(context, "أنا مريض", "أطلب خدمة طبية الآن", Icons.medical_services_outlined, const Color(0xFF00897B), const PatientHomeScreen()),
            const SizedBox(height: 20),
            _mainBtn(context, "أنا ممرض", "لوحة التحكم والطلبات", Icons.assignment_ind_outlined, const Color(0xFF039BE5), const NurseDashboard()),
          ],
        ),
      ),
    );
  }

  Widget _mainBtn(BuildContext context, String t, String sub, IconData i, Color c, Widget p) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.2)), boxShadow: [BoxShadow(color: c.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(i, color: c, size: 30)),
        const SizedBox(width: 20),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)), Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 13))]),
        const Spacer(),
        Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 18),
      ]),
    ),
  );
}

// 4. واجهة المريض
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("اختر الخدمة"), bottom: const TabBar(labelColor: Color(0xFF00897B), indicatorColor: Color(0xFF00897B), tabs: [Tab(text: "طلب جديد"), Tab(text: "طلباتي")])),
      body: const TabBarView(children: [PatientNewOrder(), PatientMyOrders()]),
    ));
  }
}

class PatientNewOrder extends StatelessWidget {
  const PatientNewOrder({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(20), crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.9, children: [
      _item(context, "حقن", "800 دج", Icons.vaccines, Colors.orange),
      _item(context, "سيروم", "2500 دج", Icons.water_drop, Colors.blue),
      _item(context, "تغيير ضماد", "1200 دج", Icons.healing, Colors.purple),
      _item(context, "قياس ضغط", "500 دج", Icons.monitor_heart, Colors.red),
      InkWell(onTap: () => _custom(context), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.dashed)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle, size: 45, color: Colors.grey[400]), const SizedBox(height: 10), Text("طلب خدمة أخرى", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold))]))),
    ]);
  }
  
  void _custom(BuildContext context) {
    final c = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("اكتب طلبك هنا"), 
      content: TextField(
        controller: c, 
        maxLines: 2,
        decoration: const InputDecoration(
          hintText: "مثال: أحتاج تغيير ضماد لمريض سكري، أو رعاية كبار السن...", 
          border: OutlineInputBorder()
        )
      ), 
      actions: [ElevatedButton(onPressed: () {Navigator.pop(context); if(c.text.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: c.text, price: "حسب الاتفاق")));}, child: const Text("متابعة"))]
    ));
  }
  
  Widget _item(BuildContext context, String t, String p, IconData i, Color c) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: t, price: p))),
    child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(i, size: 32, color: c)), const SizedBox(height: 15), Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), const SizedBox(height: 5), Text(p, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))])),
  );
}

// *** التعديل الكبير هنا: بطاقة متابعة الطلب للمريض ***
class PatientMyOrders extends StatelessWidget {
  const PatientMyOrders({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('patient_id', isEqualTo: uid).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات سابقة"));
        return ListView(padding: const EdgeInsets.all(15), children: snap.data!.docs.map((d) {
          var data = d.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'pending';
          
          // إذا كان الطلب قيد الانتظار
          if (status == 'pending') {
            return Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: Colors.orange),
                    const SizedBox(height: 15),
                    Text("جارٍ البحث عن ممرض...", style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 5),
                    Text("طلبك لخدمة '${data['service']}' قيد النشر للممرضين القريبين منك", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange[600])),
                  ],
                ),
              ),
            );
          } 
          // إذا تم قبول الطلب (إظهار اسم الممرض)
          else {
            String nurseName = data['nurse_name'] ?? "ممرض";
            bool isCompleted = status == 'completed';
            return Card(
              color: isCompleted ? Colors.grey[100] : Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(isCompleted ? Icons.check_circle : Icons.health_and_safety, size: 50, color: isCompleted ? Colors.grey : Colors.green),
                    const SizedBox(height: 15),
                    Text(isCompleted ? "تم إنجاز المهمة" : "الممرض $nurseName في الطريق!", style: TextStyle(color: isCompleted ? Colors.grey[700] : Colors.green[800], fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 5),
                    if (!isCompleted) Text("وافق الممرض $nurseName على طلبك وهو قادم لتقديم خدمة '${data['service']}'", textAlign: TextAlign.center, style: TextStyle(color: Colors.green[600])),
                  ],
                ),
              ),
            );
          }
        }).toList());
      },
    );
  }
}

// 5. شاشة تأكيد الطلب
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
      appBar: AppBar(title: const Text("تأكيد الطلب")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(20), width: double.infinity, decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(15)), child: Column(children: [Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)), Text(widget.price, style: const TextStyle(fontSize: 18, color: Colors.green))])),
            const SizedBox(height: 30),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "رقم الهاتف للتواصل", prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            InkWell(
              onTap: _loc,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: _locSuccess ? Colors.green[50] : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: _locSuccess ? Colors.green : Colors.grey.shade300)),
                child: Row(children: [
                  _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.location_on, color: _locSuccess ? Colors.green : Colors.grey),
                  const SizedBox(width: 15),
                  Expanded(child: Text(_locSuccess ? "تم تحديد موقعك بنجاح" : "اضغط هنا لتحديد موقع المنزل", style: TextStyle(color: _locSuccess ? Colors.green : Colors.black87))),
                ]),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if(_lat != null && _phone.text.isNotEmpty) {
                   FirebaseFirestore.instance.collection('requests').add({
                     'service': widget.title, 'price': widget.price, 'phone': _phone.text, 
                     'lat': _lat, 'lng': _lng, 'status': 'pending', 
                     'timestamp': FieldValue.serverTimestamp(),
                     'patient_id': FirebaseAuth.instance.currentUser?.uid,
                     'patient_name': FirebaseAuth.instance.currentUser?.displayName ?? 'مريض',
                   });
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال الطلب للممرضين"), backgroundColor: Colors.green));
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال الرقم والموقع"), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              child: const Text("تأكيد الطلب", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// 6. لوحة الممرض
class NurseDashboard extends StatelessWidget {
  const NurseDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("لوحة التحكم"), bottom: const TabBar(labelColor: Color(0xFF00897B), indicatorColor: Color(0xFF00897B), tabs: [Tab(text: "طلبات جديدة"), Tab(text: "مهامي")])),
      body: const TabBarView(children: [NurseMarket(), NurseMyTasks()]),
    ));
  }
}

class NurseMarket extends StatelessWidget {
  const NurseMarket({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snap) {
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, index) {
              var d = snap.data!.docs[index];
              var data = d.data() as Map<String, dynamic>;
              String patientName = data['patient_name'] ?? 'مريض';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.person, color: Color(0xFF00897B))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("يحتاج: ${data['service']}", style: TextStyle(color: Colors.grey[700])),
                          ])),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(20)), child: const Text("جديد", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['price'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                          ElevatedButton(
                            // *** التعديل المهم هنا: حفظ اسم الممرض عند القبول ***
                            onPressed: () => d.reference.update({
                              'status': 'accepted', 
                              'nurse_id': FirebaseAuth.instance.currentUser?.uid,
                              'nurse_name': FirebaseAuth.instance.currentUser?.displayName ?? 'ممرض' 
                            }),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10)),
                            child: const Text("قبول الطلب"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        }
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        return const Center(child: Text("لا توجد طلبات جديدة حالياً"));
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
              String pName = data['patient_name'] ?? 'مريض';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.assignment_ind, color: Color(0xFF00897B)),
                        const SizedBox(width: 10),
                        Text("المريض: $pName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 5),
                      Text("الخدمة المطلوبة: ${data['service']}", style: const TextStyle(fontSize: 16)),
                      const Divider(height: 30),
                      Row(
                        children: [
                          Expanded(child: ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse("tel:${data['phone']}")), icon: const Icon(Icons.phone), label: const Text("اتصال"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green))),
                          const SizedBox(width: 10),
                          Expanded(child: ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${data['lat']},${data['lng']}")), icon: const Icon(Icons.location_on), label: const Text("الموقع"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(child: TextButton(onPressed: () => d.reference.update({'status': 'completed'}), child: const Text("اضغط هنا عند إتمام المهمة", style: TextStyle(color: Colors.grey))))
                    ],
                  ),
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
