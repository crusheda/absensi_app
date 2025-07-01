import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/dashboard_data.dart';
import 'main_page.dart';
import 'jadwal_page.dart';
import 'package:absensi_app/pages/rekap_page.dart'; // ganti sesuai path kamu
import 'dart:convert';

class DashboardPage extends StatefulWidget {
  final int id_user;
  final String name;
  final String nama;
  final String nip;
  final String fotoProfil;

  const DashboardPage({
    super.key,
    required this.id_user,
    required this.name,
    required this.nama,
    required this.nip,
    required this.fotoProfil,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardData? dashboard;
  late Timer _timer;
  bool isError = false;
  bool isRetrying = false;
  String _currentTime = "";

  String formatTanggalIndonesia(String? tanggal) {
    if (tanggal == null) return '-';
    final dateTime = DateTime.tryParse(tanggal);
    if (dateTime == null) return '-';

    final formatter = DateFormat(
      "EEEE, dd MMMM yyyy 'pukul' HH.mm 'WIB'",
      'id',
    );
    return formatter.format(dateTime);
  }

  String bulanToNama(String? bulan) {
    if (bulan == null) return '-';
    int? bulanAngka = int.tryParse(bulan);
    if (bulanAngka == null || bulanAngka < 1 || bulanAngka > 12) return '-';

    final date = DateTime(2025, bulanAngka);
    return DateFormat.MMMM('id').format(date);
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _updateTime(),
    );
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  Future<void> _loadDashboard() async {
    setState(() {
      isError = false;
      isRetrying = true;
    });

    final url = '${ApiService.baseUrl}/dashboard/${widget.id_user}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonMap = json.decode(response.body);
        setState(() {
          dashboard = DashboardData.fromJson(jsonMap);
          isError = false;
        });
      } else {
        setState(() {
          isError = true;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
      });
    } finally {
      setState(() {
        isRetrying = false;
      });
    }
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
    if (dashboard == null) {
      return Center(
        child: isError
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Data API Gagal dimuat.",
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  isRetrying
                      ? const CupertinoActivityIndicator()
                      : CupertinoButton.filled(
                          color: CupertinoColors.activeBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          onPressed: _loadDashboard,
                          child: const Text("Muat Ulang"),
                        ),
                ],
              )
            : const CupertinoActivityIndicator(),
      );
    }

    if (isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Gagal memproses Data API Dashboard.',
              style: TextStyle(color: CupertinoColors.systemRed),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              color: CupertinoColors.activeBlue,
              onPressed: _loadDashboard,
              child: const Text("Muat Ulang"),
            ),
          ],
        ),
      );
    }

    final bool isFotoAda = widget.fotoProfil.trim().isNotEmpty;
    final fotoUrl = isFotoAda
        ? '${ApiService.simrsUrl}/storage/${widget.fotoProfil.replaceFirst('public/', '')}'
        : null;
    final fotoUrlAdminJadwal = dashboard?.jadwal?.fotoPegawai;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
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
                      widget.nama ?? '-',
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
                      children: [
                        Text(
                          "Status Pegawai",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          dashboard!.statuspgw!.namaStatus,
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
                            DateFormat('dd', 'id_ID').format(DateTime.now()),
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
                    children: [
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
                        (dashboard?.namaShift?.isNotEmpty ?? false)
                            ? dashboard!.namaShift
                            : "Tidak Ada",
                        style: TextStyle(
                          color: (dashboard?.namaShift?.isNotEmpty ?? false)
                              ? const Color.fromARGB(255, 200, 255, 205)
                              : const Color.fromARGB(255, 255, 199, 199),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        (dashboard?.shift?.isNotEmpty ?? false)
                            ? dashboard!.shift
                            : "Hubungi Admin Jadwal",
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
                  "${dashboard!.hadir}x",
                  CupertinoColors.activeBlue,
                ),
                _buildSquareStat(
                  "Absen 1x/hr",
                  "${dashboard!.absenOne}x",
                  CupertinoColors.systemOrange,
                ),
                _buildSquareStat(
                  "Terlambat",
                  "${dashboard!.terlambat}x",
                  CupertinoColors.systemRed,
                ),
                _buildSquareStat(
                  "Ijin",
                  "${dashboard!.ijin}x",
                  CupertinoColors.systemGreen,
                ),
              ],
            ),
            const SizedBox(height: 20),
            dashboard?.jadwal != null
                ? Container(
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
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: CupertinoColors.systemGrey4,
                          backgroundImage:
                              (fotoUrlAdminJadwal != null &&
                                  fotoUrlAdminJadwal.isNotEmpty)
                              ? NetworkImage(
                                  "${ApiService.simrsUrl}/storage/${fotoUrlAdminJadwal.replaceFirst('public/', '')}",
                                )
                              : const AssetImage('assets/user.png'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Jadwal ${bulanToNama(dashboard?.jadwal?.bulan)} ${dashboard?.jadwal?.tahun}",
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
                                "${dashboard?.jadwal?.namaPegawai} (Admin Jadwal)",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                formatTanggalIndonesia(
                                  dashboard?.jadwal?.updatedAt,
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: const Color.fromARGB(255, 71, 71, 71),
                          onPressed: () {
                            MainPageController.changeTab?.call(1);
                          },
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
                  )
                : const SizedBox.shrink(),
            dashboard?.jadwal != null
                ? const SizedBox(height: 20)
                : const SizedBox(height: 0),
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
        onPressed: () {
          if (title == "Riwayat Absensi") {
            MainPageController.changeTab?.call(3); // Pindah ke tab Rekap
          }
        },
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
