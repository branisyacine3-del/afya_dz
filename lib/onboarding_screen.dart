import 'package:flutter/material.dart';
import 'package:afya_dz/screens/login_screen.dart'; // سننشئها لاحقاً

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
      "body": "أول منصة جزائرية تربطك بأفضل الممرضين والأطباء وأنت في منزلك.",
      "icon": "assets/welcome.png" // سنستبدلها لاحقاً
    },
    {
      "title": "خدمات طبية متكاملة",
      "body": "حقن، تغيير ضمادات، فحص طبي، وحتى سيارة إسعاف.. بضغطة زر.",
      "icon": "assets/services.png"
    },
    {
      "title": "أمان وسرعة",
      "body": "فريقنا الطبي معتمد، وخدمتنا سريعة وتغطي 58 ولاية.",
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
            // زر التخطي
            Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                onPressed: () {
                   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreenPlaceholder()));
                },
                child: const Text("تخطي", style: TextStyle(color: Colors.teal)),
              ),
            ),
            
            // المحتوى المتغير
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(
                  title: _pages[index]['title']!,
                  body: _pages[index]['body']!,
                  iconData: index == 0 ? Icons.waving_hand : (index == 1 ? Icons.medical_services : Icons.verified_user),
                ),
              ),
            ),

            // المؤشر والنقاط
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.teal : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // زر المتابعة
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    } else {
                      // الانتقال لصفحة التسجيل
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreenPlaceholder()));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? "ابدأ الآن" : "التالي",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({required String title, required String body, required IconData iconData}) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 150, color: Colors.teal.shade300), // مؤقتاً أيقونات
          const SizedBox(height: 40),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Text(body, style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// 🚧 صفحة مؤقتة لكي لا يحدث خطأ عند الضغط
class LoginScreenPlaceholder extends StatelessWidget {
  const LoginScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل الدخول")),
      body: const Center(child: Text("هنا ستكون صفحة التسجيل والولايات")),
    );
  }
}
