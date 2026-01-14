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

// 1. المفاتيح الأصلية (مشروع afya-dz)
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
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          primary: const Color(0xFF00897B),
          secondary: const Color(0xFF4DB6AC),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
          titleTextStyle: TextStyle(color: Color(0xFF004D40), fontSize: 24, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Color(0xFF004D40)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// 2. شاشة البداية
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  bool _hasInternet = true;
  @override
  void initState() {
    super.initState();
    _checkInternet();
  }
  Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        Timer(const Duration(seconds: 3), () {
          if (FirebaseAuth.instance.currentUser != null) {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
          } else {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        });
      }
    } on SocketException catch (_) {
      if(mounted) setState(() => _hasInternet = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) {
      return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.wifi_off, size: 80, color: Colors.red), const SizedBox(height: 20), const Text("لا يوجد إنترنت"), ElevatedButton(onPressed: (){setState(() => _hasInternet = true); _checkInternet();}, child: const Text("إعادة المحاولة"))])));
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00897B), Color(0xFF80CBC4)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.health_and_safety, size: 100, color: Colors.white),
          SizedBox(height: 20),
          Text("عافية", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          Text("رعايتك في منزلك", style: TextStyle(color: Colors.white70, fontSize: 18)),
        ])),
      ),
    );
  }
}

// 3. شاشة الدخول
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
        await FirebaseFirestore.instance.collection('users').doc(uc.user!.uid).set({'email': _email.text.trim(), 'role': 'user', 'status': 'active', 'name': 'مستخدم جديد'});
        if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameInputScreen()));
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
        if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(padding: const EdgeInsets.all(30), child: Column(children: [
          const Icon(Icons.lock_open_rounded, size: 80, color: Color(0xFF00897B)),
          const SizedBox(height: 40),
          TextField(controller: _email, decoration: const InputDecoration(labelText: "البريد الإلكتروني", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "كلمة المرور", border: OutlineInputBorder())),
          const SizedBox(height: 30),
          _loading ? const CircularProgressIndicator() : Column(children: [
            ElevatedButton(onPressed: () => _auth(false), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)), child: const Text("دخول")),
            TextButton(onPressed: () => _auth(true), child: const Text("إنشاء حساب جديد"))
          ]),
        ])),
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
    User? user = FirebaseAuth.instance.currentUser;
    await user?.updateDisplayName(_nameController.text);
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'name': _nameController.text});
    if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بياناتك")),
      body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: "الاسم الكامل", border: OutlineInputBorder())),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _saveName, child: const Text("حفظ ومتابعة"))
      ])),
    );
  }
}

// 4. الشاشة الرئيسية
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isAdmin = user?.email == "admin@afya.dz"; 

    return Scaffold(
      appBar: AppBar(
        title: const Text("عافية"), 
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () async { await FirebaseAuth.instance.signOut(); if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); })],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("مرحباً ${user?.displayName ?? ''}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          if (isAdmin) 
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
              icon: const Icon(Icons.admin_panel_settings), label: const Text("لوحة الإدارة"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], minimumSize: const Size(double.infinity, 60)),
            ),
          const SizedBox(height: 20),
          _btn(context, "أنا مريض", Icons.medical_services_outlined, Colors.teal, const PatientHomeScreen()),
          const SizedBox(height: 20),
          _btn(context, "أنا ممرض", Icons.assignment_ind_outlined, Colors.blue, const NurseAuthGate()),
        ]),
      ),
    );
  }
  Widget _btn(BuildContext context, String t, IconData i, Color c, Widget p) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
    child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.3))), child: Row(children: [Icon(i, color: c, size: 30), const SizedBox(width: 20), Text(t, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c))])),
  );
}

// 5. بوابة الممرض
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

          if (role == 'user') return const NurseRegistrationForm(); // يذهب للتسجيل
          if (status == 'pending_docs') return _msg(Icons.hourglass_top, Colors.orange, "قيد المراجعة", "المدير يراجع وثائقك.");
          if (status == 'pending_payment') return const NursePaymentScreen();
          if (status == 'payment_review') return _msg(Icons.payments, Colors.blue, "مراجعة الدفع", "جاري التحقق من الوصل.");
          if (status == 'approved') return const NurseDashboard();
          return const NurseRegistrationForm();
        },
      ),
    );
  }
  Widget _msg(IconData i, Color c, String t, String s) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 80, color: c), const SizedBox(height: 20), Text(t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(s)]));
}

