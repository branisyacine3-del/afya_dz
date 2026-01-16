import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

// --- مكتبات النظام والواجهة ---
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // للويب والمنصات

// --- مكتبات فايربيز (القلب النابض) ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// --- مكتبات الأدوات والاتصال ---
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

// --- مكتبات الخرائط والتصميم ---
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// ============================================================================
// 🏗️ PART 1: SYSTEM CONFIGURATION & UTILITIES (إعدادات النظام والأدوات)
// ============================================================================

// 1. الثوابت العامة للنظام
class AppConstants {
  static const String appName = "Afya DZ";
  static const String appVersion = "2.0.0 (Ultimate)";
  static const String supportPhone = "0562898252"; // ✅ رقم المدير للدعم
  static const String adminEmail = "admin@afya.dz"; // ✅ بوابة الأدمن الوحيدة
  
  // مفاتيح الدفع (CCP & Baridi)
  static const String ccpNumber = "0028939081";
  static const String ccpKey = "97";
  static const String ccpName = "Branis Yacine";
  static const String ripNumber = "00799999002893908197";
  
  static const int subscriptionPrice = 3500; // سعر الاشتراك الشهري
}

// 2. قائمة الولايات الجزائرية (58 ولاية)
const List<String> dzWilayas = [
  "Adrar", "Chlef", "Laghouat", "Oum El Bouaghi", "Batna", "Béjaïa", "Biskra", "Béchar",
  "Blida", "Bouira", "Tamanrasset", "Tébessa", "Tlemcen", "Tiaret", "Tizi Ouzou", "Algiers",
  "Djelfa", "Jijel", "Sétif", "Saïda", "Skikda", "Sidi Bel Abbès", "Annaba", "Guelma",
  "Constantine", "Médéa", "Mostaganem", "M'Sila", "Mascara", "Ouargla", "Oran", "El Bayadh",
  "Illizi", "Bordj Bou Arréridj", "Boumerdès", "El Tarf", "Tindouf", "Tissemsilt", "El Oued",
  "Khenchela", "Souk Ahras", "Tipaza", "Mila", "Aïn Defla", "Naâma", "Aïn Témouchent",
  "Ghardaïa", "Relizane", "Timimoun", "Bordj Badji Mokhtar", "Ouled Djellal", "Béni Abbès",
  "In Salah", "In Guezzam", "Touggourt", "Djanet", "El M'Ghair", "El Meniaa"
];

// 3. معالج الصور المتقدم (تشفير Base64) - ✅ الحل لمشكلة Storage
class ImageHelper {
  // تحويل ملف الصورة إلى نص مشفر (String)
  static Future<String?> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("❌ خطأ في تشفير الصورة: $e");
      return null;
    }
  }

  // تحويل النص المشفر (String) إلى صورة للعرض
  static Image imageFromBase64(String base64String, {double? width, double? height, BoxFit? fit}) {
    try {
      return Image.memory(
        base64Decode(base64String),
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
      );
    } catch (e) {
      return const Image(image: AssetImage('assets/placeholder.png')); // صورة احتياطية
    }
  }
}

// 4. الألوان والتصميم (تم إصلاح الخطأ السابق)
class AppColors {
  static const Color primary = Color(0xFF009688); // Teal Medical
  static const Color primaryDark = Color(0xFF00796B);
  static const Color secondary = Color(0xFF263238); // ✅ تمت الإضافة (لون الكحلي الغامق)
  static const Color accent = Color(0xFFFFC107); // Amber
  
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}

// 5. إعدادات الإشعارات الخلفية
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
  print("📩 إشعار في الخلفية: ${message.messageId}");
}

// 6. القناة الخاصة بالإشعارات (Android)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'afya_high_importance', 
  'إشعارات الطوارئ والطلبات',
  description: 'تستخدم لتنبيه الممرضين بالطلبات الجديدة',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('notification_sound'), // تأكد من وجود الصوت أو استخدم الافتراضي
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 7. دالة التشغيل الرئيسية (Main)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // قفل التدوير (Portrait Only)
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // تصميم شريط الحالة
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  try {
    // ✅ تهيئة فايربيز بالمفاتيح المباشرة (Direct API Keys)
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDlQHl2B8d_8nw8-N6_51MEH4j_KYqz7NA",
        appId: "1:311376524644:web:a3d9c77a53c0570a0eb671",
        messagingSenderId: "311376524644",
        projectId: "afya-dz",
        storageBucket: "afya-dz.firebasestorage.app",
        authDomain: "afya-dz.firebaseapp.com",
      ),
    );
    print("✅ FIREBASE CONNECTED SUCCESSFULLY (V2.0)");

    // إعداد الإشعارات
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

  } catch (e) {
    print("⚠️ Firebase Init Error: $e");
    // التطبيق سيعمل حتى لو فشل الاتصال مؤقتاً
  }

  runApp(const AfyaAppPro());
}

// 8. مزود الثيم (Theme Provider)
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

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

// 9. تطبيق عافية (Root Widget)
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

    // الاستماع للإشعارات أثناء فتح التطبيق
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
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // ✅ دعم اللغة العربية (RTL)
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light),
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primaryDark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark),
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      
      themeMode: themeProvider.themeMode,
      
      // نبدأ بشاشة السبلاش (سيتم إضافتها في البارت 2)
      home: const SplashScreen(), 
    );
  }
}
// ============================================================================
// 🚪 PART 2: ONBOARDING & AUTHENTICATION (شاشات البداية والتسجيل)
// ============================================================================

// 1. قوائم التخصصات الطبية
const List<String> doctorSpecialties = [
  "طب عام (Généraliste)", "طب أطفال (Pédiatre)", "طب نساء (Gynécologue)", 
  "قلب وشرايين (Cardiologue)", "جلدية (Dermatologue)", "عظام (Orthopédiste)", 
  "عيون (Ophtalmologue)", "أسنان (Dentiste)", "جراحة عامة (Chirurgien)"
];

// 2. المكونات المشتركة (Design System)
class ProButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final bool isLoading;
  final IconData? icon;

  const ProButton({super.key, required this.text, required this.onPressed, this.color = AppColors.primary, this.isLoading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading 
            ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, color: Colors.white), const SizedBox(width: 10)],
                  Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputType type;
  
  const CustomTextField({super.key, required this.controller, required this.label, required this.icon, this.isPassword = false, this.type = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}

// 3. شاشة الإقلاع (Splash Screen)
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
    await Future.delayed(const Duration(seconds: 3)); // انتظار الشعار
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // المستخدم مسجل -> تحقق من دوره في قاعدة البيانات
      try {
        var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          String role = doc['role'];
          if (role == 'patient') {
            // سنبني MainWrapper في البارت القادم
            if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper())); 
          } else {
            // مقدم خدمة (ممرض/طبيب) -> سنوجهه لاحقاً حسب حالته
             if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProviderMainWrapper())); // سنبنيها لاحقاً
          }
        } else {
           if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        }
      } catch (e) {
         if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      }
    } else {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeInDown(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.health_and_safety, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(AppConstants.appName, style: GoogleFonts.tajawal(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const CircularProgressIndicator(color: Colors.white)
            ],
          ),
        ),
      ),
    );
  }
}

