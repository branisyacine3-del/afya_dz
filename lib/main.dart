import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // مهم للتأثيرات الزجاجية

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================================
// 1. إعدادات النظام والتصميم (Design System)
// ============================================================================

// ألوان التطبيق الاحترافية (Palette)
class AppColors {
  static const Color primary = Color(0xFF00BFA5); // التيل المشرق
  static const Color primaryDark = Color(0xFF00897B); // التيل الغامق
  static const Color accent = Color(0xFFFFAB00); // برتقالي ذهبي للتنبيهات
  static const Color background = Color(0xFFF0F2F5); // رمادي فاتح جداً للخلفيات
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF263238);
  static const Color textGrey = Color(0xFF78909C);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);

  // تدرج لوني رئيسي (Gradient)
  static const LinearGradient mainGradient = LinearGradient(
    colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // تدرج لوني للدفع (ذهبي)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFA000), Color(0xFFFF6F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

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
  // إخفاء شريط الحالة العلوي لتجربة شاشة كاملة أجمل
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
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
      title: 'Afya DZ',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Tajawal', // تأكد من إضافة الخط في pubspec.yaml للحصول على أفضل نتيجة
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: AppColors.textDark),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================================
// 2. أدوات الواجهة المخصصة (Custom Widgets) - سر الاحترافية
// ============================================================================

// زر بتأثيرات (Animated Button)
class ProButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;

  const ProButton({
    super.key, 
    required this.text, 
    required this.onPressed, 
    this.isLoading = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: color == null ? AppColors.mainGradient : null,
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (color ?? AppColors.primary).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, color: Colors.white), const SizedBox(width: 10)],
                Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
      ),
    );
  }
}

// حقل إدخال عصري (Glassmorphism Input)
class ProTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType type;
  final bool isPassword;
  final int maxLines;

  const ProTextField({
    super.key, 
    required this.controller, 
    required this.label, 
    required this.icon, 
    this.type = TextInputType.text,
    this.isPassword = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textGrey),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

// بطاقة ذات ظلال ناعمة (Soft Card)
class ProCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  const ProCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: child,
      ),
    );
  }
}

// أنيميشن الظهور (Fade Animation)
class FadeInUp extends StatefulWidget {
  final Widget child;
  final int delay;
  const FadeInUp({super.key, required this.child, this.delay = 0});
  @override
  State<FadeInUp> createState() => _FadeInUpState();
}
class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _ctrl.forward(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: widget.child));
}

// ============================================================================
// 3. الشاشات الرئيسية (Screens)
// ============================================================================

