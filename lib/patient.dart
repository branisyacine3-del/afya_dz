import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'login_screen.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // خلفية نظيفة
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("خدمات عافية", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red, size: 20),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('user_id', isEqualTo: user!.uid)
            .where('status', whereIn: ['pending', 'accepted', 'on_way'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (snapshot.data!.docs.isNotEmpty) {
            return _buildTrackingScreen(request: snapshot.data!.docs.first);
          }

          return _buildServicesList(context, user);
        },
      ),
    );
  }

  // 1. شاشة الخدمات بتصميم احترافي
  Widget _buildServicesList(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("مرحباً، ${user.email!.split('@')[0]} 👋", style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 5),
              const Text("بماذا تشعر اليوم؟", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text("الخدمات المتاحة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 15),

        // Grid
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('services').where('active', isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var services = snapshot.data!.docs;

              if (services.isEmpty) return const Center(child: Text("لا توجد خدمات متاحة"));

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.9, // جعل البطاقة أطول قليلاً
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  var service = services[index].data() as Map<String, dynamic>;
                  // ألوان متغيرة لكل بطاقة لكسر الجمود
                  List<Color> colors = [Colors.teal.shade50, Colors.blue.shade50, Colors.orange.shade50, Colors.purple.shade50];
                  List<Color> iconColors = [Colors.teal, Colors.blue, Colors.orange, Colors.purple];
                  
                  return _ServiceCard(
                    title: service['name'],
                    price: service['price'],
                    bgColor: colors[index % colors.length],
                    iconColor: iconColors[index % iconColors.length],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen(serviceName: service['name'], price: service['price']))),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  // شاشة التتبع (تحسين التصميم)
  Widget _buildTrackingScreen({required DocumentSnapshot request}) {
    var data = request.data() as Map<String, dynamic>;
    String status = data['status'];
    
    // تصميم الحالة
    IconData icon = Icons.radar;
    Color color = Colors.orange;
    String msg = "جاري البحث...";
    
    if (status == 'accepted') { icon = Icons.check_circle; color = Colors.blue; msg = "تم القبول!"; }
    if (status == 'on_way') { icon = Icons.directions_car; color = Colors.green; msg = "في الطريق إليك"; }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(30),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 60, color: color),
            ),
            const SizedBox(height: 25),
            Text(msg, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("الخدمة: ${data['service']}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),
            if (status == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => request.reference.delete(),
                  icon: const Icon(Icons.close),
                  label: const Text("إلغاء الطلب"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, elevation: 0),
                ),
              ),
            if (status != 'pending')
              const LinearProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final int price;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ServiceCard({required this.title, required this.price, required this.bgColor, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(Icons.medical_services_outlined, color: iconColor, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text("$price دج", style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// BookingScreen (تحديث بسيط ليتماشى مع الثيم)
class BookingScreen extends StatefulWidget { final String serviceName; final int price; const BookingScreen({super.key, required this.serviceName, required this.price}); @override State<BookingScreen> createState() => _BS(); }
class _BS extends State<BookingScreen> {
  final _k = GlobalKey<FormState>(); final _n = TextEditingController(); final _p = TextEditingController(); final _d = TextEditingController(); String? _l; String? _img; bool _load=false;
  @override void initState() { super.initState(); _f(); }
  Future<void> _f() async { final u=FirebaseAuth.instance.currentUser; if(u!=null){ var d=await FirebaseFirestore.instance.collection('users').doc(u.uid).get(); if(d.exists&&mounted)setState((){_n.text=d['full_name']??"";_p.text=d['phone']??"";});}}
  Future<void> _geo() async { setState(()=>_load=true); try{ LocationPermission p=await Geolocator.checkPermission(); if(p==LocationPermission.denied)p=await Geolocator.requestPermission(); Position pos=await Geolocator.getCurrentPosition(); setState(()=>_l="${pos.latitude},${pos.longitude}"); }catch(_){} setState(()=>_load=false); }
  Future<void> _cam() async { final i=await ImagePicker().pickImage(source:ImageSource.camera,imageQuality:40); if(i!=null)setState(() async =>_img=base64Encode(await File(i.path).readAsBytes())); }
  Future<void> _sub() async { if(!_k.currentState!.validate()||_l==null){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text("الموقع مطلوب!"),backgroundColor:Colors.red));return;} setState(()=>_load=true); final u=FirebaseAuth.instance.currentUser!; var d=await FirebaseFirestore.instance.collection('users').doc(u.uid).get(); await FirebaseFirestore.instance.collection('requests').add({'user_id':u.uid,'patient_name':_n.text,'phone':_p.text,'details':_d.text,'service':widget.serviceName,'price':widget.price,'location':_l,'wilaya':d['wilaya']??'','status':'pending','image_data':_img,'created_at':FieldValue.serverTimestamp()}); if(mounted){Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text("تم الإرسال")));} setState(()=>_load=false); }
  
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceName), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _k, child: Column(children: [
        Container(padding:const EdgeInsets.all(15), decoration:BoxDecoration(color:Colors.teal.shade50, borderRadius:BorderRadius.circular(10)), child:Row(children:[const Icon(Icons.info,color:Colors.teal),const SizedBox(width:10),Text("السعر: ${widget.price} دج",style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:Colors.teal))])),
        const SizedBox(height:20),
        TextFormField(controller:_n, decoration:const InputDecoration(labelText:"الاسم", prefixIcon:Icon(Icons.person))), const SizedBox(height:15),
        TextFormField(controller:_p, decoration:const InputDecoration(labelText:"الهاتف", prefixIcon:Icon(Icons.phone))), const SizedBox(height:15),
        TextFormField(controller:_d, maxLines:3, decoration:const InputDecoration(labelText:"تفاصيل", prefixIcon:Icon(Icons.description))), const SizedBox(height:20),
        Row(children:[Expanded(child:OutlinedButton.icon(onPressed:_cam, icon:Icon(_img!=null?Icons.check:Icons.camera_alt), label:const Text("صورة"))), const SizedBox(width:10), Expanded(child:OutlinedButton.icon(onPressed:_geo, icon:const Icon(Icons.location_on), label:Text(_l==null?"موقعي":"تم"), style:OutlinedButton.styleFrom(foregroundColor: _l==null?Colors.red:Colors.green)))]),
        const SizedBox(height:30),
        SizedBox(width:double.infinity, height:55, child:ElevatedButton(onPressed:_load?null:_sub, child:_load?const CircularProgressIndicator(color:Colors.white):const Text("تأكيد الحجز")))
      ]))),
    );
  }
}