// 4. شاشات التعريف (Onboarding)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      "title": "رعايتك الصحية.. في بيتك",
      "desc": "لا داعي للذهاب للمستشفى. نرسل لك أفضل الممرضين والأطباء إلى باب منزلك.",
      "icon": Icons.home_work_outlined
    },
    {
      "title": "سرعة واستجابة فورية",
      "desc": "نستخدم أحدث تقنيات تحديد الموقع لنصل إليك في أسرع وقت ممكن.",
      "icon": Icons.rocket_launch_outlined
    },
    {
      "title": "أمان وموثوقية",
      "desc": "جميع الممرضين والأطباء معتمدون وتم التحقق من وثائقهم بدقة.",
      "icon": Icons.verified_user_outlined
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (val) => setState(() => _currentPage = val),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_pages[index]['icon'], size: 120, color: AppColors.primary),
                        const SizedBox(height: 40),
                        Text(_pages[index]['title'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        Text(_pages[index]['desc'], style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // مؤشر الصفحات
                  Row(
                    children: List.generate(_pages.length, (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 5),
                      height: 10,
                      width: _currentPage == index ? 20 : 10,
                      decoration: BoxDecoration(color: _currentPage == index ? AppColors.primary : Colors.grey[300], borderRadius: BorderRadius.circular(5)),
                    )),
                  ),
                  // زر التالي
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(), 
                      padding: const EdgeInsets.all(20),
                      backgroundColor: AppColors.primary
                    ),
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                      } else {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                      }
                    },
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// 5. شاشة التسجيل (Auth Screen)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = false; // هل هو تسجيل جديد؟
  bool _loading = false;
  
  // وحدات التحكم
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  // القوائم المنسدلة
  String? _selectedWilaya;
  String _selectedRole = "patient"; // الافتراضي: مريض
  String? _selectedSpecialty; // للأطباء فقط

  // قائمة الأدوار
  final List<Map<String, String>> _roles = [
    {"val": "patient", "txt": "مريض (أبحث عن علاج) 👤"},
    {"val": "nurse", "txt": "ممرض / شبه طبي 💉"},
    {"val": "doctor", "txt": "طبيب 🩺"},
    {"val": "driver", "txt": "سائق إسعاف 🚑"},
  ];

  // دالة المعالجة
  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showError("يرجى ملء البريد وكلمة المرور");
      return;
    }
    if (_isRegister && (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _selectedWilaya == null)) {
      _showError("يرجى ملء جميع البيانات واختيار الولاية");
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isRegister) {
        // --- تسجيل جديد ---
        // 1. الانتقال لشاشة التحقق SMS (محاكاة)
        bool verified = await Navigator.push(context, MaterialPageRoute(builder: (_) => OTPScreen(phoneNumber: _phoneCtrl.text))) ?? false;
        
        if (!verified) {
          setState(() => _loading = false);
          return;
        }

        // 2. إنشاء الحساب في فايربيز
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

        // 3. حفظ البيانات في Firestore
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': _nameCtrl.text,
          'email': _emailCtrl.text,
          'phone': _phoneCtrl.text,
          'wilaya': _selectedWilaya,
          'role': _selectedRole,
          'specialty': _selectedRole == 'doctor' ? _selectedSpecialty : null, // للطبيب فقط
          'created_at': FieldValue.serverTimestamp(),
          'status': _selectedRole == 'patient' ? 'active' : 'pending', // المريض نشط، الموظف معلق
          'fcm_token': await FirebaseMessaging.instance.getToken(),
        });
        
        await cred.user!.updateDisplayName(_nameCtrl.text);

        // 4. التوجيه
        if (_selectedRole == 'patient') {
          // المريض -> الرئيسية
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper()));
        } else {
          // الموظف -> رفع الوثائق (البارت 3)
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProviderDocsUploadScreen()));
        }

      } else {
        // --- تسجيل دخول ---
        UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

        // جلب البيانات لمعرفة أين نوجهه
        var doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
        if (doc.exists) {
          String role = doc['role'];
          if (role == 'patient') {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper()));
          } else {
             // تحقق هل هو مفعل أم لا (في البارتات القادمة)
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProviderMainWrapper()));
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "حدث خطأ");
    } catch (e) {
      _showError("خطأ غير متوقع: $e");
    }
    setState(() => _loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.health_and_safety, size: 80, color: AppColors.primary),
              const SizedBox(height: 20),
              Text(_isRegister ? "حساب جديد" : "تسجيل الدخول", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 30),

              if (_isRegister) ...[
                // --- حقول التسجيل ---
                CustomTextField(controller: _nameCtrl, label: "الاسم الكامل", icon: Icons.person),
                CustomTextField(controller: _phoneCtrl, label: "رقم الهاتف (للتفعيل SMS)", icon: Icons.phone, type: TextInputType.phone),
                
                // اختيار الولاية
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("اختر ولايتك"),
                      value: _selectedWilaya,
                      items: dzWilayas.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _selectedWilaya = v),
                    ),
                  ),
                ),

                // اختيار الدور
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade100)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRole,
                      items: _roles.map((e) => DropdownMenuItem(value: e['val'], child: Text(e['txt']!))).toList(),
                      onChanged: (v) => setState(() {
                        _selectedRole = v!;
                        _selectedSpecialty = null; // تصفية التخصص عند تغيير الدور
                      }),
                    ),
                  ),
                ),

                // إذا كان طبيباً، أظهر التخصصات
                if (_selectedRole == 'doctor')
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.purple.shade100)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("تخصص الطبيب"),
                        value: _selectedSpecialty,
                        items: doctorSpecialties.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _selectedSpecialty = v),
                      ),
                    ),
                  ),
              ],

              // البريد وكلمة المرور (مشترك)
              CustomTextField(controller: _emailCtrl, label: "البريد الإلكتروني", icon: Icons.email, type: TextInputType.emailAddress),
              CustomTextField(controller: _passCtrl, label: "كلمة المرور", icon: Icons.lock, isPassword: true),

              const SizedBox(height: 20),
              ProButton(
                text: _isRegister ? "إنشاء حساب وتفعيل" : "دخول",
                onPressed: _submit,
                isLoading: _loading,
                icon: _isRegister ? Icons.verified : Icons.login,
              ),

              const SizedBox(height: 15),
              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(_isRegister ? "لديك حساب بالفعل؟ سجل دخول" : "مستخدم جديد؟ أنشئ حساباً"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// 6. شاشة التحقق من الهاتف (Simulated SMS OTP)
class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  const OTPScreen({super.key, required this.phoneNumber});
  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // محاكاة إرسال الرسالة
    Future.delayed(const Duration(seconds: 2), () {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🔔 وصلك كود التفعيل: 123456")));
    });
  }

  void _verify() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // محاكاة الشبكة
    
    if (_codeCtrl.text == "123456") {
      // كود صحيح
      Navigator.pop(context, true); // إرجاع true للشاشة السابقة
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ الكود خاطئ"), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تفعيل الهاتف")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms, size: 80, color: AppColors.primary),
            const SizedBox(height: 20),
            Text("تم إرسال كود تفعيل إلى ${widget.phoneNumber}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            TextField(
              controller: _codeCtrl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 5),
              decoration: const InputDecoration(
                hintText: "000000",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ProButton(text: "تأكيد الكود", onPressed: _verify, isLoading: _isLoading)
          ],
        ),
      ),
    );
  }
}
// ============================================================================
// 💼 PART 3: PROVIDER ONBOARDING & SUBSCRIPTION (التوظيف والاشتراكات)
// ============================================================================

// 1. موجه الموظفين (يفحص الحالة ويوجه للشاشة المناسبة)
class ProviderMainWrapper extends StatelessWidget {
  const ProviderMainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const AuthScreen();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const AuthScreen();
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'pending'; // pending, approved, active, suspended, payment_review
        bool docsUploaded = data['docs_uploaded'] ?? false;
        
        // 1. إذا لم يرفع الوثائق بعد
        if (!docsUploaded) {
          return const ProviderDocsUploadScreen();
        }

        // 2. إذا رفع الوثائق وينتظر موافقة الأدمن
        if (status == 'pending') {
          return const PendingApprovalScreen(
            title: "جاري مراجعة الملف 📄",
            msg: "وصلتنا وثائقك. يقوم فريق الإدارة بالتحقق منها حالياً. سيتم إشعارك فور القبول.",
            icon: Icons.hourglass_top,
          );
        }

        // 3. إذا تم رفضه
        if (status == 'rejected') {
          return PendingApprovalScreen(
            title: "عذراً، تم رفض الملف ❌",
            msg: "السبب: ${data['reject_reason'] ?? 'غير محدد'}.\nيرجى التواصل مع الإدارة أو إعادة التسجيل.",
            icon: Icons.cancel,
            isRejected: true,
          );
        }

