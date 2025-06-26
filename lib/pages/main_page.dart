import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'absensi_page.dart';
import 'rekap_page.dart';
import 'setting_page.dart';

class MainPage extends StatefulWidget {
  final int id_user;
  final String name;
  final String nama;
  final String nip;
  final String fotoProfil;

  const MainPage({
    super.key,
    required this.id_user,
    required this.name,
    required this.nama,
    required this.nip,
    required this.fotoProfil,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        id_user: widget.id_user,
        name: widget.name,
        nama: widget.nama,
        nip: widget.nip,
        fotoProfil: widget.fotoProfil,
      ),
      RekapPage(id_user: widget.id_user),
      AbsensiPage(id_user: widget.id_user, nip: widget.nip),
      RekapPage(id_user: widget.id_user),
      SettingPage(
        id_user: widget.id_user,
        name: widget.name,
        nama: widget.nama,
        nip: widget.nip,
        fotoProfil: widget.fotoProfil,
      ),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_history),
            label: 'Aktivitas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Absensi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Rekap'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
    );
  }
}
