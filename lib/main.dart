// ============================================================================
// 🏥 AFYA DZ - TITANIUM EDITION (V10)
// 👑 Developed for: The Manager (Branis Yacine)
// 📅 Date: January 2026
// 💻 Version: 10.0.0 (Enterprise)
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

// --- Firebase Core ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// --- Flutter Core ---
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- External Libraries (The Powerhouse) ---
import 'package:flutter_map/flutter_map.dart'; // OpenStreetMap
import 'package:latlong2/latlong.dart'; // Coordinates
import 'package:geolocator/geolocator.dart'; // GPS
import 'package:geocoding/geocoding.dart'; // Reverse Geocoding
import 'package:image_picker/image_picker.dart'; // Camera/Gallery
import 'package:intl/intl.dart' as intl; // Date Formatting
import 'package:url_launcher/url_launcher.dart'; // Calls/SMS
import 'package:shared_preferences/shared_preferences.dart'; // Local Storage
import 'package:animate_do/animate_do.dart'; // Professional Animations
import 'package:google_fonts/google_fonts.dart'; // Fonts

// ============================================================================
// 🇩🇿 CONSTANTS: ALGERIA WILAYAS DATABASE (58 STATES)
// ============================================================================
// قائمة الولايات الرسمية لضمان الفلترة الدقيقة بين المريض والممرض
const List<String> dzWilayas = [
  "01 - أدرار", "02 - الشلف", "03 - الأغواط", "04 - أم البواقي", "05 - باتنة",
  "06 - بجاية", "07 - بسكرة", "08 - بشار", "09 - البليدة", "10 - بويرة",
  "11 - تمنراست", "12 - تبسة", "13 - تلمسان", "14 - تيارت", "15 - تيزي وزو",
  "16 - الجزائر", "17 - الجلفة", "18 - جيجل", "19 - سطيف", "20 - سعيدة",
  "21 - سكيكدة", "22 - سيدي بلعباس", "23 - عنابة", "24 - قالمة", "25 - قسنطينة",
  "26 - المدية", "27 - مستغانم", "28 - المسيلة", "29 - معسكر", "30 - ورقلة",
  "31 - وهران", "32 - البيض", "33 - إليزي", "34 - برج بوعريريج", "35 - بومرداس",
  "36 - الطارف", "37 - تندوف", "38 - تيسمسيلت", "39 - الوادي", "40 - خنشلة",
  "41 - سوق أهراس", "42 - تيبازة", "43 - ميلة", "44 - عين الدفلى", "45 - النعامة",
  "46 - عين تموشنت", "47 - غرداية", "48 - غليزان", "49 - تيميمون", "50 - برج باجي مختار",
  "51 - أولاد جلال", "52 - بني عباس", "53 - إن صالح", "54 - إن قزام", "55 - تقرت",
  "56 - جانت", "57 - المغير", "58 - الميعة"
];

// ============================================================================
// ⚙️ CONFIGURATION & THEME ENGINE
// ============================================================================

// إعدادات فايربيز (تأكد من صحة البيانات الخاصة بمشروعك)
const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDlQHl2B8d_8nw8-N6_51MEH4j_KYqz7NA",
  authDomain: "afya-dz.firebaseapp.com",
  projectId: "afya-dz",
  storageBucket: "afya-dz.firebasestorage.app",
  messagingSenderId: "311376524644",
  appId: "1:311376524644:web:a3d9c77a53c0570a0eb671",
);

// --- Theme Management System (نظام إدارة الألوان والوضع الليلي) ---
class AppColors {
  // الألوان الأساسية
  static const primary = Color(0xFF00BFA5); // Teal 500
  static const primaryDark = Color(0xFF00897B); // Teal 600
  static const primaryLight = Color(0xFF1DE9B6); // Teal A400
  
  static const secondary = Color(0xFF263238); // Blue Grey 900
  static const accent = Color(0xFFFFAB00); // Amber A700
  
  // ألوان الحالة
  static const success = Color(0xFF00C853); // Green A700
  static const error = Color(0xFFD50000); // Red A700
  static const warning = Color(0xFFFFD600); // Yellow A700
  static const info = Color(0xFF2962FF); // Blue A700
  
  // ألوان الخلفيات
  static const bgLight = Color(0xFFF5F7FA);
  static const bgDark = Color(0xFF121212);
  static const surfaceLight = Colors.white;
  static const surfaceDark = Color(0xFF1E1E1E);
}

// مزود الثيم (Theme Provider) - يحفظ اختيار المستخدم
class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  
  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      return ui.window.platformBrightness == ui.Brightness.dark;
    }
    return themeMode == ThemeMode.dark;
  }

  // تحميل الإعدادات المحفوظة
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark');
    if (isDark != null) {
      themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  // تبديل الوضع وحفظه
  Future<void> toggleTheme() async {
    themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDarkMode);
    notifyListeners();
  }
}

final themeProvider = ThemeProvider();

// ============================================================================
// 🚀 MAIN ENTRY POINT (نقطة الانطلاق)
// ============================================================================

Future<void> main() async {
  // ضمان تهيئة الودجت
  WidgetsFlutterBinding.ensureInitialized();
  
  // تحسين شريط الحالة (Status Bar) ليكون شفافاً
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));
  
  // تثبيت الاتجاه العمودي (Portrait Only) لتصميم أفضل
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تهيئة فايربيز مع معالجة الأخطاء
  try {
    await Firebase.initializeApp(options: firebaseOptions);
    debugPrint("✅ Firebase Initialized Successfully");
  } catch (e) {
    debugPrint("⚠️ Firebase Init Warning: $e");
    // محاولة إعادة التهيئة الافتراضية إذا فشلت المخصصة
    try { await Firebase.initializeApp(); } catch (_) {}
  }
  
  // تحميل إعدادات الثيم
  await themeProvider.loadTheme();
  
  runApp(const AfyaAppPro());
}

// ============================================================================
// 📱 APP ROOT WIDGET (الجذر الرئيسي للتطبيق)
// ============================================================================

class AfyaAppPro extends StatelessWidget {
  const AfyaAppPro({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Afya DZ Pro',
          
          // --- Light Theme Definition ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.surfaceLight,
              background: AppColors.bgLight,
              error: AppColors.error,
            ),
            scaffoldBackgroundColor: AppColors.bgLight,
            // تنسيق النصوص (Google Fonts)
            textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme),
            // تنسيق الأزرار الافتراضي
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
            // تنسيق حقول الإدخال
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              contentPadding: const EdgeInsets.all(20),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: AppColors.secondary),
              titleTextStyle: TextStyle(color: AppColors.secondary, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
            ),
          ),

          // --- Dark Theme Definition ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
              surface: AppColors.surfaceDark,
              background: AppColors.bgDark,
            ),
            scaffoldBackgroundColor: AppColors.bgDark,
            textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
            ),
          ),
          
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(), // سننشئها في البارت القادم
        );
      }
    );
  }
}
// ============================================================================
// 🎨 PART 2: TITANIUM UI KIT (مكتبة التصميم الاحترافية)
// ============================================================================

