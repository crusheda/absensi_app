import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  double opacity = 0.0;
  double scale = 0.8;

  @override
  void initState() {
    super.initState();

    // Mulai animasi masuk
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        opacity = 1.0;
        scale = 1.0;
      });
    });

    // Jalankan semua future yang dibutuhkan saat splash
    startSplash();
  }

  /// Fungsi transisi animasi ke LoginPage
  Route _createRouteToLogin() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const LoginPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.2);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var fadeAnimation = CurvedAnimation(parent: animation, curve: curve);

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  /// Fungsi menjalankan splash + menunggu semua future
  Future<void> startSplash() async {
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)), // delay minimal splash
      // Bisa tambahkan future lain misal preload data / check token
    ]);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(_createRouteToLogin());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animasi tengah
          Center(
            child: AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 800),
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                child: Lottie.asset(
                  'assets/lottie/loading.json',
                  width: 200,
                  repeat: true,
                ),
              ),
            ),
          ),

          // Teks bawah tengah
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Text(
                  'E-Absensi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Version 3.1',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