// ---------------------- شاشة البداية (Splash) ----------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () => _checkAuth());
  }

  void _checkAuth() {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
                child: const Icon(Icons.health_and_safety_rounded, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            const FadeInUp(delay: 300, child: Text("عافية", style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w900, letterSpacing: 2))),
            const FadeInUp(delay: 500, child: Text("رعايتك الصحية.. في بيتك", style: TextStyle(color: Colors.white70, fontSize: 18))),
            const SizedBox(height: 60),
            const FadeInUp(delay: 800, child: CircularProgressIndicator(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ---------------------- شاشة الدخول والتسجيل (Auth) ----------------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      } else {
        if (_name.text.isEmpty) throw Exception("يرجى كتابة الاسم");
        UserCredential uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
        await uc.user!.updateDisplayName(_name.text);
        await FirebaseFirestore.instance.collection('users').doc(uc.user!.uid).set({
          'email': _email.text.trim(),
          'name': _name.text,
          'role': 'user',
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: ${e.toString()}"), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // رأس منحني جميل
            Container(
              height: 320,
              decoration: const BoxDecoration(
                gradient: AppColors.mainGradient,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
              ),
              child: Center(
                child: FadeInUp(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_person_rounded, size: 80, color: Colors.white),
                      const SizedBox(height: 20),
                      Text(isLogin ? "مرحباً بعودتك" : "أنشئ حسابك الآن", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(isLogin ? "سجل الدخول للمتابعة" : "انضم لفريق عافية المتميز", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeInUp(
                delay: 300,
                child: Column(
                  children: [
                    if (!isLogin) ProTextField(controller: _name, label: "الاسم الكامل", icon: Icons.person),
                    ProTextField(controller: _email, label: "البريد الإلكتروني", icon: Icons.email, type: TextInputType.emailAddress),
                    ProTextField(controller: _pass, label: "كلمة المرور", icon: Icons.lock, isPassword: true),
                    const SizedBox(height: 30),
                    ProButton(text: isLogin ? "تسجيل الدخول" : "إنشاء حساب", isLoading: _loading, onPressed: _submit),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(isLogin ? "ليس لديك حساب؟ سجل الآن" : "لديك حساب بالفعل؟ دخول", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- الشاشة الرئيسية (Dashboard) ----------------------
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    bool isAdmin = user?.email == "admin@afya.dz";

    return Scaffold(
      appBar: AppBar(
        title: const Text("عافية"),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: AppColors.error),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // بطاقة المستخدم
            FadeInUp(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                builder: (context, snap) {
                  String role = "عضو جديد";
                  if (snap.hasData && snap.data!.exists) {
                    var d = snap.data!.data() as Map<String, dynamic>;
                    if (d['role'] == 'nurse' && d['status'] == 'approved') role = "ممرض معتمد";
                  }
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(gradient: AppColors.mainGradient, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 35, backgroundColor: Colors.white, child: Text(user?.displayName?[0].toUpperCase() ?? "A", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary))),
                        const SizedBox(width: 20),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("مرحباً بك،", style: TextStyle(color: Colors.white70, fontSize: 16)),
                          Text(user?.displayName ?? "مستخدم", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                        ])),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            
            // القوائم
            if (isAdmin) FadeInUp(delay: 200, child: _menuCard(context, "لوحة الإدارة", "التحكم الكامل بالتطبيق", Icons.dashboard_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())))),
            FadeInUp(delay: 400, child: _menuCard(context, "طلب ممرض", "خدمات طبية فورية", Icons.medical_services_rounded, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientHomeScreen())))),
            FadeInUp(delay: 600, child: _menuCard(context, "أنا ممرض", "الدخول للوحة المهام", Icons.work_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseAuthGate())))),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return ProCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 32)),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(sub, style: const TextStyle(color: AppColors.textGrey, fontSize: 14))])),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 18),
        ],
      ),
    );
  }
}

// ---------------------- قسم المريض (Patient) - الاحترافي ----------------------
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("الخدمات المتاحة"), bottom: const TabBar(labelColor: AppColors.primary, unselectedLabelColor: Colors.grey, indicatorColor: AppColors.primary, indicatorWeight: 3, tabs: [Tab(text: "طلب جديد"), Tab(text: "طلباتي")])),
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
        final services = [
          {"t": "حقن", "p": p['حقن']??'800', "i": Icons.vaccines, "c": Colors.orange},
          {"t": "سيروم", "p": p['سيروم']??'2000', "i": Icons.water_drop, "c": Colors.blue},
          {"t": "تغيير ضماد", "p": p['تغيير ضماد']??'1200', "i": Icons.healing, "c": Colors.purple},
          {"t": "قياس ضغط", "p": p['قياس ضغط']??'500', "i": Icons.monitor_heart, "c": Colors.red},
          {"t": "قياس سكري", "p": p['قياس سكري']??'400', "i": Icons.bloodtype, "c": Colors.pink},
        ];

        return ListView(padding: const EdgeInsets.all(20), children: [
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.95),
            itemCount: services.length,
            itemBuilder: (ctx, i) => FadeInUp(delay: i * 100, child: _serviceCard(ctx, services[i]['t'] as String, services[i]['p'] as String, services[i]['i'] as IconData, services[i]['c'] as Color)),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: 600,
            child: InkWell(
              onTap: () => _customOrderDialog(context),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28), SizedBox(width: 15), Text("طلب خدمة خاصة أخرى", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary))]),
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _serviceCard(BuildContext context, String title, String price, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: title, price: "$price دج"))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 32)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text("$price دج", style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  void _customOrderDialog(BuildContext context) {
    final c = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [Icon(Icons.star_rounded, color: AppColors.primary), SizedBox(width: 10), Text("خدمة خاصة")]),
      content: TextField(controller: c, decoration: const InputDecoration(hintText: "مثال: علاج طبيعي، رعاية مسن...", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")), ElevatedButton(onPressed: () { Navigator.pop(ctx); if (c.text.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: c.text, price: "حسب الاتفاق"))); }, child: const Text("متابعة"))],
    ));
  }
}

