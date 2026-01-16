import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- مكتبات فايربيز ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// --- مكتبات النظام والخرائط ---
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

// --- مكتبات التصميم ---
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

// ============================================================================
// 🛠️ PART 1: INITIALIZATION & THEME (التهيئة، المفاتيح، والثيم)
// ============================================================================

// 1. معالج الإشعارات في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDlQHl2B8d_8nw8-N6_51MEH4j_KYqz7NA",
      appId: "1:311376524644:web:a3d9c77a53c0570a0eb671", 
      messagingSenderId: "311376524644",
      projectId: "afya-dz",
      storageBucket: "afya-dz.firebasestorage.app",
    ),
  );
  print("Background Message: ${message.messageId}");
}

// 2. قناة الإشعارات
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', 
  'إشعارات عافية الهامة', 
  description: 'تستخدم للتنبيهات العاجلة',
  importance: Importance.high,
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 3. دالة التشغيل الرئيسية
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تثبيت الشاشة عمودياً
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  try {
    // ✅ الاتصال المباشر (Direct Connect) لحل مشكلة الشاشة السوداء
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDlQHl2B8d_8nw8-N6_51MEH4j_KYqz7NA",
        appId: "1:311376524644:web:a3d9c77a53c0570a0eb671", 
        messagingSenderId: "311376524644",
        projectId: "afya-dz",
        storageBucket: "afya-dz.firebasestorage.app",
      ),
    );
    print("✅ FIREBASE CONNECTED SUCCESSFULLY");

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

  } catch (e) {
    print("⚠️ Error: $e");
  }

  runApp(const AfyaAppV10());
}

// 4. الألوان الطبية (V10 Palette) - المصححة
class AppColors {
  static const Color primary = Color(0xFF009688); // Teal Medical
  static const Color primaryDark = Color(0xFF00796B);
  static const Color accent = Color(0xFFFFC107); // Amber for alerts
  
  // ✅✅ هذا هو السطر الذي كان ناقصاً وتسبب في الخطأ
  static const Color secondary = Color(0xFF263238); 

  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF2196F3);
}

// 5. مزود الثيم
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
class AfyaAppV10 extends StatefulWidget {
  const AfyaAppV10({super.key});
  @override
  State<AfyaAppV10> createState() => _AfyaAppV10State();
}

class _AfyaAppV10State extends State<AfyaAppV10> {
  @override
  void initState() {
    super.initState();
    themeProvider.loadTheme();
    themeProvider.addListener(() { if (mounted) setState(() {}); });
    
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
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              color: AppColors.primary,
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
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light),
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.primary, foregroundColor: Colors.white, centerTitle: true),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark),
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(), 
    );
  }
}
// ============================================================================
// 🎨 PART 2: UI COMPONENTS & AUTHENTICATION (التصميم وشاشات الدخول)
// ============================================================================

// 1. شاشة البداية (Splash Screen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 3)); // عرض الشعار لمدة 3 ثواني
    if (FirebaseAuth.instance.currentUser != null) {
      // المستخدم مسجل -> توجيه للموجه الرئيسي (سنبني MainWrapper في البارت القادم)
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper()));
    } else {
      // غير مسجل -> شاشة الدخول
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeInDown(
          duration: const Duration(milliseconds: 1200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
                child: const Icon(Icons.local_hospital, size: 80, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text("عافية", style: GoogleFonts.tajawal(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("رعايتك الصحية.. في بيتك", style: GoogleFonts.tajawal(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 50),
              const CircularProgressIndicator(color: Colors.white)
            ],
          ),
        ),
      ),
    );
  }
}

// 2. المكونات المشتركة (Custom Widgets) لضمان الفخامة
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  const GlassCard({super.key, required this.child, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: child,
    );
  }
}

class SmartTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputType type;
  final int maxLines;

  const SmartTextField({
    super.key, 
    required this.controller, 
    required this.label, 
    required this.icon, 
    this.isPassword = false, 
    this.type = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
          hintText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}

class ProButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
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
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 10)],
                  Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
      ),
    );
  }
}

