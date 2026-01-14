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

// ---------------------------------------------------------------------------
// 1. إعدادات فايربيس (تعمل على مشروعك القديم afya-dz)
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
        fontFamily: 'Roboto', // يمكنك تغيير الخط إذا أردت
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // خلفية رمادية فاتحة جداً ومريحة
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688), // اللون الأساسي (Teal)
          primary: const Color(0xFF009688),
          secondary: const Color(0xFF26A69A),
          surface: Colors.white,
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
            elevation: 3,
            shadowColor: const Color(0xFF009688).withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF009688), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. شاشة البداية (تصميم أنيق)
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    _checkInternet();
  }

  Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        Timer(const Duration(seconds: 4), () {
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) {
      return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.wifi_off, size: 80, color: Colors.red), const SizedBox(height: 20), const Text("لا يوجد إنترنت", style: TextStyle(fontSize: 18)), const SizedBox(height: 20), ElevatedButton(onPressed: (){setState(() => _hasInternet = true); _checkInternet();}, child: const Text("إعادة المحاولة"))])));
    }
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
                child: const Icon(Icons.health_and_safety_rounded, size: 100, color: Colors.white),
              ),
              const SizedBox(height: 30),
              const Text("عافية", style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 10),
              const Text("رعايتك في منزلك", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w300)),
              const SizedBox(height: 50),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. شاشة الدخول (تصميم مودرن)
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: ${e.toString().contains('email') ? 'البريد غير صحيح' : 'كلمة المرور خطأ'}"), backgroundColor: Colors.red));
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_person_rounded, size: 80, color: Color(0xFF009688)),
              const SizedBox(height: 20),
              const Text("مرحباً بك", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
              const SizedBox(height: 10),
              const Text("سجل الدخول للمتابعة", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(controller: _email, decoration: const InputDecoration(labelText: "البريد الإلكتروني", prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 20),
              TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "كلمة المرور", prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 30),
              _loading 
                ? const Center(child: CircularProgressIndicator()) 
                : ElevatedButton(onPressed: () => _auth(false), child: const Text("تسجيل الدخول")),
              const SizedBox(height: 15),
              TextButton(onPressed: () => _auth(true), child: const Text("ليس لديك حساب؟ إنشاء حساب جديد", style: TextStyle(fontSize: 16)))
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
    User? user = FirebaseAuth.instance.currentUser;
    await user?.updateDisplayName(_nameController.text);
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({'name': _nameController.text}, SetOptions(merge: true));
    if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إكمال البيانات")),
      body: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("ما هو اسمك الحقيقي؟", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: "الاسم واللقب", prefixIcon: Icon(Icons.person))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveName, child: const Text("حفظ وبدء الاستخدام")))
      ])),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. الشاشة الرئيسية (لوحة التحكم)
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
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red), 
            onPressed: () async { await FirebaseAuth.instance.signOut(); if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); }
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF009688), Color(0xFF80CBC4)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF009688).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
              ),
              child: Row(children: [
                const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, size: 35, color: Color(0xFF009688))),
                const SizedBox(width: 15),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("مرحباً بك،", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(user?.displayName ?? "يا بطل", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
              ]),
            ),
            const SizedBox(height: 40),
            
            if (isAdmin) 
              _menuCard(context, "لوحة الإدارة", "مراجعة الطلبات والوثائق", Icons.admin_panel_settings, Colors.red[800]!, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()))),
            
            _menuCard(context, "أنا مريض", "أبحث عن ممرض الآن", Icons.medical_services_outlined, const Color(0xFF009688), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientHomeScreen()))),
            _menuCard(context, "أنا ممرض", "الدخول للوحة المهام", Icons.assignment_ind_outlined, const Color(0xFF1976D2), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseAuthGate()))),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color, size: 32)),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 5), Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 13))]),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 18),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. بوابة الممرض (التحقق الذكي)
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
          if (status == 'pending_docs') return _msg(Icons.hourglass_top, Colors.orange, "ملفك قيد المراجعة", "يقوم المدير ياسين بمراجعة الوثائق.");
          if (status == 'pending_payment') return const NursePaymentScreen();
          if (status == 'payment_review') return _msg(Icons.payments, Colors.blue, "مراجعة الدفع", "جاري التحقق من الوصل، يرجى الانتظار.");
          if (status == 'approved') return const NurseDashboard();
          return const NurseRegistrationForm();
        },
      ),
    );
  }
  Widget _msg(IconData i, Color c, String t, String s) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 100, color: c), const SizedBox(height: 20), Text(t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(s, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey))])));
}