// شاشة تأكيد الطلب (مع الخريطة والتحميل)
class OrderScreen extends StatefulWidget {
  final String title; final String price;
  const OrderScreen({super.key, required this.title, required this.price});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  final _phone = TextEditingController();
  double? _lat, _lng;
  bool _locLoading = false;
  bool _submitting = false;

  Future<void> _getLoc() async {
    setState(() => _locLoading = true);
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.whileInUse || p == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() { _lat = pos.latitude; _lng = pos.longitude; });
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تأكد من تفعيل GPS")));
    }
    setState(() => _locLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد الطلب")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // بطاقة الخدمة الكبيرة
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(gradient: AppColors.mainGradient, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]),
              child: Column(children: [
                Text(widget.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)), child: Text(widget.price, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold))),
              ]),
            ),
            const SizedBox(height: 30),
            ProTextField(controller: _phone, label: "رقم الهاتف", icon: Icons.phone, type: TextInputType.phone),
            const SizedBox(height: 20),
            // زر الموقع التفاعلي
            InkWell(
              onTap: _getLoc,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _lat != null ? AppColors.success.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _lat != null ? AppColors.success : Colors.grey.shade300),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_locLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    else Icon(Icons.location_on_rounded, color: _lat != null ? AppColors.success : Colors.grey),
                    const SizedBox(width: 15),
                    Text(_lat != null ? "تم تحديد الموقع بنجاح" : (_locLoading ? "جاري البحث عن موقعك..." : "اضغط لعرض موقعك"), style: TextStyle(color: _lat != null ? AppColors.success : Colors.black54, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ProButton(
              text: "تأكيد وإرسال",
              isLoading: _submitting,
              onPressed: () async {
                if (_phone.text.isEmpty || _lat == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("البيانات ناقصة (الهاتف والموقع)"), backgroundColor: AppColors.error));
                  return;
                }
                setState(() => _submitting = true);
                await FirebaseFirestore.instance.collection('requests').add({
                  'service': widget.title, 'price': widget.price, 'phone': _phone.text, 'lat': _lat, 'lng': _lng,
                  'status': 'pending', 'timestamp': FieldValue.serverTimestamp(),
                  'patient_id': FirebaseAuth.instance.currentUser?.uid,
                  'patient_name': FirebaseAuth.instance.currentUser?.displayName
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الإرسال بنجاح!"), backgroundColor: AppColors.success));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// قائمة طلباتي (My Orders) مع العداد الذكي
class PatientMyOrders extends StatelessWidget {
  const PatientMyOrders({super.key});

  bool _isExpired(Timestamp? t) => t != null && DateTime.now().difference(t.toDate()).inMinutes >= 10;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('patient_id', isEqualTo: uid).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات نشطة"));
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snap.data!.docs.length,
          itemBuilder: (ctx, i) {
            var d = snap.data!.docs[i]; var data = d.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';
            // منطق انتهاء الصلاحية
            if (status == 'pending' && _isExpired(data['timestamp'])) status = 'expired';

            Color color = AppColors.accent;
            String txt = "جاري البحث عن ممرض...";
            IconData icon = Icons.hourglass_top_rounded;

            if (status == 'expired') { color = AppColors.error; txt = "انتهى الوقت (ملغي)"; icon = Icons.timer_off_rounded; }
            if (status == 'accepted') { color = Colors.blue; txt = "الممرض ${data['nurse_name']} قادم"; icon = Icons.directions_run_rounded; }
            if (status == 'completed') { color = AppColors.success; txt = "اكتملت الخدمة"; icon = Icons.verified_rounded; }

            return ProCard(
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(data['service'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(data['price'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ]),
                  const Divider(height: 30),
                  Row(children: [
                    Icon(icon, color: color), const SizedBox(width: 10),
                    Expanded(child: Text(txt, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
                    if (status == 'pending') CountdownTimer(timestamp: data['timestamp']),
                  ]),
                  if (status == 'accepted') ...[
                    const SizedBox(height: 20),
                    ProButton(color: AppColors.success, text: "تأكيد استلام الخدمة", onPressed: () => d.reference.update({'status': 'completed'}), icon: Icons.check_circle),
                  ],
                  if (status == 'pending') ...[
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => d.reference.delete(), style: OutlinedButton.styleFrom(foregroundColor: AppColors.error), child: const Text("إلغاء الطلب"))),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// مؤقت تنازلي (Widget مستقل)
class CountdownTimer extends StatefulWidget {
  final Timestamp? timestamp;
  const CountdownTimer({super.key, required this.timestamp});
  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}
class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  String _remaining = "";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.timestamp == null) return;
      final end = widget.timestamp!.toDate().add(const Duration(minutes: 10));
      final diff = end.difference(DateTime.now());
      if (diff.isNegative) { _timer.cancel(); if(mounted) setState(() => _remaining = "00:00"); } 
      else { if(mounted) setState(() => _remaining = "${diff.inMinutes}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}"); }
    });
  }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Text(_remaining, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold));
}

// ---------------------- بوابة الممرض ----------------------
class NurseAuthGate extends StatelessWidget {
  const NurseAuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بوابة الممرضين")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var d = snap.data!.data() as Map<String, dynamic>?;
          String st = d?['status'] ?? 'user';
          if (d?['role'] == 'user') return const NurseForm();
          if (st == 'pending_docs') return _msg(Icons.hourglass_top_rounded, AppColors.accent, "ملفك قيد المراجعة", "يقوم فريق عافية بمراجعة وثائقك بدقة.");
          if (st == 'pending_payment') return const NursePay();
          if (st == 'payment_review') return _msg(Icons.verified_user_rounded, Colors.blue, "جاري التحقق من الدفع", "شكراً لك، سيتم التفعيل قريباً.");
          if (st == 'approved') return const NurseDash();
          return const NurseForm();
        },
      ),
    );
  }
  Widget _msg(IconData i, Color c, String t, String s) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 100, color: c), const SizedBox(height: 20), Text(t, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: c)), const SizedBox(height: 10), Text(s, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey))])));
}

