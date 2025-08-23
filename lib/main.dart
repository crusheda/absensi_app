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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ✅ Tambah variable global
late List<CameraDescription> cameras;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🔹 Background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Jangan tampilkan notifikasi manual di background
  print("Pesan diterima di background: ${message.data['title'] ?? 'No Title'}");
}

// 🔹 Inisialisasi notifikasi
Future<void> _initNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Buat channel Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'pengumuman_absensi',
    'E-Absensi Notifications',
    description: 'Notifikasi penting E-Absensi',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Request permission (iOS)
  // await FirebaseMessaging.instance.requestPermission(
  //   alert: true,
  //   badge: true,
  //   sound: true,
  // );
}

// 🔹 Tampilkan notifikasi foreground saja
Future<void> _showForegroundNotification(RemoteMessage message) async {
  final data = message.data;
  // final String? title = data['title'];
  // final String? body = data['body'];
  final String title =
      message.notification?.title ?? data['title'] ?? 'No Title';
  final String body = message.notification?.body ?? data['body'] ?? 'No Body';

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'pengumuman_absensi',
    'E-Absensi Notifications',
    channelDescription: 'Notifikasi penting E-Absensi',
    importance: Importance.max,
    priority: Priority.high,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

  NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    data.hashCode, // unik per pesan
    title,
    body,
    platformDetails,
  );
}

void main() async {
  Intl.defaultLocale = 'id_ID';
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  await Firebase.initializeApp();

  await _initNotifications();

  // 🔹 Listener untuk foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title =
        message.notification?.title ?? message.data['title'] ?? 'No Title';
    final body =
        message.notification?.body ?? message.data['body'] ?? 'No Body';

    print("🔔 Foreground message: $title");

    // Tampilkan notifikasi tray manual
    _showForegroundNotification(message);
  });

  // 🔹 Listener untuk saat user tap notifikasi dari background / terminated
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final title =
        message.notification?.title ?? message.data['title'] ?? 'No Title';
    final body =
        message.notification?.body ?? message.data['body'] ?? 'No Body';

    print("📬 Dibuka dari background / terminated: $title");
    // Navigasi halaman tertentu bisa dilakukan di sini
  });

  // 🔹 Background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
