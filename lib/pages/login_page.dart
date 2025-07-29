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

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  String _appVersion = '';

  void initState() {
    super.initState();
    _loadAppVersion();
  }

  void _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Versi ${info.version}';
    });
  }

  void login() async {
    setState(() => isLoading = true);

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    final result = await ApiService.login(username, password);

    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('id_user', result['id_user']);
      await prefs.setString('nip', result['nip']);
      await prefs.setString('name', result['nama']);
      await prefs.setString('nama', result['nama']);
      await prefs.setString('foto_profil', result['foto_profil'] ?? '');

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
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Login Gagal!'),
          content: Text(
            result['message'] ??
                'Mohon Pastikan kombinasi Username dan Password karyawan sudah sesuai. Lebih Lanjut silakan hubungi Admin.',
          ), // Text(result['message'])
          actions: [
            CupertinoDialogAction(
              child: const Text("Tutup"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Stack(
          children: [
            /// BACKGROUND ABSTRAK
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              top: 20,
              right: 20,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return Row(
                    children: [
                      Text(
                        themeProvider.isDarkMode ? 'Gelap' : 'Terang',
                        style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.none,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoSwitch(
                        value: themeProvider.isDarkMode,
                        onChanged: (isOn) {
                          themeProvider.toggleTheme(isOn);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            /// FORM LOGIN + VERSI
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// LOGO
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: const DecorationImage(
                          image: AssetImage('assets/logo/logo_clear_100kb.png'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    Text(
                      "RS PKU Muhammadiyah Sukoharjo",
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.none,
                        color:
                            CupertinoTheme.brightnessOf(context) ==
                                Brightness.dark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),

                    const SizedBox(height: 50),

                    /// USERNAME
                    CupertinoTextField(
                      controller: usernameController,
                      placeholder: 'Username',
                      style: TextStyle(
                        color:
                            CupertinoTheme.brightnessOf(context) ==
                                Brightness.dark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          CupertinoIcons.person,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// PASSWORD
                    CupertinoTextField(
                      controller: passwordController,
                      placeholder: 'Password',
                      style: TextStyle(
                        color:
                            CupertinoTheme.brightnessOf(context) ==
                                Brightness.dark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                      obscureText: _obscurePassword,
                      prefix: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          CupertinoIcons.lock,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      suffix: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            _obscurePassword
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// TOMBOL MASUK
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(8),
                        color: CupertinoColors.activeBlue.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        onPressed: isLoading ? null : login,
                        child: isLoading
                            ? const CupertinoActivityIndicator()
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    CupertinoIcons.arrow_right_circle_fill,
                                    size: 20,
                                    color: CupertinoColors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "MASUK",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    /// VERSI DI PALING BAWAH
                    Text(
                      _appVersion,
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.none,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
