import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_provider.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class SettingPage extends StatefulWidget {
  final int id_user;
  final String name;
  final String nama;
  final String nip;
  final String fotoProfil;

  const SettingPage({
    super.key,
    required this.id_user,
    required this.name,
    required this.nama,
    required this.nip,
    required this.fotoProfil,
  });

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String appVersion = '';
  bool notifAllowed = false;
  bool gpsAllowed = false;
  bool cameraAllowed = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _checkPermissions();
    _initNotifications();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = "Versi ${info.version}";
    });
  }

  Future<void> _checkPermissions() async {
    final notifStatus = await Permission.notification.status;
    final gpsStatus = await Permission.locationWhenInUse.status;
    final cameraStatus = await Permission.camera.status;

    setState(() {
      notifAllowed = notifStatus.isGranted;
      gpsAllowed = gpsStatus.isGranted;
      cameraAllowed = cameraStatus.isGranted;
    });
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showDummyNotification() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Tes Notifikasi E-Absensi',
      'Ini contoh notifikasi dari E-Absensi. Semangat!',
      notificationDetails,
    );
  }

  void _showTentangAplikasi() async {
    final info = await PackageInfo.fromPlatform();
    final versi = info.version;

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Tentang ♥️ Aplikasi"),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            "Versi: $versi\nDeveloper: Yussuf Faisal, S.Kom\nRole: Full Stack Programmer\n\nE-Absensi adalah pengembangan dari Website Absensi Simrsmu yang berbasis Flutter (AndroidApps) dilengkapi dengan GPS, validasi radius, selfie kamera, dan masih banyak lagi.",
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Tutup"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Pesan Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Batal"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Logout"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // ✅ Panggil logout dari ApiService (sudah termasuk hapus FCM token)
    final success = await ApiService.logout();

    if (context.mounted) {
      if (!success) {
        showCupertinoDialog(
          context: context,
          builder: (_) => const CupertinoAlertDialog(
            title: Text("Logout Gagal"),
            content: Text("Terjadi kesalahan, tetap akan keluar."),
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
      }

      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget _buildSwitchRow(String label, Widget switcher) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), switcher],
    );
  }

  void _showPushNotificationDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text("Push Notifikasi"),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: titleController,
                    placeholder: "Judul notifikasi",
                    maxLines: 1,
                  ),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: messageController,
                    placeholder: "Tulis pesan notifikasi...",
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text("Kirim"),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token');
                print('Token: $token'); // pastikan tidak null

                if (token == null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kamu harus login dulu")),
                  );
                  return;
                }

                bool success = await ApiService.broadcastMessage(
                  token,
                  titleController.text.trim(), // title
                  messageController.text.trim(), // body
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Pesan notifikasi berhasil dikirim"
                          : "Gagal mengirim notifikasi",
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFotoAda = widget.fotoProfil.trim().isNotEmpty;
    final fotoUrl = isFotoAda
        ? '${ApiService.simrsUrl}/storage/${widget.fotoProfil.replaceFirst('public/', '')}'
        : null;

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 🎨 BACKGROUND GRADIENT + BLUR
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.black, Colors.grey.shade900]
                      : [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -50,
            child: _blurCircle(Colors.blueAccent.withOpacity(0.2)),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _blurCircle(Colors.purpleAccent.withOpacity(0.2)),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CupertinoNavigationBar(
              middle: Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? CupertinoColors.systemGrey2
                      : CupertinoColors.black,
                ),
              ),
              backgroundColor: Colors.transparent,
              border: null,
            ),
          ),
          Positioned.fill(
            top: kToolbarHeight, // biar tidak ketimpa navbar
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: CupertinoColors.systemGrey4,
                      backgroundImage: isFotoAda
                          ? NetworkImage(fotoUrl!)
                          : const AssetImage('assets/user.png')
                                as ImageProvider,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.nama,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'NIP: ${widget.nip}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            'Mode Gelap',
                            Consumer<ThemeProvider>(
                              builder: (context, themeProvider, _) {
                                return CupertinoSwitch(
                                  value: themeProvider.isDarkMode,
                                  onChanged: (isOn) {
                                    themeProvider.toggleTheme(isOn);
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSwitchRow(
                            'Izin Notifikasi',
                            CupertinoSwitch(
                              value: notifAllowed,
                              onChanged: notifAllowed
                                  ? null
                                  : (value) async {
                                      final status = await Permission
                                          .notification
                                          .request();
                                      setState(() {
                                        notifAllowed = status.isGranted;
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSwitchRow(
                            'Izin GPS',
                            CupertinoSwitch(
                              value: gpsAllowed,
                              onChanged: gpsAllowed
                                  ? null
                                  : (value) async {
                                      final status = await Permission.location
                                          .request();
                                      setState(() {
                                        gpsAllowed = status.isGranted;
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSwitchRow(
                            'Izin Kamera',
                            CupertinoSwitch(
                              value: cameraAllowed,
                              onChanged: cameraAllowed
                                  ? null
                                  : (value) async {
                                      final status = await Permission.camera
                                          .request();
                                      setState(() {
                                        cameraAllowed = status.isGranted;
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.bell),
                      title: Text(
                        'Tes Notifikasi E-Absensi',
                        style: TextStyle(
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                      onTap: _showDummyNotification,
                    ),
                    const Divider(height: 1),
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.info),
                      title: Text(
                        'Tentang Aplikasi',
                        style: TextStyle(
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                      onTap: _showTentangAplikasi,
                    ),
                    const Divider(height: 1),
                    if (widget.id_user == 232) ...[
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.paperplane),
                        title: Text(
                          'Push Notifikasi',
                          style: TextStyle(
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                        onTap: () => _showPushNotificationDialog(context),
                      ),
                      const Divider(height: 1),
                    ],
                    CupertinoListTile(
                      leading: const Icon(
                        CupertinoIcons.square_arrow_right,
                        color: CupertinoColors.systemRed,
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: CupertinoColors.systemRed),
                      ),
                      onTap: _logout,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appVersion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
