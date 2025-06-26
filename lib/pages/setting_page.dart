import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class SettingPage extends StatelessWidget {
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

  void _showTentangAplikasi(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    final versi = info.version;

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Tentang Aplikasi"),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            "Versi: $versi\nDeveloper: Yussuf Faisal, S.Kom\n\nAplikasi Absensi Pegawai RS PKU Muhammadiyah Sukoharjo berbasis Flutter. "
            "Dilengkapi fitur GPS, validasi radius kantor, dan selfie kamera saat absen. Aplikasi ini dibuat dengan sepenuh ♥️ untuk dapat dipergunakan dengan semestinya",
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Tetap Semangat"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
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
    final bool isFotoAda = fotoProfil.trim().isNotEmpty;
    final fotoUrl = isFotoAda
        ? '${ApiService.simrsUrl}/storage/${fotoProfil.replaceFirst('public/', '')}'
        : null;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Pengaturan'),
        backgroundColor: CupertinoColors.white,
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: CupertinoColors.systemGrey4,
              backgroundImage: isFotoAda
                  ? NetworkImage(fotoUrl!)
                  : const AssetImage('assets/user.png') as ImageProvider,
            ),
            const SizedBox(height: 10),
            Text(
              nama,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              'NIP: $nip',
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                children: [
                  // CupertinoListTile(
                  //   leading: const Icon(CupertinoIcons.person),
                  //   title: const Text('Profil'),
                  //   subtitle: const Text('Lihat informasi karyawan'),
                  //   onTap: () {},
                  // ),
                  // const SizedBox(height: 8),
                  // CupertinoListTile(
                  //   leading: const Icon(CupertinoIcons.settings),
                  //   title: const Text('Pengaturan Akun'),
                  //   subtitle: const Text('Ubah preferensi akun'),
                  //   onTap: () {},
                  // ),
                  // const SizedBox(height: 8),
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.info),
                    title: const Text('Tentang Aplikasi'),
                    onTap: () => _showTentangAplikasi(context),
                  ),
                  const SizedBox(height: 8),
                  CupertinoListTile(
                    leading: const Icon(
                      CupertinoIcons.square_arrow_right,
                      color: CupertinoColors.systemRed,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: CupertinoColors.systemRed),
                    ),
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
