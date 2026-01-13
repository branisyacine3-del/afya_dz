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
import 'dart:convert'; // مكتبة تحويل الصور لنصوص

// 1. المفاتيح الأصلية (المشروع القديم afya-dz)
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
    // محاولة الاتصال التلقائي في حال وجود خطأ
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

// 2. شاشة البداية (تصميمك الأصلي + فحص النت)
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
    _checkInternetAndProceed();
  }

  Future<void> _checkInternetAndProceed() async {
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
      return Scaffold(
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          const Text("لا يوجد اتصال بالإنترنت", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: (){setState(() => _hasInternet = true); _checkInternetAndProceed();}, child: const Text("إعادة المحاولة"))
        ])),
      );
    }

    // التصميم الأصلي تماماً
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
          // أعدنا الجملة المفقودة هنا 👇
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
      UserCredential uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(uc.user!.uid).set({
        'email': _email.text.trim(),
        'role': 'user', 
        'status': 'active', 
        'name': 'مستخدم جديد'
      });
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
    User? user = FirebaseAuth.instance.currentUser;
    await user?.updateDisplayName(_nameController.text);
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'name': _nameController.text});
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
            const SizedBox(height: 40),
            
            if (isAdmin) 
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
                  icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                  label: const Text("لوحة الإدارة (Admin)", style: TextStyle(color: Colors.white, fontSize: 18)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
                ),
              ),

            _mainBtn(context, "أنا مريض", "أطلب خدمة طبية الآن", Icons.medical_services_outlined, const Color(0xFF00897B), const PatientHomeScreen()),
            const SizedBox(height: 20),
            _mainBtn(context, "أنا ممرض", "لوحة التحكم والطلبات", Icons.assignment_ind_outlined, const Color(0xFF039BE5), const NurseAuthGate()),
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

// 5. بوابة الممرض
class NurseAuthGate extends StatelessWidget {
  const NurseAuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text("التحقق من الممرض")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          
          var data = snap.data!.data() as Map<String, dynamic>?;
          String status = data != null && data.containsKey('status') ? data['status'] : 'user';
          String role = data != null && data.containsKey('role') ? data['role'] : 'user';

          if (role == 'user') return const NurseRegistrationForm();

          if (status == 'pending_docs') {
            return _statusScreen(Icons.hourglass_top, Colors.orange, "وثائقك قيد المراجعة", "يقوم المدير ياسين بمراجعة ملفك حالياً.");
          } else if (status == 'pending_payment') {
            return const NursePaymentScreen(); 
          } else if (status == 'payment_review') {
             return _statusScreen(Icons.payments, Colors.blue, "جاري التحقق من الدفع", "شكراً لك. سيتم تفعيل حسابك فور تأكيد استلام المبلغ.");
          } else if (status == 'approved') {
            return const NurseDashboard(); 
          } else {
            return const NurseRegistrationForm();
          }
        },
      ),
    );
  }

  Widget _statusScreen(IconData i, Color c, String t, String s) => Padding(
    padding: const EdgeInsets.all(30),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, size: 80, color: c),
          const SizedBox(height: 20),
          Text(t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(s, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    ),
  );
}

// *** 6. استمارة الممرض (بدون Storage - Base64) ***
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
  
  // سنحفظ الصور كـ Base64 Strings هنا
  String? _picBase64;
  String? _idBase64;
  String? _diplomaBase64;
  
  bool _isSubmitting = false;

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    // ⚠️ تقليل الجودة ضروري جداً للحفظ في قاعدة البيانات مباشرة
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20, maxWidth: 600);
    
    if (image != null) {
      // قراءة الصورة وتحويلها لنص
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى ملء البيانات ورفع الصور"), backgroundColor: Colors.red));
      return;
    }
    
    setState(() => _isSubmitting = true);

    // الحفظ في Firestore مباشرة (بدون Storage)
    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({
      'role': 'nurse',
      'status': 'pending_docs',
      'phone': _phone.text,
      'specialty': _specialty.text,
      'address': _address.text,
      'has_car': _hasCar,
      'docs_uploaded': true,
      // حفظ الصور كنصوص
      'pic_data': _picBase64,
      'id_data': _idBase64,
      'diploma_data': _diplomaBase64,
    });
    // الشاشة ستتغير تلقائياً
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 100), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("تسجيل ممرض جديد", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
          const SizedBox(height: 10),
          const Text("للانضمام لفريق عافية، يرجى ملء البيانات بدقة ورفع الوثائق.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "رقم الهاتف", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _specialty, decoration: const InputDecoration(labelText: "التخصص (مثال: ممرض دولة، تخدير...)", prefixIcon: Icon(Icons.badge), border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _address, decoration: const InputDecoration(labelText: "العنوان (الولاية والبلدية)", prefixIcon: Icon(Icons.map), border: OutlineInputBorder())),
          const SizedBox(height: 15),
          SwitchListTile(title: const Text("هل تمتلك سيارة للتنقل؟"), value: _hasCar, onChanged: (v) => setState(() => _hasCar = v)),
          const SizedBox(height: 30),
          const Text("الوثائق المطلوبة (صور)", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          _uploadBtn("صورة شخصية", _picBase64 != null, () => _pickImage('pic')),
          _uploadBtn("بطاقة التعريف", _idBase64 != null, () => _pickImage('id')),
          _uploadBtn("صورة الدبلوم", _diplomaBase64 != null, () => _pickImage('diploma')),
          
          const SizedBox(height: 30),
          
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit, 
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)), 
            child: _isSubmitting 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Text("إرسال الطلب للمراجعة")
          )
        ],
      ),
    );
  }
  
  Widget _uploadBtn(String t, bool isDone, VoidCallback onTap) => Container(
    margin: const EdgeInsets.only(bottom: 10), 
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onTap, 
      icon: Icon(isDone ? Icons.check_circle : Icons.upload_file, color: isDone ? Colors.green : Colors.grey), 
      label: Text(isDone ? "$t (تم التجهيز)" : "رفع $t (اضغط هنا)", style: TextStyle(color: isDone ? Colors.green : Colors.black)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: isDone ? Colors.green : Colors.grey)),
    )
  );
}

