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
// 🏛️ 1. نظام التصميم العالمي (Design System)
// ============================================================================

class AppTheme {
  // الألوان الأساسية
  static const Color primary = Color(0xFF00BFA5); // التيل (Teal)
  static const Color primaryDark = Color(0xFF00897B);
  static const Color secondary = Color(0xFF263238); 
  static const Color accent = Color(0xFFFFAB00); // برتقالي ذهبي
  static const Color background = Color(0xFFF4F7F6); // رمادي ثلجي
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF00C853);
  static const Color waiting = Color(0xFF29B6F6);

  // التدرجات اللونية
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1DE9B6), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // الظلال
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 5),
    )
  ];
  
  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 8),
    )
  ];

  // الخطوط
  static const TextStyle headerStyle = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w800, color: secondary, fontFamily: 'Tajawal'
  );
}

// ============================================================================
// ⚙️ 2. الإعدادات والتشغيل
// ============================================================================

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
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    try { await Firebase.initializeApp(); } catch (_) {}
  }
  
  runApp(const AfyaProApp());
}

class AfyaProApp extends StatelessWidget {
  const AfyaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Afya DZ Pro',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Tajawal', 
        scaffoldBackgroundColor: AppTheme.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          primary: AppTheme.primary,
          secondary: AppTheme.accent,
          surface: AppTheme.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppTheme.secondary),
          titleTextStyle: TextStyle(color: AppTheme.secondary, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================================
// 🧩 3. الأدوات الذكية (Custom Widgets)
// ============================================================================

// زر احترافي
class ProButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;
  final bool isOutlined;

  const ProButton({
    super.key, required this.text, required this.onPressed, 
    this.isLoading = false, this.color, this.icon, this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, height: 58,
      decoration: BoxDecoration(
        gradient: isOutlined ? null : (color == null ? AppTheme.primaryGradient : LinearGradient(colors: [color!, color!.withOpacity(0.8)])),
        borderRadius: BorderRadius.circular(18),
        boxShadow: isOutlined || onPressed == null ? [] : AppTheme.glowShadow,
        border: isOutlined ? Border.all(color: color ?? AppTheme.primary, width: 2) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () {
            HapticFeedback.lightImpact();
            if (onPressed != null) onPressed!();
          },
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: isLoading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon, color: isOutlined ? (color ?? AppTheme.primary) : Colors.white), const SizedBox(width: 12)],
                    Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isOutlined ? (color ?? AppTheme.primary) : Colors.white, fontFamily: 'Tajawal')),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

// حقل إدخال ذكي
class SmartTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType type;
  final bool isPassword;
  final int maxLines;

  const SmartTextField({super.key, required this.controller, required this.label, required this.icon, this.type = TextInputType.text, this.isPassword = false, this.maxLines = 1});

  @override
  State<SmartTextField> createState() => _SmartTextFieldState();
}
class _SmartTextFieldState extends State<SmartTextField> {
  bool _isFocused = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _isFocused ? AppTheme.primary : Colors.transparent, width: 2),
        boxShadow: _isFocused ? AppTheme.glowShadow : AppTheme.softShadow,
      ),
      child: Focus(
        onFocusChange: (focus) => setState(() => _isFocused = focus),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.isPassword,
          keyboardType: widget.type,
          maxLines: widget.maxLines,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(color: _isFocused ? AppTheme.primary : Colors.grey),
            prefixIcon: Icon(widget.icon, color: _isFocused ? AppTheme.primary : Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
        ),
      ),
    );
  }
}

// بطاقة زجاجية
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsets padding;

  const GlassCard({super.key, required this.child, this.onTap, this.color, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
        ),
        child: child,
      ),
    );
  }
}

// أنيميشن الدخول
class FadeSlide extends StatefulWidget {
  final Widget child;
  final int delay;
  const FadeSlide({super.key, required this.child, this.delay = 0});
  @override
  State<FadeSlide> createState() => _FadeSlideState();
}
class _FadeSlideState extends State<FadeSlide> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuad));
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuad));
    Future.delayed(Duration(milliseconds: widget.delay), () { if(mounted) _ctrl.forward(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: widget.child));
}
// ============================================================================
// 📺 4. شاشات العرض (Screens)
// ============================================================================

