import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    print("Error: $e");
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
        fontFamily: 'Roboto', // خط نظيف
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688), // لون أساسي طبي
          primary: const Color(0xFF009688),
          secondary: const Color(0xFFFF9800),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF009688), width: 2)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// 1. شاشة البداية (لوجو متحرك بسيط)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (FirebaseAuth.instance.currentUser != null) {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      } else {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF009688), Color(0xFF4DB6AC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.local_hospital_rounded, size: 100, color: Colors.white),
          SizedBox(height: 20),
          Text("Afya DZ", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          Text("رعايتك الصحية.. في منزلك", style: TextStyle(color: Colors.white70, fontSize: 16)),
        ])),
      ),
    );
  }
}

// 2. شاشة الدخول والتسجيل (تصميم كارت)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating));

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') _showError("حساب غير موجود، يمكنك إنشاء حساب جديد");
      else if (e.code == 'wrong-password') _showError("كلمة المرور غير صحيحة ❌");
      else _showError("خطأ: ${e.message}");
    }
    setState(() => _loading = false);
  }

  Future<void> _doRegister() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameInputScreen()));
    } catch (e) {
      _showError("حدث خطأ أثناء التسجيل: $e");
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text("مرحباً بك 👋", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
              const Text("سجل الدخول للمتابعة", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),
              TextField(controller: _email, decoration: const InputDecoration(labelText: "البريد الإلكتروني", prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 20),
              TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "كلمة المرور", prefixIcon: Icon(Icons.lock_outlined))),
              const SizedBox(height: 30),
              _loading ? const Center(child: CircularProgressIndicator()) : Column(
                children: [
                  ElevatedButton(
                    onPressed: _doLogin,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: const Color(0xFF009688), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text("تسجيل الدخول", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton(
                    onPressed: _doRegister,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), side: const BorderSide(color: Color(0xFF009688))),
                    child: const Text("إنشاء حساب جديد", style: TextStyle(fontSize: 16, color: Color(0xFF009688))),
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

// 3. شاشة إدخال الاسم
class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});
  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}
class _NameInputScreenState extends State<NameInputScreen> {
  final _nameController = TextEditingController();
  Future<void> _saveName() async {
    if (_nameController.text.isEmpty) return;
    await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text);
    if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بياناتك الشخصية"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("تم إنشاء الحساب بنجاح!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "الاسم الكامل", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _saveName, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: const Color(0xFF009688)), child: const Text("ابدأ الاستخدام", style: TextStyle(color: Colors.white, fontSize: 18))),
          ],
        ),
      ),
    );
  }
}

// 4. الشاشة الرئيسية (أزرار كبيرة وفخمة)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("أهلاً، ${user?.displayName ?? 'يا بطل'}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBigButton(context, "أنا مريض", "أبحث عن ممرض في الحال", Icons.person_search, const Color(0xFF2196F3), const PatientScreen()),
            const SizedBox(height: 20),
            _buildBigButton(context, "أنا ممرض", "الدخول للوحة التحكم", Icons.medical_services, const Color(0xFF009688), const NurseScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildBigButton(BuildContext context, String title, String sub, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(width: 10, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)))),
            const SizedBox(width: 20),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 35)),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ]),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[300]),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}

// 5. شاشة الخدمات (مع خيار "أخرى")
class PatientScreen extends StatelessWidget {
  const PatientScreen({super.key});