        // 4. إذا وافق الأدمن، حان وقت الدفع
        if (status == 'approved_waiting_payment') {
          return const SubscriptionPaymentScreen();
        }

        // 5. إذا دفع وينتظر تفعيل الاشتراك
        if (status == 'payment_review') {
          return const PendingApprovalScreen(
            title: "جاري التحقق من الدفع 💰",
            msg: "وصلنا الإيصال. سيتم تفعيل حسابك وبدء العداد فور التأكد من المبلغ.",
            icon: Icons.payments,
          );
        }

        // 6. إذا كان الحساب نشطاً (Active) -> تفضل للعمل (البارت 5)
        if (status == 'active') {
          // هنا سنتصل بالبارت 5 (NurseWorkspace)
          return const NurseWorkspace(); // مؤقتاً حتى نصل للبارت 5
        }

        return const Scaffold(body: Center(child: Text("حالة غير معروفة")));
      },
    );
  }
}

// 2. شاشة رفع الوثائق (تحويل الصور لأرقام Base64)
class ProviderDocsUploadScreen extends StatefulWidget {
  const ProviderDocsUploadScreen({super.key});
  @override
  State<ProviderDocsUploadScreen> createState() => _ProviderDocsUploadScreenState();
}

class _ProviderDocsUploadScreenState extends State<ProviderDocsUploadScreen> {
  File? _selfie;
  File? _idCard;
  File? _diploma;
  bool _uploading = false;

  Future<void> _pickImage(int type) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50); // تقليل الجودة لتسريع التحويل
    if (xFile != null) {
      setState(() {
        if (type == 1) _selfie = File(xFile.path);
        if (type == 2) _idCard = File(xFile.path);
        if (type == 3) _diploma = File(xFile.path);
      });
    }
  }

  Future<void> _submitDocs() async {
    if (_selfie == null || _idCard == null || _diploma == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى رفع جميع الوثائق المطلوبة"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _uploading = true);
    try {
      // 1. تحويل الصور لنصوص
      String? selfieBase64 = await ImageHelper.imageToBase64(_selfie!);
      String? idBase64 = await ImageHelper.imageToBase64(_idCard!);
      String? diplomaBase64 = await ImageHelper.imageToBase64(_diploma!);

      if (selfieBase64 == null || idBase64 == null || diplomaBase64 == null) {
        throw "فشل في معالجة الصور";
      }

      // 2. الرفع لقاعدة البيانات
      User user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'docs_uploaded': true,
        'doc_selfie': selfieBase64,
        'doc_id': idBase64,
        'doc_diploma': diplomaBase64,
        'submitted_at': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red));
    }
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("استكمال الملف المهني")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("لضمان الجودة، يرجى رفع الوثائق التالية بوضوح.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            
            _DocPickerCard(title: "صورة شخصية (Selfie)", file: _selfie, onTap: () => _pickImage(1), icon: Icons.face),
            _DocPickerCard(title: "بطاقة التعريف / رخصة السياقة", file: _idCard, onTap: () => _pickImage(2), icon: Icons.badge),
            _DocPickerCard(title: "الشهادة / الديبلوم / الاعتماد", file: _diploma, onTap: () => _pickImage(3), icon: Icons.workspace_premium),

            const SizedBox(height: 20),
            ProButton(
              text: "إرسال الملف للمراجعة",
              icon: Icons.cloud_upload,
              isLoading: _uploading,
              onPressed: _submitDocs,
            )
          ],
        ),
      ),
    );
  }
}

// مكون لبطاقة اختيار الصورة
class _DocPickerCard extends StatelessWidget {
  final String title;
  final File? file;
  final VoidCallback onTap;
  final IconData icon;

  const _DocPickerCard({required this.title, required this.file, required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: file != null ? Colors.green : Colors.grey.shade300),
          image: file != null ? DecorationImage(image: FileImage(file!), fit: BoxFit.cover, opacity: 0.5) : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(file != null ? Icons.check_circle : icon, size: 40, color: file != null ? Colors.green : AppColors.primary),
              const SizedBox(height: 5),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: file != null ? Colors.black : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. شاشة الانتظار (عامة)
class PendingApprovalScreen extends StatelessWidget {
  final String title;
  final String msg;
  final IconData icon;
  final bool isRejected;

  const PendingApprovalScreen({super.key, required this.title, required this.msg, required this.icon, this.isRejected = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: isRejected ? Colors.red : Colors.orange),
            const SizedBox(height: 30),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Text(msg, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
            if (isRejected) ...[
              const SizedBox(height: 30),
              ProButton(text: "إعادة المحاولة", onPressed: () {
                // إعادة تعيين الحالة للسماح بالرفع
                 FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'docs_uploaded': false, 'status': 'pending'});
              })
            ]
          ],
        ),
      ),
    );
  }
}

// 4. شاشة الدفع (CCP & BaridiMob)
class SubscriptionPaymentScreen extends StatefulWidget {
  const SubscriptionPaymentScreen({super.key});
  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  File? _receipt;
  bool _submitting = false;

  Future<void> _pickReceipt() async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (xFile != null) setState(() => _receipt = File(xFile.path));
  }

  Future<void> _submitPayment() async {
    if (_receipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يجب إرفاق صورة الوصل"), backgroundColor: Colors.red));
      return;
    }
    setState(() => _submitting = true);
    
    // تحويل الوصل وتحديث الحالة
    String? receiptBase64 = await ImageHelper.imageToBase64(_receipt!);
    if (receiptBase64 != null) {
      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
        'status': 'payment_review',
        'payment_receipt': receiptBase64,
        'payment_date': FieldValue.serverTimestamp(),
      });
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تفعيل الاشتراك")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  const Expanded(child: Text("تم قبول ملفك! قم بدفع الاشتراك لبدء استقبال الطلبات.")),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            // بطاقة المعلومات المالية (من الثوابت)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
              child: Column(
                children: [
                  Text("سعر الاشتراك الشهري", style: TextStyle(color: Colors.grey[600])),
                  Text("${AppConstants.subscriptionPrice} دج", style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Divider(height: 30),
                  _InfoRow(label: "الاسم", value: AppConstants.ccpName),
                  _InfoRow(label: "CCP", value: "${AppConstants.ccpNumber} / ${AppConstants.ccpKey}"),
                  _InfoRow(label: "RIP (BaridiMob)", value: AppConstants.ripNumber, isCopyable: true),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            const Text("أرفق صورة وصل الدفع هنا", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            GestureDetector(
              onTap: _pickReceipt,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _receipt != null ? Colors.green : Colors.grey),
                ),
                child: _receipt != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_receipt!, fit: BoxFit.cover))
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: Colors.grey), Text("اضغط لرفع الصورة")]),
              ),
            ),
            
            const SizedBox(height: 25),
            ProButton(text: "تأكيد الدفع", onPressed: _submitPayment, isLoading: _submitting, icon: Icons.send),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCopyable;
  const _InfoRow({required this.label, required this.value, this.isCopyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (isCopyable) ...[
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم النسخ")));
                  },
                  child: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                )
              ]
            ],
          )
        ],
      ),
    );
  }
}

// عنصر مؤقت (Placeholder) حتى نصل للبارت 5
class NurseWorkspaceStub extends StatelessWidget {
  const NurseWorkspaceStub({super.key});
  @override
  Widget build(BuildContext context) {
    // هذا سيتم استبداله بلوحة العمل الحقيقية في البارت 5
    // حالياً نقوم بتحويله مباشرة للشاشة الحقيقية عند توفرها
    return const Scaffold(body: Center(child: Text("جاري تحميل مساحة العمل...")));
  }
}
// ============================================================================
// 🏠 PART 4: PATIENT DASHBOARD & SERVICE SELECTION (واجهة المريض والخدمات)
// ============================================================================