// استمارة الممرض الاحترافية
class NurseForm extends StatefulWidget {
  const NurseForm({super.key});
  @override
  State<NurseForm> createState() => _NurseFormState();
}
class _NurseFormState extends State<NurseForm> {
  final _ph = TextEditingController(); final _ad = TextEditingController();
  String? _spec; String? _p, _i, _d; bool _loading = false;
  Future<void> _pick(String t) async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 20);
    if(x!=null) { final b = await File(x.path).readAsBytes(); setState(() { if(t=='p')_p=base64Encode(b); if(t=='i')_i=base64Encode(b); if(t=='d')_d=base64Encode(b); }); }
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("معلومات مهنية", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
      const SizedBox(height: 20),
      ProTextField(controller: _ph, label: "رقم الهاتف", icon: Icons.phone),
      ProTextField(controller: _ad, label: "الولاية / العنوان", icon: Icons.map),
      DropdownButtonFormField(value: _spec, decoration: InputDecoration(labelText: "التخصص", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))), items: ['ممرض دولة', 'مساعد ممرض', 'قابلة', 'مروض طبي'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged: (v)=>setState(()=>_spec=v)),
      const SizedBox(height: 30),
      const Text("الوثائق الثبوتية", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
      const SizedBox(height: 15),
      _uBtn("صورة شخصية", _p, ()=>_pick('p')), _uBtn("بطاقة التعريف", _i, ()=>_pick('i')), _uBtn("الشهادة / الدبلوم", _d, ()=>_pick('d')),
      const SizedBox(height: 30),
      ProButton(text: "إرسال الملف", isLoading: _loading, onPressed: () async {
        if(_p==null||_i==null||_d==null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الوثائق ناقصة"))); return; }
        setState(()=>_loading=true); await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({'role':'nurse','status':'pending_docs','phone':_ph.text,'specialty':_spec,'address':_ad.text,'pic_data':_p,'id_data':_i,'diploma_data':_d}, SetOptions(merge:true));
      })
    ]));
  }
  Widget _uBtn(String t, String? v, VoidCallback f) => ProCard(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), onTap: f, child: Row(children: [Icon(v!=null?Icons.check_circle:Icons.cloud_upload_rounded, color: v!=null?AppColors.success:Colors.grey), const SizedBox(width: 15), Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), if(v!=null) const Text("تم", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))]));
}