// ---------------------- 4.1 شاشة البداية التعريفية (Onboarding) ----------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      "title": "مرحباً بك في عافية",
      "desc": "رعايتك الصحية المتكاملة تصلك إلى باب منزلك بضغطة زر.",
      "icon": Icons.health_and_safety_rounded,
      "color": AppTheme.primary
    },
    {
      "title": "ممرضون محترفون",
      "desc": "نخبة من الممرضين المعتمدين جاهزون لخدمتك في أي وقت.",
      "icon": Icons.medical_services_rounded,
      "color": Colors.blue
    },
    {
      "title": "سهولة وسرعة",
      "desc": "تتبع طلبك لحظة بلحظة واستمتع بخدمة طبية آمنة ومريحة.",
      "icon": Icons.rocket_launch_rounded,
      "color": Colors.orange
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: _pages.length,
            itemBuilder: (ctx, i) => _buildPage(_pages[i]),
          ),
          Positioned(
            bottom: 50, left: 30, right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: List.generate(_pages.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.only(right: 5), height: 10, width: _currentPage == index ? 30 : 10, decoration: BoxDecoration(color: _currentPage == index ? _pages[_currentPage]['color'] : Colors.grey[300], borderRadius: BorderRadius.circular(5))))),
                FloatingActionButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageCtrl.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
                    } else {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                    }
                  },
                  backgroundColor: _pages[_currentPage]['color'],
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeSlide(child: Container(padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: data['color'].withOpacity(0.1), shape: BoxShape.circle), child: Icon(data['icon'], size: 100, color: data['color']))),
          const SizedBox(height: 50),
          FadeSlide(delay: 200, child: Text(data['title'], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.secondary))),
          const SizedBox(height: 20),
          FadeSlide(delay: 400, child: Text(data['desc'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.grey, height: 1.5))),
        ],
      ),
    );
  }
}

// ---------------------- 4.2 شاشة سبلاش (Splash) ----------------------
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FadeSlide(child: Container(padding: const EdgeInsets.all(35), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)), child: const Icon(Icons.health_and_safety_rounded, size: 80, color: Colors.white))),
          const SizedBox(height: 30),
          const FadeSlide(delay: 200, child: Text("عافية", style: TextStyle(color: Colors.white, fontSize: 55, fontWeight: FontWeight.w900, letterSpacing: 3))),
          const FadeSlide(delay: 400, child: Text("نظام الرعاية الصحية المتكامل", style: TextStyle(color: Colors.white70, fontSize: 18))),
          const SizedBox(height: 60),
          const FadeSlide(delay: 600, child: CircularProgressIndicator(color: Colors.white)),
        ])),
      ),
    );
  }
}

