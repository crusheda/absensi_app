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
  int loadingProgress = 0;

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
    if (!mounted) return;

    setState(() {
      isError = false;
      isRetrying = true;
      loadingProgress = 0;
    });

    final url = '${ApiService.baseUrl}/dashboard/${widget.id_user}';
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        loadingProgress = 70;
      });

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonMap = json.decode(response.body);
        if (!mounted) return;

        setState(() {
          dashboard = DashboardData.fromJson(jsonMap);
          isError = false;
          loadingProgress = 100;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isError = true;
        });
        _showApiErrorPopup(); // 👈 tampilkan dialog
      }
    } catch (e) {
      print('Parsing error: $e');
      if (!mounted) return;
      setState(() {
        isError = true;
      });
      _showApiErrorPopup(); // 👈 tampilkan dialog
    } finally {
      if (!mounted) return;
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

  void _showApiErrorPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text("Gagal Memuat Data"),
            content: const Text("Periksa koneksi atau hubungi admin."),
            actions: [
              // Tombol kiri: Tutup
              CupertinoDialogAction(
                child: const Text("Tutup"),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              // Tombol kanan: Muat Ulang
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text("Muat Ulang"),
                onPressed: () {
                  Navigator.of(ctx).pop(); // Tutup popup dulu
                  _loadDashboard(); // Panggil ulang load data
                },
              ),
            ],
          ),
        );
      }
    });
  }

  // Untuk NAMA SHIFT
  Widget _buildNamaShift() {
    if (isRetrying) {
      return const CupertinoTheme(
        data: CupertinoThemeData(brightness: Brightness.dark),
        child: CupertinoActivityIndicator(
          key: ValueKey('loadingNamaShiftStart'),
          radius: 10,
        ),
      );
    } else if (isError ||
        dashboard?.namaShift == null ||
        dashboard!.namaShift!.isEmpty) {
      return const Text(
        "Gagal Ambil Data!",
        key: ValueKey('loadingNamaShiftError'),
        style: TextStyle(
          color: Color.fromARGB(255, 255, 199, 199),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
        dashboard!.namaShift!,
        key: const ValueKey('loadingNamaShiftEnd'),
        style: const TextStyle(
          color: Color.fromARGB(255, 200, 255, 205),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  // Untuk SHIFT
  Widget _buildShift() {
    if (isRetrying) {
      return const CupertinoTheme(
        data: CupertinoThemeData(brightness: Brightness.dark),
        child: CupertinoActivityIndicator(
          key: ValueKey('loadingShiftStart'),
          radius: 10,
        ),
      );
    } else if (isError ||
        dashboard?.shift == null ||
        dashboard!.shift!.isEmpty) {
      return const Text(
        "Hubungi Admin Jadwal",
        key: ValueKey('loadingShiftError'),
        style: TextStyle(color: Colors.white),
      );
    } else {
      return Text(
        dashboard!.shift!,
        key: ValueKey('loadingShiftEnd'),
        style: const TextStyle(color: Colors.white),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Saat berhasil memuat dashboard
    final bool isFotoAda = widget.fotoProfil?.trim().isNotEmpty ?? false;
    final fotoUrl = isFotoAda
        ? '${ApiService.simrsUrl}/storage/${widget.fotoProfil.replaceFirst('public/', '')}'
        : null;
    final fotoUrlAdminJadwal = dashboard?.jadwal?.fotoPegawai;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // boxShadow: const [
                        //   BoxShadow(
                        //     color: CupertinoColors.systemGrey4,
                        //     blurRadius: 6,
                        //     offset: Offset(0, 3),
                        //   ),
                        // ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: CupertinoColors.systemGrey4,
                        backgroundImage: isFotoAda
                            ? NetworkImage(fotoUrl!)
                            : const AssetImage('assets/user.png')
                                  as ImageProvider,
                      ),
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
                if (isRetrying)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.tertiaryLabel
                          : CupertinoColors.systemGrey6.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // const CupertinoActivityIndicator(radius: 10),
                        // const SizedBox(width: 8),
                        Text(
                          "Memuat Dashboard...",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? CupertinoColors.systemGrey4
                                : CupertinoColors.black,
                          ),
                        ),
                        const Spacer(),
                        const CupertinoActivityIndicator(radius: 10),
                        // Text(
                        //   "$loadingProgress%",
                        //   style: const TextStyle(
                        //     fontSize: 13,
                        //     fontWeight: FontWeight.bold,
                        //     color: CupertinoColors.black,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              dashboard?.statuspgw?.namaStatus ?? '-',
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
                            color: isDark
                                ? CupertinoColors.darkBackgroundGray
                                      .withOpacity(0.5)
                                : CupertinoColors.white,
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
                                DateFormat(
                                  'dd',
                                  'id_ID',
                                ).format(DateTime.now()),
                                style: TextStyle(
                                  color: isDark
                                      ? CupertinoColors.white
                                      : CupertinoColors.activeBlue,
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
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                            child:
                                _buildNamaShift(), // Ini akan berganti dengan animasi saat berubah
                          ),
                          const SizedBox(height: 3),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                            child:
                                _buildShift(), // Ini akan berganti dengan animasi saat berubah
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 16,
                        child: Text(
                          _currentTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
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
                      context,
                      "Disiplin",
                      isRetrying
                          ? const CupertinoActivityIndicator(radius: 8)
                          : Text(
                              "${dashboard?.hadir ?? 'x'}x",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                      CupertinoColors
                          .activeBlue, // kalau kamu perlu param color lain
                    ),
                    _buildSquareStat(
                      context,
                      "Absen 1x",
                      isRetrying
                          ? const CupertinoActivityIndicator(radius: 8)
                          : Text(
                              "${dashboard?.absenOne ?? 'x'}x",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.systemOrange,
                              ),
                            ),
                      CupertinoColors.systemOrange,
                    ),
                    _buildSquareStat(
                      context,
                      "Terlambat",
                      isRetrying
                          ? const CupertinoActivityIndicator(radius: 8)
                          : Text(
                              "${dashboard?.terlambat ?? 'x'}x",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                      CupertinoColors.systemRed,
                    ),
                    _buildSquareStat(
                      context,
                      "Ijin",
                      isRetrying
                          ? const CupertinoActivityIndicator(radius: 8)
                          : Text(
                              "${dashboard?.ijin ?? 'x'}x",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.systemGreen,
                              ),
                            ),
                      CupertinoColors.systemGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                dashboard?.jadwal != null
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? CupertinoColors.secondaryLabel
                              : CupertinoColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? CupertinoColors.black
                                  : CupertinoColors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 3),
                            ),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSquareStat(
    BuildContext context,
    String label,
    Widget content,
    Color color, // tetap bisa passing accent color
  ) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.secondaryLabel
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? CupertinoColors.black
                    : CupertinoColors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              content,
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? CupertinoColors.secondaryLabel : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? CupertinoColors.black
                : CupertinoColors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: () {
          if (title == "Riwayat Absensi") {
            MainPageController.changeTab?.call(3); // Pindah ke tab Rekap
          } else if (title == "Tata Cara Absensi") {
            showCupertinoDialog(
              context: context,
              builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  title: const Text("Ah, Maaf!"),
                  content: const Text("Fitur belum tersedia untuk Saat ini :)"),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text("Tutup"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            );
          }
        },
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? CupertinoColors.systemGrey4
                      : Color.fromARGB(255, 5, 5, 5),
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
