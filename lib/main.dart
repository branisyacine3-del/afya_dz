import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart'; // لتنسيق التاريخ

// ---------------------------------------------------------------------------
// إعدادات فايربيس (مشروعك الأصلي)
// ---------------------------------------------------------------------------
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
    try { await Firebase.initializeApp(); } catch (_) {}
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
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688),
          primary: const Color(0xFF009688),
          secondary: const Color(0xFF26A69A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Color(0xFF004D40), fontSize: 22, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Color(0xFF004D40)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009688),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// شاشة عرض الصور (Zoom) - ميزة جديدة 🔍
// ---------------------------------------------------------------------------
class FullScreenImage extends StatelessWidget {
  final String base64Image;
  const FullScreenImage({super.key, required this.base64Image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer( // يسمح بالتكبير والتصغير
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(base64Decode(base64Image)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// شاشة البداية
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
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
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF009688), Color(0xFF4DB6AC)])),
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.health_and_safety_rounded, size: 100, color: Colors.white),
          SizedBox(height: 20),
          Text("عافية", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          Text("رعايتك في منزلك", style: TextStyle(color: Colors.white70, fontSize: 18)),
        ])),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// شاشة الدخول
// ---------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _auth(bool isReg) async {
    setState(() => _loading = true);
    try {
      if (isReg) {
        UserCredential uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(uc.user!.uid).set({'email': _email.text.trim(), 'role': 'user', 'status': 'active', 'name': 'مستخدم جديد'}, SetOptions(merge: true));
        if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameInputScreen()));
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
        if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("خطأ في البيانات"), backgroundColor: Colors.red));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(30), child: Column(children: [
        const Icon(Icons.lock_person, size: 80, color: Color(0xFF009688)),
        const SizedBox(height: 30),
        TextField(controller: _email, decoration: const InputDecoration(labelText: "البريد الإلكتروني", border: OutlineInputBorder())),
        const SizedBox(height: 20),
        TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "كلمة المرور", border: OutlineInputBorder())),
        const SizedBox(height: 30),
        _loading ? const CircularProgressIndicator() : Column(children: [
          ElevatedButton(onPressed: () => _auth(false), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("دخول")),
          TextButton(onPressed: () => _auth(true), child: const Text("إنشاء حساب جديد"))
        ])
      ]))),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بياناتك")),
      body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: "الاسم الكامل")),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () async {
           await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text);
           await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({'name': _nameController.text}, SetOptions(merge: true));
           if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
        }, child: const Text("حفظ"))
      ])),
    );
  }
}

// ---------------------------------------------------------------------------
// الرئيسية
// ---------------------------------------------------------------------------
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isAdmin = user?.email == "admin@afya.dz"; 

    return Scaffold(
      appBar: AppBar(
        title: const Text("الرئيسية"),
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () async { await FirebaseAuth.instance.signOut(); if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); })],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF009688), Color(0xFF4DB6AC)]), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF009688))),
              const SizedBox(width: 15),
              Text("مرحباً، ${user?.displayName ?? ''}", style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 40),
          if (isAdmin) _btn(context, "لوحة الإدارة", Icons.admin_panel_settings, Colors.red[800]!, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()))),
          _btn(context, "أنا مريض", Icons.medical_services, const Color(0xFF009688), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientHomeScreen()))),
          _btn(context, "أنا ممرض", Icons.work, const Color(0xFF1976D2), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseAuthGate()))),
        ]),
      ),
    );
  }
  Widget _btn(BuildContext context, String t, IconData i, Color c, VoidCallback f) => Padding(padding: const EdgeInsets.only(bottom: 15), child: InkWell(onTap: f, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]), child: Row(children: [Icon(i, color: c, size: 30), const SizedBox(width: 20), Text(t, style: TextStyle(fontSize: 18, color: c, fontWeight: FontWeight.bold))]))));
}

// ---------------------------------------------------------------------------
// بوابة الممرض
// ---------------------------------------------------------------------------
class NurseAuthGate extends StatelessWidget {
  const NurseAuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text("بوابة الممرض")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var data = snap.data!.data() as Map<String, dynamic>?;
          String status = data?['status'] ?? 'user';
          String role = data?['role'] ?? 'user';
          if (role == 'user') return const NurseRegistrationForm(); 
          if (status == 'pending_docs') return const Center(child: Text("ملفك قيد المراجعة"));
          if (status == 'pending_payment') return const NursePaymentScreen();
          if (status == 'payment_review') return const Center(child: Text("جاري مراجعة الدفع"));
          if (status == 'approved') return const NurseDashboard();
          return const NurseRegistrationForm();
        },
      ),
    );
  }
}