// ---------------------- 4.3 المصادقة (Auth) ----------------------
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
    if (_email.text.isEmpty || _pass.text.isEmpty) { _showError("يرجى ملء جميع الحقول"); return; }
    setState(() => _loading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      } else {
        if (_name.text.isEmpty) throw Exception("الاسم مطلوب");
        UserCredential uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
        await uc.user!.updateDisplayName(_name.text);
        await FirebaseFirestore.instance.collection('users').doc(uc.user!.uid).set({
          'email': _email.text.trim(), 'name': _name.text, 'role': 'user', 'status': 'active',
          'created_at': FieldValue.serverTimestamp(), 'rating': 5.0,
        }, SetOptions(merge: true));
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper()));
    } catch (e) { _showError(e.toString()); }
    setState(() => _loading = false);
  }

  void _showError(String msg) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 350,
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60))),
              child: Center(child: FadeSlide(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.account_circle_rounded, size: 90, color: Colors.white), const SizedBox(height: 20), Text(isLogin ? "مرحباً بعودتك" : "إنشاء حساب جديد", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(isLogin ? "سجل الدخول للمتابعة" : "انضم لمجتمع عافية", style: const TextStyle(color: Colors.white70, fontSize: 16))]))),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: FadeSlide(
                delay: 300,
                child: Column(children: [
                  if (!isLogin) SmartTextField(controller: _name, label: "الاسم الكامل", icon: Icons.person_outline_rounded),
                  SmartTextField(controller: _email, label: "البريد الإلكتروني", icon: Icons.email_outlined, type: TextInputType.emailAddress),
                  SmartTextField(controller: _pass, label: "كلمة المرور", icon: Icons.lock_outline_rounded, isPassword: true),
                  const SizedBox(height: 30),
                  ProButton(text: isLogin ? "دخول آمن" : "تسجيل", isLoading: _loading, onPressed: _submit, icon: isLogin ? Icons.login : Icons.person_add),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(isLogin ? "ليس لديك حساب؟" : "لديك حساب بالفعل؟", style: const TextStyle(color: Colors.grey)), TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "سجل الآن" : "دخول", style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)))])
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- 4.4 الغلاف الرئيسي (Bottom Navigation) ----------------------
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}
class _MainWrapperState extends State<MainWrapper> {
  int _idx = 0;
  final List<Widget> _screens = [const WelcomeScreen(), const PatientHomeScreen(), const ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: AppTheme.softShadow),
        child: NavigationBar(
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primary.withOpacity(0.2),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppTheme.primary), label: "الرئيسية"),
            NavigationDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services, color: AppTheme.primary), label: "خدماتي"),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppTheme.primary), label: "حسابي"),
          ],
        ),
      ),
    );
  }
}

// ---------------------- 4.5 الشاشة الرئيسية (Home) ----------------------
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isAdmin = user?.email == "admin@afya.dz";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220, floating: false, pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 40),
                    Row(children: [
                      CircleAvatar(radius: 35, backgroundColor: Colors.white, child: Text(user?.displayName?[0] ?? "U", style: const TextStyle(fontSize: 24, color: AppTheme.primary, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 15),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("صباح الخير 👋", style: TextStyle(color: Colors.white70)), Text(user?.displayName ?? "مستخدم", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]),
                    ]),
                    const SizedBox(height: 20),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)), child: const Row(children: [Icon(Icons.search, color: Colors.white), SizedBox(width: 10), Text("عن ماذا تبحث اليوم؟", style: TextStyle(color: Colors.white70))]))
                  ]),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (isAdmin) Container(margin: const EdgeInsets.only(bottom: 20), child: ProButton(text: "لوحة الإدارة (Admin)", color: Colors.purple, icon: Icons.dashboard_rounded, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())))),
                const Text("الخدمات السريعة", style: AppTheme.headerStyle),
                const SizedBox(height: 15),
                FadeSlide(child: _menuCard(context, "طلب ممرض فوري", "سيصلك أقرب ممرض في دقائق", Icons.medical_services_rounded, AppTheme.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientHomeScreen())))),
                FadeSlide(delay: 200, child: _menuCard(context, "بوابة الممرضين", "انضم لفريقنا أو تابع مهامك", Icons.work_history_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseAuthGate())))),
                const SizedBox(height: 30),
                const Text("آخر الأخبار", style: AppTheme.headerStyle),
                const SizedBox(height: 15),
                Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)), child: const Center(child: Text("خصم 20% على خدمات الحقن هذا الأسبوع!", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold))))
              ]),
            ),
          ),
        ],
      ),
    );
  }
  Widget _menuCard(BuildContext context, String t, String s, IconData i, Color c, VoidCallback f) {
    return GlassCard(onTap: f, child: Row(children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Icon(i, color: c, size: 32)), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(s, style: const TextStyle(color: Colors.grey, fontSize: 13))])), Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 16)]));
  }
}