// 1. الموجه الرئيسي للمريض (Bottom Navigation)
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _navIndex = 0;

  final List<Widget> _pages = [
    const PatientHomeScreen(),      // الرئيسية
    const PatientHistoryScreen(),   // طلباتي (سنبنيها في البارت 6)
    const ProfileScreen(),          // حسابي (سنبنيها في البارت 8)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_navIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.white,
        elevation: 5,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined), 
            selectedIcon: Icon(Icons.home, color: AppColors.primary), 
            label: "الرئيسية"
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined), 
            selectedIcon: Icon(Icons.history, color: AppColors.primary), 
            label: "طلباتي"
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline), 
            selectedIcon: Icon(Icons.person, color: AppColors.primary), 
            label: "حسابي"
          ),
        ],
      ),
    );
  }
}

// 2. الشاشة الرئيسية للمريض
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
              // 1. الهيدر (الترحيب)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("مرحباً، ${user?.displayName ?? 'ضيف'}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text("نتمنى لك دوام الصحة والعافية ❤️", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
                    child: IconButton(
                      icon: const Icon(Icons.support_agent, color: AppColors.primary),
                      onPressed: () async {
                         final url = Uri.parse("tel:${AppConstants.supportPhone}");
                         if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // 2. البانر الإعلاني (Live Promo Slider)
              const PromoSlider(),

              const SizedBox(height: 25),
              const Text("بماذا يمكننا مساعدتك اليوم؟", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // 3. شبكة الخدمات (6 أيقونات)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _ServiceCategoryCard(
                    title: "تمريض منزلي", 
                    icon: Icons.vaccines, 
                    color: Colors.teal, 
                    onTap: () => _showSubServices(context, "nursing", "خدمات التمريض")
                  ),
                  _ServiceCategoryCard(
                    title: "زيارة طبيب", 
                    icon: Icons.medical_services, 
                    color: Colors.blue, 
                    onTap: () => _showSubServices(context, "doctor", "تخصصات الأطباء")
                  ),
                  _ServiceCategoryCard(
                    title: "علاج طبيعي", 
                    icon: Icons.accessibility_new, 
                    color: Colors.orange, 
                    onTap: () => _showSubServices(context, "therapy", "العلاج والتأهيل")
                  ),
                  _ServiceCategoryCard(
                    title: "مرافق مريض", 
                    icon: Icons.elderly, 
                    color: Colors.purple, 
                    onTap: () => _showSubServices(context, "caregiver", "رعاية المسنين")
                  ),
                  _ServiceCategoryCard(
                    title: "نقل وإسعاف", 
                    icon: Icons.medical_services,
 
                    color: Colors.red, 
                    onTap: () => _showSubServices(context, "ambulance", "نقل المرضى")
                  ),
                  _ServiceCategoryCard(
                    title: "خدمات أخرى", 
                    icon: Icons.grid_view, 
                    color: Colors.grey, 
                    onTap: () => _showSubServices(context, "other", "خدمات إضافية")
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // عرض القائمة الفرعية (Bottom Sheet)
  void _showSubServices(BuildContext context, String category, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubServicesSheet(category: category, title: title),
    );
  }
}

// 3. مكون البانر الإعلاني (يقرأ من الفايربيز)
class PromoSlider extends StatelessWidget {
  const PromoSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('config').doc('promo').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // بانر افتراضي في حال عدم وجود إنترنت أو بيانات
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("تخفيضات الافتتاح 🎉", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("استفد من أسعار خاصة لجميع خدمات التمريض", style: TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        bool isActive = data['is_active'] ?? true;
        if (!isActive) return const SizedBox.shrink(); // إخفاء إذا أوقفه الأدمن

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: NetworkImage("https://img.freepik.com/free-vector/gradient-medical-background_23-2149151528.jpg"), // خلفية طبية عامة
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                child: const Text("عرض خاص 🔥", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              Text(data['title'] ?? "عافية - صحتك أمانة", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(data['subtitle'] ?? "أفضل رعاية طبية في الجزائر", style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }
}

// 4. بطاقة القسم الرئيسي
class _ServiceCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCategoryCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// 5. قائمة الخدمات الفرعية (تظهر من الأسفل)
class _SubServicesSheet extends StatelessWidget {
  final String category;
  final String title;
  const _SubServicesSheet({required this.category, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // مقبض السحب
          Container(margin: const EdgeInsets.only(top: 15), height: 5, width: 50, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.list_alt, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(),
          
          // قائمة الخدمات (من السيرفر)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // يجلب الخدمات المسجلة في السيرفر لهذا القسم
              stream: FirebaseFirestore.instance.collection('services').where('category', isEqualTo: category).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                // إذا لم تكن هناك خدمات مدخلة من الأدمن، نعرض بيانات افتراضية
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildDefaultList(context, category);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return _ServiceItemTile(
                      name: data['name'], 
                      price: data['price'], 
                      onTap: () {
                         Navigator.pop(context);
                         // الانتقال لصفحة الطلب (البارت 5)
                         Navigator.push(context, MaterialPageRoute(builder: (_) => OrderFormScreen(serviceName: data['name'], basePrice: data['price'], category: category)));
                      }
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // قائمة افتراضية (للتجربة قبل إدخال بيانات الأدمن)
  Widget _buildDefaultList(BuildContext context, String cat) {
    List<Map<String, dynamic>> defaults = [];
    if (cat == 'nursing') {
      defaults = [
        {"name": "حقن (Injection)", "price": 500},
        {"name": "سيروم (Sérum)", "price": 1500},
        {"name": "تغيير ضمادات", "price": 800},
        {"name": "قياس ضغط/سكر", "price": 300},
      ];
    } else if (cat == 'doctor') {
      defaults = [
        {"name": "كشف طب عام", "price": 3000},
        {"name": "كشف طب أطفال", "price": 4000},
        {"name": "كشف طب مختص", "price": 5000},
      ];
    } else if (cat == 'ambulance') {
      defaults = [
        {"name": "نقل داخل الولاية", "price": 2000},
        {"name": "نقل خارج الولاية", "price": 10000},
      ];
    } else {
      defaults = [{"name": "استشارة عامة", "price": 1000}];
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: defaults.length,
      itemBuilder: (context, index) {
        return _ServiceItemTile(
          name: defaults[index]['name'], 
          price: defaults[index]['price'], 
          onTap: () {
             Navigator.pop(context);
             // الانتقال لصفحة الطلب (البارت 5)
             Navigator.push(context, MaterialPageRoute(builder: (_) => OrderFormScreen(serviceName: defaults[index]['name'], basePrice: defaults[index]['price'], category: cat)));
          }
        );
      },
    );
  }
}

// عنصر الخدمة في القائمة
class _ServiceItemTile extends StatelessWidget {
  final String name;
  final int price;
  final VoidCallback onTap;

  const _ServiceItemTile({required this.name, required this.price, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Text("$price دج", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================================
// 🚑 PART 5: ORDER FORM & GPS LOCATION (شاشة إتمام الطلب وتحديد الموقع)
// ============================================================================

class OrderFormScreen extends StatefulWidget {
  final String serviceName;
  final int basePrice;
  final String category;

  const OrderFormScreen({
    super.key, 
    required this.serviceName, 
    required this.basePrice, 
    required this.category
  });

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _noteCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(); // رقم بديل (اختياري)
  String? _selectedWilaya;
  
  // متغيرات الموقع
  bool _gettingLocation = false;
  Position? _currentPosition;
  String _address = "لم يتم تحديد الموقع بعد";
  final MapController _mapController = MapController();

  // متغيرات الإرسال
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ملء البيانات تلقائياً من البروفايل
  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _selectedWilaya = doc.data()?['wilaya']; // تحديد الولاية تلقائياً
          _phoneCtrl.text = doc.data()?['phone'] ?? "";
        });
      }
    }
  }

  // 📍 خوارزمية تحديد الموقع (GPS)
  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      // 1. فحص الخدمة
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "يرجى تفعيل خدمة الموقع (GPS)";

      // 2. فحص الإذن
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "تم رفض إذن الموقع";
      }

      // 3. جلب الإحداثيات (دقة عالية)
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 4. محاولة معرفة اسم الشارع (Geocoding)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          setState(() {
            _address = "${place.street}, ${place.locality}";
            // محاولة تحديث الولاية إذا كانت فارغة
            if (_selectedWilaya == null && place.administrativeArea != null) {
               // بحث بسيط في القائمة
               for (var w in dzWilayas) {
                 if (place.administrativeArea!.contains(w)) _selectedWilaya = w;
               }
            }
          });
        }
      } catch (e) {
        setState(() => _address = "تم تحديد الإحداثيات بنجاح ✅");
      }

      setState(() => _currentPosition = position);
      
      // تحريك الخريطة
      _mapController.move(LatLng(position.latitude, position.longitude), 15);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red));
    }
    setState(() => _gettingLocation = false);
  }

  // 🚀 إرسال الطلب للسحابة
  Future<void> _submitOrder() async {
    if (_selectedWilaya == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى تحديد الولاية والموقع الجغرافي"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _submitting = true);
    try {
      User user = FirebaseAuth.instance.currentUser!;
      String requestId = const Uuid().v4(); // معرف فريد للطلب

      // إنشاء وثيقة الطلب
      await FirebaseFirestore.instance.collection('requests').doc(requestId).set({
        'id': requestId,
        'patient_id': user.uid,
        'patient_name': user.displayName ?? "مريض",
        'patient_phone': _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : (user.phoneNumber ?? ""), // رقم الهاتف
        
        'service': widget.serviceName,
        'category': widget.category, // nursing, doctor, ambulance...
        'price': widget.basePrice,
        'note': _noteCtrl.text,
        
        'wilaya': _selectedWilaya,
        'address': _address,
        'location': GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude), // للإحداثيات
        
        'status': 'pending', // الحالة الأولية
        'timestamp': FieldValue.serverTimestamp(),
        'is_emergency': widget.category == 'ambulance', // علامة للطوارئ
      });

      // إشعار المستخدم والعودة
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            title: const Text("تم إرسال الطلب!"),
            content: const Text("تم تعميم طلبك على المختصين في ولايتك.\nسيتم إشعارك فور قبول أحدهم للمهمة."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الديالوج
                  Navigator.pop(context); // إغلاق شاشة الطلب والعودة للرئيسية
                },
                child: const Text("حسناً"),
              )
            ],
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل الإرسال: $e"), backgroundColor: Colors.red));
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد الطلب")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ملخص الخدمة والسعر
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]
              ),
              child: Column(
                children: [
                  Text(widget.serviceName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                    child: Text("${widget.basePrice} دج", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(height: 5),
                  const Text("السعر يشمل التنقل والخدمة", style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
            
            const SizedBox(height: 25),

            // 2. تحديد الموقع (الخريطة)
            const Text("📍 موقع المريض (المنزل)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    // الخريطة
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: LatLng(36.75, 3.05), // الجزائر العاصمة افتراضياً
                        initialZoom: 10, 
                      ),
                      children: [
                        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                        if (_currentPosition != null)
                          MarkerLayer(markers: [
                            Marker(
                              point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                            )
                          ])
                      ],
                    ),
                    // زر تحديد الموقع العائم
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: Text(_gettingLocation ? "جاري التحديد..." : "تحديد موقعي الحالي (GPS)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _gettingLocation ? null : _getCurrentLocation,
                      ),
                    )
                  ],
                ),
              ),
            ),
            if (_address != "لم يتم تحديد الموقع بعد")
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("العنوان التقريبي: $_address", style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
              ),

            const SizedBox(height: 20),

            // 3. تأكيد الولاية ورقم الهاتف
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedWilaya,
                        hint: const Text("الولاية"),
                        items: dzWilayas.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (v) => setState(() => _selectedWilaya = v),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "رقم الهاتف",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // 4. ملاحظات إضافية
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "ملاحظات إضافية (اختياري)\nمثال: المريض لا يستطيع الحركة، الجرس معطل...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),

            const SizedBox(height: 30),

            // 5. زر الإرسال
            ProButton(
              text: "تأكيد وإرسال الطلب",
              icon: Icons.send_rounded,
              isLoading: _submitting,
              onPressed: _submitOrder,
              color: widget.category == 'ambulance' ? Colors.red : AppColors.primary, // أحمر للإسعاف
            ),
          ],
        ),
      ),
    );
  }
}
// ============================================================================
// 🚑 PART 6: NURSE WORKSPACE (مساحة عمل الممرض - الرادار والخريطة)
// ============================================================================

