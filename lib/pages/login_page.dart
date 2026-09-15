import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/api_service.dart';
import '../theme_provider.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  late AnimationController _animationController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _logoAnimation;
  late Animation<Offset> _formAnimation;
  late Animation<Offset> _infoAnimation;

  bool isLoading = false;
  bool _obscurePassword = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _logoAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
    );

    _formAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _infoAnimation =
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.45, 1, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();

    _loadAppVersion();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();

    if (!mounted) return;

    setState(() {
      _appVersion = 'Versi ${info.version}';
    });
  }

  bool get _canLogin {
    return usernameController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        !isLoading;
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showValidationDialog();
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.login(username, password);

      if (!mounted) return;

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setInt('id_user', result['id_user']);

        await prefs.setString('nip', result['nip']);

        await prefs.setString('name', result['nama']);

        await prefs.setString('nama', result['nama']);

        await prefs.setString('foto_profil', result['foto_profil'] ?? '');

        await ApiService.sendFcmTokenToServer();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (_) => MainPage(
              id_user: result['id_user'],
              name: result['nama'],
              nama: result['nama'],
              nip: result['nip'],
              fotoProfil: result['foto_profil'] ?? '',
            ),
          ),
        );
      } else {
        await _showLoginFailedDialog(
          result['message'] ??
              'Mohon pastikan kombinasi Username dan Password Simrsmu sudah sesuai.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      await _showLoginFailedDialog(
        'Terjadi kesalahan saat menghubungkan ke server. '
        'Silakan periksa koneksi internet Anda dan coba kembali.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _showValidationDialog() async {
    await showCupertinoDialog(
      context: context,
      builder: (_) {
        return CupertinoAlertDialog(
          title: const Text(
            'Data Belum Lengkap',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Username dan Password wajib diisi sebelum masuk.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tutup',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLoginFailedDialog(String message) async {
    if (!mounted) return;

    await showCupertinoDialog(
      context: context,
      builder: (_) {
        return CupertinoAlertDialog(
          title: const Text(
            'Login Gagal',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tutup',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;

        final backgroundColor = isDark
            ? const Color(0xFF080A0F)
            : const Color(0xFFF5F7FA);

        final cardColor = isDark
            ? const Color(0xFF11151C)
            : CupertinoColors.white;

        final textColor = isDark
            ? CupertinoColors.white
            : const Color(0xFF111827);

        final secondaryColor = isDark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF6B7280);

        return CupertinoPageScaffold(
          backgroundColor: backgroundColor,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: _AnimatedBackground(isDark: isDark),
                ),
              ),

              // ============================================================
              // HEADER
              // ============================================================
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _logoAnimation,
                          child: Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF151A22)
                                  : CupertinoColors.white,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF293140)
                                    : const Color(0xFFE5E7EB),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.activeBlue.withOpacity(
                                    0.12,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
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
                        ),

                        _buildThemeButton(
                          themeProvider: themeProvider,
                          isDark: isDark,
                          secondaryColor: secondaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ============================================================
              // CONTENT
              // ============================================================
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight;
                    final width = constraints.maxWidth;

                    final bool isSmallHeight = height < 700;
                    final bool isVerySmallHeight = height < 600;

                    final double horizontalPadding = width < 360 ? 16 : 22;

                    final double contentWidth = width < 430
                        ? width - (horizontalPadding * 2)
                        : 400;

                    /*
                     * Design height adalah tinggi natural seluruh konten
                     * login pada kondisi normal.
                     *
                     * FittedBox hanya melakukan scaleDown apabila konten
                     * tidak cukup tinggi.
                     *
                     * Jadi:
                     * - layar normal = ukuran normal
                     * - layar pendek = mengecil secukupnya
                     * - tidak scroll
                     * - tidak overflow
                     */
                    final double availableHeight = constraints.maxHeight - 10;

                    final double designHeight = isVerySmallHeight
                        ? 500
                        : isSmallHeight
                        ? 550
                        : 600;

                    final double scale = availableHeight < designHeight
                        ? availableHeight / designHeight
                        : 1.0;

                    final double safeScale = scale.clamp(0.78, 1.0);

                    final double contentTop = isVerySmallHeight
                        ? 4
                        : isSmallHeight
                        ? 8
                        : 14;

                    return SizedBox(
                      width: double.infinity,
                      height: constraints.maxHeight,
                      child: Center(
                        child: Transform.scale(
                          scale: safeScale,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: contentWidth,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: contentTop,
                                bottom: 4,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ==================================================
                                  // BRAND
                                  // ==================================================
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: _buildBrand(
                                      isDark: isDark,
                                      textColor: textColor,
                                      secondaryColor: secondaryColor,
                                      compact:
                                          isVerySmallHeight || isSmallHeight,
                                    ),
                                  ),

                                  SizedBox(
                                    height: isVerySmallHeight
                                        ? 10
                                        : isSmallHeight
                                        ? 14
                                        : 20,
                                  ),

                                  // ==================================================
                                  // LOGIN CARD
                                  // ==================================================
                                  SlideTransition(
                                    position: _formAnimation,
                                    child: FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: _buildLoginCard(
                                        isDark: isDark,
                                        cardColor: cardColor,
                                        textColor: textColor,
                                        secondaryColor: secondaryColor,
                                        compact:
                                            isVerySmallHeight || isSmallHeight,
                                        padding: isVerySmallHeight
                                            ? 13
                                            : isSmallHeight
                                            ? 15
                                            : 18,
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height: isVerySmallHeight
                                        ? 8
                                        : isSmallHeight
                                        ? 10
                                        : 14,
                                  ),

                                  // ==================================================
                                  // INFORMATION CARD
                                  // ==================================================
                                  SlideTransition(
                                    position: _infoAnimation,
                                    child: FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: _buildInformationCard(
                                        isDark: isDark,
                                        cardColor: cardColor,
                                        textColor: textColor,
                                        secondaryColor: secondaryColor,
                                        compact:
                                            isVerySmallHeight || isSmallHeight,
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height: isVerySmallHeight
                                        ? 7
                                        : isSmallHeight
                                        ? 9
                                        : 16,
                                  ),

                                  // ==================================================
                                  // VERSION
                                  // ==================================================
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Text(
                                      _appVersion,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: isVerySmallHeight ? 8 : 9.5,
                                        fontWeight: FontWeight.w500,
                                        color: secondaryColor,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========================================================================
  // BRAND
  // ========================================================================

  Widget _buildBrand({
    required bool isDark,
    required Color textColor,
    required Color secondaryColor,
    required bool compact,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'E-',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: compact ? 25 : 29,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
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
                ).createShader(bounds);
              },
              child: Text(
                'Absensi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: compact ? 25 : 29,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: compact ? 1 : 3),

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

        SizedBox(height: compact ? 6 : 9),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 4 : 5,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue.withOpacity(isDark ? 0.10 : 0.07),
            borderRadius: BorderRadius.circular(20),
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
    );
  }

  // ========================================================================
  // LOGIN CARD
  // ========================================================================

  Widget _buildLoginCard({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color secondaryColor,
    required bool compact,
    required double padding,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        padding,
        compact ? 15 : 20,
        padding,
        compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: isDark ? const Color(0xFF252B36) : const Color(0xFFE7EAF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.055),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang 👋',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 17 : 18,
              fontWeight: FontWeight.w700,
              color: textColor,
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Silakan masuk menggunakan akun Simrsmu Anda.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 9.5 : 10,
              color: secondaryColor,
              decoration: TextDecoration.none,
            ),
          ),

          SizedBox(height: compact ? 13 : 19),

          _buildFieldLabel('Username', textColor, compact: compact),

          SizedBox(height: compact ? 5 : 7),

          _buildTextField(
            controller: usernameController,
            placeholder: 'Masukkan username',
            icon: CupertinoIcons.person_fill,
            isDark: isDark,
            textColor: textColor,
            secondaryColor: secondaryColor,
            compact: compact,
            textInputAction: TextInputAction.next,
          ),

          SizedBox(height: compact ? 9 : 14),

          _buildFieldLabel('Password', textColor, compact: compact),

          SizedBox(height: compact ? 5 : 7),

          _buildTextField(
            controller: passwordController,
            placeholder: 'Masukkan password',
            icon: CupertinoIcons.lock_fill,
            isDark: isDark,
            textColor: textColor,
            secondaryColor: secondaryColor,
            compact: compact,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (_canLogin) {
                login();
              }
            },
            suffix: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minSize: 0,
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              child: Icon(
                _obscurePassword
                    ? CupertinoIcons.eye_fill
                    : CupertinoIcons.eye_slash_fill,
                size: 17,
                color: secondaryColor,
              ),
            ),
          ),

          SizedBox(height: compact ? 13 : 20),

          _buildLoginButton(isDark: isDark, compact: compact),
        ],
      ),
    );
  }

  // ========================================================================
  // FIELD LABEL
  // ========================================================================

  Widget _buildFieldLabel(String text, Color color, {required bool compact}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: compact ? 10 : 10.5,
        fontWeight: FontWeight.w600,
        color: color,
        decoration: TextDecoration.none,
      ),
    );
  }

  // ========================================================================
  // TEXT FIELD
  // ========================================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required Color secondaryColor,
    required bool compact,
    bool obscureText = false,
    TextInputAction? textInputAction,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    final fieldColor = isDark
        ? const Color(0xFF181D26)
        : const Color(0xFFF7F8FA);

    final borderColor = isDark
        ? const Color(0xFF2A313D)
        : const Color(0xFFE5E7EB);

    return CupertinoTextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      placeholder: placeholder,
      placeholderStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: compact ? 9.5 : 10.5,
        color: secondaryColor.withOpacity(0.75),
        decoration: TextDecoration.none,
      ),
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: compact ? 10.5 : 11.5,
        color: textColor,
        decoration: TextDecoration.none,
      ),
      cursorColor: CupertinoColors.activeBlue,
      prefix: Padding(
        padding: EdgeInsets.only(
          left: compact ? 11 : 13,
          right: compact ? 7 : 8,
        ),
        child: Icon(
          icon,
          size: compact ? 16 : 17,
          color: CupertinoColors.activeBlue,
        ),
      ),
      suffix: suffix,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 11 : 14,
      ),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
    );
  }

  // ========================================================================
  // LOGIN BUTTON
  // ========================================================================

  Widget _buildLoginButton({required bool isDark, required bool compact}) {
    return AnimatedBuilder(
      animation: Listenable.merge([usernameController, passwordController]),
      builder: (context, _) {
        final canLogin = _canLogin;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: compact ? 47 : 52,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: canLogin
                ? const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                  )
                : null,
            color: canLogin
                ? null
                : isDark
                ? const Color(0xFF252B35)
                : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(15),
            boxShadow: canLogin
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(15),
            onPressed: canLogin ? login : null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? Row(
                      key: const ValueKey('loading'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Memproses...',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('login'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.arrow_right_circle_fill,
                          size: 19,
                          color: CupertinoColors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MASUK',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: canLogin
                                ? CupertinoColors.white
                                : isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // ========================================================================
  // INFORMATION CARD
  // ========================================================================

  Widget _buildInformationCard({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color secondaryColor,
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF252B36) : const Color(0xFFE7EAF0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 27 : 30,
                height: compact ? 27 : 30,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withOpacity(
                    isDark ? 0.14 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  CupertinoIcons.info_circle_fill,
                  size: compact ? 14 : 16,
                  color: CupertinoColors.activeBlue,
                ),
              ),

              SizedBox(width: compact ? 8 : 10),

              Text(
                'Keterangan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 9 : 12),

          _buildInformationItem(
            icon: CupertinoIcons.person_crop_circle_fill,
            text:
                'Login Akun / Device baru membutuhkan persetujuan Kredensial Login oleh SDI terlebih dahulu',
            isDark: isDark,
            textColor: textColor,
            secondaryColor: secondaryColor,
            compact: compact,
          ),

          SizedBox(height: compact ? 7 : 9),

          _buildInformationItem(
            icon: CupertinoIcons.person_2_fill,
            text:
                'Permasalahan terkait Akun, hubungi bagian SDI atau Unit terkait',
            isDark: isDark,
            textColor: textColor,
            secondaryColor: secondaryColor,
            compact: compact,
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // INFORMATION ITEM
  // ========================================================================

  Widget _buildInformationItem({
    required IconData icon,
    required String text,
    required bool isDark,
    required Color textColor,
    required Color secondaryColor,
    required bool compact,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 23 : 26,
          height: compact ? 23 : 26,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2430) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: compact ? 11 : 13, color: secondaryColor),
        ),

        SizedBox(width: compact ? 7 : 9),

        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 8.5 : 9.5,
              height: 1.35,
              color: secondaryColor,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  // ========================================================================
  // THEME BUTTON
  // ========================================================================

  Widget _buildThemeButton({
    required ThemeProvider themeProvider,
    required bool isDark,
    required Color secondaryColor,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A22) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF282F3A) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(
              isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
              key: ValueKey(isDark),
              size: 14,
              color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFFF59E0B),
            ),
          ),

          const SizedBox(width: 2),

          CupertinoSwitch(
            value: isDark,
            onChanged: (value) async {
              await themeProvider.toggleTheme(value);
            },
            activeTrackColor: CupertinoColors.activeBlue,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ANIMATED BACKGROUND
// ============================================================================

class _AnimatedBackground extends StatefulWidget {
  final bool isDark;

  const _AnimatedBackground({required this.isDark});

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(_controller.value);

        return Stack(
          children: [
            Positioned(
              top: -100 + value * 20,
              left: -80 + value * 12,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFF2563EB,
                  ).withOpacity(widget.isDark ? 0.09 : 0.07),
                ),
              ),
            ),

            Positioned(
              top: 100 + value * 25,
              right: -130,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFF06B6D4,
                  ).withOpacity(widget.isDark ? 0.045 : 0.035),
                ),
              ),
            ),

            Positioned(
              bottom: -150 + value * 18,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFF14B8A6,
                  ).withOpacity(widget.isDark ? 0.055 : 0.04),
                ),
              ),
            ),

            Positioned(
              top: 180 + value * 12,
              left: 25,
              child: _buildDot(7, widget.isDark ? 0.16 : 0.10),
            ),

            Positioned(
              bottom: 180 - value * 14,
              left: 50,
              child: _buildDot(5, widget.isDark ? 0.12 : 0.08),
            ),

            Positioned(
              top: 320 - value * 10,
              right: 30,
              child: _buildDot(6, widget.isDark ? 0.12 : 0.08),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDot(double size, double opacity) {
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
