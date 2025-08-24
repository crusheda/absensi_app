import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import '../services/api_service.dart';

const platform = MethodChannel('com.sakudewa.absensi/integrity');

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

    // Animasi masuk
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          opacity = 1.0;
          scale = 1.0;
        });
      }
    });

    // Jalankan splash
    startSplash();
  }

  /// Cek apakah ada update aplikasi
  Future<bool> checkForUpdate() async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate().catchError((e) {
          debugPrint("Update gagal: $e");
        });
        return true;
      }
    } catch (e) {
      debugPrint("Error cek update: $e");
    }
    return false;
  }

  /// Load versi aplikasi
  void _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'Versi ${info.version}';
      });
    }
  }

  /// Transisi animasi ke LoginPage
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

  /// Ambil token dari native Kotlin
  Future<String?> _getIntegrityToken() async {
    try {
      final String token = await platform.invokeMethod('checkIntegrity');
      debugPrint("Integrity Token: $token");
      return token;
    } on PlatformException catch (e) {
      debugPrint("Play Integrity gagal: ${e.message}");
      return null;
    }
  }

  /// Kirim token ke server Laravel untuk verifikasi
  Future<bool> _verifyWithServer(String token) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiService.baseUrl}/verify_integrity',
        ), // pakai baseUrl dari ApiService
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'integrity_token': token}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] == true;
      } else {
        debugPrint("Verifikasi server gagal: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Error verifikasi server: $e");
      return false;
    }
  }

  /// Jalankan splash dan cek semua validasi
  Future<void> startSplash() async {
    await Future.delayed(const Duration(seconds: 3)); // delay minimal splash

    // cek update
    bool isUpdating = await checkForUpdate();
    if (!mounted || isUpdating) return;

    // ambil token integrity
    final token = await _getIntegrityToken();
    bool isValid = false;
    if (token != null) {
      // verifikasi token ke Laravel
      isValid = await _verifyWithServer(token);
    }
    debugPrint("Token Play Integrity anda sudah True / False : $isValid");

    if (!mounted) return;

    if (!isValid) {
      // Kalau gagal validasi → aplikasi tidak resmi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Aplikasi Tidak Resmi"),
          content: const Text(
            "Harap install aplikasi resmi dari Google Play Store.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: const Text("Tutup"),
            ),
          ],
        ),
      );
      return;
    }

    // lanjut ke LoginPage
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
          // Teks atas tengah
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
                          color: isDark
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
                        child: const Text(
                          'Absensi',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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

          // Animasi loading tengah
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

          // Teks bawah
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
