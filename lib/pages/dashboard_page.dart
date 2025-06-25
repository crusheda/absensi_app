import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

class DashboardPage extends StatefulWidget {
  final String name;
  final String nama;
  final String nip;
  final String fotoProfil;

  const DashboardPage({
    super.key,
    required this.name,
    required this.nama,
    required this.nip,
    required this.fotoProfil,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Timer _timer;
  String _currentTime = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _updateTime(),
    );
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  void _updateTime() {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm:ss').format(now);
    final suffix = now.hour < 12
        ? 'Pagi'
        : now.hour < 15
        ? 'Siang'
        : now.hour < 18
        ? 'Sore'
        : 'Malam';
    setState(() {
      _currentTime = "$timeStr $suffix";
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFotoAda = widget.fotoProfil.trim().isNotEmpty;
    final fotoUrl = isFotoAda
        ? 'https://simrsmu.com/storage/${widget.fotoProfil.replaceFirst('public/', '')}'
        : null;
    return CupertinoPageScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: CupertinoColors.systemGrey4,
                  backgroundImage: isFotoAda
                      ? NetworkImage(fotoUrl!)
                      : const AssetImage('assets/user.png') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Selamat datang kembali,",
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                    Text(
                      widget.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Image.asset("assets/logo/logo_clear_100kb.png", width: 40),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    "assets/cover2.jpg",
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  Positioned(
                    top: 12,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Status Pegawai",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          "Kontrak",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat(
                              'MMM',
                              'id_ID',
                            ).format(DateTime.now()).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('d', 'id_ID').format(DateTime.now()),
                            style: const TextStyle(
                              color: CupertinoColors.activeBlue,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Jadwal Hari Ini",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        "pagi kantor",
                        style: TextStyle(
                          color: Color.fromARGB(255, 200, 255, 205),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "08.00 - 15.00 WIB",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 10,
                    left: 16,
                    child: Text(
                      DateFormat(
                        'EEEE, d MMMM yyyy',
                        'id_ID',
                      ).format(DateTime.now()),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 16,
                    child: Text(
                      _currentTime,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "\u{1F501} Perhitungan Absensi Bulan Ini",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildSquareStat(
                  "Tepat Waktu",
                  "14x",
                  CupertinoColors.activeBlue,
                ),
                _buildSquareStat(
                  "Absen 1x/hr",
                  "0x",
                  CupertinoColors.systemOrange,
                ),
                _buildSquareStat("Terlambat", "2x", CupertinoColors.systemRed),
                _buildSquareStat("Ijin", "0x", CupertinoColors.systemGreen),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 4),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: CupertinoColors.systemGrey4,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Jadwal Juni 2025",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Diperbarui oleh:",
                          style: TextStyle(
                            fontSize: 11,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          "Herman Susilo (Admin Jadwal)",
                          style: TextStyle(
                            fontSize: 11,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          "Sabtu, 31 Mei 2025 pukul 19.51 WIB",
                          style: TextStyle(
                            fontSize: 11,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: const Color.fromARGB(255, 39, 39, 39),
                    onPressed: () {},
                    child: const Text(
                      "LIHAT",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildActionTile(
              "Riwayat Absensi",
              CupertinoIcons.clock,
              CupertinoColors.systemIndigo,
            ),
            _buildActionTile(
              "Tata Cara Absensi",
              CupertinoIcons.book,
              CupertinoColors.systemGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareStat(String label, String count, Color color) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x11000000), blurRadius: 4),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 4)],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: () {},
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color.fromARGB(255, 5, 5, 5),
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.right_chevron,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }
}