// شاشة الدفع الفخمة
class NursePay extends StatefulWidget {
  const NursePay({super.key});
  @override
  State<NursePay> createState() => _NursePayState();
}
class _NursePayState extends State<NursePay> {
  String? _r; bool _l=false;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      const Icon(Icons.workspace_premium_rounded, size: 80, color: AppColors.accent),
      const SizedBox(height: 20),
      const Text("تفعيل العضوية", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 30),
      Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 20)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("الاشتراك الشهري", style: TextStyle(color: Colors.white70)), Icon(Icons.credit_card, color: Colors.white)]),
          const SizedBox(height: 10),
          const Text("3500 DZD", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
          const Divider(color: Colors.white24, height: 40),
          _inf("CCP", "0028939081"), _inf("Clé", "97"), _inf("Name", "Branis Yacine"),
        ]),
      ),
      const SizedBox(height: 30),
      InkWell(onTap: () async {final x=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:20);if(x!=null){final b=await File(x.path).readAsBytes();setState(()=>_r=base64Encode(b));}}, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(16), color: _r!=null?AppColors.primary.withOpacity(0.1):null), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_rounded, color: AppColors.primary), const SizedBox(width: 10), Text(_r!=null?"تم اختيار الوصل":"رفع صورة الوصل", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))]))),
      const SizedBox(height: 20),
      ProButton(text: "تأكيد وإرسال", isLoading: _l, onPressed: _r==null?null:() async {setState(()=>_l=true);await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({'status':'payment_review','receipt_data':_r});})
    ]));
  }
  Widget _inf(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(k, style: const TextStyle(color: Colors.white70)), Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace'))]));
}

// لوحة الممرض
class NurseDash extends StatelessWidget {
  const NurseDash({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("لوحة التحكم"), bottom: const TabBar(labelColor: AppColors.primary, indicatorColor: AppColors.primary, tabs: [Tab(text: "الطلبات الجديدة"), Tab(text: "مهامي")])),
      body: const TabBarView(children: [NurseMkt(), NurseTasks()]),
    ));
  }
}
class NurseMkt extends StatelessWidget {
  const NurseMkt({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات"));
        return ListView.builder(padding: const EdgeInsets.all(15), itemCount: snap.data!.docs.length, itemBuilder: (ctx, i) {
          var d = snap.data!.docs[i]; var data = d.data() as Map<String, dynamic>;
          Timestamp? t = data['timestamp'];
          // إخفاء المنتهي
          if (t != null && DateTime.now().difference(t.toDate()).inMinutes >= 10) return const SizedBox();
          bool isSpec = data['price'] == 'حسب الاتفاق';
          return ProCard(child: ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.accent, child: Icon(Icons.person, color: Colors.white)),
            title: Text(data['patient_name']??""),
            subtitle: Text("${data['service']} ${isSpec ? '' : '- ${data['price']}'}"),
            trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), onPressed: ()=>d.reference.update({'status':'accepted','nurse_id':FirebaseAuth.instance.currentUser?.uid,'nurse_name':FirebaseAuth.instance.currentUser?.displayName}), child: const Text("قبول", style: TextStyle(color: Colors.white))),
          ));
        });
      },
    );
  }
}
class NurseTasks extends StatelessWidget {
  const NurseTasks({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('requests').where('nurse_id', isEqualTo: uid).where('status', isEqualTo: 'accepted').snapshots(), builder: (c,s)=>ListView.builder(padding: const EdgeInsets.all(15), itemCount: s.data?.docs.length??0, itemBuilder: (ctx,i){
      var d=s.data!.docs[i]; var data=d.data() as Map;
      return ProCard(child: Column(children: [ListTile(title: Text(data['patient_name']), subtitle: Text(data['phone'])), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [IconButton.filledTonal(onPressed: ()=>launchUrl(Uri.parse("tel:${data['phone']}")), icon: const Icon(Icons.phone)), if(data['lat']!=null) IconButton.filledTonal(onPressed: ()=>launchUrl(Uri.parse("google.navigation:q=${data['lat']},${data['lng']}")), icon: const Icon(Icons.map))]), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black87), onPressed: ()=>d.reference.update({'status':'completed_by_nurse'}), child: const Text("أنهيت العمل", style: TextStyle(color: Colors.white)))]));
    }));
  }
}

