import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
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
    if (!status.isGranted) {
      return;
    }

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
      'Ini adalah contoh Notifikasi yang diberikan oleh Aplikasi E-Absensi. Tetap Semangat Absennya ya. :)',
      notificationDetails,
    );
  }

  void _showTentangAplikasi() async {
    final info = await PackageInfo.fromPlatform();
    final versi = info.version;

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Tentang Aplikasi"),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            "Versi: $versi\nDeveloper: Yussuf Faisal, S.Kom\n\nAplikasi Absensi yang dibuat dengan sepenuh ♥️ untuk Pegawai RS PKU Muhammadiyah Sukoharjo berbasis Flutter. "
            "Dilengkapi fitur GPS, validasi radius kantor, dan selfie kamera saat absen.",
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
        title: const Text('Konfirmasi Logout'),
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

    final success = await ApiService.logout();

    if (context.mounted) {
      if (success) {
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } else {
        showCupertinoDialog(
          context: context,
          builder: (_) => const CupertinoAlertDialog(
            title: Text("Logout Gagal"),
            content: Text("Terjadi kesalahan. Silakan coba lagi."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFotoAda = widget.fotoProfil.trim().isNotEmpty;
    final fotoUrl = isFotoAda
        ? '${ApiService.simrsUrl}/storage/${widget.fotoProfil.replaceFirst('public/', '')}'
        : null;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Pengaturan',
          style: TextStyle(
            color: CupertinoTheme.brightnessOf(context) == Brightness.dark
                ? CupertinoColors.systemGrey2
                : CupertinoColors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 42,
              backgroundColor: CupertinoColors.systemGrey4,
              backgroundImage: isFotoAda
                  ? NetworkImage(fotoUrl!)
                  : const AssetImage('assets/user.png') as ImageProvider,
            ),
            const SizedBox(height: 10),
            Text(
              widget.nama,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              'NIP: ${widget.nip}',
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                children: [
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.info),
                    title: Text(
                      'Tentang Aplikasi',
                      style: TextStyle(
                        color:
                            CupertinoTheme.brightnessOf(context) ==
                                Brightness.dark
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                    onTap: _showTentangAplikasi,
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Mode Gelap'),
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Izin Notifikasi'),
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Izin GPS'),
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Izin Kamera'),
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
                          ],
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
                        color:
                            CupertinoTheme.brightnessOf(context) ==
                                Brightness.dark
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                    onTap: _showDummyNotification,
                  ),
                  const Divider(height: 1),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                appVersion,
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
