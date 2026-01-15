import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- المكتبات الخارجية ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// ============================================================================
// 🚀 PART 1: SETUP & KEYS (الإعدادات والمفاتيح اليدوية)
// ============================================================================

// 1. خدمة الإشعارات الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // هنا نستخدم نفس التهيئه اليدوية في الخلفية أيضاً
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDlQHl2B8d_8nw8-N6_51MEH4j_KYqz7NA",
      appId: "1:311376524644:web:a3d9c77a53c0570a0eb671",
      messagingSenderId: "311376524644",
      projectId: "afya-dz",
      storageBucket: "afya-dz.firebasestorage.app",
    ),
  );
  print("Handling a background message: ${message.messageId}");
}

// 2. إعداد قناة الإشعارات
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 3. نقطة البداية (Main)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // ✅✅ الحل السحري: وضعنا المفاتيح هنا مباشرة ولن يطلب ملف google-services.json أبداً
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDlQHl2B8d_8nw8-N6_51MEH4j_KYqz7NA",
        appId: "1:311376524644:web:a3d9c77a53c0570a0eb671", 
        messagingSenderId: "311376524644",
        projectId: "afya-dz",
        storageBucket: "afya-dz.firebasestorage.app",
      ),
    );
    print("✅ Firebase Connected Successfully via Code!");

    // إعداد الإشعارات
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
  } catch (e) {
    print("⚠️ Error Initializing Firebase: $e");
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const AfyaAppPro());
}

// 4. الثوابت والألوان
class AppColors {
  static const Color primary = Color(0xFF00BFA5);
  static const Color primaryDark = Color(0xFF008E76);
  static const Color secondary = Color(0xFF263238);
  static const Color accent = Color(0xFFFFD740);
  static const Color background = Color(0xFFF5F7FA);
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFD50000);
}

// قائمة الولايات
const List<String> dzWilayas = [
  "Adrar", "Chlef", "Laghouat", "Oum El Bouaghi", "Batna", "Béjaïa", "Biskra", "Béchar",
  "Blida", "Bouira", "Tamanrasset", "Tébessa", "Tlemcen", "Tiaret", "Tizi Ouzou", "Algiers",
  "Djelfa", "Jijel", "Sétif", "Saïda", "Skikda", "Sidi Bel Abbès", "Annaba", "Guelma",
  "Constantine", "Médéa", "Mostaganem", "M'Sila", "Mascara", "Ouargla", "Oran", "El Bayadh",
  "Illizi", "Bordj Bou Arréridj", "Boumerdès", "El Tarf", "Tindouf", "Tissemsilt", "El Oued",
  "Khenchela", "Souk Ahras", "Tipaza", "Mila", "Aïn Defla", "Naâma", "Aïn Témouchent",
  "Ghardaïa", "Relizane", "Timimoun", "Bordj Badji Mokhtar", "Ouled Djellal", "Béni Abbès",
  "In Salah", "In Guezzam", "Touggourt", "Djanet", "In Gall", "El Meniaa"
];

// 5. مزود الحالة (Theme)
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}
final themeProvider = ThemeProvider();

// 6. الجذر الرئيسي
class AfyaAppPro extends StatefulWidget {
  const AfyaAppPro({super.key});
  @override
  State<AfyaAppPro> createState() => _AfyaAppProState();
}

class _AfyaAppProState extends State<AfyaAppPro> {
  @override
  void initState() {
    super.initState();
    themeProvider.loadTheme();
    themeProvider.addListener(() { if (mounted) setState(() {}); });
    
    // الاستماع للإشعارات
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: 'launcher_icon',
              importance: Importance.max,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afya DZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark),
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}

// 7. مراقب الإنترنت
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        bool isOffline = snapshot.data != null && snapshot.data!.contains(ConnectivityResult.none);
        return Column(
          children: [
            Expanded(child: child),
            if (isOffline) Container(width: double.infinity, color: Colors.red, padding: const EdgeInsets.all(5), child: const Text("لا يوجد إنترنت ⚠️", textAlign: TextAlign.center, style: TextStyle(color: Colors.white)))
          ],
        );
      },
    );
  }
}
// ============================================================================
// 🎨 PART 2: UI COMPONENTS & AUTHENTICATION (أدوات التصميم والدخول)
// ============================================================================

