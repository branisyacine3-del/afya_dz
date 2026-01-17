import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// مكتبات التاريخ والوقت وتنسيق الأرقام ستلزمنا لاحقاً
import 'package:intl/intl.dart'; 

// ==========================================
// 🚀 AFYA PRO - (PART 1: CORE ENGINE)
// ==========================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. محاولة الاتصال بفايربيز بذكاء (Try/Catch) لتجنب الشاشة البيضاء
  try {
    await Firebase.initializeApp();
    print("✅ SYSTEM: Firebase Connected Successfully.");
  } catch (e) {
    print("❌ SYSTEM ERROR: Firebase Failed: $e");
  }

  runApp(const AfyaApp());
}

// 🎨 ثيمات التطبيق العالمية (Global Theme)
// تغيير لون هنا يغيره في التطبيق كله
class AppColors {
  static const Color primary = Color(0xFF009688); // Teal (الرئيسي)
  static const Color primaryDark = Color(0xFF00796B); 
  static const Color accent = Color(0xFFFF9800); // البرتقالي (للأزرار المهمة)
  static const Color bg = Color(0xFFF5F7FA); // خلفية رمادية فاتحة مريحة للعين
  static const Color textMain = Color(0xFF2D3436);
  static const Color success = Color(0xFF00B894); // أخضر النجاح
  static const Color error = Color(0xFFD63031); // أحمر الخطأ
}

// 📱 التطبيق الرئيسي
class AfyaApp extends StatelessWidget {
  const AfyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // إخفاء شريط Debug
      title: 'Afya Pro',
      // ضبط الثيم ليكون احترافياً وموحداً
      theme: ThemeData(
        useMaterial3: false, // نستخدم Material 2 لاستقرار أكبر في التصميم
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto', // خط نظيف (يمكن تغييره للعربي لاحقاً)
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      // نقطة البداية: الموجه الذكي
      home: const AuthWrapper(),
    );
  }
}

// 🛡️ البواب الذكي (The Gatekeeper)
// هذه أهم قطعة في الكود: تحدد من أنت وتوجهك لمكانك الصحيح
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // استماع حي لحالة الدخول
      builder: (context, snapshot) {
        // 1. حالة الانتظار (تحميل)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. إذا كان هناك مستخدم مسجل
        if (snapshot.hasData && snapshot.data != null) {
          // نذهب لفحص دوره في قاعدة البيانات (هل هو مدير أم مريض؟)
          return UserRoleDispatcher(uid: snapshot.data!.uid);
        }

        // 3. إذا لم يكن مسجلاً، اذهب لشاشة الدخول
        return const LoginScreen();
      },
    );
  }
}

// 🔀 موزع الأدوار (Role Dispatcher)
// يفحص "بطاقة تعريف" المستخدم من Firestore
class UserRoleDispatcher extends StatefulWidget {
  final String uid;
  const UserRoleDispatcher({super.key, required this.uid});

  @override
  State<UserRoleDispatcher> createState() => _UserRoleDispatcherState();
}

class _UserRoleDispatcherState extends State<UserRoleDispatcher> {
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  // دالة جلب الدور (محمية من الأخطاء)
  Future<void> _fetchUserRole() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          role = doc.get('role'); // admin, patient, provider
          isLoading = false;
        });
      } else {
        // مستخدم جديد (ليس لديه بيانات بعد)
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("⚠️ خطأ في جلب الدور: $e");
      // في حالة الخطأ، نعيد المحاولة أو نبقى في التحميل
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.accent)));
    }

    // التوجيه النهائي حسب الدور
    if (role == 'admin') return const AdminDashboard(); // سننشئها في البارت 3
    if (role == 'provider') return const ProviderDashboard(); // سننشئها في البارت 5
    if (role == 'patient') return const PatientHome(); // سننشئها في البارت 4

    // إذا لم يكن لديه دور (مستخدم جديد تماماً)، يذهب لاختيار الدور
    return const RoleSelectionScreen();
  }
}
// ==========================================
// 🔐 PART 2: AUTHENTICATION & REGISTRATION
// ==========================================