// ---------------------- 4.6 الملف الشخصي (Profile) ----------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        const SizedBox(height: 50),
        Center(child: CircleAvatar(radius: 60, backgroundColor: AppTheme.primary.withOpacity(0.1), child: Icon(Icons.person, size: 60, color: AppTheme.primary))),
        const SizedBox(height: 20),
        Text(user?.displayName ?? "مستخدم", style: AppTheme.headerStyle),
        Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 40),
        _item("تعديل الملف الشخصي", Icons.edit), _item("الإعدادات", Icons.settings), _item("المساعدة والدعم", Icons.headset_mic),
        const SizedBox(height: 20),
        ProButton(text: "تسجيل الخروج", color: AppTheme.error, icon: Icons.logout, onPressed: () async { await FirebaseAuth.instance.signOut(); if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen())); }),
      ])),
    );
  }
  Widget _item(String t, IconData i) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: Icon(i, color: AppTheme.secondary), title: Text(t), trailing: const Icon(Icons.chevron_right)));
}
// ============================================================================
// 🏥 4.7 خدمات المريض (Patient Services & Orders)
// ============================================================================

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text("الخدمات الطبية")),
        body: Column(
          children: [
            Container(
              color: AppTheme.background,
              child: const TabBar(
                labelColor: AppTheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                tabs: [Tab(text: "طلب جديد"), Tab(text: "سجل الطلبات")],
              ),
            ),
            const Expanded(child: TabBarView(children: [PatientNewOrder(), PatientMyOrders()])),
          ],
        ),
      ),
    );
  }
}

// شاشة اختيار الخدمة (New Order)
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
        ];

        return ListView(
          padding: const EdgeInsets.all(20), 
          children: [
            const Text("اختر الخدمة المطلوبة", style: AppTheme.headerStyle),
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.0),
              itemCount: services.length,
              itemBuilder: (ctx, i) => FadeSlide(delay: i * 100, child: _serviceCard(ctx, services[i]['t'] as String, services[i]['p'] as String, services[i]['i'] as IconData, services[i]['c'] as Color)),
            ),
            const SizedBox(height: 24),
            FadeSlide(
              delay: 500, 
              child: InkWell(
                onTap: () => _customOrderDialog(context), 
                child: Container(
                  padding: const EdgeInsets.all(20), 
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primary.withOpacity(0.3))), 
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary, size: 28), SizedBox(width: 15), Text("طلب خدمة خاصة أخرى", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary))])
                )
              )
            ),
          ]
        );
      }
    );
  }

  Widget _serviceCard(BuildContext context, String title, String price, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: title, price: "$price دج"))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 32)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text("$price دج", style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
  
  void _customOrderDialog(BuildContext context) {
    final c = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text("خدمة خاصة"), content: TextField(controller: c, decoration: const InputDecoration(hintText: "صف الخدمة...")), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("إلغاء")), ElevatedButton(onPressed: (){Navigator.pop(ctx); if(c.text.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_)=>OrderScreen(title: c.text, price: "حسب الاتفاق")));}, child: const Text("متابعة"))]));
  }
}

// سجل الطلبات (Order History) - ✅ تم الإصلاح (لن تختفي الطلبات)
class PatientMyOrders extends StatelessWidget {
  const PatientMyOrders({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // ⚠️ ملاحظة: أزلنا orderBy من هنا لتجنب مشاكل الفهرسة التي كانت تخفي البيانات
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('patient_id', isEqualTo: uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 80, color: Colors.grey[300]), const SizedBox(height: 20), const Text("لا توجد طلبات سابقة")]));
        
        // نقوم بالترتيب هنا يدوياً (أكثر أماناً)
        var docs = snap.data!.docs;
        docs.sort((a, b) {
           Timestamp t1 = a['timestamp'] ?? Timestamp.now();
           Timestamp t2 = b['timestamp'] ?? Timestamp.now();
           return t2.compareTo(t1); // الأحدث أولاً
        });

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            var d = docs[i]; var data = d.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';
            
            // الألوان والحالات
            Color color = AppTheme.waiting;
            String txt = "جاري البحث عن ممرض...";
            IconData icon = Icons.hourglass_top_rounded;

            if (status == 'accepted') { color = Colors.blue; txt = "الممرض ${data['nurse_name'] ?? 'غير معروف'} في الطريق"; icon = Icons.directions_run; }
            if (status == 'completed') { color = AppTheme.success; txt = "اكتملت الخدمة"; icon = Icons.verified; }

            return GlassCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  // رأس البطاقة الملون
                  Container(
                    padding: const EdgeInsets.all(15), 
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))), 
                    child: Row(children: [
                      Icon(icon, color: color, size: 20), 
                      const SizedBox(width: 10), 
                      Text(txt, style: TextStyle(color: color, fontWeight: FontWeight.bold)), 
                      const Spacer(), 
                      if(status=='pending') const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                    ])
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(data['service'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(data['price'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey))]),
                      const SizedBox(height: 20),
                      
                      // أزرار التحكم
                      if (status == 'accepted') ProButton(text: "تأكيد استلام الخدمة", color: AppTheme.success, icon: Icons.check_circle, onPressed: () => d.reference.update({'status': 'completed'})),
                      if (status == 'pending') SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => d.reference.delete(), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error), child: const Text("إلغاء الطلب"))),
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