// 1. حقل الإدخال الذكي (Smart Text Field) - ✅ تصميم دائم الاستدارة
class SmartTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputType type;
  final int maxLines;
  final bool readOnly;

  const SmartTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.type = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  State<SmartTextField> createState() => _SmartTextFieldState();
}

class _SmartTextFieldState extends State<SmartTextField> {
  bool _isFocused = false;
  bool _showPass = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Focus(
        onFocusChange: (focus) => setState(() => _isFocused = focus),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.isPassword && !_showPass,
          keyboardType: widget.type,
          maxLines: widget.maxLines,
          readOnly: widget.readOnly,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _isFocused ? AppColors.primary : Colors.grey,
              fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal
            ),
            prefixIcon: Icon(widget.icon, color: _isFocused ? AppColors.primary : Colors.grey),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  )
                : null,
            filled: true,
            // ✅ تثبيت الحواف الدائرية لمنع المربعات
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), 
              borderSide: const BorderSide(color: AppColors.primary, width: 2)
            ),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.error)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ),
    );
  }
}

// 2. الزر الاحترافي (Pro Button)
class ProButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool isLoading;
  final bool isSmall;

  const ProButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = AppColors.primary,
    this.icon,
    this.isLoading = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isSmall ? null : double.infinity,
      height: isSmall ? 40 : 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: isSmall ? 16 : 22), const SizedBox(width: 10)],
                  Text(text, style: TextStyle(fontSize: isSmall ? 14 : 18, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}

// 3. البطاقة الزجاجية (Glass Card)
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final bool borderGlow;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(15),
    this.color,
    this.borderGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: borderGlow 
              ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5)
              : Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: child,
      ),
    );
  }
}

// 4. شاشة البداية (Splash Screen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.health_and_safety, size: 80, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(child: const Text("Afya DZ", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
            FadeInUp(delay: const Duration(milliseconds: 200), child: const Text("عافيتك تصلك للمنزل", style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 40),
            FadeInUp(delay: const Duration(milliseconds: 400), child: const CircularProgressIndicator(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

// 5. شاشة الشرح (Onboarding)
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.medical_services_outlined, size: 100, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            FadeInUp(child: Text("مرحباً بك في عافية", style: GoogleFonts.tajawal(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
            const SizedBox(height: 15),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text("أقرب ممرض إليك في أقل من 30 دقيقة.\nخدمة موثوقة، آمنة، وسريعة.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
              ),
            ),
            const SizedBox(height: 60),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ProButton(text: "ابدأ الآن", color: Colors.white, onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()))),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// 6. شاشة التسجيل والدخول (Auth Screen)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      } else {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
        
        // حفظ البيانات
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': _nameCtrl.text,
          'email': _emailCtrl.text,
          'role': 'user',
          'created_at': FieldValue.serverTimestamp(),
          // ملاحظة: مع التهيئة اليدوية قد لا يعمل الـ Token في بعض الحالات، لكن لن يوقف التطبيق
          'fcm_token': await FirebaseMessaging.instance.getToken().catchError((e) => null), 
        });
        await cred.user!.updateDisplayName(_nameCtrl.text);
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "حدث خطأ"), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInDown(child: Text(_isLogin ? "تسجيل الدخول" : "إنشاء حساب جديد", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary))),
                const SizedBox(height: 10),
                const Text("مرحباً بعودتك لعافية", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
      
                if (!_isLogin) FadeInUp(child: SmartTextField(controller: _nameCtrl, label: "الاسم الكامل", icon: Icons.person)),
                FadeInUp(delay: const Duration(milliseconds: 100), child: SmartTextField(controller: _emailCtrl, label: "البريد الإلكتروني", icon: Icons.email, type: TextInputType.emailAddress)),
                FadeInUp(delay: const Duration(milliseconds: 200), child: SmartTextField(controller: _passCtrl, label: "كلمة المرور", icon: Icons.lock, isPassword: true)),
      
                const SizedBox(height: 30),
                FadeInUp(delay: const Duration(milliseconds: 300), child: ProButton(text: _isLogin ? "دخول" : "تسجيل", isLoading: _loading, onPressed: _submit)),
                const SizedBox(height: 20),
                TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? "ليس لديك حساب؟ سجل الآن" : "لديك حساب؟ سجل دخولك"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ============================================================================
// 🏠 PART 3: MAIN WRAPPER & HOME SCREEN (الرئيسية والتوجه)
// ============================================================================

// 1. الموجه الرئيسي (Main Wrapper) - يوجه المستخدم حسب رتبته
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _navIndex = 0;
  String? _userRole;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  // معرفة رتبة المستخدم (مريض، ممرض، أدمن)
  Future<void> _fetchUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userRole = doc['role']; // 'admin', 'nurse', 'user'
          _loading = false;
        });
        
        // تحديث توكن الإشعارات لضمان وصول التنبيهات
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcm_token': token});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // توجيه الأدمن والممرض (سنبني شاشاتهم في البارتات القادمة)
    if (_userRole == 'admin') return const AdminDashboard(); // في البارت 7
    if (_userRole == 'nurse') return const NurseDashboard(); // في البارت 6

    // واجهة المريض (Bottom Navigation)
    final List<Widget> pages = [
      const PatientHomeScreen(),
      const RequestsHistoryScreen(), // في البارت 5
      const ProfileScreen(), // في البارت 8
    ];

    return ConnectivityWrapper(
      child: Scaffold(
        body: pages[_navIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.primary), label: "الرئيسية"),
            NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history, color: AppColors.primary), label: "طلباتي"),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.primary), label: "حسابي"),
          ],
        ),
      ),
    );
  }
}

