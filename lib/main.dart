import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
    print("Firebase Error: $e");
  }
  runApp(const AfyaApp());
}

class AfyaApp extends StatelessWidget {
  const AfyaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afya DZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())));
  }
  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: Colors.blue, body: Center(child: Icon(Icons.health_and_safety, size: 80, color: Colors.white)));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  Future<void> _auth() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
    } catch (e) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _loading = false); return;
      }
    }
    if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
      TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
      const SizedBox(height: 20),
      _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _auth, child: const Text("Login"))
    ])),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Welcome")),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientScreen())), child: const Text("I am Patient")),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseScreen())), child: const Text("I am Nurse")),
    ])),
  );
}

class PatientScreen extends StatelessWidget {
  const PatientScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Services")),
    body: ListView(children: [
      ListTile(title: const Text("Injection (800 DA)"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderScreen(title: "Injection", price: 800)))),
      ListTile(title: const Text("Serum (2500 DA)"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderScreen(title: "Serum", price: 2500)))),
    ]),
  );
}

class OrderScreen extends StatefulWidget {
  final String title; final int price;
  const OrderScreen({super.key, required this.title, required this.price});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  final _phone = TextEditingController();
  double? _lat, _lng;
  String _status = "Locating...";
  
  @override
  void initState() {
    super.initState();
    _getLocation();
  }
  
  Future<void> _getLocation() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      Position pos = await Geolocator.getCurrentPosition();
      setState(() { _lat = pos.latitude; _lng = pos.longitude; _status = "Locating Done ✅"; });
    } catch (e) { setState(() => _status = "GPS Error"); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone Number")),
      const SizedBox(height: 20),
      Text(_status),
      const Spacer(),
      ElevatedButton(
        onPressed: () {
          if (_lat == null) return;
          FirebaseFirestore.instance.collection('requests').add({
            'service': widget.title, 'price': widget.price, 'phone': _phone.text,
            'lat': _lat, 'lng': _lng, 'status': 'pending'
          });
          Navigator.pop(context);
        }, 
        child: const Text("Send Request")
      )
    ])),
  );
}

class NurseScreen extends StatelessWidget {
  const NurseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nurse Dashboard")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(children: snap.data!.docs.map((d) {
            var data = d.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['service'] ?? ""),
              subtitle: Text(data['phone'] ?? ""),
              trailing: IconButton(
                icon: const Icon(Icons.map, color: Colors.blue),
                // تم تصحيح الرابط هنا
                onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${data['lat']},${data['lng']}")),
              ),
            );
          }).toList());
        },
      ),
    );
  }
}