// ---------------------------------------------------------------------------
// 6. استمارة الممرض (النسخة الجميلة والمحسنة)
// ---------------------------------------------------------------------------
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
  
  bool _isUploading = false;
  double _progressValue = 0.0;
  Timer? _timer;

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    // ⚠️ ضغط قوي للصور (Quality 10) لتمريرها كبيانات
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 10, maxWidth: 400);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        String s = base64Encode(bytes);
        if (type == 'pic') _picBase64 = s;
        if (type == 'id') _idBase64 = s;
        if (type == 'diploma') _diplomaBase64 = s;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم اختيار الصورة بنجاح ✅"), backgroundColor: Colors.green));
    }
  }

  Future<void> _submit() async {
    if (_phone.text.isEmpty || _specialty.text.isEmpty || _picBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى ملء البيانات ورفع صورة شخصية"), backgroundColor: Colors.red));
      return;
    }
    setState(() { _isUploading = true; _progressValue = 0.1; });

    // محاكاة التحميل
    _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      setState(() { if (_progressValue < 0.9) _progressValue += 0.05; });
    });

    try {
      // ✅ استخدام SetOption(merge: true) لضمان الكتابة
      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({
        'role': 'nurse',
        'status': 'pending_docs',
        'phone': _phone.text,
        'specialty': _specialty.text,
        'address': _address.text,
        'has_car': _hasCar,
        'docs_uploaded': true,
        'pic_data': _picBase64,
        'id_data': _idBase64,
        'diploma_data': _diplomaBase64,
      }, SetOptions(merge: true));

      _timer?.cancel();
      setState(() => _progressValue = 1.0);
    } catch (e) {
      _timer?.cancel();
      setState(() { _isUploading = false; _progressValue = 0.0; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ملف التوظيف", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
          const Text("انضم لفريق عافية الآن", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "رقم الهاتف", prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 15),
          TextField(controller: _specialty, decoration: const InputDecoration(labelText: "التخصص (مثال: ممرض دولة)", prefixIcon: Icon(Icons.work))),
          const SizedBox(height: 15),
          TextField(controller: _address, decoration: const InputDecoration(labelText: "العنوان (الولاية)", prefixIcon: Icon(Icons.map))),
          const SizedBox(height: 15),
          SwitchListTile(title: const Text("أملك سيارة خاصة"), value: _hasCar, onChanged: (v) => setState(() => _hasCar = v), activeColor: const Color(0xFF009688)),
          const SizedBox(height: 30),
          const Text("الوثائق المطلوبة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _uploadCard("صورة شخصية", _picBase64 != null, () => _pickImage('pic')),
          _uploadCard("بطاقة التعريف", _idBase64 != null, () => _pickImage('id')),
          _uploadCard("صورة الدبلوم", _diplomaBase64 != null, () => _pickImage('diploma')),
          const SizedBox(height: 30),
          
          if (_isUploading)
            Column(children: [
              LinearProgressIndicator(value: _progressValue, minHeight: 15, borderRadius: BorderRadius.circular(10), color: const Color(0xFF009688), backgroundColor: Colors.grey[200]),
              const SizedBox(height: 10),
              Text("${(_progressValue * 100).toInt()}% جاري معالجة الملف...", style: const TextStyle(fontWeight: FontWeight.bold))
            ])
          else
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submit, child: const Text("إرسال الملف للمراجعة"))),
        ],
      ),
    );
  }

  Widget _uploadCard(String title, bool done, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: done ? const Color(0xFFE0F2F1) : Colors.white,
          border: Border.all(color: done ? const Color(0xFF009688) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(15)
        ),
        child: Row(children: [
          Icon(done ? Icons.check_circle : Icons.cloud_upload_outlined, color: done ? const Color(0xFF009688) : Colors.grey),
          const SizedBox(width: 15),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: done ? const Color(0xFF009688) : Colors.black)),
          const Spacer(),
          if(done) const Text("تم", style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold))
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. شاشة الدفع (تصميم مالي)
// ---------------------------------------------------------------------------
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
     _timer = Timer.periodic(const Duration(milliseconds: 200), (t) { setState(() { if(_progressValue < 0.9) _progressValue += 0.05; }); });
     try {
        await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({'status': 'payment_review', 'receipt_data': _receiptBase64}, SetOptions(merge: true));
        _timer?.cancel();
        setState(() => _progressValue = 1.0);
     } catch(e) {
        _timer?.cancel();
        setState(() { _isUploading = false; _progressValue = 0.0; });
     }
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Icon(Icons.verified_user_outlined, size: 80, color: Color(0xFF009688)),
        const SizedBox(height: 20),
        const Text("تهانينا! تم قبولك", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text("لتفعيل حسابك، يرجى دفع الاشتراك", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade200)),
          child: Column(children: [
            const Text("الاشتراك الشهري", style: TextStyle(color: Colors.orange)),
            const Text("3500 دج", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
            const Divider(),
            _infoRow("CCP", "0028939081"),
            _infoRow("Clé", "97"),
            _infoRow("الاسم", "Branis Yacine"),
          ]),
        ),
        const SizedBox(height: 30),
        if (_isUploading)
           LinearProgressIndicator(value: _progressValue, minHeight: 10, color: const Color(0xFF009688))
        else
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _submitPay, icon: Icon(_receiptBase64 != null ? Icons.check : Icons.camera_alt), label: Text(_receiptBase64 != null ? "تأكيد وإرسال" : "رفع الوصل")))
      ]),
    );
  }
  Widget _infoRow(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'))]));
}