// 2. الشاشة الرئيسية للمريض (Patient Home)
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر (الترحيب)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("مرحباً بك 👋", style: TextStyle(color: Colors.grey)),
                      Text(user?.displayName ?? "زائر", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
                    child: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // شريط البحث
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "ابحث عن خدمة، ممرض...",
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // ✅ استدعاء العروض من الفايربيز مباشرة
              const Text("عروض حصرية 🔥", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('config').doc('promo').snapshots(),
                builder: (context, snapshot) {
                  // النص الافتراضي
                  String title = "خصم 20% هذا الأسبوع";
                  String subtitle = "على جميع الحقن المنزلية";
                  
                  if (snapshot.hasData && snapshot.data!.exists) {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    title = data['title'] ?? title;
                    subtitle = data['subtitle'] ?? subtitle;
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD740), Color(0xFFFFAB00)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(20)),
                                child: const Text("مكتمل", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 10),
                              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(subtitle, style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        const Icon(Icons.local_offer, size: 60, color: Colors.white24),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),
              const Text("خدماتنا الطبية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // شبكة الخدمات
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _ServiceCard(
                    title: "حقن", 
                    price: "500 دج", 
                    icon: Icons.vaccines, 
                    color: Colors.blue[50]!, 
                    iconColor: Colors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestServiceScreen(serviceName: "حقن", basePrice: 500))),
                  ),
                  _ServiceCard(
                    title: "سيروم", 
                    price: "1500 دج", 
                    icon: Icons.water_drop, 
                    color: Colors.cyan[50]!, 
                    iconColor: Colors.cyan,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestServiceScreen(serviceName: "سيروم", basePrice: 1500))),
                  ),
                  _ServiceCard(
                    title: "تغيير ضمادات", 
                    price: "800 دج", 
                    icon: Icons.healing, 
                    color: Colors.purple[50]!, 
                    iconColor: Colors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestServiceScreen(serviceName: "تغيير ضمادات", basePrice: 800))),
                  ),
                  _ServiceCard(
                    title: "قياس ضغط", 
                    price: "300 دج", 
                    icon: Icons.monitor_heart, 
                    color: Colors.red[50]!, 
                    iconColor: Colors.red,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestServiceScreen(serviceName: "قياس ضغط", basePrice: 300))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. بطاقة الخدمة (مكون صغير)