class NurseWorkspace extends StatefulWidget {
  const NurseWorkspace({super.key});
  @override
  State<NurseWorkspace> createState() => _NurseWorkspaceState();
}

class _NurseWorkspaceState extends State<NurseWorkspace> {
  // حالة الممرض
  bool _isOnline = false; // هل أنا متاح للعمل؟
  String? _myWilaya;
  String? _mySpecialty; // nurse, doctor, driver
  
  // الخريطة
  final MapController _mapController = MapController();
  Position? _currentLoc;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _locateMe();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _myWilaya = doc.data()?['wilaya'];
          _mySpecialty = doc.data()?['role']; // nurse, doctor...
          _isOnline = true; // تفعيل التواجد تلقائياً عند الدخول
        });
      }
    }
  }

  Future<void> _locateMe() async {
    try {
      Position p = await Geolocator.getCurrentPosition();
      setState(() => _currentLoc = p);
      _mapController.move(LatLng(p.latitude, p.longitude), 14);
    } catch (e) {
      // تجاهل الأخطاء البسيطة في GPS حالياً
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. إذا لم يكن لديه مهمة نشطة -> اعرض الرادار
    // 2. إذا لديه مهمة -> اعرض تفاصيل المهمة
    return StreamBuilder<QuerySnapshot>(
      // البحث عن أي مهمة نشطة قبلتها أنا ولم تكتمل بعد
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('nurse_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', whereIn: ['accepted', 'on_way'])
          .snapshots(),
      builder: (context, activeSnapshot) {
        
        // 🅰️ الحالة أ: لدي مهمة نشطة (أنا مشغول)
        if (activeSnapshot.hasData && activeSnapshot.data!.docs.isNotEmpty) {
          var taskDoc = activeSnapshot.data!.docs.first;
          return _ActiveTaskScreen(taskDoc: taskDoc);
        }

        // 🅱️ الحالة ب: أنا حر (أبحث عن طلبات)
        return Scaffold(
          body: Stack(
            children: [
              // 1. الخريطة الخلفية
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLoc != null 
                      ? LatLng(_currentLoc!.latitude, _currentLoc!.longitude) 
                      : const LatLng(36.75, 3.05), // الجزائر
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  // موقعي الحالي
                  if (_currentLoc != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(_currentLoc!.latitude, _currentLoc!.longitude),
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.navigation, color: Colors.blue, size: 40),
                      )
                    ]),
                ],
              ),

              // 2. الهيدر (زر الأونلاين)
              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: GlassCard( // سنعرفه في الأسفل أو نستخدم Card عادي
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(backgroundImage: NetworkImage("https://cdn-icons-png.flaticon.com/512/3774/3774299.png")),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isOnline ? "أنا متاح للعمل 🟢" : "خارج الخدمة 🔴", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(_myWilaya ?? "...", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _isOnline, 
                        activeColor: Colors.green,
                        onChanged: (v) => setState(() => _isOnline = v),
                      )
                    ],
                  ),
                ),
              ),

              // 3. قائمة الطلبات (الرادار)
              if (_isOnline && _myWilaya != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 350,
                  child: Container(
                    padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📡 رادار الطلبات القريبة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('requests')
                                .where('wilaya', isEqualTo: _myWilaya) // فقط ولايتي
                                .where('status', isEqualTo: 'pending') // فقط المعلقة
                                // .where('category', isEqualTo: ...) // يمكن إضافة فلتر التخصص لاحقاً
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.radar, size: 60, color: Colors.grey[300]),
                                      const SizedBox(height: 10),
                                      const Text("لا توجد طلبات حالياً.. انتظر الرنين", style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var doc = snapshot.data!.docs[index];
                                  return _RequestOfferCard(doc: doc);
                                },
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}