// 1. شاشة إدخال رقم الهاتف (Login Screen)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  // دالة إرسال الرمز (SMS)
  Future<void> _sendCode() async {
    String phone = _phoneCtrl.text.trim();
    
    // التحقق البسيط من الرقم
    if (phone.isEmpty || phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("يرجى كتابة رقم هاتف صحيح (9 أرقام على الأقل)"),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    // معالجة الرقم للجزائر (حذف الصفر الأول وإضافة +213)
    if (phone.startsWith('0')) phone = phone.substring(1);
    // إذا لم يكن يبدأ بـ +، نضيف كود الجزائر
    if (!phone.startsWith('+')) phone = '+213$phone';

    setState(() => _isLoading = true);

    // بدء عملية التحقق من فايربيز
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      // 1. التحقق التلقائي (في بعض هواتف أندرويد الحديثة)
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        // الـ StreamBuilder في البارت 1 سيقوم بنقلك تلقائياً
      },
      // 2. فشل التحقق
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        String msg = "فشل التحقق: ${e.message}";
        if (e.code == 'invalid-phone-number') msg = "رقم الهاتف غير صحيح.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
      },
      // 3. تم إرسال الكود بنجاح -> انتقل لشاشة الرمز
      codeSent: (String vid, int? token) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(verificationId: vid, phone: phone)),
        );
      },
      // 4. انتهاء مهلة الكود
      codeAutoRetrievalTimeout: (String vid) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار بسيط
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.health_and_safety, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 30),
              
              const Text("تسجيل الدخول", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              const SizedBox(height: 10),
              const Text("سجل دخولك لتطلب خدمات التمريض والإسعاف", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              // حقل الهاتف
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 18, letterSpacing: 1),
                decoration: const InputDecoration(
                  labelText: "رقم الهاتف",
                  prefixText: "+213 ",
                  prefixIcon: Icon(Icons.phone_android),
                  hintText: "612 34 56 78",
                ),
              ),
              const SizedBox(height: 25),

              // زر الدخول
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("إرسال رمز التحقق 📩", style: TextStyle(fontSize: 18)),
                ),
              ),
              
              const SizedBox(height: 20),
              const Text("بتسجيل الدخول أنت توافق على شروط الاستخدام", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. شاشة إدخال الرمز (OTP Screen)
class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phone;
  const OtpScreen({super.key, required this.verificationId, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    String code = _otpCtrl.text.trim();
    if (code.length < 6) return;

    setState(() => _isLoading = true);
    try {
      // إنشاء بيانات الاعتماد
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );
      // تسجيل الدخول
      await FirebaseAuth.instance.signInWithCredential(credential);
      // تنظيف المكدس والعودة (الـ AuthWrapper سيتولى الباقي)
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("الرمز غير صحيح، حاول مجدداً ❌"),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد الرقم")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text("تم إرسال الرمز إلى ${widget.phone}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),
            
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 30, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "000000",
                counterText: "",
                border: UnderlineInputBorder(),
              ),
              onChanged: (val) {
                if (val.length == 6) _verifyOtp(); // تحقق تلقائي عند اكتمال الرقم
              },
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("تفعيل الحساب ✅", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. شاشة اختيار الدور (Role Selection) - تظهر مرة واحدة في العمر
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;

  Future<void> _setRole(String role) async {
    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // حفظ بيانات المستخدم في Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'phone': user.phoneNumber,
        'role': role, // 'patient' أو 'provider'
        'createdAt': FieldValue.serverTimestamp(),
        'name': role == 'patient' ? 'مريض جديد' : 'مقدم خدمة', // اسم مؤقت
        'status': 'active',
      });
      // بعد الحفظ، الـ StreamBuilder في الصفحة الرئيسية سيعيد التوجيه تلقائياً
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: AppColors.primary),
            const SizedBox(height: 20),
            const Text("أهلاً بك في عافية", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("من فضلك، اختر نوع الحساب للمتابعة", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 50),

            // زر المريض
            _buildBigButton(
              "أبحث عن رعاية صحية",
              "أنا مريض أو مرافق",
              Icons.sick,
              Colors.teal,
              () => _setRole('patient'),
            ),
            const SizedBox(height: 20),

            // زر الممرض/السائق
            _buildBigButton(
              "أنا مقدم خدمة",
              "ممرض، سائق، أو طبيب",
              Icons.medical_services,
              Colors.orange,
              () => _setRole('provider'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// ==========================================
// 👮 PART 3: SUPER ADMIN DASHBOARD & PRICING
// ==========================================

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // دالة الخروج
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    // الـ AuthWrapper سيعيدك لصفحة الدخول
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("غرفة القيادة 👮‍♂️"),
        backgroundColor: Colors.blueGrey.shade900,
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.redAccent)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("مرحباً أيها المدير،", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("إليك ملخص ما يحدث في عافية الآن:", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // 1. بطاقات الإحصائيات (Live Stats)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('requests').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                var docs = snapshot.data!.docs;
                int total = docs.length;
                int pending = docs.where((d) => d['status'] == 'pending').length;
                int completed = docs.where((d) => d['status'] == 'completed').length;
                
                return Row(
                  children: [
                    _buildStatCard("الكل", total.toString(), Colors.blue),
                    _buildStatCard("انتظار", pending.toString(), Colors.orange),
                    _buildStatCard("مكتمل", completed.toString(), Colors.green),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),

            const Text("أدوات التحكم", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // 2. شبكة الأزرار (Tools Grid)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildToolBtn(
                  "💰 إدارة الأسعار", 
                  Icons.price_change, 
                  Colors.teal, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPriceSettings()))
                ),
                _buildToolBtn(
                  "🚑 مراقبة الطلبات", 
                  Icons.monitor_heart, 
                  Colors.indigo, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRequestsMonitor()))
                ),
                _buildToolBtn(
                  "👥 المستخدمين", 
                  Icons.people, 
                  Colors.purple, 
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("قريباً: إدارة الحظر والتوثيق")));
                  }
                ),
                _buildToolBtn(
                  "⚙️ الإعدادات", 
                  Icons.settings, 
                  Colors.grey, 
                  () {}
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // تصميم بطاقة الإحصائيات
  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // تصميم زر الأداة
  Widget _buildToolBtn(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 💰 شاشة التحكم بالأسعار (Dynamic Price Engine)
// ---------------------------------------------------------
class AdminPriceSettings extends StatefulWidget {
  const AdminPriceSettings({super.key});

  @override
  State<AdminPriceSettings> createState() => _AdminPriceSettingsState();
}

class _AdminPriceSettingsState extends State<AdminPriceSettings> {
  // الأسعار الافتراضية (Fallback) في حال كانت قاعدة البيانات فارغة
  Map<String, dynamic> prices = {
    'nurse_injection': 500,
    'nurse_serum': 1500,
    'nurse_change': 800,
    'doctor_visit': 3000,
    'ambulance_local': 2000,
    'ambulance_out': 10000,
  };
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  // 1. جلب الأسعار من Firestore
  Future<void> _loadPrices() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('app_settings').doc('prices').get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          prices.addAll(doc.data() as Map<String, dynamic>);
        });
      }
    } catch (e) {
      print("Error loading prices: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 2. تحديث السعر في Firestore
  Future<void> _updatePrice(String key, int newPrice) async {
    setState(() => prices[key] = newPrice); // تحديث محلي سريع
    await FirebaseFirestore.instance.collection('app_settings').doc('prices').set(prices, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث السعر بنجاح ✅")));
  }

  // نافذة تعديل السعر
  void _showEditDialog(String title, String key) {
    TextEditingController ctrl = TextEditingController(text: prices[key].toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تعديل سعر: $title"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: "دج"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                _updatePrice(key, int.parse(ctrl.text));
                Navigator.pop(ctx);
              }
            },
            child: const Text("حفظ"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إدارة الأسعار"), backgroundColor: Colors.teal),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection("💉 خدمات التمريض"),
                _buildPriceTile("حقن (Injection)", 'nurse_injection'),
                _buildPriceTile("سيروم (Sérum)", 'nurse_serum'),
                _buildPriceTile("تغيير ضمادات", 'nurse_change'),
                
                _buildSection("👨‍⚕️ الأطباء"),
                _buildPriceTile("زيارة منزلية", 'doctor_visit'),

                _buildSection("🚑 الإسعاف"),
                _buildPriceTile("نقل داخل الولاية", 'ambulance_local'),
                _buildPriceTile("نقل خارج الولاية", 'ambulance_out'),
              ],
            ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
    );
  }

  Widget _buildPriceTile(String name, String key) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(name),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text("${prices[key]} دج", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        ),
        onTap: () => _showEditDialog(name, key),
      ),
    );
  }
}