class _ServiceCard extends StatelessWidget {
  final String title;
  final String price;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ServiceCard({required this.title, required this.price, required this.icon, required this.color, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(price, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
// ============================================================================
// 🚑 PART 4: REQUEST SERVICE SCREEN (شاشة طلب الخدمة وتحديد الموقع)
// ============================================================================

class RequestServiceScreen extends StatefulWidget {
  final String serviceName;
  final int basePrice;

  const RequestServiceScreen({super.key, required this.serviceName, required this.basePrice});

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController(); // وصف الحالة (مهم للممرض)
  String? _selectedWilaya;
  bool _loading = false;
  Position? _currentPosition;
  String _address = "يرجى تحديد موقع المنزل";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ملء الهاتف تلقائياً
  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    // إذا كان لدينا رقم هاتف محفوظ
    if (user != null && user.phoneNumber != null) {
      _phoneCtrl.text = user.phoneNumber!;
    }
  }

  // 📍 تحديد الموقع الحالي (GPS)
  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "خدمة الموقع مغلقة، يرجى تفعيل GPS";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "تم رفض إذن الموقع";
      }

      // جلب الإحداثيات
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // محاولة تحويل الإحداثيات لاسم مدينة (Geocoding)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
           String? administrativeArea = placemarks.first.administrativeArea; // اسم الولاية
           if (administrativeArea != null) {
             // محاولة تحديد الولاية تلقائياً
             for (var w in dzWilayas) {
               if (administrativeArea.toLowerCase().contains(w.toLowerCase())) {
                 setState(() => _selectedWilaya = w);
                 break;
               }
             }
           }
           setState(() => _address = "${placemarks.first.street}, ${placemarks.first.locality}");
        }
      } catch (e) {
        setState(() => _address = "تم تحديد الإحداثيات بنجاح ✅");
      }

      setState(() => _currentPosition = position);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  // 🚀 إرسال الطلب للسيرفر
  Future<void> _submitRequest() async {
    if (_phoneCtrl.text.isEmpty || _selectedWilaya == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى ملء الهاتف، واختيار الولاية، وتحديد الموقع"), backgroundColor: AppColors.warning)
      );
      return;
    }

    setState(() => _loading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      
      // حفظ الطلب في قاعدة البيانات
      await FirebaseFirestore.instance.collection('requests').add({
        'service': widget.serviceName,
        'price': widget.basePrice,
        'patient_id': user?.uid,
        'patient_name': user?.displayName ?? "مريض",
        'phone': _phoneCtrl.text,
        'description': _descCtrl.text, // الملاحظات
        'wilaya': _selectedWilaya,
        'location': GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude), // الإحداثيات
        'address': _address,
        'status': 'pending', // الحالة المبدئية
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: AppColors.success, size: 50),
            title: const Text("تم إرسال الطلب!"),
            content: const Text("طلبك وصل لجميع الممرضين في منطقتك. انتظر اتصالاً قريباً."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الديالوج
                  Navigator.pop(context); // العودة للرئيسية
                },
                child: const Text("حسناً"),
              )
            ],
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل الإرسال: $e"), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تأكيد طلب ${widget.serviceName}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // بطاقة ملخص الخدمة
            GlassCard(
              color: const Color(0xFF263238),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(widget.serviceName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                      child: Text("${widget.basePrice} دج", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // حقول الإدخال
            SmartTextField(controller: _phoneCtrl, label: "رقم الهاتف للاتصال", icon: Icons.phone, type: TextInputType.phone),
            
            SmartTextField(
              controller: _descCtrl, 
              label: "وصف الحالة (اختياري)", 
              icon: Icons.description, 
              maxLines: 3, 
            ),
            const Text("مثال: الطابق الثالث، الجرس معطل، حساسية...", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),

            // زر الموقع
            GestureDetector(
              onTap: _getCurrentLocation,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _currentPosition == null ? Colors.grey.shade300 : AppColors.success)
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: _currentPosition == null ? Colors.grey : AppColors.success),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_currentPosition == null ? "تحديد موقع المنزل" : "تم تحديد الموقع", style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (_currentPosition != null) Text(_address, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (_loading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // قائمة الولايات
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text("اختر الولاية"),
                  value: _selectedWilaya,
                  items: dzWilayas.map((String w) {
                    return DropdownMenuItem<String>(value: w, child: Text(w));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedWilaya = val),
                ),
              ),
            ),

            const SizedBox(height: 40),
            
            ProButton(
              text: "إرسال الطلب الآن",
              icon: Icons.send,
              isLoading: _loading,
              onPressed: _submitRequest,
            )
          ],
        ),
      ),
    );
  }
}
// ============================================================================
// 📜 PART 5: REQUESTS HISTORY (سجل طلبات المريض)
// ============================================================================