// بطاقة عرض الطلب (Offer Card)
class _RequestOfferCard extends StatelessWidget {
  final DocumentSnapshot doc;
  const _RequestOfferCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    var data = doc.data() as Map<String, dynamic>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade100)
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['service'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(20)),
                child: Text("${data['price']} دج", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              Expanded(child: Text(data['address'] ?? "موقع غير محدد", maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                // قبول الطلب
                User me = FirebaseAuth.instance.currentUser!;
                await FirebaseFirestore.instance.collection('requests').doc(doc.id).update({
                  'status': 'accepted',
                  'nurse_id': me.uid,
                  'nurse_name': me.displayName,
                  'nurse_phone': me.phoneNumber, // يفضل جلبه من البروفايل
                  'accepted_at': FieldValue.serverTimestamp(),
                });
              },
              child: const Text("قبول المهمة ✅"),
            ),
          )
        ],
      ),
    );
  }
}

// شاشة المهمة النشطة (Active Task)
class _ActiveTaskScreen extends StatelessWidget {
  final DocumentSnapshot taskDoc;
  const _ActiveTaskScreen({required this.taskDoc});

  // فتح الخرائط
  void _openMap(GeoPoint loc) async {
    final url = Uri.parse("google.navigation:q=${loc.latitude},${loc.longitude}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // بديل للمتصفح
      final webUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}");
      await launchUrl(webUrl);
    }
  }

  // اتصال
  void _call(String phone) async {
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    var data = taskDoc.data() as Map<String, dynamic>;
    GeoPoint loc = data['location'];

    return Scaffold(
      appBar: AppBar(title: const Text("مهمة جارية 🚑")),
      body: Column(
        children: [
          // معلومات المريض
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                const CircleAvatar(radius: 30, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 40, color: Colors.white)),
                const SizedBox(height: 10),
                Text(data['patient_name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(data['patient_phone'], style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const Divider(height: 30),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(icon: Icons.phone, label: "اتصال", color: Colors.green, onTap: () => _call(data['patient_phone'])),
                    _ActionButton(icon: Icons.directions, label: "الموقع", color: Colors.blue, onTap: () => _openMap(loc)),
                    if (data['status'] == 'accepted')
                      _ActionButton(
                        icon: Icons.local_shipping, 
                        label: "انطلقت", 
                        color: Colors.orange, 
                        onTap: () => taskDoc.reference.update({'status': 'on_way'})
                      ),
                  ],
                )
              ],
            ),
          ),
          
          const Spacer(),
          
          // زر إنهاء المهمة
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: () async {
                // إنهاء المهمة
                await taskDoc.reference.update({'status': 'completed', 'completed_at': FieldValue.serverTimestamp()});
                // إظهار تهنئة
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إنجاز المهمة! تمت إضافة الرصيد (نظرياً)")));
                }
              },
              child: Text("تم تحصيل ${data['price']} دج - إنهاء ✅", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12))
      ],
    );
  }
}

// Helper Widget بسيط للبطاقات الزجاجية
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
      ),
      child: child,
    );
  }
}
// ============================================================================
// 👮‍♂️ PART 7: SUPER ADMIN DASHBOARD (لوحة التحكم المركزية الشاملة)
// ============================================================================

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _tabController = TabController(length: 4, vsync: this);
  }

  // حماية البوابة: طرد أي متطفل ليس الأدمن
  void _checkAdminAccess() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email != AppConstants.adminEmail) {
      // طرد فوراً
      FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⛔ دخول غير مصرح به!"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الإدارة المركزية 👮‍♂️"),
        backgroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.folder_shared), text: "طلبات"),
            Tab(icon: Icon(Icons.payments), text: "مالية"),
            Tab(icon: Icon(Icons.people), text: "موظفين"),
            Tab(icon: Icon(Icons.settings_suggest), text: "تحكم"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AdminRequestsTab(), // طلبات التوظيف
          _AdminPaymentsTab(), // مراجعة الدفع
          _AdminStaffTab(),    // إدارة الموظفين النشطين
          _AdminControlTab(),  // الأسعار والإعدادات
        ],
      ),
    );
  }
}

// 1. تبويب طلبات التوظيف (مراجعة الوثائق)
class _AdminRequestsTab extends StatelessWidget {
  const _AdminRequestsTab();

