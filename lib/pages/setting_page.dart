import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme_provider.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'profil_page.dart';

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

    if (!mounted) return;

    setState(() {
      appVersion = 'Versi ${info.version}';
    });
  }

  Future<void> _checkPermissions() async {
    final notifStatus = await Permission.notification.status;
    final gpsStatus = await Permission.locationWhenInUse.status;
    final cameraStatus = await Permission.camera.status;

    if (!mounted) return;

    setState(() {
      notifAllowed = notifStatus.isGranted;
      gpsAllowed = gpsStatus.isGranted;
      cameraAllowed = cameraStatus.isGranted;
    });
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings: settings);
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();

    if (!mounted) return;

    setState(() {
      notifAllowed = status.isGranted;
    });
  }

  Future<void> _requestGpsPermission() async {
    final status = await Permission.locationWhenInUse.request();

    if (!mounted) return;

    setState(() {
      gpsAllowed = status.isGranted;
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (!mounted) return;

    setState(() {
      cameraAllowed = status.isGranted;
    });
  }

  Future<void> _showDummyNotification() async {
    final status = await Permission.notification.request();

    if (!mounted) return;

    setState(() {
      notifAllowed = status.isGranted;
    });

    if (!status.isGranted) return;

    const androidDetails = AndroidNotificationDetails(
      'dummy_notif_absensi',
      'Contoh Notifikasi E-Absensi',
      channelDescription: 'Contoh E-Absensi menampilkan notifikasi Dummy',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Tes Notifikasi Informasi E-Absensi',
      body:
          'Ini adalah contoh notifikasi dari Aplikasi E-Absensi. Jangan lupa absensi ya :)',
      notificationDetails: notificationDetails,
    );
  }

  Future<void> _showTentangAplikasi() async {
    final info = await PackageInfo.fromPlatform();

    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) {
        final isDark =
            CupertinoTheme.brightnessOf(dialogContext) == Brightness.dark;

        return CupertinoAlertDialog(
          title: const Text(
            'Tentang Aplikasi',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Versi: ${info.version}\n'
              'Developer: Yussuf Faisal, S.Kom\n'
              'Role: Full Stack Programmer\n\n'
              'E-Absensi adalah pengembangan dari Website Absensi '
              'Simrsmu yang berbasis Flutter (AndroidApps) '
              'dilengkapi dengan GPS, validasi radius, selfie '
              'kamera, dan masih banyak lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                height: 1.5,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text(
                'Tutup',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text(
            'Keluar dari Aplikasi?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Anda harus login kembali untuk menggunakan aplikasi.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text(
                'Batal',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text(
                'Logout',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (!mounted) return;

    _showLoadingDialog();

    final success = await ApiService.logout();

    if (!mounted) return;

    Navigator.of(context).pop();

    if (!success) {
      await showCupertinoDialog(
        context: context,
        builder: (dialogContext) {
          return const CupertinoAlertDialog(
            title: Text(
              'Logout Gagal',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Terjadi kesalahan, tetapi Anda tetap akan keluar dari aplikasi.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
          );
        },
      );
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showLoadingDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const CupertinoAlertDialog(
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: CupertinoActivityIndicator(radius: 12),
          ),
        );
      },
    );
  }

  void _showPushNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text(
            'Push Notifikasi',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              children: [
                CupertinoTextField(
                  controller: titleController,
                  placeholder: 'Judul notifikasi',
                  padding: const EdgeInsets.all(12),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                  placeholderStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C2027)
                        : const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: messageController,
                  placeholder: 'Tulis pesan notifikasi...',
                  padding: const EdgeInsets.all(12),
                  maxLines: 4,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                  placeholderStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C2027)
                        : const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text(
                'Batal',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text(
                'Kirim',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                final message = messageController.text.trim();

                if (title.isEmpty || message.isEmpty) {
                  return;
                }

                final prefs = await SharedPreferences.getInstance();

                final token = prefs.getString('token');

                if (token == null || token.isEmpty) {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  return;
                }

                final success = await ApiService.broadcastMessage(
                  token,
                  title,
                  message,
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                await showCupertinoDialog(
                  context: context,
                  builder: (resultContext) {
                    return CupertinoAlertDialog(
                      title: Text(
                        success ? 'Berhasil' : 'Gagal',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: Text(
                        success
                            ? 'Pesan notifikasi berhasil dikirim.'
                            : 'Gagal mengirim notifikasi.',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.pop(resultContext);
                          },
                        ),
                      ],
                    );
                  },
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
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final foregroundColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.black;

    final secondaryColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.systemGrey;

    final backgroundColor = isDark
        ? const Color(0xFF080A0F)
        : const Color(0xFFF5F7FA);

    final cardColor = isDark ? const Color(0xFF11151C) : CupertinoColors.white;

    final isFotoAda = widget.fotoProfil.trim().isNotEmpty;

    final fotoUrl = isFotoAda
        ? '${ApiService.simrsUrl}/storage/${widget.fotoProfil.replaceFirst('public/', '')}'
        : null;

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(
              context,
              isDark: isDark,
              foregroundColor: foregroundColor,
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                child: Column(
                  children: [
                    _buildProfileCard(
                      context,
                      isDark: isDark,
                      cardColor: cardColor,
                      foregroundColor: foregroundColor,
                      secondaryColor: secondaryColor,
                      fotoUrl: fotoUrl,
                      isFotoAda: isFotoAda,
                    ),

                    const SizedBox(height: 18),

                    _buildSectionTitle('Preferensi', secondaryColor),

                    const SizedBox(height: 8),

                    _buildSettingsCard(
                      isDark: isDark,
                      cardColor: cardColor,
                      children: [
                        _buildSettingRow(
                          icon: CupertinoIcons.moon_fill,
                          title: 'Mode Gelap',
                          subtitle: 'Gunakan tampilan gelap',
                          trailing: Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return CupertinoSwitch(
                                value: themeProvider.isDarkMode,
                                onChanged: (value) {
                                  themeProvider.toggleTheme(value);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _buildSectionTitle('Izin Aplikasi', secondaryColor),

                    const SizedBox(height: 8),

                    _buildSettingsCard(
                      isDark: isDark,
                      cardColor: cardColor,
                      children: [
                        _buildSettingRow(
                          icon: CupertinoIcons.bell_fill,
                          title: 'Notifikasi',
                          subtitle: notifAllowed
                              ? 'Izin telah diberikan'
                              : 'Izin belum diberikan',
                          trailing: CupertinoSwitch(
                            value: notifAllowed,
                            onChanged: notifAllowed
                                ? null
                                : (_) => _requestNotificationPermission(),
                          ),
                        ),

                        _buildDivider(isDark),

                        _buildSettingRow(
                          icon: CupertinoIcons.location_fill,
                          title: 'Lokasi / GPS',
                          subtitle: gpsAllowed
                              ? 'Izin telah diberikan'
                              : 'Izin belum diberikan',
                          trailing: CupertinoSwitch(
                            value: gpsAllowed,
                            onChanged: gpsAllowed
                                ? null
                                : (_) => _requestGpsPermission(),
                          ),
                        ),

                        _buildDivider(isDark),

                        _buildSettingRow(
                          icon: CupertinoIcons.camera_fill,
                          title: 'Kamera',
                          subtitle: cameraAllowed
                              ? 'Izin telah diberikan'
                              : 'Izin belum diberikan',
                          trailing: CupertinoSwitch(
                            value: cameraAllowed,
                            onChanged: cameraAllowed
                                ? null
                                : (_) => _requestCameraPermission(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _buildSectionTitle('Aplikasi', secondaryColor),

                    const SizedBox(height: 8),

                    _buildSettingsCard(
                      isDark: isDark,
                      cardColor: cardColor,
                      children: [
                        _buildActionRow(
                          icon: CupertinoIcons.bell,
                          title: 'Tes Notifikasi E-Absensi',
                          subtitle: 'Coba kirim notifikasi ke perangkat',
                          onTap: _showDummyNotification,
                          isDark: isDark,
                        ),

                        if (widget.id_user == 232) ...[
                          _buildDivider(isDark),
                          _buildActionRow(
                            icon: CupertinoIcons.paperplane_fill,
                            title: 'Push Notifikasi',
                            subtitle: 'Kirim notifikasi ke pengguna',
                            onTap: () => _showPushNotificationDialog(context),
                            isDark: isDark,
                          ),
                        ],

                        _buildDivider(isDark),

                        _buildActionRow(
                          icon: CupertinoIcons.info_circle_fill,
                          title: 'Tentang Aplikasi',
                          subtitle: appVersion.isEmpty
                              ? 'Informasi aplikasi'
                              : appVersion,
                          onTap: _showTentangAplikasi,
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _buildLogoutButton(isDark: isDark),

                    const SizedBox(height: 18),

                    Text(
                      appVersion,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: secondaryColor,
                        decoration: TextDecoration.none,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'E-Absensi by Sakudewa',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: secondaryColor,
                        decoration: TextDecoration.none,
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

  Widget _buildHeader(
    BuildContext context, {
    required bool isDark,
    required Color foregroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Text(
            'Pengaturan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required bool isDark,
    required Color cardColor,
    required Color foregroundColor,
    required Color secondaryColor,
    required String? fotoUrl,
    required bool isFotoAda,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => ProfilePage(fotoProfil: widget.fotoProfil),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
          ),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'profile-photo',
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF303744)
                        : const Color(0xFFE5E7EB),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: isFotoAda
                      ? CachedNetworkImage(
                          imageUrl: fotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const CupertinoActivityIndicator(),
                          errorWidget: (_, __, ___) =>
                              Image.asset('assets/user.png', fit: BoxFit.cover),
                        )
                      : Image.asset('assets/user.png', fit: BoxFit.cover),
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: foregroundColor,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'NIP ${widget.nip}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: secondaryColor,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.person_fill,
                        size: 11,
                        color: CupertinoColors.activeBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lihat Profil',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.activeBlue,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Icon(CupertinoIcons.chevron_right, size: 17, color: secondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required Color cardColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          _buildIconContainer(icon),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: CupertinoColors.systemGrey,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),

          trailing,
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            _buildIconContainer(icon),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFEAECEF)
                          : const Color(0xFF242A33),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: CupertinoColors.systemGrey,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              CupertinoIcons.chevron_right,
              size: 15,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: CupertinoColors.activeBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 17, color: CupertinoColors.activeBlue),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 64),
      color: isDark ? const Color(0xFF242A33) : const Color(0xFFEAECEF),
    );
  }

  Widget _buildLogoutButton({required bool isDark}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1518) : const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF512027) : const Color(0xFFFFD5D9),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.square_arrow_right,
              size: 17,
              color: CupertinoColors.systemRed,
            ),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.systemRed,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