// 1. بطاقة زجاجية متطورة (Advanced Glassmorphism Card)
// تدعم التمويه الخلفي (Blur) وتتكيف مع الوضع المظلم
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color? color;
  final bool borderGlow;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
    this.borderGlow = false,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // تحديد لون الخلفية بناءً على الثيم
    final baseColor = color ?? (isDark 
        ? const Color(0xFF252525).withOpacity(0.7) 
        : Colors.white.withOpacity(0.8));
    
    // تحديد لون الحدود
    final borderColor = isDark 
        ? Colors.white.withOpacity(0.1) 
        : Colors.white.withOpacity(0.6);

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderGlow ? AppColors.primary.withOpacity(0.5) : borderColor, 
                width: borderGlow ? 1.5 : 1
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                splashColor: AppColors.primary.withOpacity(0.1),
                highlightColor: AppColors.primary.withOpacity(0.05),
                child: Padding(
                  padding: padding,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 2. زر تفاعلي احترافي (Pro Interactive Button)
// يحتوي على تأثير "الضغط" (Scale) ومؤشر تحميل مدمج
class ProButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;
  final bool isOutlined;
  final bool isSmall;

  const ProButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.icon,
    this.isOutlined = false,
    this.isSmall = false,
  });

  @override
  State<ProButton> createState() => _ProButtonState();
}

class _ProButtonState extends State<ProButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(_scaleCtrl);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? AppColors.primary;
    
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) => _scaleCtrl.reverse(),
      onTapCancel: () => _scaleCtrl.reverse(),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: widget.isSmall ? 40 : 58,
          width: widget.isSmall ? null : double.infinity,
          padding: EdgeInsets.symmetric(horizontal: widget.isSmall ? 16 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: widget.isOutlined 
                ? null 
                : LinearGradient(
                    colors: [themeColor, themeColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: widget.isOutlined 
                ? Border.all(color: themeColor, width: 2) 
                : null,
            boxShadow: (widget.isOutlined || widget.onPressed == null) 
                ? [] 
                : [BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      color: widget.isOutlined ? themeColor : Colors.white, 
                      strokeWidth: 2.5
                    )
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon, 
                          color: widget.isOutlined ? themeColor : Colors.white, 
                          size: widget.isSmall ? 18 : 22
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: widget.isSmall ? 14 : 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                          color: widget.isOutlined ? themeColor : Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// 3. حقل إدخال ذكي (Smart Text Field)
// يتوهج عند التركيز (Focus) ويدعم الأيقونات
class SmartTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType type;
  final bool isPassword;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final String? Function(String?)? validator;

  const SmartTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.type = TextInputType.text,
    this.isPassword = false,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.validator,
  });

  @override
  State<SmartTextField> createState() => _SmartTextFieldState();
}

class _SmartTextFieldState extends State<SmartTextField> {
  bool _isFocused = false;
  bool _showPass = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Focus(
      onFocusChange: (focus) => setState(() => _isFocused = focus),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isFocused ? AppColors.primary : Colors.transparent, 
            width: 2
          ),
          boxShadow: [
            BoxShadow(
              color: _isFocused ? AppColors.primary.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: _isFocused ? 15 : 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && !_showPass,
          keyboardType: widget.type,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          onTap: widget.onTap,
          validator: widget.validator,
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _isFocused ? AppColors.primary : Colors.grey,
              fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal
            ),
            prefixIcon: Icon(
              widget.icon, 
              color: _isFocused ? AppColors.primary : Colors.grey
            ),
            suffixIcon: widget.isPassword 
                ? IconButton(
                    icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ) 
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none, // سنعتمد على التحقق اليدوي أو SnackBar للجمالية
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
        ),
      ),
    );
  }
}

// 4. شارة الحالة (Status Badge)
// تعرض حالة الطلب بتصميم أنيق وألوان متغيرة
class StatusBadge extends StatelessWidget {
  final String status;
  
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = "قيد الانتظار";
        icon = Icons.hourglass_empty;
        break;
      case 'accepted':
        color = Colors.blue;
        text = "مقبول";
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
      case 'completed_by_nurse':
        color = AppColors.success;
        text = "مكتمل";
        icon = Icons.verified;
        break;
      case 'rejected':
      case 'cancelled':
        color = AppColors.error;
        text = "ملغى";
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// 5. حالة الفراغ (Empty State)
// تظهر عندما لا تكون هناك بيانات
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyState({
    super.key, 
    this.title = "لا توجد بيانات", 
    this.subtitle = "لم يتم العثور على أي نتائج في الوقت الحالي",
    this.icon = Icons.inbox_outlined
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. حاوية الأنيميشن العالمية (Universal Fade Animation)
class FadeInSlide extends StatelessWidget {
  final Widget child;
  final int delay;
  final bool slideUp;

  const FadeInSlide({super.key, required this.child, this.delay = 0, this.slideUp = true});

  @override
  Widget build(BuildContext context) {
    // نستخدم مكتبة animate_do لتأثيرات سلسة واحترافية
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 600),
      from: slideUp ? 20 : -20,
      child: child,
    );
  }
}
// ============================================================================
// 🗺️ PART 3: MAPS ENGINE & AUTHENTICATION (محرك الخرائط والمصادقة)
// ============================================================================

// 1. أداة اختيار الموقع المجانية (OpenStreetMap Picker)
// لا تحتاج API Key ولا دفع - تعمل 100% مجاناً
class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  const MapPickerScreen({super.key, this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  // إحداثيات افتراضية (وسط الجزائر)
  LatLng _selectedLocation = const LatLng(36.75, 3.05); 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _isLoading = false;
    } else {
      _getCurrentLocation();
    }
  }

  // تحديد موقع المستخدم الحالي عند الفتح
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _selectedLocation = LatLng(position.latitude, position.longitude);
            _isLoading = false;
          });
          // تحريك الكاميرا للموقع
          _mapController.move(_selectedLocation, 15);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("GPS Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // طبقة الخريطة (OpenStreetMap)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 13.0,
              onTap: (_, point) {
                setState(() => _selectedLocation = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.afya.dz', // ضروري لسياسة الاستخدام
              ),
              // العلامة الحمراء المتحركة
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 80,
                    height: 80,
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: const Icon(Icons.location_on, color: AppColors.error, size: 50),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // زر تحديد الموقع الحالي (GPS)
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppColors.primary),
              onPressed: () {
                _getCurrentLocation();
                _mapController.move(_selectedLocation, 15);
              },
            ),
          ),

          // زر التأكيد السفلي
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: FadeInUp(
              child: GlassCard(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "حرك الدبوس لتحديد الموقع بدقة",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ProButton(
                      text: "تأكيد هذا الموقع",
                      icon: Icons.check_circle,
                      onPressed: () {
                        Navigator.pop(context, _selectedLocation);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            )
        ],
      ),
    );
  }
}