// *** 7. شاشة الدفع (Base64) ***
class NursePaymentScreen extends StatefulWidget {
  const NursePaymentScreen({super.key});
  @override
  State<NursePaymentScreen> createState() => _NursePaymentScreenState();
}
class _NursePaymentScreenState extends State<NursePaymentScreen> {
  String? _receiptBase64;
  bool _submitting = false;

  Future<void> _pickReceipt() async {
     final ImagePicker picker = ImagePicker();
     final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20, maxWidth: 600);
     if(image != null) {
       final bytes = await File(image.path).readAsBytes();
       setState(() => _receiptBase64 = base64Encode(bytes));
     }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.monetization_on, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text("تفعيل الحساب", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("تم قبول وثائقك بنجاح! ✅\nللبدء في العمل، يرجى دفع اشتراك الشهر الأول.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          const SizedBox(height: 30),
          Card(
            color: Colors.yellow[50],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("مبلغ الاشتراك الشهري", style: TextStyle(color: Colors.grey)),
                  const Text("3500 دج", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                  const Text("+ 3 أيام مجانية كهدية ترحيبية 🎁", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _rowCopy("CCP", "0028939081"),
                  _rowCopy("Clé", "97"),
                  _rowCopy("الاسم", "Branis Yacine"),
                  const Divider(),
                  _rowCopy("RIP", "00799999002893908197"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _submitting ? null : () async {
              if(_receiptBase64 == null) { _pickReceipt(); return; }
              setState(() => _submitting = true);
              await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({
                'status': 'payment_review', 
                'receipt_data': _receiptBase64 
              });
            },
            icon: Icon(_receiptBase64 != null ? Icons.check : Icons.camera_alt),
            label: _submitting ? const CircularProgressIndicator() : Text(_receiptBase64 != null ? "تأكيد الإرسال" : "رفع صورة وصل الدفع"),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: _receiptBase64 != null ? Colors.green : null),
          )
        ],
      ),
    );
  }
  Widget _rowCopy(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(fontWeight: FontWeight.bold)), Row(children: [Text(v, style: const TextStyle(fontFamily: 'monospace')), IconButton(icon: const Icon(Icons.copy, size: 15), onPressed: () => Clipboard.setData(ClipboardData(text: v)))])]),
  );
}

// *** 8. لوحة الإدارة ***
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(title: const Text("الإدارة"), backgroundColor: Colors.red[50], bottom: const TabBar(isScrollable: true, tabs: [Tab(text: "توثيق الحسابات"), Tab(text: "مراجعة الدفع"), Tab(text: "تغيير الأسعار")])),
        body: const TabBarView(children: [AdminDocsReview(), AdminPaymentReview(), AdminPricesControl()]),
      ),
    );
  }
}