class RequestsHistoryScreen extends StatelessWidget {
  const RequestsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("طلباتي السابقة")),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ هذا الكود يستمع للتغييرات في قاعدة البيانات مباشرة
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('patient_id', isEqualTo: user?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("لا توجد طلبات سابقة", style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              
              // تحديد اللون والنص حسب الحالة
              String status = data['status'] ?? 'pending';
              Color statusColor = Colors.orange;
              String statusText = "قيد الانتظار ⏳";

              if (status == 'accepted') {
                statusColor = Colors.blue;
                statusText = "تم القبول (الممرض قادم) 🚑";
              } else if (status == 'completed') {
                statusColor = Colors.green;
                statusText = "مكتمل ✅";
              } else if (status == 'cancelled') {
                statusColor = Colors.red;
                statusText = "ملغي ❌";
              } else if (status == 'on_way') {
                statusColor = Colors.purple;
                statusText = "الممرض في الطريق 🚚";
              }

              // تحويل التاريخ من Timestamp لنص مقروء
              String dateStr = "الآن";
              if (data['timestamp'] != null) {
                DateTime date = (data['timestamp'] as Timestamp).toDate();
                dateStr = intl.DateFormat('yyyy/MM/dd  hh:mm a').format(date);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['service'] ?? "خدمة", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, size: 18, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text("${data['price']} دج", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      
                      // زر الإلغاء (يظهر فقط إذا كان الطلب معلقاً)
                      if (status == 'pending') ...[
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              // تأكيد الإلغاء
                              bool? confirm = await showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("إلغاء الطلب؟"),
                                  content: const Text("هل أنت متأكد من إلغاء هذا الطلب؟"),
                                  actions: [
                                    TextButton(child: const Text("تراجع"), onPressed: () => Navigator.pop(context, false)),
                                    TextButton(child: const Text("نعم، الغِ الطلب", style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(context, true)),
                                  ],
                                )
                              );
                              
                              if (confirm == true) {
                                await FirebaseFirestore.instance.collection('requests').doc(doc.id).update({'status': 'cancelled'});
                              }
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                            child: const Text("إلغاء الطلب"),
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
// ============================================================================
// 🚑 PART 6: NURSE DASHBOARD (لوحة تحكم الممرض)
// ============================================================================

class NurseDashboard extends StatefulWidget {
  const NurseDashboard({super.key});
  @override
  State<NurseDashboard> createState() => _NurseDashboardState();
}

class _NurseDashboardState extends State<NurseDashboard> {
  int _tabIndex = 0; // 0 = الطلبات الجديدة، 1 = مهامي الحالية
  String? _nurseWilaya;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getNurseData();
  }

  // جلب بيانات الممرض (لمعرفة ولايته)
  Future<void> _getNurseData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _nurseWilaya = doc['wilaya']; // مثلاً "Oran"
          _loading = false;
        });
        // تحديث التوكن لاستلام الإشعارات
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcm_token': token});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // إذا لم يكن للممرض ولاية مسجلة
    if (_nurseWilaya == null) return const Scaffold(body: Center(child: Text("يرجى تحديث ملفك الشخصي وتحديد الولاية")));

    return ConnectivityWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tabIndex == 0 ? "طلبات الانتظار ($_nurseWilaya)" : "مهامي الحالية"),
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen())))),
          ],
        ),
        body: _tabIndex == 0 
            ? _AvailableRequestsList(wilaya: _nurseWilaya!) // الطلبات الجديدة
            : _MyActiveTasksList(), // المهام المقبولة
        
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (i) => setState(() => _tabIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.list_alt), label: "طلبات جديدة"),
            NavigationDestination(icon: Icon(Icons.local_hospital), label: "مهامي"),
          ],
        ),
      ),
    );
  }
}

