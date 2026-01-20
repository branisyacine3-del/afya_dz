import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة الإدارة"),
        backgroundColor: Colors.red.shade900, // لون مميز للمدير (أحمر غامق)
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 100, color: Colors.red),
            SizedBox(height: 20),
            Text(
              "أهلاً بك يا مدير النظام 👮‍♂️", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            SizedBox(height: 10),
            Text(
              "هنا ستتمكن من مراقبة الطلبات والأرباح قريباً.", 
              style: TextStyle(color: Colors.grey, fontSize: 16)
            ),
          ],
        ),
      ),
    );
  }
}
