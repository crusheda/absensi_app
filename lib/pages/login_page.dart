import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
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
          title: const Text("Login Gagal"),
          content: Text(result['message']),
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(middle: Text("")),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo + Teks
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: const DecorationImage(
                          image: AssetImage('assets/logo/logo_clear_100kb.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "E-Absensi",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "RS PKU Muhammadiyah Sukoharjo",
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // USERNAME
                CupertinoTextField(
                  controller: usernameController,
                  placeholder: 'Masukkan Username',
                  prefix: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      CupertinoIcons.person,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                const SizedBox(height: 16),

                // PASSWORD
                CupertinoTextField(
                  controller: passwordController,
                  placeholder: 'Masukkan Password',
                  obscureText: _obscurePassword,
                  prefix: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      CupertinoIcons.lock,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  suffix: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      child: Icon(
                        _obscurePassword
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Butuh Bantuan?",
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Lupa Password",
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: isLoading ? null : login,
                    child: isLoading
                        ? const CupertinoActivityIndicator()
                        : const Text("MASUK"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