// *** 6. استمارة الممرض (مع إصلاح الرفع + شريط التحميل) ***
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
  
  String? _picBase64;
  String? _idBase64;
  String? _diplomaBase64;
  
  // متغيرات شريط التحميل
  bool _isUploading = false;
  double _progressValue = 0.0;
  Timer? _timer;

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    // ⚠️ ضغط قوي جداً للصور (Quality 10) لحل مشكلة الـ 1 ميغا
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 10, maxWidth: 400);
    
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      String base64String = base64Encode(bytes);
      setState(() {
        if (type == 'pic') _picBase64 = base64String;
        if (type == 'id') _idBase64 = base64String;
        if (type == 'diploma') _diplomaBase64 = base64String;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تجهيز الصورة ✅"), backgroundColor: Colors.green));
    }
  }

  Future<void> _submit() async {
    if (_phone.text.isEmpty || _specialty.text.isEmpty || _picBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("املأ البيانات وارفع صورة شخصية على الأقل"), backgroundColor: Colors.red));
      return;
    }
    
    // بدء التحميل
    setState(() {
      _isUploading = true;
      _progressValue = 0.1; // البداية 10%
    });

    // محاكاة شريط التقدم أثناء الانتظار
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        if (_progressValue < 0.9) {
          _progressValue += 0.05; // زيادة تدريجية وهمية
        }
      });
    });

    try {
      // ✅ الحل الجذري: استخدام Set مع Merge لإنشاء الملف بالقوة
      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({
        'role': 'nurse',
        'status': 'pending_docs',
        'phone': _phone.text,
        'specialty': _specialty.text,
        'address': _address.text,
        'has_car': _hasCar,
        'docs_uploaded': true,
        'pic_data': _picBase64,
        'id_data': _idBase64, // يمكن أن يكون null عادي
        'diploma_data': _diplomaBase64, // يمكن أن يكون null عادي
      }, SetOptions(merge: true));

      // عند الانتهاء بنجاح
      _timer?.cancel();
      setState(() {
        _progressValue = 1.0; // 100%
      });
      
      await Future.delayed(const Duration(seconds: 1)); // انتظار لحظة لرؤية الـ 100%
      // الانتقال سيحدث تلقائياً عبر StreamBuilder

    } catch (e) {
      _timer?.cancel();
      setState(() {
        _isUploading = false;
        _progressValue = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل الرفع: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 100),
      child: Column(children: [
        const Text("تسجيل ممرض", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 20),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "الهاتف", border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _specialty, decoration: const InputDecoration(labelText: "التخصص", border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _address, decoration: const InputDecoration(labelText: "العنوان", border: OutlineInputBorder())),
        SwitchListTile(title: const Text("أملك سيارة"), value: _hasCar, onChanged: (v) => setState(() => _hasCar = v)),
        const SizedBox(height: 20),
        _btn("صورة شخصية", _picBase64 != null, () => _pickImage('pic')),
        _btn("بطاقة التعريف", _idBase64 != null, () => _pickImage('id')),
        _btn("صورة الدبلوم", _diplomaBase64 != null, () => _pickImage('diploma')),
        const SizedBox(height: 30),
        
        // زر الإرسال أو شريط التحميل
        if (_isUploading)
          Column(
            children: [
              LinearProgressIndicator(
                value: _progressValue,
                minHeight: 15,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 10),
              Text("${(_progressValue * 100).toInt()}% جاري رفع الملفات...", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          )
        else
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
            child: const Text("إرسال الطلب للمراجعة"),
          )
      ]),
    );
  }
  Widget _btn(String t, bool done, VoidCallback f) => OutlinedButton.icon(onPressed: f, icon: Icon(done ? Icons.check : Icons.upload), label: Text(t), style: OutlinedButton.styleFrom(foregroundColor: done ? Colors.green : Colors.grey));
}

// 7. شاشة الدفع (مع شريط التحميل أيضاً)
class NursePaymentScreen extends StatefulWidget {
  const NursePaymentScreen({super.key});
  @override
  State<NursePaymentScreen> createState() => _NursePaymentScreenState();
}
class _NursePaymentScreenState extends State<NursePaymentScreen> {
  String? _receiptBase64;
  bool _isUploading = false;
  double _progressValue = 0.0;
  Timer? _timer;

  Future<void> _pickReceipt() async {
     final ImagePicker picker = ImagePicker();
     final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 10, maxWidth: 400);
     if(image != null) {
       final bytes = await File(image.path).readAsBytes();
       setState(() => _receiptBase64 = base64Encode(bytes));
     }
  }

  Future<void> _submitPay() async {
     if(_receiptBase64 == null) { _pickReceipt(); return; }
     
     setState(() { _isUploading = true; _progressValue = 0.1; });
     _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
        setState(() { if(_progressValue < 0.9) _progressValue += 0.05; });
     });

     try {
        await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({
          'status': 'payment_review',
          'receipt_data': _receiptBase64 
        }, SetOptions(merge: true));
        
        _timer?.cancel();
        setState(() => _progressValue = 1.0);
     } catch(e) {
        _timer?.cancel();
        setState(() { _isUploading = false; _progressValue = 0.0; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل الإرسال"), backgroundColor: Colors.red));
     }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Text("اشتراك شهري: 3500 دج", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 20),
        const SelectableText("CCP: 0028939081 Clé 97\nName: Branis Yacine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
        const SizedBox(height: 30),
        
        if (_isUploading)
           Column(children: [
             LinearProgressIndicator(value: _progressValue, minHeight: 10, color: Colors.green),
             Text("${(_progressValue * 100).toInt()}%")
           ])
        else
          ElevatedButton.icon(
            onPressed: _submitPay,
            icon: Icon(_receiptBase64 != null ? Icons.check : Icons.camera_alt),
            label: Text(_receiptBase64 != null ? "تأكيد وإرسال" : "رفع وصل الدفع"),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          )
      ]),
    );
  }
}