// شاشة التأكيد (Confirmation) مع الموقع
class OrderScreen extends StatefulWidget {
  final String title; final String price;
  const OrderScreen({super.key, required this.title, required this.price});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  final _phone = TextEditingController(); double? _lat, _lng; bool _locLoading = false;
  
  Future<void> _getLoc() async { 
    setState(() => _locLoading = true); 
    try { 
      LocationPermission p = await Geolocator.checkPermission();
      if(p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if(p == LocationPermission.whileInUse || p == LocationPermission.always) {
         Position pos = await Geolocator.getCurrentPosition(); 
         setState(() { _lat = pos.latitude; _lng = pos.longitude; }); 
      }
    } catch (_) {} 
    setState(() => _locLoading = false); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد الطلب")),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(30), decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(30), boxShadow: AppTheme.glowShadow), child: Column(children: [Text(widget.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)), child: Text(widget.price, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)))])),
        const SizedBox(height: 40),
        SmartTextField(controller: _phone, label: "رقم الهاتف", icon: Icons.phone, type: TextInputType.phone),
        const SizedBox(height: 20),
        InkWell(onTap: _getLoc, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _lat != null ? AppTheme.success.withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _lat != null ? AppTheme.success : Colors.grey.shade300)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [_locLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : Icon(Icons.location_on_rounded, color: _lat != null ? AppTheme.success : Colors.grey), const SizedBox(width: 15), Text(_lat != null ? "تم تحديد الموقع" : "اضغط لتحديد الموقع", style: TextStyle(color: _lat != null ? AppTheme.success : Colors.black54, fontWeight: FontWeight.bold))]))),
        const SizedBox(height: 40),
        ProButton(text: "إرسال الطلب", onPressed: () {
          if (_phone.text.isEmpty || _lat == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("البيانات ناقصة"))); return; }
          FirebaseFirestore.instance.collection('requests').add({'service': widget.title, 'price': widget.price, 'phone': _phone.text, 'lat': _lat, 'lng': _lng, 'status': 'pending', 'timestamp': FieldValue.serverTimestamp(), 'patient_id': FirebaseAuth.instance.currentUser?.uid, 'patient_name': FirebaseAuth.instance.currentUser?.displayName});
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال طلبك بنجاح!"), backgroundColor: AppTheme.success));
        })
      ])),
    );
  }
}
// ============================================================================
// 👩‍⚕️ 4.8 بوابة الممرض (Nurse Gate) - مع التعديلات الجديدة
// ============================================================================

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
          
          // إذا لم يسجل بعد، اعرض الاستمارة
          if (d?['role'] == 'user') return const NurseForm();
          
          // ✅ شاشات انتظار احترافية وملونة (بدلاً من الشاشة البيضاء)
          if (st == 'pending_docs') return _statusScreen(Icons.hourglass_top_rounded, AppTheme.accent, "ملفك قيد المراجعة", "يقوم فريق الإدارة بمراجعة وثائقك بدقة..\nسيتم الرد عليك قريباً.");
          if (st == 'pending_payment') return const NursePay();
          if (st == 'payment_review') return _statusScreen(Icons.verified_user_rounded, Colors.blue, "مراجعة الدفع", "وصلنا الإيصال ونقوم بالتحقق منه لتفعيل حسابك نهائياً.");
          if (st == 'approved') return const NurseDash();
          
          return const NurseForm();
        },
      ),
    );
  }

  Widget _statusScreen(IconData i, Color c, String t, String s) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FadeSlide(child: Container(padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(i, size: 80, color: c))),
        const SizedBox(height: 40),
        FadeSlide(delay: 200, child: Text(t, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: c))),
        const SizedBox(height: 15),
        FadeSlide(delay: 400, child: Text(s, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.grey, height: 1.5))),
      ]),
    ),
  );
}