class NurseRegistrationForm extends StatefulWidget {
  const NurseRegistrationForm({super.key});
  @override
  State<NurseRegistrationForm> createState() => _NurseRegistrationFormState();
}
class _NurseRegistrationFormState extends State<NurseRegistrationForm> {
  final _phone = TextEditingController();
  final _specialty = TextEditingController();
  final _address = TextEditingController();
  bool _hasCar = false;
  String? _pic, _id, _dip;
  bool _loading = false;

  Future<void> _pick(String t) async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 10, maxWidth: 400);
    if(x!=null) {
      final b = await File(x.path).readAsBytes();
      setState(() { if(t=='p') _pic=base64Encode(b); if(t=='i') _id=base64Encode(b); if(t=='d') _dip=base64Encode(b); });
    }
  }

  Future<void> _sub() async {
    if(_phone.text.isEmpty || _pic==null) return;
    setState(() => _loading = true);
    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({
      'role': 'nurse', 'status': 'pending_docs', 'phone': _phone.text, 'specialty': _specialty.text, 'address': _address.text, 'has_car': _hasCar,
      'pic_data': _pic, 'id_data': _id, 'diploma_data': _dip
    }, SetOptions(merge: true));
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      TextField(controller: _phone, decoration: const InputDecoration(labelText: "الهاتف")), const SizedBox(height: 10),
      TextField(controller: _specialty, decoration: const InputDecoration(labelText: "التخصص")), const SizedBox(height: 10),
      TextField(controller: _address, decoration: const InputDecoration(labelText: "العنوان")), const SizedBox(height: 10),
      SwitchListTile(title: const Text("سيارة"), value: _hasCar, onChanged: (v)=>setState(()=>_hasCar=v)),
      ElevatedButton(onPressed: ()=>_pick('p'), child: Text(_pic==null?"صورة شخصية":"تم")),
      ElevatedButton(onPressed: ()=>_pick('i'), child: Text(_id==null?"بطاقة تعريف":"تم")),
      ElevatedButton(onPressed: ()=>_pick('d'), child: Text(_dip==null?"دبلوم":"تم")),
      const SizedBox(height: 20),
      _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _sub, child: const Text("إرسال"))
    ]));
  }
}

class NursePaymentScreen extends StatefulWidget {
  const NursePaymentScreen({super.key});
  @override
  State<NursePaymentScreen> createState() => _NursePaymentScreenState();
}
class _NursePaymentScreenState extends State<NursePaymentScreen> {
  String? _rec; bool _load=false;
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text("اشتراك: 3500 دج\nCCP: 0028939081 - 97", textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () async {
        final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 10, maxWidth: 400);
        if(x!=null) { final b=await File(x.path).readAsBytes(); setState(()=>_rec=base64Encode(b)); }
      }, child: Text(_rec==null?"رفع الوصل":"تم الاختيار")),
      const SizedBox(height: 20),
      if(_load) const CircularProgressIndicator() else ElevatedButton(onPressed: () async {
        if(_rec==null) return;
        setState(()=>_load=true);
        await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({'status': 'payment_review', 'receipt_data': _rec}, SetOptions(merge: true));
      }, child: const Text("تأكيد"))
    ]);
  }
}

// ---------------------------------------------------------------------------
// لوحة الإدارة (تم إضافة التكبير والأسعار الكاملة) ✅
// ---------------------------------------------------------------------------
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: Scaffold(
      appBar: AppBar(title: const Text("الإدارة"), bottom: const TabBar(tabs: [Tab(text: "التوثيق"), Tab(text: "المدفوعات"), Tab(text: "الأسعار")])),
      body: const TabBarView(children: [AdminDocsReview(), AdminPaymentReview(), AdminPricesControl()]),
    ));
  }
}

class AdminDocsReview extends StatelessWidget {
  const AdminDocsReview({super.key});
  void _openImage(BuildContext context, String? base64) {
    if(base64 != null) Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImage(base64Image: base64)));
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'pending_docs').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد ملفات"));
        return ListView.builder(itemCount: snap.data!.docs.length, itemBuilder: (ctx, i) {
          var d = snap.data!.docs[i];
          var data = d.data() as Map<String, dynamic>;
          return Card(child: ExpansionTile(
            title: Text(data['name']??"ممرض"), subtitle: Text(data['phone']??""),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                if(data['id_data']!=null) GestureDetector(onTap: ()=>_openImage(context, data['id_data']), child: const Column(children: [Icon(Icons.image, size: 50), Text("بطاقة")])),
                if(data['diploma_data']!=null) GestureDetector(onTap: ()=>_openImage(context, data['diploma_data']), child: const Column(children: [Icon(Icons.school, size: 50), Text("دبلوم")])),
              ]),
              ElevatedButton(onPressed: ()=>d.reference.update({'status': 'pending_payment'}), child: const Text("قبول"))
            ]
          ));
        });
      },
    );
  }
}