// 3. شاشة التسجيل والدخول الموحدة (Auth Screen)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  // دالة الدخول / التسجيل
  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    if (!_isLogin && (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty)) return;

    setState(() => _loading = true);
    try {
      UserCredential cred;
      if (_isLogin) {
        // تسجيل الدخول
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(), 
          password: _passCtrl.text.trim()
        );
      } else {
        // إنشاء حساب جديد
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(), 
          password: _passCtrl.text.trim()
        );
        
        // حفظ بيانات المستخدم في فايربيز (Firestore)
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': _nameCtrl.text,
          'email': _emailCtrl.text,
          'phone': _phoneCtrl.text,
          'role': 'user', // افتراضياً مستخدم عادي
          'created_at': FieldValue.serverTimestamp(),
          'fcm_token': await FirebaseMessaging.instance.getToken(), // لحفظ توكن الإشعارات
        });
        
        // تحديث اسم المستخدم في Auth
        await cred.user!.updateDisplayName(_nameCtrl.text);
      }
      
      // التوجيه للرئيسية
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper()));

    } on FirebaseAuthException catch (e) {
      String msg = "حدث خطأ ما";
      if (e.code == 'user-not-found') msg = "المستخدم غير موجود";
      if (e.code == 'wrong-password') msg = "كلمة المرور خاطئة";
      if (e.code == 'email-already-in-use') msg = "البريد مسجل مسبقاً";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Center(child: Icon(Icons.security, size: 80, color: AppColors.primary.withOpacity(0.8))),
              const SizedBox(height: 20),
              Text(_isLogin ? "مرحباً بعودتك 👋" : "حساب جديد 🚀", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text(_isLogin ? "سجل دخولك للمتابعة" : "انضم لعائلة عافية الآن", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 40),
              
              if (!_isLogin) ...[
                SmartTextField(controller: _nameCtrl, label: "الاسم الكامل", icon: Icons.person),
                SmartTextField(controller: _phoneCtrl, label: "رقم الهاتف", icon: Icons.phone, type: TextInputType.phone),
              ],
              
              SmartTextField(controller: _emailCtrl, label: "البريد الإلكتروني", icon: Icons.email, type: TextInputType.emailAddress),
              SmartTextField(controller: _passCtrl, label: "كلمة المرور", icon: Icons.lock, isPassword: true),
              
              const SizedBox(height: 30),
              
              ProButton(
                text: _isLogin ? "تسجيل الدخول" : "إنشاء حساب",
                onPressed: _submit,
                isLoading: _loading,
                icon: _isLogin ? Icons.login : Icons.person_add,
              ),
              
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin ? "ليس لديك حساب؟" : "لديك حساب بالفعل؟"),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? "سجل الآن" : "دخول", style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
// ============================================================================
// 🏠 PART 3: MAIN WRAPPER & PATIENT HOME (الموجه الذكي وواجهة المريض)
// ============================================================================

// 1. الموجه الذكي (يفرز المستخدمين حسب الرتبة)
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

  // معرفة رتبة المستخدم وتحديث التوكن
  Future<void> _fetchUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // جلب الرتبة من قاعدة البيانات
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
      } else {
        // حالة نادرة: المستخدم مسجل في Auth لكن ليس في Firestore
        setState(() {
          _userRole = 'user';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 🔥 هنا الحل لمشكلة اختفاء اللوحات: التوجيه حسب الرتبة
    if (_userRole == 'admin') return const AdminDashboard(); // سنبنيها في البارت 7
    if (_userRole == 'nurse') return const NurseDashboard(); // سنبنيها في البارت 6

    // إذا كان مريضاً عادياً، نعرض له شريط التنقل السفلي
    final List<Widget> pages = [
      const PatientHomeScreen(),
      const RequestsHistoryScreen(), // البارت 5
      const ProfileScreen(), // البارت 8
    ];

    return Scaffold(
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
              // الهيدر والترحيب
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("مرحباً بك 👋", style: TextStyle(color: Colors.grey[600])),
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
              const SizedBox(height: 25),

              // بنر العروض (يقرأ من السيرفر مباشرة)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('config').doc('promo').snapshots(),
                builder: (context, snapshot) {
                  // القيم الافتراضية في حال لم يضع الأدمن عرضاً
                  String title = "خدمة تمريض منزلي";
                  String subtitle = "نصلك أينما كنت في الجزائر";
                  bool isActive = false;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    title = data['title'] ?? title;
                    subtitle = data['subtitle'] ?? subtitle;
                    isActive = true;
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                                  child: const Text("عرض خاص 🔥", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                                ),
                              const SizedBox(height: 10),
                              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        // أيقونة طبية كبيرة شفافة
                        Icon(Icons.medical_services_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
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
                    title: "حقن (Injection)", 
                    price: "500 دج", 
                    icon: Icons.vaccines, 
                    color: Colors.blue[50]!, 
                    iconColor: Colors.blue,
                    // سنبني صفحة الطلب RequestServiceScreen في البارت 4
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestServiceScreen(serviceName: "حقن", basePrice: 500))),
                  ),
                  _ServiceCard(
                    title: "سيروم (Serum)", 
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

// مكون بطاقة الخدمة
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(price, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
// ============================================================================
// 🚑 PART 4: REQUEST SERVICE SCREEN (شاشة طلب الخدمة، الخريطة، والموقع)
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
  final _descCtrl = TextEditingController(); 
  String? _selectedWilaya;
  bool _loading = false;
  Position? _currentPosition;
  String _address = "يرجى تحديد موقع المنزل";
  final MapController _mapController = MapController(); // للتحكم في الخريطة

  // قائمة الولايات (يمكن توسيعها)
  final List<String> dzWilayas = [
    "Adrar", "Chlef", "Laghouat", "Oum El Bouaghi", "Batna", "Béjaïa", "Biskra", "Béchar",
    "Blida", "Bouira", "Tamanrasset", "Tébessa", "Tlemcen", "Tiaret", "Tizi Ouzou", "Algiers",
    "Djelfa", "Jijel", "Sétif", "Saïda", "Skikda", "Sidi Bel Abbès", "Annaba", "Guelma",
    "Constantine", "Médéa", "Mostaganem", "M'Sila", "Mascara", "Ouargla", "Oran", "El Bayadh"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ملء الهاتف تلقائياً
  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // محاولة جلب الهاتف من البروفايل أو الوثيقة
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists && doc.data()!.containsKey('phone')) {
          setState(() => _phoneCtrl.text = doc['phone']);
        }
      });
    }
  }

  // 📍 تحديد الموقع الحالي (GPS)
  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "خدمة الموقع (GPS) مغلقة، يرجى تفعيلها";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "تم رفض إذن الموقع";
      }

      // جلب الإحداثيات
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // تحويل الإحداثيات لاسم مدينة (Reverse Geocoding)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
           Placemark place = placemarks.first;
           String? administrativeArea = place.administrativeArea; // الولاية
           
           // محاولة تحديد الولاية تلقائياً في القائمة
           if (administrativeArea != null) {
             for (var w in dzWilayas) {
               if (administrativeArea.toLowerCase().contains(w.toLowerCase())) {
                 setState(() => _selectedWilaya = w);
                 break;
               }
             }
           }
           setState(() => _address = "${place.street}, ${place.locality}");
        }
      } catch (e) {
        setState(() => _address = "تم تحديد الإحداثيات بنجاح ✅");
      }

      setState(() {
        _currentPosition = position;
      });
      
      // تحريك الخريطة للموقع الجديد
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
      
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
      String requestId = const Uuid().v4(); // رقم طلب فريد
      
      // حفظ الطلب
      await FirebaseFirestore.instance.collection('requests').doc(requestId).set({
        'id': requestId,
        'service': widget.serviceName,
        'price': widget.basePrice,
        'patient_id': user?.uid,
        'patient_name': user?.displayName ?? "مريض",
        'phone': _phoneCtrl.text,
        'description': _descCtrl.text,
        'wilaya': _selectedWilaya,
        'location': GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
        'address': _address,
        'status': 'pending', // في الانتظار
        'timestamp': FieldValue.serverTimestamp(),
        'is_emergency': false, // يمكن تفعيلها مستقبلاً
      });
      
      if (mounted) {
        // نجاح! إظهار رسالة والعودة
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: AppColors.success, size: 60),
            title: const Text("تم إرسال الطلب!"),
            content: const Text("تم إشعار الممرضين في منطقتك. يرجى انتظار قبول الطلب."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الديالوج
                  Navigator.pop(context); // العودة للرئيسية
                },
                child: const Text("موافق"),
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
      appBar: AppBar(title: Text("طلب ${widget.serviceName}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // بطاقة ملخص الخدمة
            GlassCard(
              color: AppColors.secondary,
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
            const SizedBox(height: 25),

            // الحقول
            SmartTextField(controller: _phoneCtrl, label: "رقم الهاتف للاتصال", icon: Icons.phone, type: TextInputType.phone),
            SmartTextField(controller: _descCtrl, label: "وصف الحالة (اختياري)", icon: Icons.description, maxLines: 3),
            
            const SizedBox(height: 20),

            // زر تحديد الموقع + الخريطة المصغرة
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(_currentPosition == null ? "تحديد موقعي (GPS)" : "تحديث الموقع"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 10),
                
                // الخريطة (تظهر فقط عند تحديد الموقع)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _currentPosition == null 
                        ? Center(child: Text("لم يتم تحديد الموقع بعد", style: TextStyle(color: Colors.grey[400])))
                        : FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              initialZoom: 15,
                            ),
                            children: [
                              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                              MarkerLayer(markers: [
                                Marker(
                                  point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                )
                              ]),
                            ],
                          ),
                  ),
                ),
                if (_address != "يرجى تحديد موقع المنزل")
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("📍 $_address", style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // قائمة الولايات
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text("اختر الولاية يدوياً"),
                  value: _selectedWilaya,
                  items: dzWilayas.map((String w) {
                    return DropdownMenuItem<String>(value: w, child: Text(w));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedWilaya = val),
                ),
              ),
            ),

            const SizedBox(height: 40),
            
            // زر الإرسال النهائي
            ProButton(
              text: "تأكيد وإرسال الطلب",
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
// 📜 PART 5: REQUESTS HISTORY (سجل الطلبات وتتبع الحالة)
// ============================================================================

class RequestsHistoryScreen extends StatelessWidget {
  const RequestsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("طلباتي السابقة")),
      body: StreamBuilder<QuerySnapshot>(
        // الاستماع المباشر للتغييرات
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('patient_id', isEqualTo: user?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // حالة القائمة فارغة
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

          // عرض القائمة
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              
              // تحديد مظهر البطاقة حسب الحالة
              String status = data['status'] ?? 'pending';
              Color statusColor = AppColors.warning;
              String statusText = "قيد الانتظار ⏳";

              if (status == 'accepted') {
                statusColor = AppColors.info;
                statusText = "تم القبول (الممرض قادم) 🚑";
              } else if (status == 'on_way') {
                statusColor = Colors.purple;
                statusText = "الممرض في الطريق إليك 🚚";
              } else if (status == 'completed') {
                statusColor = AppColors.success;
                statusText = "مكتمل ✅";
              } else if (status == 'cancelled') {
                statusColor = AppColors.error;
                statusText = "ملغي ❌";
              }

              // تنسيق التاريخ
              String dateStr = "الآن";
              if (data['timestamp'] != null) {
                DateTime date = (data['timestamp'] as Timestamp).toDate();
                dateStr = intl.DateFormat('yyyy/MM/dd  hh:mm a').format(date);
              }

              return FadeInUp( // أنيميشن دخول جميل
                duration: Duration(milliseconds: 300 + (index * 100)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        // الرأس: الخدمة والحالة
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(data['service'] ?? "خدمة طبية", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                            )
                          ],
                        ),
                        const Divider(height: 20),
                        
                        // التفاصيل
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 18, color: Colors.grey),
                            Text("${data['price']} دج", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),

                        // معلومات الممرض (تظهر فقط إذا تم القبول)
                        if (data.containsKey('nurse_name') && status != 'pending' && status != 'cancelled') ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                const Icon(Icons.person, size: 20, color: Colors.blue),
                                const SizedBox(width: 10),
                                Text("الممرض: ${data['nurse_name']}"),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.phone, color: Colors.green),
                                  onPressed: () async {
                                    final url = Uri.parse("tel:${data['nurse_phone']}");
                                    if (await canLaunchUrl(url)) await launchUrl(url);
                                  },
                                )
                              ],
                            ),
                          )
                        ],
                        
                        // زر الإلغاء (فقط للطلبات المعلقة)
                        if (status == 'pending') ...[
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text("إلغاء الطلب"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error, 
                                side: const BorderSide(color: AppColors.error)
                              ),
                              onPressed: () async {
                                bool? confirm = await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("تأكيد الإلغاء"),
                                    content: const Text("هل أنت متأكد؟ لا يمكن التراجع عن هذا الإجراء."),
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
                            ),
                          )
                        ]
                      ],
                    ),
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
// 🚑 PART 6: NURSE DASHBOARD (لوحة تحكم الممرض، الخرائط، وإدارة المهام)
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

    // إذا لم يكن للممرض ولاية مسجلة، نطلب منه تحديث الملف
    if (_nurseWilaya == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("لوحة الممرض")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber, size: 60, color: Colors.orange),
              const SizedBox(height: 20),
              const Text("يرجى تحديث ملفك الشخصي وتحديد ولاية العمل", style: TextStyle(fontSize: 16)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())), // البارت 8
                child: const Text("الذهاب للملف الشخصي"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabIndex == 0 ? "طلبات الانتظار ($_nurseWilaya)" : "مهامي النشطة"),
        actions: [
          // زر تحديث القائمة يدوياً
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {})),
        ],
      ),
      body: _tabIndex == 0 
          ? _AvailableRequestsList(wilaya: _nurseWilaya!) // الطلبات الجديدة
          : _MyActiveTasksList(), // المهام المقبولة
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined), 
            selectedIcon: Icon(Icons.list_alt, color: AppColors.primary),
            label: "طلبات جديدة"
          ),
          NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined), 
            selectedIcon: Icon(Icons.local_hospital, color: AppColors.primary),
            label: "مهامي"
          ),
        ],
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
                const Text("لا توجد طلبات جديدة في منطقتك حالياً", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return FadeInUp(
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: _NurseRequestCard(doc: snapshot.data!.docs[index], isMyTask: false),
            );
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
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("ليس لديك مهام نشطة، اذهب للطلبات الجديدة واقبل واحدة"));
        }

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
  final bool isMyTask;

  const _NurseRequestCard({required this.doc, required this.isMyTask});

  // فتح خرائط جوجل للملاحة
  void _openMap(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
          // 1. الخريطة المصغرة (Static Preview)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(loc.latitude, loc.longitude),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // تجميد الخريطة
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
                  // زر القبول (للطلبات الجديدة)
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
                        User nurse = FirebaseAuth.instance.currentUser!;
                        // تحديث حالة الطلب وربطه بالممرض
                        await FirebaseFirestore.instance.collection('requests').doc(doc.id).update({
                          'status': 'accepted',
                          'nurse_id': nurse.uid,
                          'nurse_name': nurse.displayName,
                          'nurse_phone': nurse.phoneNumber ?? "00000000", // يفضل جلب الهاتف من البروفايل
                        });
                      },
                    ),
                  )
                else
                  // أزرار التحكم في المهمة (للمهام النشطة)
                  Row(
                    children: [
                      _CircleBtn(icon: Icons.phone, color: Colors.green, onTap: () => _callPatient(data['phone'])),
                      const SizedBox(width: 10),
                      _CircleBtn(icon: Icons.directions, color: Colors.blue, onTap: () => _openMap(loc.latitude, loc.longitude)),
                      const SizedBox(width: 10),
                      
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
                              )
                            );
                          }
                        ),
                        
                      const Spacer(),

                      // زر تغيير الحالة المتتابع
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: status == 'accepted' ? Colors.purple : AppColors.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          onPressed: () async {
                            if (status == 'accepted') {
                              // تحويل لـ "في الطريق"
                              await FirebaseFirestore.instance.collection('requests').doc(doc.id).update({'status': 'on_way'});
                            } else {
                              // تحويل لـ "مكتمل"
                              await FirebaseFirestore.instance.collection('requests').doc(doc.id).update({'status': 'completed'});
                            }
                          },
                          child: Text(
                            status == 'accepted' ? "أنا في الطريق 🚚" : "إنهاء المهمة ✅", 
                            style: const TextStyle(color: Colors.white, fontSize: 11)
                          ),
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
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
// ============================================================================
// 👮‍♂️ PART 7: ADMIN DASHBOARD (لوحة التحكم المركزية والإدارة)
// ============================================================================

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  final List<Widget> _pages = [
    const _AdminRequestsView(), // مراقبة العمليات
    const _AdminNursesView(),   // إدارة الموظفين
    const _AdminControlRoom(),  // التحكم في الأسعار والعروض
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
            icon: const Icon(Icons.logout, color: Colors.redAccent), 
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
            },
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.monitor_heart), label: "العمليات"),
          NavigationDestination(icon: Icon(Icons.people_alt), label: "الممرضين"),
          NavigationDestination(icon: Icon(Icons.settings_suggest), label: "التحكم"),
        ],
      ),
    );
  }
}