// استمارة الممرض (✅ تم التعديل: إضافة الاسم + تخصص كتابة حرة)
class NurseForm extends StatefulWidget {
  const NurseForm({super.key});
  @override
  State<NurseForm> createState() => _NurseFormState();
}
class _NurseFormState extends State<NurseForm> {
  final _name = TextEditingController(); 
  final _ph = TextEditingController(); 
  final _ad = TextEditingController(); 
  final _spec = TextEditingController(); // أصبح تيكست عادي للكتابة
  
  String? _p, _i, _d; 
  bool _loading = false;
  
  @override 
  void initState() { 
    super.initState(); 
    _name.text = FirebaseAuth.instance.currentUser?.displayName ?? ""; 
  }
  
  Future<void> _pick(String t) async { 
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 25); 
    if(x!=null) { 
      final b = await File(x.path).readAsBytes(); 
      setState(() { if(t=='p')_p=base64Encode(b); if(t=='i')_i=base64Encode(b); if(t=='d')_d=base64Encode(b); }); 
    } 
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("المعلومات المهنية", style: AppTheme.headerStyle), const SizedBox(height: 20),
      
      // ✅ الحقول الجديدة
      SmartTextField(controller: _name, label: "الاسم الكامل", icon: Icons.person),
      SmartTextField(controller: _ph, label: "رقم الهاتف", icon: Icons.phone),
      SmartTextField(controller: _ad, label: "الولاية / العنوان", icon: Icons.map),
      SmartTextField(controller: _spec, label: "التخصص (مثال: ممرض دولة، قابلة...)", icon: Icons.work_outline),
      
      const SizedBox(height: 30),
      const Text("المستندات المطلوبة", style: AppTheme.headerStyle), const SizedBox(height: 15),
      _docBtn("صورة شخصية", _p, ()=>_pick('p')), 
      _docBtn("بطاقة التعريف", _i, ()=>_pick('i')), 
      _docBtn("الشهادة / الدبلوم", _d, ()=>_pick('d')),
      
      const SizedBox(height: 30),
      ProButton(text: "إرسال الملف للمراجعة", isLoading: _loading, onPressed: () async {
        if(_p==null || _name.text.isEmpty || _spec.text.isEmpty) { 
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى ملء كافة البيانات"))); return; 
        }
        setState(()=>_loading=true);
        await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({
          'role':'nurse',
          'status':'pending_docs',
          'name':_name.text,
          'phone':_ph.text,
          'specialty':_spec.text, // حفظ التخصص كنص
          'address':_ad.text,
          'pic_data':_p, 'id_data':_i, 'diploma_data':_d, 
          'submitted_at': FieldValue.serverTimestamp()
        }, SetOptions(merge:true));
        setState(()=>_loading=false);
      })
    ]));
  }
  Widget _docBtn(String t, String? v, VoidCallback f) => GlassCard(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), onTap: f, child: Row(children: [Icon(v!=null?Icons.check_circle:Icons.cloud_upload_rounded, color: v!=null?AppTheme.success:Colors.grey), const SizedBox(width: 15), Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), if(v!=null) const Text("تم الرفع", style: TextStyle(color: AppTheme.success))]));
}