// ---------------------------------------------------------
// 🚑 مراقبة الطلبات (Admin Requests Monitor)
// ---------------------------------------------------------
class AdminRequestsMonitor extends StatelessWidget {
  const AdminRequestsMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("كل الطلبات"), backgroundColor: Colors.indigo),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests').orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          
          if (docs.isEmpty) return const Center(child: Text("لا توجد طلبات حتى الآن"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              var data = docs[i].data() as Map<String, dynamic>;
              Color statusColor = Colors.grey;
              if (data['status'] == 'pending') statusColor = Colors.orange;
              if (data['status'] == 'accepted') statusColor = Colors.blue;
              if (data['status'] == 'completed') statusColor = Colors.green;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: statusColor, child: const Icon(Icons.history, color: Colors.white)),
                  title: Text(data['service'] ?? 'خدمة'),
                  subtitle: Text("${data['patientName'] ?? 'مريض'} • ${data['price']} دج"),
                  trailing: Text(data['status'].toString().toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
// ==========================================
// 🏥 PART 4: PATIENT APP (UI & ORDERING)
// ==========================================

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  // دالة الخروج
  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("عافية - خدمات صحية"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "طلباتي السابقة",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientOrdersHistory())),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.white70)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // بنر ترحيبي
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("مرحباً بك ❤️", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text("نحن هنا لرعايتك. اختر الخدمة التي تحتاجها وسنصلك فوراً.", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Icon(Icons.favorite, color: Colors.white, size: 50),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Align(alignment: Alignment.centerRight, child: Text("الخدمات المتاحة", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 15),

            // شبكة الخدمات
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: [
                _buildServiceCard("خدمات تمريض", Icons.medical_services, Colors.teal, 'nurse'),
                _buildServiceCard("طبيب منزلي", Icons.person, Colors.blue, 'doctor'),
                _buildServiceCard("إسعاف ونقل", Icons.ambulance, Colors.red, 'ambulance'),
                _buildServiceCard("رعاية مسنين", Icons.elderly, Colors.orange, 'elderly'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color, String category) {
    return InkWell(
      onTap: () => _showSubServices(context, category, title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // القائمة المنبثقة الذكية (تجلب الأسعار من السيرفر)
  void _showSubServices(BuildContext context, String category, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('app_settings').doc('prices').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // الأسعار الافتراضية
                Map<String, dynamic> prices = {
                  'nurse_injection': 500, 'nurse_serum': 1500, 'nurse_change': 800,
                  'doctor_visit': 3000, 'ambulance_local': 2000, 'ambulance_out': 10000,
                };

                // تحديث بالأسعار الحقيقية من الأدمن
                if (snapshot.hasData && snapshot.data!.exists) {
                  prices.addAll(snapshot.data!.data() as Map<String, dynamic>);
                }

                // تحضير القائمة حسب الفئة
                List<Map<String, dynamic>> services = [];
                if (category == 'nurse') {
                  services = [
                    {'name': 'حقن (Injection)', 'price': prices['nurse_injection']},
                    {'name': 'سيروم (Sérum)', 'price': prices['nurse_serum']},
                    {'name': 'تغيير ضمادات', 'price': prices['nurse_change']},
                  ];
                } else if (category == 'doctor') {
                  services = [{'name': 'زيارة منزلية', 'price': prices['doctor_visit']}];
                } else if (category == 'ambulance') {
                  services = [
                    {'name': 'نقل داخل الولاية', 'price': prices['ambulance_local']},
                    {'name': 'نقل خارج الولاية', 'price': prices['ambulance_out']},
                  ];
                }

                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                      const SizedBox(height: 20),
                      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: services.length,
                          itemBuilder: (ctx, i) => Card(
                            margin: const EdgeInsets.only(bottom: 15),
                            elevation: 0,
                            color: Colors.grey.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              title: Text(services[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                                child: Text("${services[i]['price']} دج", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              onTap: () {
                                Navigator.pop(context); // إغلاق القائمة
                                // الذهاب لتأكيد الطلب
                                Navigator.push(context, MaterialPageRoute(builder: (_) => OrderConfirmScreen(
                                  serviceName: services[i]['name'],
                                  price: services[i]['price'],
                                )));
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          },
        );
      }
    );
  }
}

// ---------------------------------------------------------
// 📝 شاشة تأكيد الطلب (Order Confirmation)
// ---------------------------------------------------------
class OrderConfirmScreen extends StatefulWidget {
  final String serviceName;
  final int price;

  const OrderConfirmScreen({super.key, required this.serviceName, required this.price});

  @override
  State<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends State<OrderConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;

    try {
      // إرسال الطلب إلى Firestore
      await FirebaseFirestore.instance.collection('requests').add({
        'patientId': user?.uid,
        'patientName': user?.phoneNumber ?? 'مريض', // يمكن جلب الاسم الحقيقي
        'service': widget.serviceName,
        'price': widget.price,
        'address': _addressCtrl.text,
        'status': 'pending', // حالة الانتظار
        'created_at': FieldValue.serverTimestamp(),
        // موقع افتراضي (يمكن تطويره لاحقاً لاستخدام GPS)
        'location': const GeoPoint(36.75, 3.05), 
      });

      if (mounted) {
        // رسالة نجاح
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            content: const Text("تم إرسال طلبك بنجاح!\nسيتصل بك أقرب مقدم خدمة.", textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // العودة للرئيسية
                },
                child: const Text("حسناً"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد الحجز")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ملخص الفاتورة
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("الخدمة:", style: TextStyle(color: Colors.grey)),
                        Text(widget.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("التكلفة التقريبية:", style: TextStyle(color: Colors.grey)),
                        Text("${widget.price} دج", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text("عنوانك الحالي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: "الولاية، الدائرة، اسم الحي، رقم المنزل...",
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) => v!.isEmpty ? "يرجى كتابة العنوان" : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("تأكيد الطلب وإرسال 🚀", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 📜 سجل طلبات المريض (My Orders)
// ---------------------------------------------------------
class PatientOrdersHistory extends StatelessWidget {
  const PatientOrdersHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("طلباتي السابقة")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('patientId', isEqualTo: uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const Text("ليس لديك طلبات سابقة", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              var data = docs[i].data() as Map<String, dynamic>;
              String status = data['status'];
              Color color = status == 'pending' ? Colors.orange : (status == 'accepted' ? Colors.blue : Colors.green);
              String statusText = status == 'pending' ? 'قيد الانتظار' : (status == 'accepted' ? 'تم القبول' : 'مكتمل');

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(Icons.medical_services, color: color)),
                  title: Text(data['service']),
                  subtitle: Text("${data['price']} دج • $statusText"),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
// ==========================================
// 🚑 PART 5: PROVIDER APP (NURSE/DRIVER)
// ==========================================

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? _myUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // دالة الخروج
  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // دالة قبول الطلب (محمية بـ Transaction لمنع التضارب)
  Future<void> _acceptOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference orderRef = FirebaseFirestore.instance.collection('requests').doc(orderId);
        DocumentSnapshot snapshot = await transaction.get(orderRef);

        if (!snapshot.exists) throw Exception("الطلب غير موجود!");
        
        // التحقق من أن الطلب ما زال متاحاً
        if (snapshot['status'] != 'pending') {
          throw Exception("عذراً، تم قبول هذا الطلب من قبل زميل آخر.");
        }

        // تحديث الطلب ليصبح ملكاً لهذا الممرض
        transaction.update(orderRef, {
          'status': 'accepted',
          'providerId': _myUid,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("تم قبول المهمة بنجاح! 🦅"),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll("Exception:", "")),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  // دالة إنهاء الطلب (إكمال المهمة)
  Future<void> _completeOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(orderId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("عمل رائع! تم إكمال المهمة ✅")));
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة الكابتن 🚑"),
        backgroundColor: Colors.indigo,
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.radar), text: "الرادار (طلبات جديدة)"),
            Tab(icon: Icon(Icons.assignment_turned_in), text: "مهامي الحالية"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList('pending'),   // شاشة الرادار
          _buildOrdersList('accepted'),  // شاشة المهام المقبولة
        ],
      ),
    );
  }

  // باني القوائم (يعمل لكلتا الحالتين)
  Widget _buildOrdersList(String listType) {
    Query query = FirebaseFirestore.instance.collection('requests');

    if (listType == 'pending') {
      // الرادار: يظهر فقط الطلبات المعلقة
      query = query.where('status', isEqualTo: 'pending').orderBy('created_at', descending: true);
    } else {
      // مهامي: تظهر الطلبات التي قبلها هذا الممرض تحديداً
      query = query
          .where('providerId', isEqualTo: _myUid)
          .where('status', isEqualTo: 'accepted')
          .orderBy('acceptedAt', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(listType == 'pending' ? Icons.radar : Icons.check_circle_outline, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text(
                  listType == 'pending' ? "جارٍ البحث عن طلبات قريبة..." : "ليس لديك مهام نشطة حالياً",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            var data = docs[i].data() as Map<String, dynamic>;
            bool isPending = listType == 'pending';

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: isPending ? Colors.orange.withOpacity(0.5) : Colors.green.withOpacity(0.5), width: 1),
              ),
              child: Column(
                children: [
                  // رأس البطاقة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(isPending ? Icons.notification_important : Icons.person, color: isPending ? Colors.orange : Colors.green),
                            const SizedBox(width: 8),
                            Text(isPending ? "طلب جديد!" : "مهمة نشطة", style: TextStyle(fontWeight: FontWeight.bold, color: isPending ? Colors.orange[800] : Colors.green[800])),
                          ],
                        ),
                        Text("${data['price']} دج", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                  
                  // تفاصيل الطلب
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['service'] ?? 'خدمة', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            Expanded(child: Text(data['address'] ?? 'العنوان غير محدد', style: const TextStyle(fontSize: 16))),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // الأزرار
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: isPending 
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                                  icon: const Icon(Icons.touch_app),
                                  label: const Text("قبول المهمة فوراً"),
                                  onPressed: () => _acceptOrder(docs[i].id),
                                )
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  icon: const Icon(Icons.check),
                                  label: const Text("إكمال وإنهاء المهمة"),
                                  onPressed: () => _completeOrder(docs[i].id),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
// ==========================================
// ℹ️ PART 6: UTILITIES & ABOUT SCREEN
// ==========================================

// شاشة "عن التطبيق" تظهر في الإعدادات
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("عن عافية"), backgroundColor: Colors.grey),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text("Afya Pro", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Version 3.0.0 (Final Release)", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "منصة صحية متكاملة تربط المرضى بمقدمي الرعاية الصحية في الجزائر بذكاء وسرعة.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 50),
            const Text("Developed by: CEO & Gemini", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ✅ END OF FILE - SYSTEM READY
// ==========================================