class AdminPaymentReview extends StatelessWidget {
  const AdminPaymentReview({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'payment_review').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد مدفوعات"));
        return ListView.builder(itemCount: snap.data!.docs.length, itemBuilder: (ctx, i) {
          var d = snap.data!.docs[i];
          var data = d.data() as Map<String, dynamic>;
          return Card(child: ListTile(
            title: Text(data['name']??"ممرض"),
            trailing: data['receipt_data']!=null 
              ? IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImage(base64Image: data['receipt_data'])))) 
              : null,
            subtitle: ElevatedButton(onPressed: ()=>d.reference.update({'status': 'approved'}), child: const Text("تفعيل الحساب")),
          ));
        });
      },
    );
  }
}

class AdminPricesControl extends StatefulWidget {
  const AdminPricesControl({super.key});
  @override
  State<AdminPricesControl> createState() => _AdminPricesControlState();
}
class _AdminPricesControlState extends State<AdminPricesControl> {
  final _c1 = TextEditingController(); // حقن
  final _c2 = TextEditingController(); // سيروم
  final _c3 = TextEditingController(); // ضماد
  final _c4 = TextEditingController(); // ضغط

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('config').doc('prices').snapshots(),
      builder: (context, snap) {
        var data = snap.data?.data() as Map<String, dynamic>? ?? {};
        if(_c1.text.isEmpty) _c1.text = data['حقن'] ?? '800';
        if(_c2.text.isEmpty) _c2.text = data['سيروم'] ?? '2000';
        if(_c3.text.isEmpty) _c3.text = data['تغيير ضماد'] ?? '1200';
        if(_c4.text.isEmpty) _c4.text = data['قياس ضغط'] ?? '500';

        return ListView(padding: const EdgeInsets.all(20), children: [
          TextField(controller: _c1, decoration: const InputDecoration(labelText: "سعر الحقن")),
          TextField(controller: _c2, decoration: const InputDecoration(labelText: "سعر السيروم")),
          TextField(controller: _c3, decoration: const InputDecoration(labelText: "سعر تغيير ضماد")),
          TextField(controller: _c4, decoration: const InputDecoration(labelText: "سعر قياس الضغط")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {
            FirebaseFirestore.instance.collection('config').doc('prices').set({
              'حقن': _c1.text, 'سيروم': _c2.text, 'تغيير ضماد': _c3.text, 'قياس ضغط': _c4.text
            }, SetOptions(merge: true));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ")));
          }, child: const Text("حفظ التعديلات"))
        ]);
      }
    );
  }
}

// ---------------------------------------------------------------------------
// واجهة المريض (تحديثات التصميم والمؤقت) ⏳
// ---------------------------------------------------------------------------
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("الخدمات"), bottom: const TabBar(tabs: [Tab(text: "طلب جديد"), Tab(text: "طلباتي")])),
      body: const TabBarView(children: [PatientNewOrder(), PatientMyOrders()]),
    ));
  }
}