// شاشة الدفع للممرض
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
      const Icon(Icons.workspace_premium_rounded, size: 80, color: AppTheme.accent),
      const SizedBox(height: 20),
      const Text("تفعيل الاشتراك", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 30),
      Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFA000), Color(0xFFFF6F00)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 20)]), child: const Column(children: [Text("الاشتراك الشهري", style: TextStyle(color: Colors.white70)), SizedBox(height: 10), Text("3500 DA", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)), Divider(color: Colors.white24, height: 40), Text("CCP: 0028939081 - 97", style: TextStyle(color: Colors.white, fontSize: 18))])),
      const SizedBox(height: 30),
      GlassCard(onTap: () async {final x=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:25);if(x!=null){final b=await File(x.path).readAsBytes();setState(()=>_r=base64Encode(b));}}, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_r!=null?Icons.check_circle:Icons.camera_alt, color: _r!=null?AppTheme.success:AppTheme.primary), const SizedBox(width: 15), Text(_r!=null?"تم اختيار الوصل":"رفع صورة الوصل")])),
      const SizedBox(height: 25),
      ProButton(text: "تأكيد الدفع", isLoading: _l, color: AppTheme.success, onPressed: _r==null?null:() async {setState(()=>_l=true);await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({'status':'payment_review','receipt_data':_r});})
    ]));
  }
}

// لوحة تحكم الممرض (Dashboard)
class NurseDash extends StatelessWidget {
  const NurseDash({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text("لوحة التحكم"), bottom: const TabBar(labelColor: AppTheme.primary, indicatorColor: AppTheme.primary, tabs: [Tab(text: "الطلبات الجديدة"), Tab(text: "مهامي")])),
      body: const TabBarView(children: [NurseMarket(), NurseTasks()]),
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات جديدة"));
        return ListView.builder(padding: const EdgeInsets.all(20), itemCount: snap.data!.docs.length, itemBuilder: (ctx, i) {
          var d = snap.data!.docs[i]; var data = d.data() as Map<String, dynamic>;
          // عرض جميع الطلبات
          return GlassCard(child: Column(children: [
            ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: AppTheme.accent.withOpacity(0.1), child: const Icon(Icons.person, color: AppTheme.accent)), title: Text(data['patient_name']??""), subtitle: Text(data['service'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)), trailing: Text(data['price'])),
            const Divider(),
            ProButton(text: "قبول الطلب", onPressed: ()=>d.reference.update({'status':'accepted','nurse_id':FirebaseAuth.instance.currentUser?.uid,'nurse_name':FirebaseAuth.instance.currentUser?.displayName}))
          ]));
        });
      },
    );
  }
}

class NurseTasks extends StatelessWidget {
  const NurseTasks({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('requests').where('nurse_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid).where('status', isEqualTo: 'accepted').snapshots(), builder: (c,s)=>ListView.builder(padding: const EdgeInsets.all(20), itemCount: s.data?.docs.length??0, itemBuilder: (ctx,i){
      var d=s.data!.docs[i]; var data=d.data() as Map;
      return GlassCard(child: Column(children: [ListTile(contentPadding: EdgeInsets.zero, title: Text(data['patient_name']??""), subtitle: Text(data['phone']), leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.directions_run, color: Colors.white))), const SizedBox(height: 10), Row(children: [Expanded(child: ProButton(text: "اتصال", color: AppTheme.success, icon: Icons.call, onPressed: ()=>launchUrl(Uri.parse("tel:${data['phone']}")))), const SizedBox(width: 10), if(data['lat']!=null) Expanded(child: ProButton(text: "الخريطة", color: Colors.blue, icon: Icons.map, onPressed: ()=>launchUrl(Uri.parse("google.navigation:q=${data['lat']},${data['lng']}"))))]), const SizedBox(height: 10), ProButton(text: "أنهيت العمل", isOutlined: true, onPressed: ()=>d.reference.update({'status':'completed_by_nurse'}))]));
    }));
  }
}

// ============================================================================
// 👑 4.10 لوحة الإدارة (Admin Dashboard) - ✅ تم إصلاح اختفاء القائمة
// ============================================================================

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: Scaffold(appBar: AppBar(title: const Text("الإدارة"), bottom: const TabBar(labelColor: Colors.purple, indicatorColor: Colors.purple, tabs: [Tab(text: "التوثيق"), Tab(text: "المالية"), Tab(text: "الأسعار")])), body: const TabBarView(children: [AdminDocs(), AdminPay(), AdminPrices()])));
  }
}

class AdminDocs extends StatelessWidget {
  const AdminDocs({super.key});
  