// 2. شاشات الترحيب (Onboarding)
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
      "desc": "الرعاية الصحية المتكاملة تصلك إلى باب منزلك بذكاء وسرعة فائقة.",
      "icon": Icons.health_and_safety_outlined,
      "color": AppColors.primary
    },
    {
      "title": "تتبع مباشر وحقيقي",
      "desc": "شاهد تحرك الممرض نحوك لحظة بلحظة عبر الخريطة التفاعلية داخل التطبيق.",
      "icon": Icons.map_outlined,
      "color": AppColors.info
    },
    {
      "title": "نخبة المحترفين",
      "desc": "ممرضون معتمدون جاهزون لخدمتك في جميع ولايات الجزائر الـ 58.",
      "icon": Icons.verified_user_outlined,
      "color": AppColors.accent
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
            bottom: 40, left: 30, right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // مؤشر الصفحات (Dots)
                Row(
                  children: List.generate(_pages.length, (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 5),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? _pages[_currentPage]['color'] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4)
                    )
                  ))
                ),
                // زر التالي
                FloatingActionButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageCtrl.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
                    } else {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                    }
                  },
                  backgroundColor: _pages[_currentPage]['color'],
                  elevation: 0,
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: (data['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(data['icon'], size: 100, color: data['color']),
            ),
          ),
          const SizedBox(height: 50),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              data['title'],
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
          ),
          const SizedBox(height: 20),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Text(
              data['desc'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.grey, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// 3. شاشة البداية الذكية (Splash Screen)
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
    await Future.delayed(const Duration(seconds: 3)); // انتظار للأنيميشن
    if (FirebaseAuth.instance.currentUser != null) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper()));
    } else {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
          )
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)
                  ),
                  child: const Icon(Icons.health_and_safety, size: 80, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
              FadeInUp(
                child: const Text(
                  "عافية",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: const Text(
                  "الرعاية الصحية في جيبك",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              const SizedBox(height: 60),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// 4. شاشة المصادقة (Auth Screen - Login & Register)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    try {
      if (isLogin) {
        // تسجيل الدخول
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim()
        );
      } else {
        // إنشاء حساب جديد
        UserCredential uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim()
        );
        // تحديث الاسم
        await uc.user!.updateDisplayName(_nameCtrl.text);
        // حفظ البيانات في قاعدة البيانات
        await FirebaseFirestore.instance.collection('users').doc(uc.user!.uid).set({
          'uid': uc.user!.uid,
          'email': _emailCtrl.text.trim(),
          'name': _nameCtrl.text,
          'role': 'user', // الدور الافتراضي: مستخدم عادي
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
          'rating': 5.0, // تقييم افتراضي
        });
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper()));
    } on FirebaseAuthException catch (e) {
      String msg = "حدث خطأ غير متوقع";
      if (e.code == 'user-not-found') msg = "لا يوجد مستخدم بهذا البريد";
      if (e.code == 'wrong-password') msg = "كلمة المرور خاطئة";
      if (e.code == 'email-already-in-use') msg = "البريد الإلكتروني مسجل بالفعل";
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // رأس الصفحة المنحني
            Container(
              height: 320,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                  bottomRight: Radius.circular(60)
                )
              ),
              child: Center(
                child: FadeInDown(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_person_outlined, size: 80, color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        isLogin ? "تسجيل الدخول" : "إنشاء حساب جديد",
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isLogin ? "مرحباً بعودتك لعافية" : "ابدأ رحلتك الصحية معنا",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // نموذج الإدخال
            Padding(
              padding: const EdgeInsets.all(30),
              child: FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!isLogin) 
                        SmartTextField(
                          controller: _nameCtrl, 
                          label: "الاسم الكامل", 
                          icon: Icons.person_outline,
                          validator: (v) => v!.isEmpty ? "الاسم مطلوب" : null,
                        ),
                      
                      SmartTextField(
                        controller: _emailCtrl, 
                        label: "البريد الإلكتروني", 
                        icon: Icons.email_outlined, 
                        type: TextInputType.emailAddress,
                        validator: (v) => !v!.contains("@") ? "بريد غير صالح" : null,
                      ),
                      
                      SmartTextField(
                        controller: _passCtrl, 
                        label: "كلمة المرور", 
                        icon: Icons.lock_outline, 
                        isPassword: true,
                        validator: (v) => v!.length < 6 ? "كلمة المرور قصيرة جداً" : null,
                      ),
                      
                      const SizedBox(height: 30),
                      
                      ProButton(
                        text: isLogin ? "دخول آمن" : "إنشاء الحساب",
                        onPressed: _submit,
                        isLoading: _loading,
                        icon: isLogin ? Icons.login : Icons.person_add,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      TextButton(
                        onPressed: () => setState(() => isLogin = !isLogin),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.grey, fontFamily: 'Tajawal'),
                            children: [
                              TextSpan(text: isLogin ? "ليس لديك حساب؟ " : "لديك حساب بالفعل؟ "),
                              TextSpan(
                                text: isLogin ? "سجل الآن" : "سجل الدخول",
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                              )
                            ]
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ============================================================================
// 🏠 PART 4: DASHBOARD & CORE SCREENS (لوحة التحكم والشاشات الرئيسية)
// ============================================================================

// 1. الغلاف الرئيسي للتنقل (Main Navigation Wrapper)
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  
  // قائمة الشاشات الرئيسية
  final List<Widget> _screens = [
    const PatientHomeScreen(), // الرئيسية
    const MyOrdersScreen(),    // طلباتي (سنضيفها في البارت القادم)
    const ProfileScreen(),     // حسابي
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // نستخدم IndexedStack للحفاظ على حالة الصفحات عند التنقل
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // شريط تنقل عائم وعصري
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: NavigationBar(
            height: 70,
            backgroundColor: isDark ? const Color(0xFF252525) : Colors.white,
            elevation: 0,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
              HapticFeedback.lightImpact(); // اهتزاز خفيف عند الضغط
            },
            indicatorColor: AppColors.primary.withOpacity(0.15),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary),
                label: "الرئيسية",
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                label: "طلباتي",
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                label: "حسابي",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. الشاشة الرئيسية للمريض (Patient Home Dashboard)
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email == "admin@afya.dz"; // بريد المدير
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // رأس الصفحة المتحرك (Sliver App Bar)
          SliverAppBar(
            expandedHeight: 180,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight
                  )
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("مرحباً بك 👋", style: TextStyle(color: Colors.white70, fontSize: 16)),
                              Text(
                                user?.displayName ?? "ضيف عافية",
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          // زر الإشعارات
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.notifications_outlined, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 25),
                      // زر البحث الوهمي
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 10),
                              Text("ابحث عن خدمة، ممرض...", style: TextStyle(color: Colors.grey))
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // محتوى الصفحة
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // زر المدير (يظهر فقط للإيميل المحدد)
                  if (isAdmin)
                    FadeInUp(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ProButton(
                          text: "لوحة التحكم المركزية (Admin)",
                          icon: Icons.admin_panel_settings,
                          color: Colors.purple,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
                        ),
                      ),
                    ),

                  // قسم العروض الحصرية (Dynamic Banner)
                  const Text("عروض حصرية 🔥", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.accent, Colors.orange]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20, bottom: -20,
                            child: Icon(Icons.local_offer, size: 150, color: Colors.white.withOpacity(0.2)),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StatusBadge(status: 'completed'), // Badge كتجربة
                                SizedBox(height: 10),
                                Text("خصم 20% هذا الأسبوع", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                Text("على جميع الحقن المنزلية", style: TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // شبكة الخدمات (Services Grid)
                  const Text("خدماتنا الطبية", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.1,
                    children: [
                      _serviceCard(context, "حقن", "500 دج", Icons.vaccines, Colors.teal, 300),
                      _serviceCard(context, "سيروم", "1500 دج", Icons.water_drop, Colors.blue, 400),
                      _serviceCard(context, "تغيير ضماد", "800 دج", Icons.healing, Colors.purple, 500),
                      _serviceCard(context, "قياس ضغط", "300 دج", Icons.monitor_heart, Colors.red, 600),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // زر بوابة الممرضين
                  FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    child: GlassCard(
                      color: Colors.blue.withOpacity(0.1),
                      borderGlow: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseAuthGate())),
                      child: const ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.medical_services, color: Colors.white)),
                        title: Text("بوابة الممرضين", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("انضم لفريقنا أو تابع مهامك"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(BuildContext context, String title, String price, IconData icon, Color color, int delay) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: GlassCard(
        padding: EdgeInsets.zero,
        onTap: () => _showOrderDialog(context, title, price),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text(price, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // نافذة الطلب (سنقوم ببرمجتها بالتفصيل لاحقاً، هذا مجرد Placeholder)
  void _showOrderDialog(BuildContext context, String title, String price) {
    // سنربطها بشاشة الطلب الكاملة في البارت الخامس
    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(serviceName: title, price: price)));
  }
}

// 3. الملف الشخصي والإعدادات (Profile Screen)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // 📞 الاتصال بالمدير (الدعم الفني)
  void _callSupport() async {
    final Uri url = Uri.parse('tel:0562898252');
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = themeProvider.isDarkMode; // استخدام المزود للتحقق من الثيم

    return Scaffold(
      appBar: AppBar(title: const Text("الملف الشخصي")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // صورة المستخدم
            FadeInDown(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      user?.displayName?[0].toUpperCase() ?? "U",
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: Text(
                user?.displayName ?? "مستخدم عافية",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 40),

            // قائمة الإعدادات
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  const Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.only(bottom: 10), child: Text("الإعدادات العامة", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))),
                  
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // زر الوضع الليلي (يعمل 100%)
                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.dark_mode, color: Colors.purple)),
                          title: const Text("الوضع الليلي"),
                          trailing: Switch(
                            value: isDark,
                            onChanged: (val) => themeProvider.toggleTheme(), // تبديل الثيم
                            activeColor: AppColors.primary,
                          ),
                        ),
                        const Divider(height: 1),
                        // زر اللغة
                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.language, color: Colors.blue)),
                          title: const Text("اللغة"),
                          trailing: const Text("العربية", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.only(bottom: 10), child: Text("الدعم والأمان", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))),

                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // زر الاتصال بالدعم (رقمك الخاص)
                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.headset_mic, color: AppColors.success)),
                          title: const Text("المساعدة والدعم"),
                          subtitle: const Text("تواصل مباشر مع الإدارة"),
                          onTap: _callSupport,
                        ),
                        const Divider(height: 1),
                        // زر تسجيل الخروج
                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.logout, color: AppColors.error)),
                          title: const Text("تسجيل الخروج"),
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            const Text("Afya DZ v10.0.0 (Titanium)", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 80), // مسافة للشريط السفلي
          ],
        ),
      ),
    );
  }
}