// ---------------------------------------------------------------------------
// 8. لوحة الإدارة (مع عرض الصور)
// ---------------------------------------------------------------------------
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: Scaffold(
      appBar: AppBar(title: const Text("لوحة الإدارة"), bottom: const TabBar(labelColor: Color(0xFF009688), indicatorColor: Color(0xFF009688), tabs: [Tab(text: "التوثيق"), Tab(text: "المدفوعات"), Tab(text: "الأسعار")])),
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد ملفات للمراجعة"));
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, index) {
            var d = snap.data!.docs[index];
            var data = d.data() as Map<String, dynamic>;
            String? pic = data['pic_data'];
            String? idCard = data['id_data'];
            String? diploma = data['diploma_data'];

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              child: ExpansionTile(
                leading: CircleAvatar(backgroundImage: pic != null ? MemoryImage(base64Decode(pic)) : null, child: pic == null ? const Icon(Icons.person) : null),
                title: Text(data['name'] ?? "ممرض"),
                subtitle: Text("تخصص: ${data['specialty'] ?? ''}"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (idCard != null) ...[const Text("بطاقة التعريف:", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 5), Image.memory(base64Decode(idCard), height: 150, width: double.infinity, fit: BoxFit.cover), const SizedBox(height: 15)],
                      if (diploma != null) ...[const Text("الدبلوم:", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 5), Image.memory(base64Decode(diploma), height: 150, width: double.infinity, fit: BoxFit.cover), const SizedBox(height: 15)],
                      ElevatedButton(onPressed: () => d.reference.update({'status': 'pending_payment'}), child: const Text("قبول الوثائق ✅"))
                    ]),
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

class AdminPaymentReview extends StatelessWidget {
  const AdminPaymentReview({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'payment_review').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد مدفوعات"));
        return ListView.builder(itemCount: snap.data!.docs.length, padding: const EdgeInsets.all(15), itemBuilder: (ctx, i) {
          var d = snap.data!.docs[i];
          var data = d.data() as Map<String, dynamic>;
          String? receipt = data['receipt_data'];
          return Card(
            child: ExpansionTile(
              title: Text(data['name'] ?? "ممرض"),
              subtitle: const Text("دفع الاشتراك"),
              children: [
                if(receipt != null) Padding(padding: const EdgeInsets.all(10), child: Image.memory(base64Decode(receipt), height: 200, fit: BoxFit.contain)),
                Padding(padding: const EdgeInsets.all(10), child: ElevatedButton(onPressed: () => d.reference.update({'status': 'approved'}), child: const Text("تفعيل الحساب نهائياً 🚀")))
              ],
            ),
          );
        });
      },
    );
  }
}

class AdminPricesControl extends StatelessWidget {
  const AdminPricesControl({super.key});
  @override
  Widget build(BuildContext context) {
    final c1 = TextEditingController();
    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      const Text("تعديل الأسعار", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      TextField(controller: c1, decoration: const InputDecoration(labelText: "سعر الحقن (دج)")),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () => FirebaseFirestore.instance.collection('config').doc('prices').set({'حقن': c1.text}, SetOptions(merge: true)), child: const Text("حفظ"))
    ]));
  }
}