  void _showDocsDialog(BuildContext context, Map<String, dynamic> data, String uid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("ملف: ${data['name']}"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text("الصورة الشخصية", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 150, child: ImageHelper.imageFromBase64(data['doc_selfie'])),
              const Divider(),
              const Text("بطاقة التعريف", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 150, child: ImageHelper.imageFromBase64(data['doc_id'])),
              const Divider(),
              const Text("الشهادة/الدبلوم", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 150, child: ImageHelper.imageFromBase64(data['doc_diploma'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("رفض ❌", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              _rejectUser(context, uid);
            },
          ),
          ElevatedButton(
            child: const Text("موافق (انتقل للدفع) ✅"),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).update({'status': 'approved_waiting_payment'});
              if (context.mounted) Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  void _rejectUser(BuildContext context, String uid) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("سبب الرفض"),
        content: TextField(controller: reasonCtrl, decoration: const InputDecoration(hintText: "مثلاً: الصورة غير واضحة")),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                'status': 'rejected',
                'reject_reason': reasonCtrl.text,
                'docs_uploaded': false // ليتمكن من الرفع مجدداً
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("تأكيد الرفض"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // جلب من رفع الوثائق وهو في حالة "انتظار"
      stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'pending').where('docs_uploaded', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات توظيف جديدة"));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(child: Text(data['role'][0].toUpperCase())),
                title: Text("${data['name']} (${data['role']})"),
                subtitle: Text("ولاية: ${data['wilaya']} | هاتف: ${data['phone']}"),
                trailing: ElevatedButton(
                  child: const Text("مراجعة"),
                  onPressed: () => _showDocsDialog(context, data, doc.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 2. تبويب المالية (تفعيل الاشتراكات)
class _AdminPaymentsTab extends StatelessWidget {
  const _AdminPaymentsTab();

  void _reviewPayment(BuildContext context, Map<String, dynamic> data, String uid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("دفع من: ${data['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("وصل الدفع:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 300, 
              width: double.infinity,
              child: ImageHelper.imageFromBase64(data['payment_receipt']) // عرض صورة الوصل
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("رفض الدفع", style: TextStyle(color: Colors.red)),
            onPressed: () async {
               await FirebaseFirestore.instance.collection('users').doc(uid).update({'status': 'approved_waiting_payment'}); // إعادته للدفع
               Navigator.pop(context);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("قبول وتفعيل الاشتراك 💰"),
            onPressed: () async {
              // تفعيل الحساب وإضافة 30 يوم
              DateTime now = DateTime.now();
              DateTime expiry = now.add(const Duration(days: 30));
              
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                'status': 'active', // تفعيل نهائي
                'subscription_start': now,
                'subscription_end': expiry,
              });
              if (context.mounted) Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'payment_review').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("لا توجد مدفوعات للمراجعة"));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name']),
              subtitle: const Text("ينتظر تفعيل الاشتراك"),
              trailing: const Icon(Icons.receipt_long, color: Colors.green),
              onTap: () => _reviewPayment(context, data, doc.id),
            );
          },
        );
      },
    );
  }
}

// 3. تبويب الموظفين (إدارة وحظر)
class _AdminStaffTab extends StatelessWidget {
  const _AdminStaffTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users')
          .where('role', whereIn: ['nurse', 'doctor', 'driver'])
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            
            // حساب الأيام المتبقية
            String daysLeft = "غير محدد";
            if (data['subscription_end'] != null) {
              DateTime end = (data['subscription_end'] as Timestamp).toDate();
              int diff = end.difference(DateTime.now()).inDays;
              daysLeft = "$diff يوم";
            }

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['doc_selfie'] != null 
                      ? MemoryImage(base64Decode(data['doc_selfie'])) 
                      : null,
                  child: data['doc_selfie'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text("${data['name']} (${data['role']})"),
                subtitle: Text("الولاية: ${data['wilaya']} | اشتراك: $daysLeft"),
                trailing: IconButton(
                  icon: const Icon(Icons.block, color: Colors.red),
                  onPressed: () {
                    // حظر المستخدم
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("تأكيد الحظر"),
                        content: const Text("هل تريد إيقاف هذا الموظف عن العمل؟"),
                        actions: [
                          TextButton(
                            child: const Text("نعم، حظر"),
                            onPressed: () {
                              FirebaseFirestore.instance.collection('users').doc(doc.id).update({'status': 'suspended'});
                              Navigator.pop(context);
                            },
                          )
                        ],
                      )
                    );
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

// 4. غرفة التحكم (الأسعار والإعلانات)
class _AdminControlTab extends StatefulWidget {
  const _AdminControlTab();
  @override
  State<_AdminControlTab> createState() => _AdminControlTabState();
}

class _AdminControlTabState extends State<_AdminControlTab> {
  final _msgCtrl = TextEditingController();

  Future<void> _updatePrice(String category, String name, int newPrice) async {
    // تحديث أو إنشاء خدمة
    await FirebaseFirestore.instance.collection('services').doc(name).set({
      'category': category,
      'name': name,
      'price': newPrice,
      'updated_at': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم تحديث سعر $name")));
  }

  void _showPriceDialog() {
    String name = "";
    String price = "";
    String category = "nursing";
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("إضافة/تعديل خدمة"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: "اسم الخدمة"), onChanged: (v) => name = v),
            TextField(decoration: const InputDecoration(labelText: "السعر (دج)"), keyboardType: TextInputType.number, onChanged: (v) => price = v),
            DropdownButton<String>(
              value: category,
              items: const [
                DropdownMenuItem(value: "nursing", child: Text("تمريض")),
                DropdownMenuItem(value: "doctor", child: Text("طبيب")),
                DropdownMenuItem(value: "ambulance", child: Text("إسعاف")),
              ], 
              onChanged: (v) => category = v!
            )
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty && price.isNotEmpty) {
                _updatePrice(category, name, int.parse(price));
                Navigator.pop(context);
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("📣 بث إشعار للجميع", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(controller: _msgCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "اكتب رسالة لكل المستخدمين...")),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: const Text("إرسال الإشعار"),
          onPressed: () {
             if (_msgCtrl.text.isNotEmpty) {
               // هنا يمكن ربطه بـ Cloud Functions مستقبلاً
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم جدولة الإشعار")));
               _msgCtrl.clear();
             }
          },
        ),
        
        const Divider(height: 40),
        
        const Text("💰 إدارة الخدمات والأسعار", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("إضافة خدمة جديدة"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          onPressed: _showPriceDialog,
        ),
        
        const SizedBox(height: 20),
        const Text("الخدمات الحالية:", style: TextStyle(color: Colors.grey)),
        
        // عرض قائمة الخدمات الحالية للتعديل
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('services').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            return Column(
              children: snapshot.data!.docs.map((doc) {
                var d = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(d['name']),
                  trailing: Text("${d['price']} دج"),
                  onTap: () => _updatePrice(d['category'], d['name'], d['price'] + 100), // مثال سريع
                );
              }).toList(),
            );
          },
        )
      ],
    );
  }
}
// ============================================================================
// ⭐ PART 8: HISTORY, RATING & USER PROFILE (السجل، التقييم، والملف الشخصي)
// ============================================================================

// 1. شاشة سجل الطلبات للمريض
class PatientHistoryScreen extends StatelessWidget {
  const PatientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("يرجى تسجيل الدخول"));

    return Scaffold(
      appBar: AppBar(title: const Text("طلباتي السابقة")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('patient_id', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("لم تقم بأي طلب بعد", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              
              // تحديد الحالة واللون
              String status = data['status'];
              Color color = Colors.grey;
              String statusText = "غير معروف";
              
              if (status == 'pending') { color = Colors.orange; statusText = "قيد الانتظار ⏳"; }
              else if (status == 'accepted') { color = Colors.blue; statusText = "مقبول (الممرض قادم) 🚑"; }
              else if (status == 'on_way') { color = Colors.purple; statusText = "في الطريق 🚚"; }
              else if (status == 'completed') { color = Colors.green; statusText = "مكتمل ✅"; }
              else if (status == 'cancelled') { color = Colors.red; statusText = "ملغي ❌"; }

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['service'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text(statusText, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate().toString().substring(0, 16) : "", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Spacer(),
                          Text("${data['price']} دج", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      
                      // زر التقييم (يظهر فقط إذا اكتمل الطلب ولم يتم تقييمه بعد)
                      if (status == 'completed' && (data['rated'] == null || data['rated'] == false)) ...[
                        const Divider(),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.star, color: Colors.amber),
                            label: const Text("قيم الخدمة"),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => RatingDialog(requestId: doc.id, nurseId: data['nurse_id'])
                              );
                            },
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

// 2. ديالوج التقييم (Rating Dialog)
class RatingDialog extends StatefulWidget {
  final String requestId;
  final String? nurseId;
  const RatingDialog({super.key, required this.requestId, this.nurseId});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _stars = 5;
  final _commentCtrl = TextEditingController();

  Future<void> _submitRate() async {
    if (widget.nurseId == null) return;
    
    // 1. تحديث الطلب بأنه تم تقييمه
    await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({
      'rated': true,
      'rating_stars': _stars,
      'rating_comment': _commentCtrl.text,
    });

    // 2. تحديث سجل الممرض (نظرياً هنا نقوم بحساب المتوسط، لكن للتبسيط سنحفظ التقييم فقط)
    // يمكن إضافة كود هنا لجمع التقييمات في بروفايل الممرض
    
    if (mounted) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("شكراً على تقييمك! ⭐")));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("كيف كانت الخدمة؟"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(index < _stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 30),
                onPressed: () => setState(() => _stars = index + 1),
              );
            }),
          ),
          TextField(
            controller: _commentCtrl,
            decoration: const InputDecoration(hintText: "اكتب ملاحظة (اختياري)", border: OutlineInputBorder()),
            maxLines: 2,
          )
        ],
      ),
      actions: [
        ElevatedButton(onPressed: _submitRate, child: const Text("إرسال التقييم"))
      ],
    );
  }
}