  // ✅ دالة الحماية (تمنع توقف التطبيق إذا كانت الصورة تالفة)
  Widget _safeImg(String? b64) {
    if (b64 == null || b64.length < 100) return const Icon(Icons.broken_image, color: Colors.grey, size: 40);
    try { return CircleAvatar(backgroundImage: MemoryImage(base64Decode(b64))); } catch (e) { return const Icon(Icons.error, color: Colors.red); }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'pending_docs').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد ملفات معلقة"));
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snap.data!.docs.length,
          itemBuilder: (ctx, i) {
            var d = snap.data!.docs[i];
            var data = d.data() as Map<String, dynamic>;
            // استخدام _safeImg لعرض الصورة بأمان
            return GlassCard(child: ExpansionTile(
              leading: GestureDetector(onTap: ()=>_z(context, data['pic_data']), child: _safeImg(data['pic_data'])),
              title: Text(data['name'] ?? "مجهول"), 
              subtitle: Text(data['specialty'] ?? "غير محدد"),
              children: [
                Padding(padding: const EdgeInsets.all(15), child: Column(children: [
                  Text("الهاتف: ${data['phone']}"), const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [IconButton(icon: const Icon(Icons.credit_card, size: 30, color: AppTheme.primary), onPressed: ()=>_z(context, data['id_data'])), IconButton(icon: const Icon(Icons.school, size: 30, color: AppTheme.primary), onPressed: ()=>_z(context, data['diploma_data']))]),
                  const SizedBox(height: 15),
                  Row(children: [Expanded(child: OutlinedButton(onPressed: ()=>d.reference.update({'status':'rejected'}), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error), child: const Text("رفض"))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: ()=>d.reference.update({'status':'pending_payment'}), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white), child: const Text("قبول")))])
                ]))
              ]
            ));
          }
        );
      },
    );
  }
  void _z(BuildContext c, String? b) { if(b!=null && b.length>100) Navigator.push(c, MaterialPageRoute(builder: (_)=>FullScreenImage(base64Image: b))); }
}

class AdminPay extends StatelessWidget {
  const AdminPay({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'payment_review').snapshots(), builder: (c,s)=>ListView.builder(padding: const EdgeInsets.all(15), itemCount: s.data?.docs.length??0, itemBuilder: (ctx,i){
      var d=s.data!.docs[i]; var data=d.data() as Map;
      return GlassCard(child: ExpansionTile(title: Text(data['name']??""), subtitle: Text(data['email']??""), children: [GestureDetector(onTap: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>FullScreenImage(base64Image:data['receipt_data']))), child: Container(height: 200, margin: const EdgeInsets.all(10), child: data['receipt_data']!=null?Image.memory(base64Decode(data['receipt_data']), fit: BoxFit.cover):null)), Padding(padding: const EdgeInsets.all(10), child: ProButton(text: "تفعيل الحساب", color: AppTheme.success, onPressed: ()=>d.reference.update({'status':'approved'})))]));
    }));
  }
}

class AdminPrices extends StatelessWidget {
  const AdminPrices({super.key});
  @override
  Widget build(BuildContext context) {
    final c1=TextEditingController(), c2=TextEditingController(), c3=TextEditingController(), c4=TextEditingController();
    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [SmartTextField(controller: c1, label: "سعر الحقن", icon: Icons.vaccines), SmartTextField(controller: c2, label: "سعر السيروم", icon: Icons.water_drop), SmartTextField(controller: c3, label: "سعر الضماد", icon: Icons.healing), SmartTextField(controller: c4, label: "سعر الضغط", icon: Icons.monitor_heart), ProButton(text: "حفظ", color: Colors.purple, onPressed: ()=>FirebaseFirestore.instance.collection('config').doc('prices').set({'حقن':c1.text,'سيروم':c2.text,'تغيير ضماد':c3.text,'قياس ضغط':c4.text}, SetOptions(merge:true)))]));
  }
}

class FullScreenImage extends StatelessWidget {
  final String base64Image; const FullScreenImage({super.key, required this.base64Image});
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(iconTheme: const IconThemeData(color: Colors.white)), body: Center(child: InteractiveViewer(child: Image.memory(base64Decode(base64Image)))));
}