// 8. لوحة الإدارة
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: Scaffold(
      appBar: AppBar(title: const Text("الإدارة"), backgroundColor: Colors.red[50], bottom: const TabBar(tabs: [Tab(text: "التوثيق"), Tab(text: "المدفوعات"), Tab(text: "الأسعار")])),
      body: const TabBarView(children: [AdminDocsReview(), AdminPaymentReview(), AdminPricesControl()]),
    ));
  }
}
class AdminDocsReview extends StatelessWidget {
  const AdminDocsReview({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'pending_docs').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد ملفات"));
        return ListView(children: snap.data!.docs.map((d) {
          var data = d.data() as Map<String, dynamic>;
          return Card(child: ListTile(
            title: Text(data['name'] ?? "ممرض"),
            subtitle: Text(data['phone'] ?? ""),
            trailing: ElevatedButton(onPressed: () => d.reference.update({'status': 'pending_payment'}), child: const Text("قبول")),
          ));
        }).toList());
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
        return ListView(children: snap.data!.docs.map((d) {
          var data = d.data() as Map<String, dynamic>;
          return Card(child: ListTile(
            title: Text(data['name'] ?? "ممرض"),
            subtitle: const Text("تم إرسال الوصل"),
            trailing: ElevatedButton(onPressed: () => d.reference.update({'status': 'approved'}), child: const Text("تفعيل")),
          ));
        }).toList());
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
  final _c1 = TextEditingController(); 
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text("تغيير سعر الحقن"),
      TextField(controller: _c1),
      ElevatedButton(onPressed: () {
        FirebaseFirestore.instance.collection('config').doc('prices').set({'حقن': _c1.text}, SetOptions(merge: true));
      }, child: const Text("حفظ"))
    ]);
  }
}

// 9. واجهة المريض
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("الخدمات"), bottom: const TabBar(tabs: [Tab(text: "طلب"), Tab(text: "طلباتي")])),
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
        return GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(20), crossAxisSpacing: 10, mainAxisSpacing: 10, children: [
          _item(context, "حقن", "${p['حقن'] ?? '800'} دج", Icons.vaccines, Colors.orange),
          _item(context, "سيروم", "${p['سيروم'] ?? '2500'} دج", Icons.water_drop, Colors.blue),
        ]);
      }
    );
  }
  Widget _item(BuildContext context, String t, String p, IconData i, Color c) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: t, price: p))), child: Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 40, color: c), Text(t), Text(p, style: const TextStyle(color: Colors.green))])));
}
class PatientMyOrders extends StatelessWidget {
  const PatientMyOrders({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('patient_id', isEqualTo: uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات"));
        var docs = snap.data!.docs;
        docs.sort((a, b) { // ترتيب محلي
           var t1 = a['timestamp'] as Timestamp?;
           var t2 = b['timestamp'] as Timestamp?;
           if (t1 == null || t2 == null) return 0;
           return t2.compareTo(t1); 
        });
        return ListView(children: docs.map((d) {
          var data = d.data() as Map<String, dynamic>;
          return Card(child: ListTile(title: Text(data['service']), subtitle: Text(data['status']), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: ()=> d.reference.delete())));
        }).toList());
      },
    );
  }
}

// 10. شاشة تأكيد الطلب
class OrderScreen extends StatefulWidget {
  final String title; final String price;
  const OrderScreen({super.key, required this.title, required this.price});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  final _phone = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد")),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Text("${widget.title} - ${widget.price}", style: const TextStyle(fontSize: 20)),
        TextField(controller: _phone, decoration: const InputDecoration(labelText: "رقم هاتفك")),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () {
          if(_phone.text.isNotEmpty) {
            FirebaseFirestore.instance.collection('requests').add({
              'service': widget.title, 'price': widget.price, 'phone': _phone.text, 
              'status': 'pending', 'timestamp': FieldValue.serverTimestamp(),
              'patient_id': FirebaseAuth.instance.currentUser?.uid,
              'patient_name': FirebaseAuth.instance.currentUser?.displayName
            });
            Navigator.pop(context);
          }
        }, child: const Text("تأكيد الطلب"))
      ])),
    );
  }
}

// 11. لوحة الممرض
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
      stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات"));
        return ListView(children: snap.data!.docs.map((d) {
          var data = d.data() as Map<String, dynamic>;
          return Card(child: ListTile(
            title: Text(data['patient_name'] ?? "مريض"),
            subtitle: Text("${data['service']} - ${data['price']}"),
            trailing: ElevatedButton(onPressed: () => d.reference.update({'status': 'accepted', 'nurse_id': FirebaseAuth.instance.currentUser?.uid}), child: const Text("قبول")),
          ));
        }).toList());
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
        return ListView(children: snap.data!.docs.map((d) {
          var data = d.data() as Map<String, dynamic>;
          return Card(child: ListTile(title: Text(data['patient_name'] ?? "مريض"), trailing: ElevatedButton(onPressed: () => d.reference.update({'status': 'completed'}), child: const Text("إنهاء"))));
        }).toList());
      },
    );
  }
}
