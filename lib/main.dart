import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';
import 'pages/splash_page.dart';

// ✅ Tambah variable global
late List<CameraDescription> cameras;

void main() async {
  Intl.defaultLocale = 'id_ID';
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);

  // ✅ Inisialisasi kamera di awal
  cameras = await availableCameras();

  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final themeProvider = ThemeProvider();
        themeProvider.loadTheme();
        return themeProvider;
      },
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialPage() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final id_user = prefs.getInt('id_user');
    final token = prefs.getString('token');
    final name = prefs.getString('name');
    final nama = prefs.getString('nama');
    final nip = prefs.getString('nip');
    final foto = prefs.getString('foto_profil');

    if (id_user != null && token != null && nama != null && nip != null) {
      return MainPage(
        id_user: id_user,
        name: name ?? '',
        nama: nama,
        nip: nip,
        fotoProfil: foto ?? '',
      );
    } else {
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'E-Absensi',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: FutureBuilder<Widget>(
            future: _getInitialPage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return snapshot.data!;
              } else {
                return const SplashPage();
              }
            },
          ),
        );
      },
    );
  }
}