// 1. قائمة الطلبات الجديدة (المتوفرة في الولاية)
class _AvailableRequestsList extends StatelessWidget {
  final String wilaya;
  const _AvailableRequestsList({required this.wilaya});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('wilaya', isEqualTo: wilaya) // ✅ فلترة حسب الولاية
          .where('status', isEqualTo: 'pending') // ✅ فقط الطلبات المعلقة
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 10),
                const Text("لا توجد طلبات جديدة في ولايتك حالياً", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return _NurseRequestCard(doc: snapshot.data!.docs[index], isMyTask: false);
          },
        );
      },
    );
  }
}

// 2. قائمة مهامي (التي قبلتها أنا)
class _MyActiveTasksList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser!.uid;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('nurse_id', isEqualTo: myId) // ✅ طلباتي أنا فقط
          .where('status', whereIn: ['accepted', 'on_way']) // ✅ لم تكتمل بعد
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("ليس لديك مهام نشطة"));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return _NurseRequestCard(doc: snapshot.data!.docs[index], isMyTask: true);
          },
        );
      },
    );
  }
}

// 3. بطاقة الطلب الذكية للممرض
class _NurseRequestCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool isMyTask; // هل هذا الطلب في قائمة مهامي أم في الانتظار؟

  const _NurseRequestCard({required this.doc, required this.isMyTask});

  // فتح خرائط جوجل
  void _openMap(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // الاتصال بالمريض
  void _callPatient(String phone) async {
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    var data = doc.data() as Map<String, dynamic>;
    GeoPoint loc = data['location'];
    String status = data['status'];
    
    // التحقق من وجود ملاحظة
    bool hasNote = data['description'] != null && data['description'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          // 1. الخريطة المصغرة
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(loc.latitude, loc.longitude),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // تعطيل التحريك
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  MarkerLayer(markers: [
                    Marker(point: LatLng(loc.latitude, loc.longitude), child: const Icon(Icons.location_on, color: Colors.red, size: 40))
                  ])
                ],
              ),
            ),
          ),
          
          // 2. تفاصيل الطلب
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['service'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                      child: Text("${data['price']} دج", style: const TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 5),
                Text("المريض: ${data['patient_name']}", style: const TextStyle(color: Colors.grey)),
                Text("العنوان: ${data['address']}", style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                
                const SizedBox(height: 15),

                // 3. أزرار التحكم
                if (!isMyTask)
                  // زر القبول
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text("قبول الطلب"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () async {
                        // تحديث الحالة لـ "مقبول" وربط الممرض
                        User nurse = FirebaseAuth.instance.currentUser!;
                        await FirebaseFirestore.instance.collection('requests').doc(doc.id).update({
                          'status': 'accepted',
                          'nurse_id': nurse.uid,
                          'nurse_name': nurse.displayName,
                          'nurse_phone': nurse.phoneNumber ?? "00000000",
                        });
                      },
                    ),
                  )
                else
                  // أزرار التحكم في المهمة
                  Row(
                    children: [
                      // زر الاتصال
                      _CircleBtn(icon: Icons.phone, color: Colors.green, onTap: () => _callPatient(data['phone'])),
                      const SizedBox(width: 10),
                      // زر الملاحة
                      _CircleBtn(icon: Icons.map, color: Colors.blue, onTap: () => _openMap(loc.latitude, loc.longitude)),
                      const SizedBox(width: 10),
                      
                      // زر الملاحظة
                      if (hasNote)
                        _CircleBtn(
                          icon: Icons.sticky_note_2, 
                          color: Colors.orange, 
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("ملاحظة المريض"),
                                content: Text(data['description']),
                                icon: const Icon(Icons.info, color: Colors.orange),
                              )
                            );
                          }
                        ),
                        
                      const Spacer(),

                      // زر تغيير الحالة
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: status == 'accepted' ? Colors.orange : AppColors.primary),
                          onPressed: () async {
                            if (status == 'accepted') {
                              // تحويل لـ "في الطريق"
                              await FirebaseFirestore.instance.collection('requests').doc(doc.id).update({'status': 'on_way'});
                            } else {
                              // تحويل لـ "مكتمل"
                              await FirebaseFirestore.instance.collection('requests').doc(doc.id).update({'status': 'completed'});
                            }
                          },
                          child: Text(status == 'accepted' ? "أنا في الطريق" : "إنهاء المهمة", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      )
                    ],
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// زر دائري صغير
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
// ============================================================================
// 👮‍♂️ PART 7: ADMIN DASHBOARD (لوحة الإدارة والتحكم الكامل)
// ============================================================================

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  final List<Widget> _pages = [
    const _AdminRequestsView(), // مراقبة الطلبات
    const _AdminNursesView(),   // إدارة الممرضين
    const _AdminControlRoom(),  // غرفة التحكم (أسعار + عروض + إشعارات)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الإدارة المركزية 👮‍♂️"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen())))
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long), label: "الطلبات"),
          NavigationDestination(icon: Icon(Icons.people_alt), label: "الممرضين"),
          NavigationDestination(icon: Icon(Icons.settings_suggest), label: "التحكم"),
        ],
      ),
    );
  }
}