class PatientNewOrder extends StatelessWidget {
  const PatientNewOrder({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('config').doc('prices').snapshots(),
      builder: (context, snap) {
        var p = snap.data?.data() as Map<String, dynamic>? ?? {};
        return ListView(padding: const EdgeInsets.all(20), children: [
          Wrap(runSpacing: 15, spacing: 15, alignment: WrapAlignment.center, children: [
            _card(context, "حقن", "${p['حقن']??'800'} دج", Icons.vaccines, Colors.orange),
            _card(context, "سيروم", "${p['سيروم']??'2000'} دج", Icons.water_drop, Colors.blue),
            _card(context, "تغيير ضماد", "${p['تغيير ضماد']??'1200'} دج", Icons.healing, Colors.purple),
            _card(context, "قياس ضغط", "${p['قياس ضغط']??'500'} دج", Icons.monitor_heart, Colors.red),
          ]),
          const SizedBox(height: 20),
          // زر خدمة خاصة (تمت إعادته) ✅
          InkWell(
            onTap: () => _customOrder(context),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle, color: Colors.teal), SizedBox(width: 10), Text("طلب خدمة أخرى (خاصة)", style: TextStyle(fontWeight: FontWeight.bold))]),
            ),
          )
        ]);
      }
    );
  }
  
  void _customOrder(BuildContext context) {
    TextEditingController c = TextEditingController();
    showDialog(context: context, builder: (_)=>AlertDialog(title: const Text("اكتب نوع الخدمة"), content: TextField(controller: c), actions: [ElevatedButton(onPressed: (){Navigator.pop(context); if(c.text.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_)=>OrderScreen(title: c.text, price: "حسب الاتفاق")));}, child: const Text("متابعة"))]));
  }

  Widget _card(BuildContext context, String t, String p, IconData i, Color c) {
    return InkWell(onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>OrderScreen(title: t, price: p))), child: Container(width: 150, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]), child: Column(children: [CircleAvatar(backgroundColor: c.withOpacity(0.1), child: Icon(i, color: c)), const SizedBox(height: 10), Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), Text(p, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))])));
  }
}

class PatientMyOrders extends StatelessWidget {
  const PatientMyOrders({super.key});

  // دالة لحساب الوقت المنقضي
  String _formatDate(Timestamp? t) {
    if (t == null) return "";
    return DateFormat('yyyy-MM-dd HH:mm').format(t.toDate());
  }

  // دالة للتحقق من انتهاء الصلاحية (10 دقائق)
  bool _isExpired(Timestamp? t) {
    if (t == null) return false;
    final diff = DateTime.now().difference(t.toDate());
    return diff.inMinutes >= 10;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('patient_id', isEqualTo: uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات"));
        
        var docs = snap.data!.docs;
        // تنظيف تلقائي للطلبات القديمة (محلياً) وتحديثها في السيرفر
        for (var d in docs) {
          var data = d.data() as Map<String, dynamic>;
          if (data['status'] == 'pending' && _isExpired(data['timestamp'])) {
             // تحديث الحالة إلى منتهي الصلاحية إذا لم يقم السيرفر بذلك
             d.reference.update({'status': 'expired'}); 
          }
        }

        return ListView.builder(padding: const EdgeInsets.all(15), itemCount: docs.length, itemBuilder: (ctx, i) {
          var d = docs[i];
          var data = d.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'pending';
          String price = data['price'] ?? '';
          String service = data['service'] ?? '';
          String nurseName = data['nurse_name'] ?? '';
          
          Color statusColor = Colors.orange;
          String statusText = "جاري البحث عن ممرض...";
          
          if (status == 'expired') { statusColor = Colors.red; statusText = "انتهى الوقت (لم يقبل أحد)"; }
          if (status == 'accepted') { statusColor = Colors.blue; statusText = "الممرض $nurseName في طريقه إليك 🚑"; }
          if (status == 'completed') { statusColor = Colors.green; statusText = "اكتملت الخدمة ✅"; }

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
              border: Border(right: BorderSide(color: statusColor, width: 5))
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(service, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(price, style: const TextStyle(fontSize: 16, color: Colors.teal, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 5),
                  Text(_formatDate(data['timestamp']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      if(status == 'pending') const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                      if(status == 'pending') const SizedBox(width: 10),
                      Expanded(child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  
                  // الأزرار حسب الحالة
                  if (status == 'pending') 
                    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: ()=>d.reference.delete(), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text("إلغاء الطلب"))),
                  
                  if (status == 'accepted')
                     SizedBox(width: double.infinity, child: ElevatedButton.icon(
                       onPressed: () => d.reference.update({'status': 'completed'}), 
                       icon: const Icon(Icons.check_circle),
                       label: const Text("اضغط هنا عند استلام الخدمة"),
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                     )),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

// ---------------------------------------------------------------------------
// شاشة تأكيد الطلب (مع استرجاع الموقع والـ Loading) 📍
// ---------------------------------------------------------------------------
class OrderScreen extends StatefulWidget {
  final String title; final String price;
  const OrderScreen({super.key, required this.title, required this.price});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  final _phone = TextEditingController();
  double? _lat, _lng;
  bool _gettingLoc = false; // لتأثير التحميل

  Future<void> _getLocation() async {
    setState(() => _gettingLoc = true);
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.whileInUse || p == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition();
        setState(() { _lat = pos.latitude; _lng = pos.longitude; });
      }
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تعذر تحديد الموقع")));
    }
    setState(() => _gettingLoc = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد الطلب")),
      body: SingleChildScrollView(padding: const EdgeInsets.all(25), child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(15)),
          child: Column(children: [Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)), Text(widget.price, style: const TextStyle(fontSize: 18))]),
        ),
        const SizedBox(height: 30),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "رقم هاتفك للتواصل", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())),
        const SizedBox(height: 20),
        
        // زر الموقع (تمت إعادته مع تأثير التحميل) ✅
        InkWell(
          onTap: _getLocation,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _lat != null ? Colors.green[50] : Colors.white,
              border: Border.all(color: _lat != null ? Colors.green : Colors.grey),
              borderRadius: BorderRadius.circular(10)
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if(_gettingLoc) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else Icon(Icons.location_on, color: _lat != null ? Colors.green : Colors.grey),
              const SizedBox(width: 10),
              Text(_lat != null ? "تم تحديد الموقع بنجاح ✅" : (_gettingLoc ? "جاري جلب الموقع..." : "اضغط لتحديد موقع منزلك"))
            ]),
          ),
        ),

