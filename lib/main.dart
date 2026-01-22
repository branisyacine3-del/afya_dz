import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// سنقوم بإنشاء هذه الملفات في الخطوات القادمة، لا تقلق من الخط الأحمر مؤقتاً
import 'auth_screens.dart'; // الملف رقم 2
import 'patient_flow.dart'; // الملف رقم 3
import 'provider_flow.dart'; // الملف رقم 4
import 'admin_panel.dart';   // الملف رقم 5

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AfyaApp());
}

class AfyaApp extends StatelessWidget {
  const AfyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Afya DZ',
      // 🎨 الثيم الاحترافي (Medical Glassmorphism)
      theme: ThemeData(
        fontFamily: 'Cairo', // تأكد من إضافة الخط في pubspec.yaml
        primaryColor: const Color(0xFF009688), // Teal الطبي
        scaffoldBackgroundColor: const Color(0xFFF0F4F8), // رمادي ثلجي مريح للعين
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688),
          primary: const Color(0xFF009688),
          secondary: const Color(0xFF26A69A),
          background: const Color(0xFFF0F4F8),
        ),
        // تصميم الأزرار الموحد
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009688),
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0xFF009688).withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        ),
        // تصميم حقول الإدخال
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF009688))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// 🌊 شاشة السبلاش الذكية (Smart Splash)
// -----------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // إعداد الأنيميشن
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    
    _controller.forward();
    
    // بدء الفحص الذكي
    _smartRouting();
  }

  Future<void> _smartRouting() async {
    await Future.delayed(const Duration(seconds: 3)); // وقت لظهور الشعار
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // 1. مستخدم جديد -> شاشات الترحيب
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OnboardingScreen()));
    } else {
      // 2. مستخدم مسجل -> فحص دوره وتوجيهه
      if (user.email == "admin@afya.dz") {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard())); // سننشئه في الملف 5
        return;
      }
      
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          String role = doc['role'] ?? 'patient';
          
          if (role == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard())); // ملف 5
          } else if (role == 'provider') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProviderGate())); // ملف 4
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PatientHome())); // ملف 3
          }
        } else {
          // حساب موجود في Auth ومحذوف من Firestore (نادرة)
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())); // ملف 2
        }
      } catch (e) {
        // في حال انقطاع النت، نعيده للتسجيل كإجراء آمن
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF009688), Color(0xFF80CBC4)], // تدرج لوني طبي
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
                        ),
                        child: const Icon(Icons.medical_services_rounded, size: 80, color: Color(0xFF009688)),
                      ),
                      const SizedBox(height: 20),
                      const Text("عافية", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: const Text("عافيتك.. دائماً أقرب ❤️", style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                      const SizedBox(height: 50),
                      const CircularProgressIndicator(color: Colors.white),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 📖 شاشات الترحيب (Onboarding) - تظهر مرة واحدة
// -----------------------------------------------------------------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "مرحباً بك في عافية",
      "desc": "أول منصة جزائرية ذكية تربطك بأفضل الممرضين والأطباء وأنت في منزلك.",
      "icon": "assets/logo.png" // سنستخدم أيقونة افتراضية في الكود
    },
    {
      "title": "خدمات طبية شاملة",
      "desc": "حقن، تغيير ضمادات، فحص طبي، ونقل صحي.. بضغطة زر واحدة.",
      "icon": "assets/service.png"
    },
    {
      "title": "أمان وموثوقية",
      "desc": "جميع شركائنا معتمدون وتم التحقق من وثائقهم بدقة لراحتك وسلامتك.",
      "icon": "assets/safe.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                child: const Text("تخطي", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPageContent(index),
              ),
            ),
            // المؤشرات والزر
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 25 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? const Color(0xFF009688) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                        } else {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                        }
                      },
                      child: Text(_currentPage == _pages.length - 1 ? "ابدأ الآن" : "التالي"),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(int index) {
    IconData icon = Icons.medical_services;
    if (index == 1) icon = Icons.healing;
    if (index == 2) icon = Icons.verified_user;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: const Color(0xFF009688).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 100, color: const Color(0xFF009688)),
          ),
          const SizedBox(height: 40),
          Text(
            _pages[index]['title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          Text(
            _pages[index]['desc']!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