// 1. عرض كل الطلبات (للمراقبة فقط)
class _AdminRequestsView extends StatelessWidget {
  const _AdminRequestsView();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text("${data['service']} - ${data['wilaya']}"),
              subtitle: Text("مريض: ${data['patient_name']} | ممرض: ${data['nurse_name'] ?? '---'}"),
              trailing: Text(data['status'], style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }
}

// 2. إدارة الممرضين (تفعيل / حظر)
class _AdminNursesView extends StatelessWidget {
  const _AdminNursesView();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'nurse').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            bool isApproved = data['approved'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.medical_services, color: isApproved ? Colors.white : Colors.grey), backgroundColor: isApproved ? Colors.green : Colors.grey[300]),
                title: Text(data['name']),
                subtitle: Text("${data['wilaya']} - ${data['phone']}"),
                trailing: Switch(
                  value: isApproved,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    FirebaseFirestore.instance.collection('users').doc(doc.id).update({'approved': val});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 3. ⚙️ غرفة التحكم (Control Room)
class _AdminControlRoom extends StatefulWidget {
  const _AdminControlRoom();
  @override
  State<_AdminControlRoom> createState() => _AdminControlRoomState();
}

class _AdminControlRoomState extends State<_AdminControlRoom> {
  final _promoTitleCtrl = TextEditingController();
  final _promoSubCtrl = TextEditingController();
  
  final _notifTitleCtrl = TextEditingController();
  final _notifBodyCtrl = TextEditingController();
  
  // تحديث بنر العروض
  void _updatePromo() {
    if (_promoTitleCtrl.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('config').doc('promo').set({
        'title': _promoTitleCtrl.text,
        'subtitle': _promoSubCtrl.text,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث العروض ✅")));
    }
  }

  // إرسال إشعار للجميع
  Future<void> _sendBroadcast() async {
    if (_notifTitleCtrl.text.isEmpty || _notifBodyCtrl.text.isEmpty) return;
    
    // محاكاة إرسال (لأن الإرسال الحقيقي يحتاج Cloud Functions)
    // هنا سنحفظه في قاعدة البيانات فقط
    await FirebaseFirestore.instance.collection('broadcasts').add({
      'title': _notifTitleCtrl.text,
      'body': _notifBodyCtrl.text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم جدولة الإشعار للإرسال 🚀")));
    _notifTitleCtrl.clear();
    _notifBodyCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🏷️ إدارة العروض (البنر)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: _promoTitleCtrl, decoration: const InputDecoration(labelText: "العنوان (مثال: خصم 50%)", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _promoSubCtrl, decoration: const InputDecoration(labelText: "الوصف الفرعي", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          ProButton(text: "تحديث العرض", onPressed: _updatePromo, color: Colors.orange, isSmall: true),
          
          const Divider(height: 40),

          const Text("💰 إدارة الأسعار", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("غيّر الأسعار الحالية", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          _PriceEditRow(label: "سعر الحقن", serviceKey: "injection"),
          _PriceEditRow(label: "سعر السيروم", serviceKey: "serum"),
          
          const Divider(height: 40),

          const Text("📢 بث إشعار للجميع", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
          const SizedBox(height: 10),
          TextField(controller: _notifTitleCtrl, decoration: const InputDecoration(labelText: "عنوان الإشعار", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _notifBodyCtrl, decoration: const InputDecoration(labelText: "نص الرسالة", border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 10),
          ProButton(text: "إرسال لجميع المستخدمين", icon: Icons.send, onPressed: _sendBroadcast, color: Colors.purple),
        ],
      ),
    );
  }
}

// صف صغير لتعديل السعر
class _PriceEditRow extends StatelessWidget {
  final String label;
  final String serviceKey;
  const _PriceEditRow({required this.label, required this.serviceKey});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(width: 100, child: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "السعر", isDense: true, border: OutlineInputBorder()))),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.green),
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('config').doc('prices').set({serviceKey: int.parse(ctrl.text)}, SetOptions(merge: true));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ")));
              }
            },
          )
        ],
      ),
    );
  }
}
// ============================================================================
// 👤 PART 8: PROFILE & SETTINGS (الملف الشخصي والإعدادات النهائية)
// ============================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  File? _localImage; // لحفظ الصورة المؤقتة من المعرض
  bool _isFrench = false; // لتغيير اللغة

  // 1. تغيير الاسم
  void _editName() {
    final nameCtrl = TextEditingController(text: user?.displayName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تغيير الاسم"),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "الاسم الجديد", border: OutlineInputBorder())),
        actions: [
          TextButton(child: const Text("إلغاء"), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text("حفظ"),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                // تحديث في فايربيز Auth
                await user?.updateDisplayName(nameCtrl.text);
                // تحديث في قاعدة البيانات
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'name': nameCtrl.text});
                
                await user?.reload();
                setState(() => user = FirebaseAuth.instance.currentUser);
                if (mounted) Navigator.pop(context);
              }
            },
          )
        ],
      ),
    );
  }

  // 2. تغيير الصورة (فتح المعرض)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _localImage = File(image.path);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث الصورة (محلياً) ✅")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الملف الشخصي")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // صورة البروفايل مع زر التعديل
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: _localImage != null 
                          ? FileImage(_localImage!) as ImageProvider
                          : const NetworkImage("https://cdn-icons-png.flaticon.com/512/3135/3135715.png"), // صورة افتراضية
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage, // ✅ فتح المعرض
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            
            // الاسم والبريد
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(user?.displayName ?? "مستخدم", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.grey), onPressed: _editName)
              ],
            ),
            Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 40),

            // الإعدادات العامة
            const Align(alignment: Alignment.centerRight, child: Text("الإعدادات العامة", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("الوضع الليلي 🌙"),
                    value: themeProvider.isDarkMode,
                    onChanged: (val) => themeProvider.toggleTheme(),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text("اللغة الفرنسية (Français) 🇫🇷"),
                    subtitle: const Text("تغيير لغة التطبيق"),
                    value: _isFrench,
                    activeColor: Colors.blue,
                    onChanged: (val) {
                      setState(() => _isFrench = val);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("سيتم إضافة الترجمة الكاملة في التحديث القادم")));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerRight, child: Text("الدعم والأمان", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),

            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.headset_mic, color: Colors.green)),
                    title: const Text("المساعدة والدعم"),
                    subtitle: const Text("تواصل مباشر مع الإدارة"),
                    onTap: () async {
                      final url = Uri.parse("tel:0697443312"); // رقمك
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.logout, color: Colors.red)),
                    title: const Text("تسجيل الخروج"),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (route) => false);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            Text("V 2.0.0 (Direct Connect Edition)", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