// ---------------------------------------------------------------------------
// 9. واجهة المريض (تصميم البطاقات)
// ---------------------------------------------------------------------------
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("الخدمات الطبية"), bottom: const TabBar(labelColor: Color(0xFF009688), indicatorColor: Color(0xFF009688), tabs: [Tab(text: "طلب جديد"), Tab(text: "طلباتي")])),
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
        return GridView.count(
          crossAxisCount: 2, padding: const EdgeInsets.all(20), crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.9,
          children: [
            _srvCard(context, "حقن", "${p['حقن'] ?? '800'} دج", Icons.vaccines, Colors.orange),
            _srvCard(context, "سيروم", "${p['سيروم'] ?? '2500'} دج", Icons.water_drop, Colors.blue),
            _srvCard(context, "تغيير ضماد", "1200 دج", Icons.healing, Colors.purple),
            _srvCard(context, "قياس ضغط", "500 دج", Icons.monitor_heart, Colors.red),
          ],
        );
      }
    );
  }
  Widget _srvCard(BuildContext ctx, String t, String p, IconData i, Color c) => InkWell(
    onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => OrderScreen(title: t, price: p))),
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(radius: 30, backgroundColor: c.withOpacity(0.1), child: Icon(i, color: c, size: 30)),
        const SizedBox(height: 15),
        Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 5),
        Text(p, style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold))
      ]),
    ),
  );
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
        return ListView.builder(itemCount: snap.data!.docs.length, padding: const EdgeInsets.all(15), itemBuilder: (ctx, i) {
          var d = snap.data!.docs[i];
          var data = d.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'pending';
          return Card(
            color: status == 'completed' ? Colors.grey[50] : Colors.white,
            child: ListTile(
              leading: Icon(status == 'completed' ? Icons.check_circle : Icons.watch_later, color: status == 'completed' ? Colors.green : Colors.orange),
              title: Text(data['service']),
              subtitle: Text(status == 'pending' ? "جاري البحث عن ممرض..." : "تم القبول/الإنجاز"),
              trailing: status == 'pending' ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: ()=> d.reference.delete()) : null,
            ),
          );
        });
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 10. شاشة تأكيد الطلب
// ---------------------------------------------------------------------------
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
      appBar: AppBar(title: const Text("تأكيد الطلب")),
      body: Padding(padding: const EdgeInsets.all(25), child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20), width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(15)),
          child: Column(children: [
            Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
            Text(widget.price, style: const TextStyle(fontSize: 20)),
          ]),
        ),
        const SizedBox(height: 30),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "رقم هاتفك للتواصل", prefixIcon: Icon(Icons.phone))),
        const Spacer(),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {
          if(_phone.text.isNotEmpty) {
            FirebaseFirestore.instance.collection('requests').add({
              'service': widget.title, 'price': widget.price, 'phone': _phone.text, 
              'status': 'pending', 'timestamp': FieldValue.serverTimestamp(),
              'patient_id': FirebaseAuth.instance.currentUser?.uid,
              'patient_name': FirebaseAuth.instance.currentUser?.displayName
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال الطلب بنجاح"), backgroundColor: Colors.green));
          }
        }, child: const Text("تأكيد وحجز الآن")))
      ])),
    );
  }
}

// ---------------------------------------------------------------------------
// 11. لوحة الممرض (المهام)
// ---------------------------------------------------------------------------
class NurseDashboard extends StatelessWidget {
  const NurseDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("مهامي"), bottom: const TabBar(labelColor: Color(0xFF009688), indicatorColor: Color(0xFF009688), tabs: [Tab(text: "طلبات جديدة"), Tab(text: "قيد التنفيذ")])),
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات في الانتظار"));
        return ListView.builder(itemCount: snap.data!.docs.length, padding: const EdgeInsets.all(15), itemBuilder: (ctx, i) {
          var d = snap.data!.docs[i];
          var data = d.data() as Map<String, dynamic>;
          return Card(child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
            title: Text(data['patient_name'] ?? "مريض"),
            subtitle: Text("${data['service']} - ${data['price']}"),
            trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688), padding: const EdgeInsets.symmetric(horizontal: 10)), onPressed: () => d.reference.update({'status': 'accepted', 'nurse_id': FirebaseAuth.instance.currentUser?.uid}), child: const Text("قبول", style: TextStyle(fontSize: 14))),
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("ليس لديك مهام حالياً"));
        return ListView.builder(itemCount: snap.data!.docs.length, padding: const EdgeInsets.all(15), itemBuilder: (ctx, i) {
          var d = snap.data!.docs[i];
          var data = d.data() as Map<String, dynamic>;
          return Card(child: Column(children: [
            ListTile(title: Text("المريض: ${data['patient_name']}"), subtitle: Text("الهاتف: ${data['phone']}"), leading: const Icon(Icons.run_circle, color: Colors.blue, size: 40)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              IconButton(onPressed: () => launchUrl(Uri.parse("tel:${data['phone']}")), icon: const Icon(Icons.call, color: Colors.green)),
              ElevatedButton(onPressed: () => d.reference.update({'status': 'completed'}), style: ElevatedButton.styleFrom(backgroundColor: Colors.black), child: const Text("إنهاء الخدمة"))
            ]),
            const SizedBox(height: 10)
          ]));
        });
      },
    );
  }
}