class AdminPricesControl extends StatefulWidget {
  const AdminPricesControl({super.key});
  @override
  State<AdminPricesControl> createState() => _AdminPricesControlState();
}
class _AdminPricesControlState extends State<AdminPricesControl> {
  final Map<String, TextEditingController> _controllers = {
    'حقن': TextEditingController(),
    'سيروم': TextEditingController(),
    'تغيير ضماد': TextEditingController(),
    'قياس ضغط': TextEditingController(),
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('config').doc('prices').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var data = snap.data!.data() as Map<String, dynamic>? ?? {};

        if (_controllers['حقن']!.text.isEmpty) _controllers['حقن']!.text = data['حقن'] ?? '800';
        if (_controllers['سيروم']!.text.isEmpty) _controllers['سيروم']!.text = data['سيروم'] ?? '2500';
        if (_controllers['تغيير ضماد']!.text.isEmpty) _controllers['تغيير ضماد']!.text = data['تغيير ضماد'] ?? '1200';
        if (_controllers['قياس ضغط']!.text.isEmpty) _controllers['قياس ضغط']!.text = data['قياس ضغط'] ?? '500';

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text("تعديل أسعار الخدمات (بالدينار)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ..._controllers.keys.map((key) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: TextField(
                controller: _controllers[key],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: key, suffixText: "دج", border: const OutlineInputBorder()),
              ),
            )),
            ElevatedButton.icon(
              onPressed: () {
                FirebaseFirestore.instance.collection('config').doc('prices').set({
                  'حقن': _controllers['حقن']!.text,
                  'سيروم': _controllers['سيروم']!.text,
                  'تغيير ضماد': _controllers['تغيير ضماد']!.text,
                  'قياس ضغط': _controllers['قياس ضغط']!.text,
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث الأسعار بنجاح!"), backgroundColor: Colors.green));
              },
              icon: const Icon(Icons.save),
              label: const Text("حفظ الأسعار الجديدة"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            )
          ],
        );
      },
    );
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
        return ListView(padding: const EdgeInsets.all(10), children: snap.data!.docs.map((d) {
          var data = d.data() as Map<String, dynamic>;
          return Card(child: ListTile(
            title: Text(data['name'] ?? "ممرض"),
            subtitle: Text("${data['specialty']} - ${data['phone']}"),
            trailing: ElevatedButton(
              onPressed: () => d.reference.update({'status': 'pending_payment'}), 
              child: const Text("قبول الوثائق"),
            ),
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد مدفوعات للمراجعة"));
        return ListView(padding: const EdgeInsets.all(10), children: snap.data!.docs.map((d) {
          var data = d.data() as Map<String, dynamic>;
          return Card(child: ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.green),
            title: Text(data['name'] ?? "ممرض"),
            subtitle: const Text("أرسل وصل الدفع"),
            trailing: ElevatedButton(
              onPressed: () => d.reference.update({'status': 'approved'}), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("تفعيل الحساب"),
            ),
          ));
        }).toList());
      },
    );
  }
}

// 9. واجهة المريض
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('config').doc('prices').snapshots(),
      builder: (context, snap) {
        var p = snap.data?.data() as Map<String, dynamic>? ?? {}; 
        
        return GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(20), crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.9, children: [
          _item(context, "حقن", "${p['حقن'] ?? '800'} دج", Icons.vaccines, Colors.orange),
          _item(context, "سيروم", "${p['سيروم'] ?? '2500'} دج", Icons.water_drop, Colors.blue),
          _item(context, "تغيير ضماد", "${p['تغيير ضماد'] ?? '1200'} دج", Icons.healing, Colors.purple),
          _item(context, "قياس ضغط", "${p['قياس ضغط'] ?? '500'} دج", Icons.monitor_heart, Colors.red),
          InkWell(onTap: () => _custom(context), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle, size: 45, color: Colors.grey[400]), const SizedBox(height: 10), Text("طلب خدمة أخرى", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold))]))),
        ]);
      }
    );
  }
  
  void _custom(BuildContext context) {
    final c = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text("اكتب طلبك"), content: TextField(controller: c, decoration: const InputDecoration(hintText: "مثال: تغيير ضماد...")), actions: [ElevatedButton(onPressed: () {Navigator.pop(context); if(c.text.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: c.text, price: "حسب الاتفاق")));}, child: const Text("متابعة"))]));
  }
  
  Widget _item(BuildContext context, String t, String p, IconData i, Color c) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: t, price: p))), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(i, size: 32, color: c)), const SizedBox(height: 15), Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), const SizedBox(height: 5), Text(p, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))])));
}