  // نافذة الطلب الخاص
  void _showCustomOrderDialog(BuildContext context) {
    final customController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("خدمة أخرى / خاصة", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("صف لنا ماذا تحتاج بالضبط:"),
            const SizedBox(height: 15),
            TextField(controller: customController, decoration: const InputDecoration(hintText: "مثال: جلسة علاج طبيعي، غيار جرح..")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (customController.text.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: customController.text, price: "حسب الاتفاق")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
            child: const Text("متابعة", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("اختر الخدمة المطلوبة"), centerTitle: true),
      body: GridView.count(
        crossAxisCount: 2, padding: const EdgeInsets.all(16), crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
        children: [
          _srvCard(context, "حقن", "800 دج", Icons.vaccines, Colors.orange),
          _srvCard(context, "سيروم", "2500 دج", Icons.water_drop, Colors.blue),
          _srvCard(context, "تغيير ضماد", "1200 دج", Icons.healing, Colors.purple),
          _srvCard(context, "قياس ضغط", "500 دج", Icons.monitor_heart, Colors.red),
          // الزر الجديد للخدمة الخاصة
          InkWell(
            onTap: () => _showCustomOrderDialog(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, size: 45, color: Colors.grey[600]),
                  const SizedBox(height: 10),
                  Text("خدمة أخرى", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey[700])),
                  const Text("اكتب طلبك الخاص", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _srvCard(BuildContext context, String title, String price, IconData icon, Color color) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(title: title, price: price))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 35, color: color)),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 5),
            Text(price, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// 6. شاشة تأكيد الطلب (مع تحسين الـ GPS)
class OrderScreen extends StatefulWidget {
  final String title; final String price;
  const OrderScreen({super.key, required this.title, required this.price});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  final _phone = TextEditingController();
  String _status = "اضغط هنا لتحديد موقعك للممرض";
  double? _lat, _lng;
  bool _loading = false;
  bool _locationFound = false;

  Future<void> _getLocation() async {
    setState(() { _loading = true; _status = "جاري تحديد الموقع..."; });
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.deniedForever) {
        setState(() { _status = "⚠️ يجب تفعيل الموقع من إعدادات الهاتف"; _loading = false; });
        return;
      }
      Position pos = await Geolocator.getCurrentPosition();
      setState(() { _lat = pos.latitude; _lng = pos.longitude; _status = "تم تحديد موقع المنزل بنجاح ✅"; _loading = false; _locationFound = true; });
    } catch (e) {
      setState(() { _status = "❌ فشل. تأكد أن GPS يعمل وحاول مجدداً"; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("تأكيد طلب: ${widget.title}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
            const SizedBox(height: 5),
            Text("السعر المتوقع: ${widget.price}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "رقم هاتفك للتواصل", prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 20),
            InkWell(
              onTap: _getLocation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _locationFound ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _locationFound ? Colors.green : Colors.blue.withOpacity(0.3)),
                ),
                child: Row(children: [
                  _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_locationFound ? Icons.check_circle : Icons.location_on, color: _locationFound ? Colors.green : Colors.blue),
                  const SizedBox(width: 15),
                  Expanded(child: Text(_status, style: TextStyle(color: _locationFound ? Colors.green[800] : Colors.blue[800], fontWeight: FontWeight.bold))),
                ]),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if(_lat != null && _phone.text.isNotEmpty) {
                   FirebaseFirestore.instance.collection('requests').add({
                     'service': widget.title, 
                     'price': widget.price, 
                     'phone': _phone.text, 
                     'lat': _lat, 
                     'lng': _lng, 
                     'timestamp': FieldValue.serverTimestamp()
                   });
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم إرسال طلبك للممرضين بنجاح!"), backgroundColor: Colors.green));
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى كتابة الرقم وتحديد الموقع"), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: const Color(0xFF009688), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text("تأكيد الطلب الآن", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// 7. لوحة الممرض (المتطورة)
class NurseScreen extends StatelessWidget {
  const NurseScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
       throw Exception('Could not launch map');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("طلبات المرضى القريبة"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment_turned_in, size: 60, color: Colors.grey), SizedBox(height: 10), Text("لا توجد طلبات جديدة")]));
          
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snap.data!.docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.person, color: Color(0xFF009688))),
                            const SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(data['service'] ?? "خدمة", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text("السعر: ${data['price']}", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                            ]),
                          ]),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)), child: const Text("جديد", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      const Divider(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _makePhoneCall(data['phone']),
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text("اتصال"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openMap(data['lat'], data['lng']),
                              icon: const Icon(Icons.location_on, size: 18),
                              label: const Text("الخريطة"),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            ),
                          ),
                        ],
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