// 4. شاشات فرعية (Search & Notification)
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الإشعارات")),
      body: const EmptyState(
        title: "لا توجد إشعارات",
        subtitle: "سنخبرك فور وجود عروض جديدة أو تحديثات على طلباتك",
        icon: Icons.notifications_off_outlined,
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SmartTextField(
          controller: TextEditingController(), 
          label: "بحث...", 
          icon: Icons.search,
        ),
      ),
      body: const EmptyState(
        title: "ما الذي تبحث عنه؟",
        subtitle: "جرب البحث عن 'حقن' أو 'ممرض في وهران'...",
        icon: Icons.search_off,
      ),
    );
  }
}
// ============================================================================
// 🛒 PART 5: ORDER SYSTEM & SMART FILTERING (نظام الطلبات والذكاء الجغرافي)
// ============================================================================

// 1. شاشة تأكيد الطلب (Advanced Order Screen)
class OrderScreen extends StatefulWidget {
  final String serviceName;
  final String price;

  const OrderScreen({super.key, required this.serviceName, required this.price});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedWilaya;
  LatLng? _selectedLocation;
  bool _isLoading = false;

  // دالة فتح الخريطة لاختيار الموقع
  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen())
    );

    if (result != null && result is LatLng) {
      setState(() {
        _selectedLocation = result;
      });
      
      // 🧠 ذكاء جغرافي: محاولة اكتشاف الولاية تلقائياً من الإحداثيات
      // هذا يوفر على المستخدم البحث في القائمة
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(result.latitude, result.longitude);
        if (placemarks.isNotEmpty) {
          String? adminArea = placemarks.first.administrativeArea; // عادة يحتوي على اسم الولاية
          // محاولة مطابقة الاسم مع قائمتنا الثابتة
          for (var w in dzWilayas) {
            // بحث ذكي (يحتوي على الاسم)
            if (adminArea != null && w.contains(adminArea.split(" ").last)) {
              setState(() => _selectedWilaya = w);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم تحديد الولاية تلقائياً: $w"), backgroundColor: AppColors.success));
              break;
            }
          }
        }
      } catch (_) {
        // فشل التحديد التلقائي لا يهم، سيختار يدوياً
      }
    }
  }

  Future<void> _submitOrder() async {
    if (_phoneCtrl.text.isEmpty || _selectedWilaya == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى تحديد الموقع، الولاية، ورقم الهاتف"), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'service': widget.serviceName,
        'price': widget.price,
        'patient_id': user?.uid,
        'patient_name': user?.displayName,
        'phone': _phoneCtrl.text,
        'description': _descCtrl.text,
        'wilaya': _selectedWilaya, // 🔑 مفتاح الفلترة للممرض
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
        'status': 'pending', // الحالة الأولية
        'timestamp': FieldValue.serverTimestamp(),
        'nurse_id': null,
      });

      if (mounted) {
        Navigator.pop(context); // إغلاق الشاشة
        // عرض رسالة نجاح جميلة
        showDialog(context: context, builder: (_) => const SuccessDialog());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تأكيد طلب ${widget.serviceName}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ملخص الخدمة
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.secondary, Colors.black87]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(widget.serviceName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(15)),
                      child: Text(widget.price, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // نموذج البيانات
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  SmartTextField(controller: _phoneCtrl, label: "رقم الهاتف للاتصال", icon: Icons.phone, type: TextInputType.phone),
                  SmartTextField(controller: _descCtrl, label: "وصف الحالة (اختياري)", icon: Icons.description, maxLines: 3),
                  
                  // اختيار الموقع (الزر الكبير)
                  GestureDetector(
                    onTap: _pickLocation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _selectedLocation != null ? AppColors.success.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _selectedLocation != null ? AppColors.success : Colors.grey.shade300,
                          width: 2
                        )
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: _selectedLocation != null ? AppColors.success : Colors.grey, size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedLocation != null ? "تم تحديد الموقع بنجاح" : "تحديد موقع المنزل",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _selectedLocation != null ? AppColors.success : Colors.black87
                                  ),
                                ),
                                if (_selectedLocation != null)
                                  const Text("اضغط للتغيير", style: TextStyle(color: Colors.grey, fontSize: 12))
                                else
                                  const Text("اضغط لفتح الخريطة", style: TextStyle(color: Colors.grey, fontSize: 12))
                              ],
                            ),
                          ),
                          if (_selectedLocation != null) const Icon(Icons.check_circle, color: AppColors.success)
                        ],
                      ),
                    ),
                  ),

                  // القائمة المنسدلة للولايات (Dropdown)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _selectedWilaya != null ? AppColors.primary : Colors.transparent)
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Row(children: const [Icon(Icons.map_outlined, color: Colors.grey), SizedBox(width: 10), Text("اختر الولاية")]),
                        value: _selectedWilaya,
                        icon: const Icon(Icons.arrow_drop_down_circle, color: AppColors.primary),
                        items: dzWilayas.map((String w) {
                          return DropdownMenuItem<String>(
                            value: w,
                            child: Text(w, style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedWilaya = val),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  ProButton(
                    text: "إرسال الطلب الآن",
                    icon: Icons.send,
                    isLoading: _isLoading,
                    onPressed: _submitOrder,
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

// نافذة النجاح (Dialog)
class SuccessDialog extends StatelessWidget {
  const SuccessDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeInDown(child: const Icon(Icons.check_circle, color: AppColors.success, size: 80)),
            const SizedBox(height: 20),
            const Text("تم استلام طلبك!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 10),
            const Text("جاري إشعار الممرضين في منطقتك.\nستصلك الموافقة قريباً.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ProButton(text: "حسناً", onPressed: () => Navigator.pop(context), isSmall: true)
          ],
        ),
      ),
    );
  }
}

// 2. شاشة طلباتي (My Orders History)
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(title: const Text("سجل الطلبات")),
      body: StreamBuilder<QuerySnapshot>(
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
            return const EmptyState(title: "لا توجد طلبات", subtitle: "لم تقم بطلب أي خدمة طبية بعد", icon: Icons.history);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'pending';

              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: GlassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: status == 'accepted' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle
                          ),
                          child: Icon(
                            status == 'accepted' ? Icons.medical_services : Icons.access_time,
                            color: status == 'accepted' ? Colors.blue : Colors.orange
                          ),
                        ),
                        title: Text(data['service'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['price'], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        trailing: StatusBadge(status: status),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // عرض التاريخ
                            Text(
                              data['timestamp'] != null 
                                ? intl.DateFormat('dd/MM/yyyy HH:mm').format((data['timestamp'] as Timestamp).toDate())
                                : "الآن",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            
                            // أزرار التحكم (التتبع أو الإلغاء)
                            if (status == 'accepted')
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(
                                    orderId: doc.id,
                                    targetLat: data['lat'],
                                    targetLng: data['lng'],
                                    nurseName: data['nurse_name'] ?? "ممرض",
                                  )));
                                },
                                icon: const Icon(Icons.map, size: 16),
                                label: const Text("تتبع الممرض"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 15)),
                              )
                            else if (status == 'pending')
                              TextButton(
                                onPressed: () => doc.reference.delete(),
                                child: const Text("إلغاء الطلب", style: TextStyle(color: Colors.red)),
                              )
                          ],
                        ),
                      )
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