// إصلاح قائمة المريض (بدون فهرسة معقدة)
class PatientMyOrders extends StatelessWidget {
  const PatientMyOrders({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      // أزلنا orderBy لحل مشكلة الفهرسة
      stream: FirebaseFirestore.instance.collection('requests').where('patient_id', isEqualTo: uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات سابقة"));
        
        // نقوم بالترتيب هنا في الهاتف بدلاً من السيرفر
        var docs = snap.data!.docs;
        docs.sort((a, b) {
           var t1 = a['timestamp'] as Timestamp?;
           var t2 = b['timestamp'] as Timestamp?;
           if (t1 == null || t2 == null) return 0;
           return t2.compareTo(t1); 
        });

        return ListView(padding: const EdgeInsets.all(15), children: docs.map((d) {
          var data = d.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'pending';
          
          if (status == 'pending') {
            return Card(color: Colors.orange[50], child: ListTile(title: Text(data['service']), subtitle: const Text("جارٍ البحث عن ممرض..."), leading: const CircularProgressIndicator(), trailing: IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: ()=> d.reference.delete())));
          } else {
            String nurseName = data['nurse_name'] ?? "ممرض";
            bool isCompleted = status == 'completed';
            return Card(
              color: isCompleted ? Colors.grey[100] : Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(children: [
                      Icon(isCompleted ? Icons.check_circle : Icons.run_circle, size: 40, color: isCompleted ? Colors.green : Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isCompleted ? "اكتملت الخدمة" : "الممرض $nurseName قادم", style: const TextStyle(fontWeight: FontWeight.bold)), Text(data['service'])])),
                    ]),
                    if (!isCompleted) 
                      TextButton.icon(
                        onPressed: () => d.reference.update({'status': 'completed'}), 
                        icon: const Icon(Icons.check), 
                        label: const Text("اضغط هنا عند استلام الخدمة")
                      )
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

// 10. شاشة تأكيد الطلب
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

  Future<void> _loc() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      Position pos = await Geolocator.getCurrentPosition();
      setState(() { _lat = pos.latitude; _lng = pos.longitude; _locSuccess = true; });
    } catch (e) { /* */ }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد الطلب")),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [Container(padding: const EdgeInsets.all(20), width: double.infinity, decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(15)), child: Column(children: [Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)), Text(widget.price, style: const TextStyle(fontSize: 18, color: Colors.green))])), const SizedBox(height: 30), TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "رقم الهاتف", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())), const SizedBox(height: 20), InkWell(onTap: _loc, child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _locSuccess ? Colors.green[50] : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: _locSuccess ? Colors.green : Colors.grey.shade300)), child: Row(children: [Icon(Icons.location_on, color: _locSuccess ? Colors.green : Colors.grey), const SizedBox(width: 15), Expanded(child: Text(_locSuccess ? "تم تحديد الموقع" : "اضغط لتحديد الموقع"))]))), const SizedBox(height: 40), ElevatedButton(onPressed: () { if(_lat != null && _phone.text.isNotEmpty) { FirebaseFirestore.instance.collection('requests').add({'service': widget.title, 'price': widget.price, 'phone': _phone.text, 'lat': _lat, 'lng': _lng, 'status': 'pending', 'timestamp': FieldValue.serverTimestamp(), 'patient_id': FirebaseAuth.instance.currentUser?.uid, 'patient_name': FirebaseAuth.instance.currentUser?.displayName ?? 'مريض'}); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الإرسال"), backgroundColor: Colors.green)); } }, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)), child: const Text("تأكيد الطلب"))])),
    );
  }
}

// 11. لوحة الممرض
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات جديدة حالياً"));
        return ListView.builder(padding: const EdgeInsets.all(15), itemCount: snap.data!.docs.length, itemBuilder: (context, index) {
          var d = snap.data!.docs[index];
          var data = d.data() as Map<String, dynamic>;
          return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Row(children: [const CircleAvatar(child: Icon(Icons.person)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['patient_name'] ?? 'مريض', style: const TextStyle(fontWeight: FontWeight.bold)), Text("يحتاج: ${data['service']}")] ))]), const SizedBox(height: 15), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(data['price'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), ElevatedButton(onPressed: () => d.reference.update({'status': 'accepted', 'nurse_id': FirebaseAuth.instance.currentUser?.uid, 'nurse_name': FirebaseAuth.instance.currentUser?.displayName}), child: const Text("قبول الطلب"))])])));
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("ليس لديك مهام جارية"));
        return ListView.builder(padding: const EdgeInsets.all(15), itemCount: snap.data!.docs.length, itemBuilder: (context, index) {
          var d = snap.data!.docs[index];
          var data = d.data() as Map<String, dynamic>;
          return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text("المريض: ${data['patient_name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(), Row(children: [Expanded(child: ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse("tel:${data['phone']}")), icon: const Icon(Icons.phone), label: const Text("اتصال"))), const SizedBox(width: 10), Expanded(child: ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${data['lat']},${data['lng']}")), icon: const Icon(Icons.location_on), label: const Text("الموقع")))]), const SizedBox(height: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black), onPressed: () => d.reference.update({'status': 'completed'}), child: const Text("✔ إنهاء المهمة (قبضت الثمن)"))])));
        });
      },
    );
  }
}