// 1. مراقبة الطلبات (Live Monitor)
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
            
            // تحديد لون الحالة
            Color statusColor = Colors.grey;
            if (data['status'] == 'pending') statusColor = Colors.orange;
            if (data['status'] == 'accepted') statusColor = Colors.blue;
            if (data['status'] == 'completed') statusColor = Colors.green;
            if (data['status'] == 'cancelled') statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: statusColor, child: const Icon(Icons.medical_services, color: Colors.white, size: 15)),
                title: Text("${data['service']} - ${data['wilaya']}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("مريض: ${data['patient_name']}"),
                    if (data.containsKey('nurse_name')) Text("ممرض: ${data['nurse_name']}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    Text(data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate().toString().substring(0, 16) : "", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                trailing: Text("${data['price']} دج", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}

// 2. إدارة الممرضين (Approve / Block)
class _AdminNursesView extends StatelessWidget {
  const _AdminNursesView();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'nurse').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("لا يوجد ممرضين مسجلين"));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            bool isApproved = data['approved'] ?? false; // هل وافق عليه الأدمن؟

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isApproved ? Colors.green : Colors.grey,
                  child: Icon(isApproved ? Icons.check : Icons.person_off, color: Colors.white),
                ),
                title: Text(data['name']),
                subtitle: Text("${data['wilaya'] ?? 'بدون ولاية'} - ${data['phone']}"),
                trailing: Switch(
                  value: isApproved,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    // تفعيل أو تجميد حساب الممرض
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

// 3. ⚙️ غرفة التحكم (Control Room) - الأخطر والأهم
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
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث العروض في كل التطبيقات ✅")));
      _promoTitleCtrl.clear();
      _promoSubCtrl.clear();
    }
  }

  // إرسال إشعار عام
  Future<void> _sendBroadcast() async {
    if (_notifTitleCtrl.text.isEmpty || _notifBodyCtrl.text.isEmpty) return;
    
    // نحفظ الإشعار في مجموعة خاصة (يمكن ربطها بـ Cloud Functions لاحقاً للإرسال الفعلي)
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
          // 1. قسم العروض
          const Text("🏷️ بنر العروض (الشاشة الرئيسية)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: _promoTitleCtrl, decoration: const InputDecoration(labelText: "العنوان (مثال: خصم 50%)", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _promoSubCtrl, decoration: const InputDecoration(labelText: "الوصف الفرعي", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          ProButton(text: "تحديث العرض", onPressed: _updatePromo, color: Colors.orange, isSmall: true),
          
          const Divider(height: 40),

          // 2. قسم الأسعار
          const Text("💰 تسعير الخدمات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("سيتم تحديث الأسعار فوراً لدى جميع المرضى", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          _PriceEditRow(label: "سعر الحقن (Injection)", serviceKey: "injection"),
          _PriceEditRow(label: "سعر السيروم (Serum)", serviceKey: "serum"),
          _PriceEditRow(label: "تغيير ضمادات", serviceKey: "bandage"),
          
          const Divider(height: 40),

          // 3. قسم الإشعارات
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

// مكون صغير لتعديل السعر
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث السعر ✅")));
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
  bool _isFrench = false; // لتغيير اللغة (واجهة فقط حالياً)

  // 1. تعديل الاسم
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
                // تحديث في Auth
                await user?.updateDisplayName(nameCtrl.text);
                // تحديث في Firestore
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

  // 2. اختيار صورة من المعرض
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
            
            // صورة البروفايل
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
                      onTap: _pickImage,
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
                  // زر الوضع الليلي
                  SwitchListTile(
                    title: const Text("الوضع الليلي 🌙"),
                    secondary: const Icon(Icons.dark_mode),
                    value: themeProvider.isDarkMode,
                    onChanged: (val) => themeProvider.toggleTheme(),
                  ),
                  const Divider(height: 1),
                  // زر اللغة
                  SwitchListTile(
                    title: const Text("الفرنسية (Français) 🇫🇷"),
                    secondary: const Icon(Icons.language),
                    subtitle: const Text("تغيير لغة الواجهة"),
                    value: _isFrench,
                    activeColor: Colors.blue,
                    onChanged: (val) {
                      setState(() => _isFrench = val);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("سيتم تفعيل الترجمة الكاملة قريباً")));
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
                      final url = Uri.parse("tel:0697443312"); // رقم الهاتف
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
            Text("V 10.0.0 (Legendary Release)", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// ======================= END OF MAIN.DART =======================