// 3. شاشة التتبع (Tracking Screen) - خرائط مجانية
class TrackingScreen extends StatelessWidget {
  final String orderId;
  final double targetLat;
  final double targetLng;
  final String nurseName;

  const TrackingScreen({
    super.key, 
    required this.orderId, 
    required this.targetLat, 
    required this.targetLng,
    required this.nurseName
  });

  // الاتصال بالممرض
  void _callNurse(String? phone) async {
    if (phone == null) return;
    final Uri url = Uri.parse('tel:$phone');
    if (!await launchUrl(url)) throw 'Could not launch $url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("تتبع الطلب", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Stack(
        children: [
          // الخريطة
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(targetLat, targetLng),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.afya.dz'),
              // علامة المريض (المنزل)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(targetLat, targetLng),
                    width: 60, height: 60,
                    child: const Icon(Icons.home, color: AppColors.primary, size: 40),
                  ),
                  // علامة الممرض (محاكاة قريبة)
                  Marker(
                    point: LatLng(targetLat + 0.002, targetLng + 0.002), // موقع وهمي قريب
                    width: 60, height: 60,
                    child: const Icon(Icons.directions_car, color: Colors.blue, size: 40),
                  ),
                ],
              ),
            ],
          ),
          
          // بطاقة معلومات الممرض السفلية
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: FadeInUp(
              child: GlassCard(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("الممرض $nurseName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                              const Text("في الطريق إليك • 5 دقائق", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        // زر الاتصال
                        Container(
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.phone, color: Colors.white),
                            onPressed: () {
                              // هنا يجب جلب رقم الممرض الحقيقي من قاعدة البيانات
                              // للمثال سنفتح الهاتف فقط
                              _callNurse("0000000000"); 
                            },
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(value: 0.7, minHeight: 6, color: Colors.blue, backgroundColor: Colors.grey),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
// ============================================================================
// 👩‍⚕️ PART 6: NURSE GATE & SMART LOGIC (بوابة الممرض والذكاء الوظيفي)
// ============================================================================

// 1. البوابة الذكية (Nurse Logic Gate)
// توجه الممرض حسب حالته (جديد، قيد المراجعة، مقبول، منتهي الاشتراك)
class NurseAuthGate extends StatelessWidget {
  const NurseAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        String status = userData?['status'] ?? 'user';
        String role = userData?['role'] ?? 'user';

        // 🧠 المنطق الذكي للاشتراك (30 يوماً)
        if (status == 'approved' && userData?['activated_at'] != null) {
          Timestamp activationTime = userData!['activated_at'];
          int daysPassed = DateTime.now().difference(activationTime.toDate()).inDays;
          if (daysPassed > 30) {
            status = 'expired'; // انتهى الاشتراك
          }
        }

        // توجيه حسب الحالة
        if (status == 'approved') {
          return const NurseDashboard(); // ✅ مقبول -> لوحة التحكم
        }

        // باقي الحالات تظهر في شاشة انتظار جميلة
        return Scaffold(
          appBar: AppBar(title: const Text("بوابة الممرضين")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (role == 'user' || status == 'active') const NurseRegisterForm(), // 1. تسجيل جديد
                
                if (status == 'pending_docs') // 2. انتظار الوثائق
                  const StatusScreen(
                    icon: Icons.hourglass_top, 
                    color: Colors.orange, 
                    title: "ملفك قيد المراجعة", 
                    desc: "يقوم فريق الإدارة بمراجعة وثائقك.\nسيتم الرد عليك قريباً."
                  ),
                
                if (status == 'pending_payment' || status == 'expired') // 3. الدفع أو التجديد
                   NursePaymentScreen(isRenewal: status == 'expired'),
                
                if (status == 'payment_review') // 4. مراجعة الدفع
                  const StatusScreen(
                    icon: Icons.search, 
                    color: Colors.blue, 
                    title: "جاري مراجعة الدفع", 
                    desc: "وصلنا الإيصال ونقوم بالتحقق منه لتفعيل اشتراكك."
                  ),
                  
                if (status == 'banned') // 5. محظور
                  const StatusScreen(
                    icon: Icons.block, 
                    color: AppColors.error, 
                    title: "تم حظر الحساب", 
                    desc: "يرجى التواصل مع الإدارة لحل المشكلة."
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// شاشة عرض الحالة (Status Widget)
class StatusScreen extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const StatusScreen({super.key, required this.icon, required this.color, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeInUp(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 80, color: color),
              ),
              const SizedBox(height: 30),
              Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 15),
              Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. نموذج تسجيل الممرض (مع القائمة المنسدلة للولايات)
class NurseRegisterForm extends StatefulWidget {
  const NurseRegisterForm({super.key});
  @override
  State<NurseRegisterForm> createState() => _NurseRegisterFormState();
}

class _NurseRegisterFormState extends State<NurseRegisterForm> {
  final _phoneCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  String? _selectedWilaya;
  // متغيرات لحفظ الصور (Base64)
  String? _picData, _idData, _diplomaData;
  bool _loading = false;

  Future<void> _pickImage(String type) async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        String base64 = base64Encode(bytes);
        if (type == 'pic') _picData = base64;
        if (type == 'id') _idData = base64;
        if (type == 'dip') _diplomaData = base64;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("انضم لفريقنا الطبي", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text("أكمل بياناتك لنبدأ المراجعة", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),

        SmartTextField(controller: _phoneCtrl, label: "رقم الهاتف", icon: Icons.phone, type: TextInputType.phone),
        SmartTextField(controller: _specCtrl, label: "التخصص (مثال: ممرض دولة)", icon: Icons.work_outline),

        // 🔑 القائمة المنسدلة للولايات (Dropdown) - جوهر الفلترة
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text("اختر ولاية العمل"),
              value: _selectedWilaya,
              items: dzWilayas.map((String w) {
                return DropdownMenuItem<String>(value: w, child: Text(w));
              }).toList(),
              onChanged: (val) => setState(() => _selectedWilaya = val),
            ),
          ),
        ),

        const SizedBox(height: 20),
        const Align(alignment: Alignment.centerRight, child: Text("المستندات المطلوبة:", style: TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
        
        _uploadBtn("صورة شخصية", _picData != null, () => _pickImage('pic')),
        _uploadBtn("بطاقة التعريف", _idData != null, () => _pickImage('id')),
        _uploadBtn("الشهادة / الدبلوم", _diplomaData != null, () => _pickImage('dip')),

        const SizedBox(height: 30),
        ProButton(
          text: "إرسال الملف للمراجعة",
          isLoading: _loading,
          onPressed: () async {
            if (_selectedWilaya == null || _picData == null || _phoneCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إكمال البيانات والصورة الشخصية")));
              return;
            }
            setState(() => _loading = true);
            await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({
              'role': 'nurse',
              'status': 'pending_docs',
              'phone': _phoneCtrl.text,
              'specialty': _specCtrl.text,
              'address': _selectedWilaya, // حفظ الولاية للفلترة لاحقاً
              'pic_data': _picData,
              'id_data': _idData,
              'diploma_data': _diplomaData,
              'submitted_at': FieldValue.serverTimestamp(),
            });
            setState(() => _loading = false);
          },
        )
      ],
    );
  }

  Widget _uploadBtn(String title, bool done, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.cloud_upload, color: done ? AppColors.success : AppColors.primary),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          if (done) const Text("تم الرفع", style: TextStyle(color: AppColors.success, fontSize: 12))
        ],
      ),
    );
  }
}

