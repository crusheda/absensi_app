import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:absensi_app/models/dashboard_data.dart';
import 'package:absensi_app/pages/faq_page.dart';
import 'package:absensi_app/pages/main_page_controller.dart';
import 'package:absensi_app/pages/pdf_view_page.dart';
import 'package:absensi_app/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

    return DateFormat(
      "EEEE, dd MMMM yyyy 'pukul' HH.mm 'WIB'",
      'id',
    ).format(dateTime);
  }

  String bulanToNama(String? bulan) {
    if (bulan == null) return '-';

    final bulanAngka = int.tryParse(bulan);

    if (bulanAngka == null || bulanAngka < 1 || bulanAngka > 12) {
      return '-';
    }

    return DateFormat.MMMM(
      'id',
    ).format(DateTime(2025, bulanAngka));
  }

  @override
  void initState() {
    super.initState();

    _loadDashboard();
    _updateTime();
    _initFcmToken();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  void _initFcmToken() async {
    await ApiService.sendFcmTokenToServer();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      isError = false;
      isRetrying = true;
      loadingProgress = 0;
    });

    final url =
        '${ApiService.baseUrl}/dashboard/${widget.id_user}';

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

        _showApiErrorPopup();
      }
    } catch (e) {
      print('Parsing error: $e');

      if (!mounted) return;

      setState(() {
        isError = true;
      });

      _showApiErrorPopup();
    } finally {
      if (!mounted) return;

      setState(() {
        isRetrying = false;
      });
    }
  }

  void _updateTime() {
    if (!mounted) return;

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
      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text("Gagal Memuat Data"),
          content: const Text(
            "Periksa koneksi atau hubungi admin.",
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text("Tutup"),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text("Muat Ulang"),
              onPressed: () {
                Navigator.of(ctx).pop();
                _loadDashboard();
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNamaShift() {
    if (isRetrying) {
      return const CupertinoActivityIndicator(
        radius: 8,
        color: Colors.white,
      );
    }

    if (isError ||
        dashboard?.namaShift == null ||
        dashboard!.namaShift!.isEmpty) {
      return const Text(
        "Belum tersedia",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Text(
      dashboard!.namaShift!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildShift() {
    if (isRetrying) {
      return const SizedBox.shrink();
    }

    if (isError ||
        dashboard?.shift == null ||
        dashboard!.shift!.isEmpty) {
      return const Text(
        "Hubungi Admin Jadwal",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10,
        ),
      );
    }

    return Text(
      dashboard!.shift!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 10,
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final isFotoAda =
        widget.fotoProfil.trim().isNotEmpty;

    final fotoUrl = isFotoAda
        ? '${ApiService.simrsUrl}/storage/${widget.fotoProfil.replaceFirst('public/', '')}'
        : null;

    final fotoUrlAdminJadwal =
        dashboard?.jadwal?.fotoPegawai;

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1117)
          : const Color(0xFFF5F8FC),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF0D1117),
                          Color(0xFF111827),
                        ]
                      : const [
                          Color(0xFFF8FAFF),
                          Color(0xFFF2F6FB),
                        ],
                ),
              ),
            ),
          ),
          if (!isDark) ...[
            Positioned(
              top: -110,
              right: -80,
              child: _blurCircle(
                const Color(0x443B82F6),
              ),
            ),
            Positioned(
              top: 260,
              left: -110,
              child: _blurCircle(
                const Color(0x222563EB),
              ),
            ),
          ],
          SafeArea(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                14,
                8,
                14,
                22,
              ),
              children: [
                _buildHeader(
                  isDark,
                  isFotoAda,
                  fotoUrl,
                ),
                const SizedBox(height: 11),
                if (isRetrying) ...[
                  _buildLoadingCard(isDark),
                  const SizedBox(height: 9),
                ],
                _buildTodaySchedule(
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildSectionTitle(
                  "Ringkasan Absensi",
                  "Bulan ini",
                  isDark,
                ),
                const SizedBox(height: 7),
                _buildStatistics(isDark),
                if (dashboard?.jadwal != null) ...[
                  const SizedBox(height: 12),
                  _buildAdminSchedule(
                    isDark,
                    fotoUrlAdminJadwal,
                  ),
                ],
                const SizedBox(height: 12),
                _buildSectionTitle(
                  "Menu Cepat",
                  null,
                  isDark,
                ),
                const SizedBox(height: 7),
                _buildQuickActions(
                  context,
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    bool isDark,
    bool isFotoAda,
    String? fotoUrl,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isDark ? 0.20 : 0.06,
                ),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: isFotoAda
                ? CachedNetworkImage(
                    imageUrl: fotoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: isDark
                          ? Colors.white10
                          : const Color(0xFFE9EEF5),
                      child: const Icon(
                        CupertinoIcons.person_fill,
                        size: 19,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    errorWidget: (_, __, ___) {
                      return Image.asset(
                        'assets/user.png',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'assets/user.png',
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selamat datang kembali 👋",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? Colors.white54
                      : const Color(0xFF7B8794),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF152238),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 37,
          height: 37,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isDark ? 0.12 : 0.05,
                ),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Image.asset(
            "assets/logo/logo_clear_100kb.png",
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : const Color(0xFFE6ECF4),
        ),
      ),
      child: Row(
        children: [
          const CupertinoActivityIndicator(
            radius: 7,
          ),
          const SizedBox(width: 8),
          Text(
            "Memuat dashboard...",
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? Colors.white70
                  : const Color(0xFF667386),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule(bool isDark) {
    final now = DateTime.now();

    final tanggal = DateFormat(
      'EEEE, d MMMM',
      'id_ID',
    ).format(now);

    final currentTime =
        _currentTime.isNotEmpty
            ? _currentTime.split(' ').first
            : '--:--:--';

    final currentPeriod =
        _currentTime.contains(' ')
            ? _currentTime.split(' ').last
            : '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF17355F),
                      Color(0xFF142B49),
                    ]
                  : const [
                      Color(0xFF3183ED),
                      Color(0xFF2563EB),
                    ],
            ),
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        CupertinoIcons.calendar,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "JADWAL HARI INI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      tanggal,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // DETAIL SHIFT
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    // ICON SHIFT
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        CupertinoIcons.sun_max_fill,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),

                    const SizedBox(width: 9),

                    // NAMA SHIFT + JAM SHIFT
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNamaShift(),
                          const SizedBox(height: 2),
                          _buildShift(),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // JAM SEKARANG
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currentTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentPeriod.isNotEmpty
                              ? currentPeriod.toUpperCase()
                              : "SEKARANG",
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 7),

              // STATUS
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.white54,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "Status: ${dashboard?.statuspgw?.namaStatus ?? '-'}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Aktif",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    String? trailing,
    bool isDark,
  ) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? Colors.white
                : const Color(0xFF172033),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 9,
              color: isDark
                  ? Colors.white38
                  : const Color(0xFF8994A5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatistics(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 7,
      mainAxisSpacing: 7,
      childAspectRatio: 0.95,
      children: [
        _buildCompactStat(
          "Disiplin",
          dashboard?.hadir,
          CupertinoIcons.checkmark_seal_fill,
          const Color(0xFF2563EB),
          isDark,
        ),
        _buildCompactStat(
          "Absen 1x",
          dashboard?.absenOne,
          CupertinoIcons.exclamationmark_circle_fill,
          const Color(0xFFF59E0B),
          isDark,
        ),
        _buildCompactStat(
          "Terlambat",
          dashboard?.terlambat,
          CupertinoIcons.clock_fill,
          const Color(0xFFEF4444),
          isDark,
        ),
        _buildCompactStat(
          "Ijin/DL",
          dashboard?.ijin,
          CupertinoIcons.doc_checkmark_fill,
          const Color(0xFF10B981),
          isDark,
        ),
      ],
    );
  }

  Widget _buildCompactStat(
    String title,
    dynamic value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.055)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : const Color(0xFFE6ECF4),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.035),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          if (isRetrying)
            const CupertinoActivityIndicator(
              radius: 6,
            )
          else
            Text(
              "${value ?? 'x'}x",
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF172033),
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 1),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 7,
              color: isDark
                  ? Colors.white54
                  : const Color(0xFF7A8699),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSchedule(
    bool isDark,
    String? fotoUrlAdminJadwal,
  ) {
    final imageUrl =
        fotoUrlAdminJadwal != null &&
                fotoUrlAdminJadwal.isNotEmpty
            ? "${ApiService.simrsUrl}/storage/${fotoUrlAdminJadwal.replaceFirst('public/', '')}"
            : null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.055)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : const Color(0xFFE6ECF4),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.035),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white10
                  : const Color(0xFFF0F4FA),
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) {
                        return Image.asset(
                          'assets/user.png',
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/user.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Jadwal ${bulanToNama(dashboard?.jadwal?.bulan)} ${dashboard?.jadwal?.tahun}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF172033),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Diperbarui oleh ${dashboard?.jadwal?.namaPegawai ?? '-'}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8,
                    color: isDark
                        ? Colors.white.withOpacity(0.45)
                        : const Color(0xFF8792A3),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  formatTanggalIndonesia(
                    dashboard?.jadwal?.updatedAt,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 7,
                    color: isDark
                        ? Colors.white.withOpacity(0.30)
                        : const Color(0xFF9BA5B4),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildSmallButton(
            "LIHAT",
            const Color(0xFF2563EB),
            () {
              MainPageController.changeTab?.call(1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    bool isDark,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.45,
      ),
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return _buildQuickAction(
              title: "Riwayat",
              icon: CupertinoIcons.clock,
              color: const Color(0xFF4F46E5),
              isDark: isDark,
              onTap: () {
                MainPageController
                    .changeTab
                    ?.call(3);
              },
            );

          case 1:
            return _buildQuickAction(
              title: "Dokumentasi",
              icon: CupertinoIcons.book,
              color: const Color(0xFF059669),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => PdfViewPage(
                      assetPath:
                          'assets/pdf/tata_cara_eabsensi.pdf',
                    ),
                  ),
                );
              },
            );

          case 2:
            return _buildQuickAction(
              title: "FAQ",
              icon:
                  CupertinoIcons.question_circle,
              color: const Color(0xFF2563EB),
              isDark: isDark,
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) =>
                        const FaqPage(),
                  ),
                );
              },
            );

          default:
            return _buildQuickAction(
              title: "Berita",
              icon: CupertinoIcons.news,
              color: const Color(0xFF0D9488),
              isDark: isDark,
              onTap: () {
                showCupertinoDialog(
                  context: context,
                  builder: (dialogContext) {
                    return CupertinoAlertDialog(
                      title: const Text(
                        "Fitur belum tersedia!",
                      ),
                      content: const Text(
                        "Fitur Berita Terkini masih dalam proses pengembangan oleh Developer. Mohon tunggu update berikutnya 😊",
                      ),
                      actions: [
                        CupertinoDialogAction(
                          isDefaultAction: true,
                          child:
                              const Text("Tutup"),
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                            ).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
        }
      },
    );
  }

  Widget _buildQuickAction({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.055)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : const Color(0xFFE6ECF4),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF172033),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_right,
              size: 11,
              color: isDark
                  ? Colors.white.withOpacity(0.30)
                  : const Color(0xFFA3ADBB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurCircle(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 80,
          sigmaY: 80,
        ),
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }
}