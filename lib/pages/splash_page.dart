import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();

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

  void _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Versi ${info.version}';
    });
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
    ]);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(_createRouteToLogin());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? CupertinoColors.black.withOpacity(0.5)
          : CupertinoColors.white,
      body: Stack(
        children: [
          // Teks atas tengah dengan fade in
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 800),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'E-',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color:
                              CupertinoTheme.brightnessOf(context) ==
                                  Brightness.dark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            CupertinoColors.activeBlue,
                            CupertinoColors.systemTeal,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'Absensi',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors
                                .white, // HARUS white agar gradient terlihat
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RS PKU Muhammadiyah Sukoharjo',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

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
                  width: 300,
                  repeat: true,
                ),
              ),
            ),
          ),

          // Teks bawah tengah dengan fade in
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 800),
              child: Column(
                children: [
                  Text(
                    '@ 2025 . Sakudewa Tech',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _appVersion,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
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
}