// 3. شاشة الدفع (Payment Screen)
class NursePaymentScreen extends StatefulWidget {
  final bool isRenewal;
  const NursePaymentScreen({super.key, this.isRenewal = false});
  @override
  State<NursePaymentScreen> createState() => _NursePaymentScreenState();
}

class _NursePaymentScreenState extends State<NursePaymentScreen> {
  String? _receiptBase64;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(widget.isRenewal ? Icons.update : Icons.workspace_premium, size: 60, color: AppColors.accent),
        const SizedBox(height: 20),
        Text(widget.isRenewal ? "تجديد الاشتراك" : "تفعيل العضوية", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (widget.isRenewal) const Text("انتهت صلاحية الـ 30 يوماً. جدد الآن.", style: TextStyle(color: AppColors.error)),
        const SizedBox(height: 30),
        
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD740), Color(0xFFFF6F00)]), borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: const [
              Text("الاشتراك الشهري", style: TextStyle(color: Colors.black54)),
              Text("3500 DZD", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black)),
              Divider(color: Colors.black12),
              Text("CCP: 0028939081 - 97", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Name: Branis Yacine"),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        GlassCard(
          onTap: () async {
            final x = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (x != null) {
              final b = await File(x.path).readAsBytes();
              setState(() => _receiptBase64 = base64Encode(b));
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_receiptBase64 != null ? Icons.check_circle : Icons.camera_alt, color: _receiptBase64 != null ? AppColors.success : AppColors.primary),
              const SizedBox(width: 10),
              Text(_receiptBase64 != null ? "تم اختيار الوصل" : "اضغط لرفع صورة الوصل")
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        ProButton(
          text: "تأكيد الدفع",
          isLoading: _loading,
          onPressed: _receiptBase64 == null ? null : () async {
            setState(() => _loading = true);
            await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({
              'status': 'payment_review',
              'receipt_data': _receiptBase64
            });
          },
        )
      ],
    );
  }
}

// 4. لوحة تحكم الممرض (Nurse Dashboard - Filtered)
class NurseDashboard extends StatelessWidget {
  const NurseDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("لوحة التحكم"),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: "الطلبات المتاحة"), Tab(text: "مهامي")],
          ),
        ),
        body: const TabBarView(children: [NurseMarketTab(), NurseMyTasksTab()]),
      ),
    );
  }
}

// تبويب سوق الطلبات (المفلتر حسب الولاية)
class NurseMarketTab extends StatelessWidget {
  const NurseMarketTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. نجلب بيانات الممرض لنعرف ولايته
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
        
        String myWilaya = userSnap.data!.get('address') ?? ""; // ولاية الممرض