        const SizedBox(height: 30),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {
          if(_phone.text.isNotEmpty) {
            FirebaseFirestore.instance.collection('requests').add({
              'service': widget.title, 'price': widget.price, 'phone': _phone.text, 
              'lat': _lat, 'lng': _lng,
              'status': 'pending', 'timestamp': FieldValue.serverTimestamp(),
              'patient_id': FirebaseAuth.instance.currentUser?.uid,
              'patient_name': FirebaseAuth.instance.currentUser?.displayName
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الإرسال"), backgroundColor: Colors.green));
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("رقم الهاتف ضروري"), backgroundColor: Colors.red));
          }
        }, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text("تأكيد الطلب")))
      ])),
    );
  }
}

// ---------------------------------------------------------------------------
// لوحة الممرض (فلترة المنتهي)
// ---------------------------------------------------------------------------
class NurseDashboard extends StatelessWidget {
  const NurseDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("لوحة الممرض"), bottom: const TabBar(tabs: [Tab(text: "جديد"), Tab(text: "مهامي")])),
      body: const TabBarView(children: [NurseMarket(), NurseMyTasks()]),
    ));
  }
}
class NurseMarket extends StatelessWidget {
  const NurseMarket({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // نعرض فقط المعلق (المنتهي لا يظهر)
      stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات جديدة"));
        return ListView.builder(itemCount: snap.data!.docs.length, padding: const EdgeInsets.all(15), itemBuilder: (ctx, i) {
          var d = snap.data!.docs[i];
          var data = d.data() as Map<String, dynamic>;
          
          // تحقق إضافي من الوقت (لكي لا يقبل طلباً منتهياً)
          Timestamp? t = data['timestamp'];
          if(t != null && DateTime.now().difference(t.toDate()).inMinutes >= 10) {
             return const SizedBox(); // إخفاء الطلب المنتهي فوراً
          }

          return Card(child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
            title: Text(data['patient_name']??"مريض"),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${data['service']} - ${data['price']}"),
              if(data['lat']!=null) const Text("📍 يوجد موقع", style: TextStyle(color: Colors.green, fontSize: 12))
            ]),
            trailing: ElevatedButton(onPressed: () => d.reference.update({'status': 'accepted', 'nurse_id': FirebaseAuth.instance.currentUser?.uid, 'nurse_name': FirebaseAuth.instance.currentUser?.displayName}), child: const Text("قبول")),
          ));
        });
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا مهام"));
        return ListView.builder(itemCount: snap.data!.docs.length, padding: const EdgeInsets.all(15), itemBuilder: (ctx, i) {
          var d = snap.data!.docs[i];
          var data = d.data() as Map<String, dynamic>;
          return Card(child: Column(children: [
            ListTile(title: Text(data['patient_name']??""), subtitle: Text(data['phone']??""), leading: const Icon(Icons.run_circle, size: 40, color: Colors.blue)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              IconButton(onPressed: ()=>launchUrl(Uri.parse("tel:${data['phone']}")), icon: const Icon(Icons.call, color: Colors.green)),
              if(data['lat']!=null) IconButton(onPressed: ()=>launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${data['lat']},${data['lng']}")), icon: const Icon(Icons.location_on, color: Colors.red)),
            ]),
            const Padding(padding: EdgeInsets.all(8.0), child: Text("انتظر تأكيد المريض للاكتمال...", style: TextStyle(color: Colors.grey)))
          ]));
        });
      },
    );
  }
}