// ---------------------- لوحة الأدمن (Full Zoom & Control) ----------------------
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: Scaffold(
      appBar: AppBar(title: const Text("الإدارة المركزية"), bottom: const TabBar(labelColor: Colors.purple, indicatorColor: Colors.purple, tabs: [Tab(text: "توثيق"), Tab(text: "مالية"), Tab(text: "أسعار")])),
      body: const TabBarView(children: [AdminDocs(), AdminPay(), AdminPrices()]),
    ));
  }
}
class AdminDocs extends StatelessWidget {
  const AdminDocs({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'pending_docs').snapshots(), builder: (c,s)=>ListView.builder(itemCount: s.data?.docs.length??0, itemBuilder: (ctx,i){
      var d=s.data!.docs[i]; var data=d.data() as Map;
      return ProCard(child: ExpansionTile(
        leading: GestureDetector(onTap: ()=>_z(context, data['pic_data']), child: CircleAvatar(backgroundImage: MemoryImage(base64Decode(data['pic_data'])))),
        title: Text(data['name']), subtitle: Text("${data['specialty']} - ${data['address']}"),
        children: [Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [IconButton(icon: const Icon(Icons.credit_card, size: 40), onPressed: ()=>_z(context, data['id_data'])), IconButton(icon: const Icon(Icons.school, size: 40), onPressed: ()=>_z(context, data['diploma_data']))]), Row(children: [Expanded(child: OutlinedButton(onPressed: ()=>d.reference.update({'status':'rejected'}), child: const Text("رفض"))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: ()=>d.reference.update({'status':'pending_payment'}), child: const Text("قبول")))])]
      ));
    }));
  }
  void _z(BuildContext c, String b) => Navigator.push(c, MaterialPageRoute(builder: (_)=>FullScreenImage(base64Image: b)));
}
class AdminPay extends StatelessWidget {
  const AdminPay({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'payment_review').snapshots(), builder: (c,s)=>ListView.builder(itemCount: s.data?.docs.length??0, itemBuilder: (ctx,i){
      var d=s.data!.docs[i]; var data=d.data() as Map;
      return ProCard(child: ExpansionTile(title: Text(data['name']), subtitle: Text(data['email']), children: [
        GestureDetector(onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>FullScreenImage(base64Image: data['receipt_data']))), child: Container(height: 150, width: double.infinity, margin: const EdgeInsets.all(10), child: Image.memory(base64Decode(data['receipt_data']), fit: BoxFit.cover))),
        ElevatedButton(onPressed: ()=>d.reference.update({'status':'approved'}), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success), child: const Text("تفعيل الحساب", style: TextStyle(color: Colors.white)))
      ]));
    }));
  }
}
class AdminPrices extends StatelessWidget {
  const AdminPrices({super.key});
  @override
  Widget build(BuildContext context) {
    final c1=TextEditingController(), c2=TextEditingController(), c3=TextEditingController(), c4=TextEditingController();
    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      ProTextField(controller: c1, label: "سعر الحقن", icon: Icons.vaccines), ProTextField(controller: c2, label: "سعر السيروم", icon: Icons.water_drop),
      ProTextField(controller: c3, label: "سعر الضماد", icon: Icons.healing), ProTextField(controller: c4, label: "سعر الضغط", icon: Icons.monitor_heart),
      const SizedBox(height: 20),
      ProButton(text: "حفظ الأسعار", onPressed: ()=>FirebaseFirestore.instance.collection('config').doc('prices').set({'حقن':c1.text,'سيروم':c2.text,'تغيير ضماد':c3.text,'قياس ضغط':c4.text}, SetOptions(merge:true)))
    ]));
  }
}
class FullScreenImage extends StatelessWidget {
  final String base64Image;
  const FullScreenImage({super.key, required this.base64Image});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(iconTheme: const IconThemeData(color: Colors.white)), body: Center(child: InteractiveViewer(child: Image.memory(base64Decode(base64Image)))));
}