        // 2. نجلب الطلبات التي حالتها 'pending'
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
          builder: (context, reqSnap) {
            if (!reqSnap.hasData || reqSnap.data!.docs.isEmpty) {
              return const EmptyState(title: "لا توجد طلبات", subtitle: "السوق هادئ حالياً");
            }

            // 3. فلترة يدوية للتأكد من تطابق الولاية (Client-side Filtering)
            // بما أننا وحدنا القائمة المنسدلة، المقارنة String == String ستعمل 100%
            var availableDocs = reqSnap.data!.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['wilaya'] == myWilaya; // ✅ التطابق الصارم
            }).toList();

            if (availableDocs.isEmpty) {
              return EmptyState(title: "لا طلبات في $myWilaya", subtitle: "انتظر وصول طلبات من منطقتك", icon: Icons.location_off);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: availableDocs.length,
              itemBuilder: (ctx, i) {
                var d = availableDocs[i];
                var data = d.data() as Map<String, dynamic>;
                
                return FadeInUp(
                  child: GlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.1), child: const Icon(Icons.person, color: Colors.orange)),
                          title: Text(data['patient_name'] ?? "مريض", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(data['service'], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          trailing: Text(data['price'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 5), Text(data['wilaya'] ?? "", style: const TextStyle(color: Colors.grey))]),
                        ),
                        const Divider(),
                        ProButton(
                          text: "قبول الطلب",
                          onPressed: () {
                            d.reference.update({
                              'status': 'accepted',
                              'nurse_id': FirebaseAuth.instance.currentUser?.uid,
                              'nurse_name': FirebaseAuth.instance.currentUser?.displayName
                            });
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// تبويب مهامي (الطلبات المقبولة)
class NurseMyTasksTab extends StatelessWidget {
  const NurseMyTasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('nurse_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyState(title: "ليس لديك مهام", subtitle: "اقبل طلبات من السوق لتبدأ العمل", icon: Icons.work_off);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (ctx, i) {
            var d = snapshot.data!.docs[i];
            var data = d.data() as Map<String, dynamic>;

            return GlassCard(
              borderGlow: true,
              child: Column(
                children: [
                  ListTile(
                    title: Text(data['patient_name'] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text(data['phone'] ?? ""),
                    leading: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle), child: const Icon(Icons.directions_run, color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.success),
                      onPressed: () => launchUrl(Uri.parse("tel:${data['phone']}")),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // زر فتح خرائط جوجل الخارجية (للذهاب)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.map),
                          label: const Text("الملاحة (GPS)"),
                          onPressed: () {
                            // فتح Google Maps للتوجيه الحقيقي
                            launchUrl(Uri.parse("google.navigation:q=${data['lat']},${data['lng']}"));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // زر الإنهاء
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text("إنهاء المهمة"),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                          onPressed: () {
                            d.reference.update({'status': 'completed_by_nurse'});
                          },
                        ),
                      ),
                    ],
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
// ============================================================================
// 👮‍♂️ PART 7: ADMIN COMMAND CENTER (لوحة القيادة المركزية)
// ============================================================================

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("الإدارة المركزية"),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "طلبات الانضمام"),
              Tab(text: "قائمة الممرضين"),
              Tab(text: "إدارة العروض"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminRequestsTab(), // طلبات المعلقة (وثائق + دفع)
            AdminNursesListTab(), // الممرضين المقبولين
            AdminOffersManager(), // التحكم في بنر العروض
          ],
        ),
      ),
    );
  }
}

// 1. تبويب الطلبات المعلقة (Pending Requests)
class AdminRequestsTab extends StatelessWidget {
  const AdminRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // جلب أي مستخدم حالته "انتظار وثائق" أو "مراجعة دفع"
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('status', whereIn: ['pending_docs', 'payment_review'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        if (snapshot.data!.docs.isEmpty) {
          return const EmptyState(
            title: "لا توجد طلبات معلقة", 
            subtitle: "كل الأمور تحت السيطرة", 
            icon: Icons.check_circle_outline
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (ctx, i) {
            var doc = snapshot.data!.docs[i];
            var data = doc.data() as Map<String, dynamic>;
            bool isPayment = data['status'] == 'payment_review';

            return FadeInUp(
              child: GlassCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPayment ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    child: Icon(isPayment ? Icons.payments : Icons.file_copy, color: isPayment ? Colors.blue : Colors.orange),
                  ),
                  title: Text(data['name'] ?? "مجهول", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isPayment ? "يريد تفعيل الاشتراك" : "مراجعة الوثائق"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => NurseDetailScreen(docId: doc.id, data: data))
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 2. تبويب قائمة الممرضين (All Nurses)
class AdminNursesListTab extends StatelessWidget {
  const AdminNursesListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'nurse')
          .where('status', whereIn: ['approved', 'banned', 'expired'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        if (snapshot.data!.docs.isEmpty) {
          return const EmptyState(title: "لا يوجد ممرضين", subtitle: "القائمة فارغة حالياً");
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (ctx, i) {
            var doc = snapshot.data!.docs[i];
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'];

            return FadeInUp(
              delay: Duration(milliseconds: i * 50),
              child: GlassCard(
                borderGlow: status == 'approved', // توهج للمفعلين فقط
                child: ListTile(
                  leading: Hero(
                    tag: doc.id,
                    child: CircleAvatar(
                      backgroundImage: data['pic_data'] != null 
                          ? MemoryImage(base64Decode(data['pic_data'])) 
                          : null,
                      child: data['pic_data'] == null ? const Icon(Icons.person) : null,
                    ),
                  ),
                  title: Text(data['name'] ?? "بدون اسم", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['address'] ?? "ولاية غير محددة"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'approved' ? AppColors.success : (status == 'banned' ? AppColors.error : Colors.grey),
                      borderRadius: BorderRadius.circular(5)
                    ),
                    child: Text(
                      status == 'approved' ? "نشط" : (status == 'banned' ? "محظور" : "منتهي"),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => NurseDetailScreen(docId: doc.id, data: data))
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 3. مدير العروض (Offer Manager)
class AdminOffersManager extends StatefulWidget {
  const AdminOffersManager({super.key});
  @override
  State<AdminOffersManager> createState() => _AdminOffersManagerState();
}

class _AdminOffersManagerState extends State<AdminOffersManager> {
  final _titleCtrl = TextEditingController();
  final _subTitleCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("تحديث بنر العروض", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("هذا النص سيظهر لجميع المرضى في الشاشة الرئيسية", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          SmartTextField(controller: _titleCtrl, label: "عنوان العرض (مثال: خصم 20%)", icon: Icons.title),
          SmartTextField(controller: _subTitleCtrl, label: "الوصف (مثال: على الحقن المنزلية)", icon: Icons.description),
          
          const SizedBox(height: 20),
          ProButton(
            text: "نشر العرض للجميع",
            icon: Icons.campaign,
            color: Colors.orange,
            isLoading: _loading,
            onPressed: () async {
              setState(() => _loading = true);
              // حفظ في قاعدة البيانات (config collection)
              await FirebaseFirestore.instance.collection('config').doc('banner').set({
                'title': _titleCtrl.text,
                'subtitle': _subTitleCtrl.text,
                'updated_at': FieldValue.serverTimestamp()
              });
              setState(() => _loading = false);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث العرض بنجاح!")));
            },
          )
        ],
      ),
    );
  }
}

// 4. شاشة تفاصيل الممرض الكاملة (The Super Admin View)
class NurseDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const NurseDetailScreen({super.key, required this.docId, required this.data});

  @override
  State<NurseDetailScreen> createState() => _NurseDetailScreenState();
}

class _NurseDetailScreenState extends State<NurseDetailScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data['name']);
    _phoneCtrl = TextEditingController(text: widget.data['phone']);
  }

  // حساب الأيام المتبقية
  Map<String, dynamic> _calcSubscription() {
    if (widget.data['activated_at'] == null) return {'days': 0, 'status': 'غير مفعل', 'color': Colors.grey};
    
    Timestamp act = widget.data['activated_at'];
    int daysPassed = DateTime.now().difference(act.toDate()).inDays;
    int daysLeft = 30 - daysPassed;
    
    if (daysLeft < 0) return {'days': 0, 'status': 'منتهي ($daysLeft يوم)', 'color': AppColors.error};
    return {'days': daysLeft, 'status': 'نشط ($daysLeft يوم متبقي)', 'color': AppColors.success};
  }

  @override
  Widget build(BuildContext context) {
    var subInfo = _calcSubscription();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "تعديل البيانات" : widget.data['name'] ?? "التفاصيل"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () async {
              if (_isEditing) {
                // حفظ التعديلات
                await FirebaseFirestore.instance.collection('users').doc(widget.docId).update({
                  'name': _nameCtrl.text,
                  'phone': _phoneCtrl.text,
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث البيانات")));
              }
              setState(() => _isEditing = !_isEditing);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // صورة البروفايل الكبيرة
            Hero(
              tag: widget.docId,
              child: GestureDetector(
                onTap: () => _openImage(widget.data['pic_data']),
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                    image: widget.data['pic_data'] != null 
                        ? DecorationImage(image: MemoryImage(base64Decode(widget.data['pic_data'])), fit: BoxFit.cover)
                        : null
                  ),
                  child: widget.data['pic_data'] == null ? const Icon(Icons.person, size: 50) : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // حالة الاشتراك
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: (subInfo['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(subInfo['status'], style: TextStyle(color: subInfo['color'], fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 30),

            // الحقول القابلة للتعديل
            SmartTextField(controller: _nameCtrl, label: "الاسم الكامل", icon: Icons.person, readOnly: !_isEditing),
            SmartTextField(controller: _phoneCtrl, label: "رقم الهاتف", icon: Icons.phone, readOnly: !_isEditing),
            
            // عرض المعلومات الثابتة
            if (widget.data['email'] != null)
              ListTile(leading: const Icon(Icons.email), title: const Text("البريد الإلكتروني"), subtitle: Text(widget.data['email'])),
            ListTile(leading: const Icon(Icons.map), title: const Text("الولاية"), subtitle: Text(widget.data['address'] ?? "غير محدد")),

            const Divider(height: 40),
            const Text("المستندات المرفقة (اضغط للتكبير)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _docThumbnail("الهوية", widget.data['id_data']),
                _docThumbnail("الشهادة", widget.data['diploma_data']),
                _docThumbnail("الوصل", widget.data['receipt_data']),
              ],
            ),

            const SizedBox(height: 40),

            // أزرار التحكم الخطيرة
            if (widget.data['status'] == 'pending_docs')
              ProButton(
                text: "قبول الوثائق (طلب الدفع)",
                color: Colors.orange,
                onPressed: () => _updateStatus('pending_payment'),
              ),

            if (widget.data['status'] == 'payment_review')
              ProButton(
                text: "تفعيل الاشتراك (30 يوم)",
                color: AppColors.success,
                icon: Icons.check_circle,
                onPressed: () {
                   FirebaseFirestore.instance.collection('users').doc(widget.docId).update({
                    'status': 'approved',
                    'activated_at': FieldValue.serverTimestamp() // بدء العداد
                  });
                  Navigator.pop(context);
                },
              ),

            const SizedBox(height: 10),
            if (widget.data['status'] != 'pending_docs' && widget.data['status'] != 'payment_review')
              Row(
                children: [
                  Expanded(
                    child: ProButton(
                      text: widget.data['status'] == 'banned' ? "فك الحظر" : "حظر",
                      color: widget.data['status'] == 'banned' ? Colors.grey : AppColors.error,
                      onPressed: () => _updateStatus(widget.data['status'] == 'banned' ? 'approved' : 'banned'),
                    ),
                  ),
                  if (widget.data['status'] == 'expired') ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ProButton(
                        text: "تجديد مجاني",
                        color: Colors.blue,
                        onPressed: () => FirebaseFirestore.instance.collection('users').doc(widget.docId).update({
                          'status': 'approved',
                          'activated_at': FieldValue.serverTimestamp()
                        }),
                      ),
                    ),
                  ]
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _docThumbnail(String label, String? b64) {
    if (b64 == null) return Column(children: [const Icon(Icons.broken_image, color: Colors.grey), Text(label)]);
    return GestureDetector(
      onTap: () => _openImage(b64),
      child: Column(
        children: [
          Container(
            height: 70, width: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(image: MemoryImage(base64Decode(b64)), fit: BoxFit.cover)
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12))
        ],
      ),
    );
  }

  void _openImage(String? b64) {
    if (b64 == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: InteractiveViewer(child: Center(child: Image.memory(base64Decode(b64)))),
    )));
  }

  void _updateStatus(String newStatus) {
    FirebaseFirestore.instance.collection('users').doc(widget.docId).update({'status': newStatus});
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم تغيير الحالة إلى $newStatus")));
  }
}
// ============================================================================
// 🏁 PART 8: UTILITIES & FINAL TOUCHES (الأدوات واللمسات الأخيرة)
// ============================================================================

// 1. بنر العروض الديناميكي (يربط بين الأدمن والمريض)
// هذا الويدجت يقرأ البيانات الحية من Firebase Config
class DynamicPromoBanner extends StatelessWidget {
  const DynamicPromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('config').doc('banner').snapshots(),
      builder: (context, snapshot) {
        // بيانات افتراضية في حال عدم وجود انترنت
        String title = "خصم 20% هذا الأسبوع";
        String subtitle = "على جميع الخدمات المنزلية";
        
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          title = data['title'] ?? title;
          subtitle = data['subtitle'] ?? subtitle;
        }

        return FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: Container(
            height: 160,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8F00), Color(0xFFFF6F00)], // لون برتقالي جذاب
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6F00).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Stack(
              children: [
                // خلفية زخرفية
                Positioned(
                  right: -30, bottom: -30,
                  child: Icon(Icons.local_offer_outlined, size: 180, color: Colors.white.withOpacity(0.15)),
                ),
                Positioned(
                  left: 20, top: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    radius: 20,
                    child: const Icon(Icons.star, color: Colors.white),
                  ),
                ),
                
                // النصوص
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: const Text(
                          "عرض خاص 🔥", 
                          style: TextStyle(color: Color(0xFFFF6F00), fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// 2. شاشة سياسة الخصوصية (Privacy Policy)
// مطلوبة قانونياً في متاجر التطبيقات
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("سياسة الخصوصية")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.security, size: 60, color: AppColors.primary),
            const SizedBox(height: 20),
            const Text(
              "خصوصيتك أولوية قصوى",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "نحن في تطبيق عافية (Afya DZ) نلتزم بحماية بياناتك الطبية والشخصية وفقاً للمعايير العالمية.",
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
            const Divider(height: 40),
            _policyItem("1. جمع البيانات", "نجمع فقط البيانات الضرورية لتقديم الخدمة (الاسم، الهاتف، الموقع الجغرافي)."),
            _policyItem("2. استخدام الموقع", "نستخدم موقعك الجغرافي فقط لربطك بأقرب ممرض متاح ولتوجيه الممرض إليك."),
            _policyItem("3. مشاركة البيانات", "لا نشارك بياناتك مع أي طرف ثالث لأغراض تسويقية. تشارك فقط مع الممرض المعالج."),
            _policyItem("4. الأمان", "جميع البيانات مشفرة ومحفوظة في خوادم آمنة."),
            const SizedBox(height: 30),
            const Center(child: Text("Version 10.0.0 (Titanium)", style: TextStyle(color: Colors.grey))),
            const Center(child: Text("© 2026 Branis Yacine", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _policyItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
          const SizedBox(height: 5),
          Text(content, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ============================================================================
// 🎉 END OF CODE - AFYA DZ TITANIUM EDITION (V10)
// ============================================================================
