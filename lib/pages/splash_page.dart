import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'login_page.dart';
import '../services/api_service.dart';

const platform = MethodChannel('com.sakudewa.absensi/integrity');

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _backgroundController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _loadingScaleAnimation;
  late Animation<double> _loadingFadeAnimation;
  late Animation<Offset> _footerSlideAnimation;

  String _appVersion = '';

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _setupAnimations();
    _loadAppVersion();

    _animationController.forward();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    startSplash();
  }

  // ===========================================================================
  // ANIMATIONS
  // ===========================================================================

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    _loadingScaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.18, 0.72, curve: Curves.easeOutBack),
      ),
    );

    _loadingFadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.18, 0.65, curve: Curves.easeOut),
    );

    _footerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
          ),
        );
  }

  // ===========================================================================
  // LOAD VERSION
  // ===========================================================================

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        _appVersion = 'Versi ${info.version}';
      });
    } catch (e) {
      debugPrint('Gagal mengambil versi aplikasi: $e');
    }
  }

  // ===========================================================================
  // CHECK UPDATE
  // ===========================================================================

  Future<bool> checkForUpdate() async {
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate().catchError((e) {
          debugPrint('Update gagal: $e');
        });

        return true;
      }
    } catch (e) {
      debugPrint('Error cek update: $e');
    }

    return false;
  }

  // ===========================================================================
  // PLAY INTEGRITY
  // ===========================================================================

  Future<String?> _getIntegrityToken() async {
    try {
      final String token = await platform.invokeMethod('checkIntegrity');

      debugPrint('Integrity Token: $token');

      return token;
    } on PlatformException catch (e) {
      debugPrint('Play Integrity gagal: ${e.message}');

      return null;
    } catch (e) {
      debugPrint('Play Integrity error: $e');

      return null;
    }
  }

  // ===========================================================================
  // VERIFY INTEGRITY TO SERVER
  // ===========================================================================

  Future<bool> _verifyWithServer(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/verify_integrity'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'integrity_token': token}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['valid'] == true;
      }

      debugPrint('Verifikasi server gagal: ${response.statusCode}');

      return false;
    } catch (e) {
      debugPrint('Error verifikasi server: $e');

      return false;
    }
  }

  // ===========================================================================
  // START SPLASH
  // ===========================================================================

  Future<void> startSplash() async {
    // Memberikan waktu minimal untuk menampilkan splash.
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // -------------------------------------------------------------------------
    // CEK UPDATE
    // -------------------------------------------------------------------------

    final bool isUpdating = await checkForUpdate();

    if (!mounted || isUpdating) {
      return;
    }

    // -------------------------------------------------------------------------
    // PLAY INTEGRITY
    // -------------------------------------------------------------------------

    final String? token = await _getIntegrityToken();

    bool isValid = false;

    if (token != null && token.isNotEmpty) {
      isValid = await _verifyWithServer(token);
    }

    debugPrint('Token Play Integrity anda sudah True / False : $isValid');

    if (!mounted) return;

    // -------------------------------------------------------------------------
    // INVALID APPLICATION
    // -------------------------------------------------------------------------

    if (!isValid) {
      _showUnauthorizedDialog();
      return;
    }

    // -------------------------------------------------------------------------
    // LOGIN
    // -------------------------------------------------------------------------

    _navigateToLogin();
  }

  // ===========================================================================
  // UNAUTHORIZED DIALOG
  // ===========================================================================

  void _showUnauthorizedDialog() {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

        return CupertinoAlertDialog(
          title: const Text(
            'Aplikasi Tidak Resmi',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Harap install aplikasi resmi dari Google Play Store.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: false,
              onPressed: () {
                SystemNavigator.pop();
              },
              child: Text(
                'Tutup',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: isDark
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.activeBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // NAVIGATE LOGIN
  // ===========================================================================

  void _navigateToLogin() {
    if (!mounted || _isNavigating) {
      return;
    }

    _isNavigating = true;

    Navigator.of(context).pushReplacement(_createRouteToLogin());
  }

  // ===========================================================================
  // LOGIN ROUTE
  // ===========================================================================

  Route _createRouteToLogin() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const LoginPage();
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        final scaleAnimation = Tween<double>(begin: 0.985, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);

    final bool isDark = brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF080A0F)
        : const Color(0xFFF5F7FA);

    final primaryTextColor = isDark
        ? CupertinoColors.white
        : const Color(0xFF111827);

    final secondaryTextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final bool isSmallHeight = height < 680;

          final bool isVerySmallHeight = height < 600;

          final double horizontalPadding = width < 360 ? 18 : 24;

          return Stack(
            children: [
              // ==============================================================
              // ANIMATED BACKGROUND
              // ==============================================================
              Positioned.fill(
                child: IgnorePointer(
                  child: _SplashBackground(
                    controller: _backgroundController,
                    isDark: isDark,
                  ),
                ),
              ),

              // ==============================================================
              // MAIN CONTENT
              // ==============================================================
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      // ========================================================
                      // TOP BRAND
                      // ========================================================
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildBrand(
                            isDark: isDark,
                            textColor: primaryTextColor,
                            secondaryColor: secondaryTextColor,
                            compact: isVerySmallHeight || isSmallHeight,
                          ),
                        ),
                      ),

                      // ========================================================
                      // CENTER LOADING
                      // ========================================================
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: _buildLoadingAnimation(
                            width: width,
                            compact: isVerySmallHeight || isSmallHeight,
                            isDark: isDark,
                          ),
                        ),
                      ),

                      // ========================================================
                      // FOOTER
                      // ========================================================
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: isVerySmallHeight ? 12 : 22,
                            ),
                            child: _buildFooter(
                              isDark: isDark,
                              secondaryColor: secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // BRAND
  // ===========================================================================

  Widget _buildBrand({
    required bool isDark,
    required Color textColor,
    required Color secondaryColor,
    required bool compact,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _logoSlideAnimation,
        child: ScaleTransition(
          scale: _logoScaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---------------------------------------------------------------
              // LOGO ICON
              // ---------------------------------------------------------------
              Container(
                width: compact ? 72 : 82,
                height: compact ? 72 : 82,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF11151C)
                      : CupertinoColors.white,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF293140)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF2563EB,
                      ).withOpacity(isDark ? 0.22 : 0.14),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo/logo_clear_100kb.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(height: compact ? 13 : 16),

              // ---------------------------------------------------------------
              // E-ABSENSI
              // ---------------------------------------------------------------
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'E-',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: compact ? 27 : 31,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: textColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFF2563EB),
                          Color(0xFF0EA5E9),
                          Color(0xFF14B8A6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Text(
                      'Absensi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: compact ? 27 : 31,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: compact ? 2 : 4),

              Text(
                'RS PKU Muhammadiyah Sukoharjo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: compact ? 9.5 : 11,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                  decoration: TextDecoration.none,
                ),
              ),

              SizedBox(height: compact ? 7 : 10),

              // ---------------------------------------------------------------
              // STATUS BADGE
              // ---------------------------------------------------------------
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 11,
                  vertical: compact ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withOpacity(
                    isDark ? 0.10 : 0.07,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: CupertinoColors.activeBlue.withOpacity(
                      isDark ? 0.12 : 0.08,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sistem Absensi Karyawan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: compact ? 7.5 : 8.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFF2563EB),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LOADING ANIMATION
  // ===========================================================================

  Widget _buildLoadingAnimation({
    required double width,
    required bool compact,
    required bool isDark,
  }) {
    final double animationSize = compact
        ? width < 380
              ? 190
              : 210
        : width < 380
        ? 220
        : 260;

    return FadeTransition(
      opacity: _loadingFadeAnimation,
      child: ScaleTransition(
        scale: _loadingScaleAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ---------------------------------------------------------------
            // SOFT GLOW
            // ---------------------------------------------------------------
            Container(
              width: animationSize * 0.72,
              height: animationSize * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withOpacity(isDark ? 0.15 : 0.08),
                    const Color(0xFF0EA5E9).withOpacity(isDark ? 0.06 : 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // LOTTIE
            // ---------------------------------------------------------------
            Lottie.asset(
              'assets/lottie/loading.json',
              width: animationSize,
              height: animationSize,
              fit: BoxFit.contain,
              repeat: true,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FOOTER
  // ===========================================================================

  Widget _buildFooter({required bool isDark, required Color secondaryColor}) {
    return SlideTransition(
      position: _footerSlideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '© 2025 · Sakudewa Tech',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
                decoration: TextDecoration.none,
              ),
            ),

            if (_appVersion.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                _appVersion,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: secondaryColor.withOpacity(0.75),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();

    super.dispose();
  }
}

// ============================================================================
// SPLASH BACKGROUND
// ============================================================================

class _SplashBackground extends StatelessWidget {
  final Animation<double> controller;
  final bool isDark;

  const _SplashBackground({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(controller.value);

        return Stack(
          children: [
            // ================================================================
            // TOP LEFT BLUE ORB
            // ================================================================
            Positioned(
              top: -110 + (value * 25),
              left: -100 + (value * 18),
              child: _buildOrb(
                size: 280,
                color: const Color(0xFF2563EB),
                opacity: isDark ? 0.085 : 0.055,
              ),
            ),

            // ================================================================
            // TOP RIGHT CYAN ORB
            // ================================================================
            Positioned(
              top: 80 + (value * 35),
              right: -150,
              child: _buildOrb(
                size: 310,
                color: const Color(0xFF06B6D4),
                opacity: isDark ? 0.045 : 0.028,
              ),
            ),

            // ================================================================
            // BOTTOM RIGHT TEAL ORB
            // ================================================================
            Positioned(
              bottom: -170 + (value * 20),
              right: -100,
              child: _buildOrb(
                size: 340,
                color: const Color(0xFF14B8A6),
                opacity: isDark ? 0.055 : 0.035,
              ),
            ),

            // ================================================================
            // SMALL DECORATIVE DOTS
            // ================================================================
            Positioned(
              top: 190 + (value * 15),
              left: 30,
              child: _buildDot(size: 7, opacity: isDark ? 0.16 : 0.10),
            ),

            Positioned(
              top: 330 - (value * 12),
              right: 35,
              child: _buildDot(size: 6, opacity: isDark ? 0.13 : 0.08),
            ),

            Positioned(
              bottom: 190 + (value * 15),
              left: 55,
              child: _buildDot(size: 5, opacity: isDark ? 0.11 : 0.07),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrb({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  Widget _buildDot({required double size, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2563EB).withOpacity(opacity),
      ),
    );
  }
}