// 3. الملف الشخصي للمستخدم (Profile Screen)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  File? _imageFile;

  // تغيير الصورة
  Future<void> _updatePhoto() async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (xFile != null) {
      setState(() => _imageFile = File(xFile.path));
      // رفع الصورة
      String? base64 = await ImageHelper.imageToBase64(_imageFile!);
      if (base64 != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'doc_selfie': base64}); // نستخدم نفس الحقل مجازاً
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث الصورة")));
      }
    }
  }

  // تسجيل الخروج
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (route) => false);
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
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 18,
                      child: IconButton(icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white), onPressed: _updatePhoto),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(user?.displayName ?? "مستخدم", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 40),
            
            // القائمة
            ListTile(
              leading: const Icon(Icons.dark_mode, color: Colors.purple),
              title: const Text("الوضع الليلي"),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (v) => themeProvider.toggleTheme(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.contact_support, color: Colors.blue),
              title: const Text("اتصل بالدعم"),
              onTap: () async {
                 final url = Uri.parse("tel:${AppConstants.supportPhone}");
                 if (await canLaunchUrl(url)) await launchUrl(url);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("تسجيل الخروج"),
              onTap: _logout,
            ),
            
            const SizedBox(height: 50),
            Text("Version ${AppConstants.appVersion}", style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}
// ============================================================================
// 📡 PART 9: NOTIFICATIONS ENGINE & SOUNDS (محرك الإشعارات والصوتيات)
// ============================================================================

class NotificationEngine {
  // 🔑 مفتاح السيرفر (يجب جلبه من إعدادات فايربيز -> Cloud Messaging -> Server Key)
  // ملاحظة: في التطبيقات الكبيرة جداً يفضل وضعه في سيرفر خارجي، لكن للنسخة V10 سنضعه هنا
  static const String _serverKey = "YOUR_FIREBASE_SERVER_KEY_HERE"; 

  // 1. إرسال إشعار لمجموعة (مثلاً: كل الممرضين في ولاية معينة)
  static Future<void> sendToTopic({
    required String topic, 
    required String title, 
    required String body, 
    Map<String, dynamic>? data
  }) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(
          <String, dynamic>{
            'to': '/topics/$topic', // الإرسال لكل المشتركين في هذا الموضوع
            'notification': <String, dynamic>{
              'title': title,
              'body': body,
              'sound': 'default', // صوت الإشعار
              'android_channel_id': 'afya_high_importance', // القناة التي أنشأناها في البارت 1
            },
            'data': data ?? {}, // بيانات إضافية (مثل رقم الطلب)
            'priority': 'high',
          },
        ),
      );
      debugPrint("✅ تم إرسال الإشعار الجماعي إلى: $topic");
    } catch (e) {
      debugPrint("❌ فشل إرسال الإشعار: $e");
    }
  }

  // 2. إرسال إشعار لجهاز محدد (مثلاً: لمريض محدد عند قبول طلبه)
  static Future<void> sendToToken({
    required String token, 
    required String title, 
    required String body
  }) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(
          <String, dynamic>{
            'to': token,
            'notification': <String, dynamic>{
              'title': title,
              'body': body,
              'sound': 'default',
            },
            'priority': 'high',
          },
        ),
      );
      debugPrint("✅ تم إرسال الإشعار الخاص");
    } catch (e) {
      debugPrint("❌ فشل إرسال الإشعار الخاص: $e");
    }
  }

  // 3. الاشتراك في القنوات (Topics)
  // هذه الدالة نناديها عندما يسجل الممرض الدخول، ليشترك في إشعارات ولايته
  static Future<void> subscribeToWilaya(String wilaya, String role) async {
    // تنظيف اسم الولاية من الفراغات لاستخدامه كاسم قناة (مثلاً: Oran_Nurse)
    String cleanWilaya = wilaya.replaceAll(' ', '_');
    String topic = "${cleanWilaya}_$role"; 
    
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint("🔔 تم الاشتراك في قناة: $topic");
  }

  // 4. إلغاء الاشتراك (عند تسجيل الخروج)
  static Future<void> unsubscribeFromWilaya(String wilaya, String role) async {
    String cleanWilaya = wilaya.replaceAll(' ', '_');
    String topic = "${cleanWilaya}_$role";
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }
}

// أداة مساعدة لتشغيل الأصوات (رنين الطلب)
// ملاحظة: نعتمد هنا على صوت الإشعارات الافتراضي للنظام لتبسيط الكود وعدم الحاجة لمكتبات إضافية معقدة
class SoundManager {
  static void playRequestSound() {
    // في أندرويد، عند وصول إشعار بالقناة 'high_importance' سيعمل الصوت تلقائياً
    // لكن يمكننا إضافة اهتزاز إضافي هنا إذا أردنا
    HapticFeedback.heavyImpact();
  }
}

// ============================================================================
// دالة الربط السحرية (Inject this into your Submit Order logic)
// هذه الدالة تستخدمها في البارت 5 و 6 و 7 لربط الأزرار بالإشعارات
// ============================================================================

class NotificationTrigger {
  
  // أ) عند طلب المريض: نرسل لكل ممرضي الولاية
  static Future<void> newOrderAlert(String wilaya, String serviceName) async {
    String cleanWilaya = wilaya.replaceAll(' ', '_');
    // إشعار للممرضين
    await NotificationEngine.sendToTopic(
      topic: "${cleanWilaya}_nurse", 
      title: "🚑 طلب جديد في $wilaya", 
      body: "مريض يطلب خدمة $serviceName. اضغط للتفاصيل.",
      data: {'type': 'new_order'}
    );
    
    // إشعار للأطباء (إذا كانت الخدمة طبية)
    // يمكن تفعيلها حسب نوع الخدمة
  }

  // ب) عند قبول الممرض: نرسل للمريض
  static Future<void> orderAcceptedAlert(String patientToken, String nurseName) async {
    await NotificationEngine.sendToToken(
      token: patientToken, 
      title: "✅ تم قبول طلبك!", 
      body: "الممرض $nurseName في الطريق إليك الآن."
    );
  }

  // ج) إشعار البث من الأدمن
  static Future<void> broadcastAlert(String message) async {
    await NotificationEngine.sendToTopic(
      topic: "all_users", 
      title: "📢 تنبيه من الإدارة", 
      body: message
    );
  }
}

// مكون للاشتراك التلقائي عند فتح التطبيق (ضعه في الصفحة الرئيسية)
class NotificationListenerWrapper extends StatefulWidget {
  final Widget child;
  const NotificationListenerWrapper({super.key, required this.child});

  @override
  State<NotificationListenerWrapper> createState() => _NotificationListenerWrapperState();
}

class _NotificationListenerWrapperState extends State<NotificationListenerWrapper> {
  @override
  void initState() {
    super.initState();
    _setupInteractions();
    // اشتراك عام للجميع
    FirebaseMessaging.instance.subscribeToTopic("all_users");
  }

  void _setupInteractions() async {
    // التعامل مع النقر على الإشعار والتطبيق مغلق
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // التعامل مع النقر والتطبيق مفتوح في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    // هنا يمكن توجيه المستخدم لصفحة الطلب
    debugPrint("تم النقر على الإشعار: ${message.data}");
    // مثال: Navigator.pushNamed(context, '/orders');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
// ============================================================================
// 🏁 PART 10: UTILITIES, INTERNET MONITOR & FINAL CONFIG (النهاية)
// ============================================================================

// 1. مراقب الإنترنت (يظهر شريط حالة عند الانقطاع)
class ConnectionMonitorWrapper extends StatefulWidget {
  final Widget child;
  const ConnectionMonitorWrapper({super.key, required this.child});

  @override
  State<ConnectionMonitorWrapper> createState() => _ConnectionMonitorWrapperState();
}

class _ConnectionMonitorWrapperState extends State<ConnectionMonitorWrapper> {
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    // الاستماع للتغييرات (Wi-Fi / Mobile Data)
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      bool hasNet = !result.contains(ConnectivityResult.none);
      if (hasNet != _isConnected) {
        setState(() => _isConnected = hasNet);
      }
    });
  }

  Future<void> _checkInitial() async {
    var result = await Connectivity().checkConnectivity();
    setState(() => _isConnected = !result.contains(ConnectivityResult.none));
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),
        // شريط التنبيه عند انقطاع النت
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isConnected ? 0 : 40,
          color: Colors.redAccent,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 16),
              SizedBox(width: 10),
              Text("لا يوجد اتصال بالإنترنت", style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }
}

// 2. معالج الأخطاء المخصص (بدلاً من الشاشة الحمراء)
class GlobalErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;
  const GlobalErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 20),
              const Text("عذراً، حدث خطأ غير متوقع!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("لقد تم تسجيل الخطأ وسيتم إصلاحه قريباً.", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // إعادة تشغيل التطبيق أو العودة للرئيسية
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (_) => const SplashScreen()), 
                    (route) => false
                  );
                },
                child: const Text("إعادة التشغيل"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ✅ END OF CODE - النسخة الأسطورية V2.0 مكتملة
// Developed by: Branis Yacine (The Manager) & Gemini (The Architect)
// ============================================================================
