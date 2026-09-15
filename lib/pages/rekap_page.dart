import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showDialog, Scaffold;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../services/api_service.dart';
import 'rekap_detail_page.dart';

class RiwayatModel {
  final IconData icon;
  final int idAbsensi;
  final String shift;
  final String waktu;
  final int jenis;
  final String? tglIn;
  final String? tglOut;
  final int terlambat;

  RiwayatModel({
    required this.icon,
    required this.idAbsensi,
    required this.shift,
    required this.waktu,
    required this.jenis,
    required this.tglIn,
    required this.tglOut,
    required this.terlambat,
  });

  factory RiwayatModel.fromJson(Map<String, dynamic> json) {
    return RiwayatModel(
      icon: CupertinoIcons.sun_max,
      idAbsensi: int.tryParse('${json['id']}') ?? 0,
      shift: '${json['nm_shift'] ?? '-'}',
      waktu: '${json['tgl_in'] ?? '-'}',
      jenis: int.tryParse('${json['jenis'] ?? 0}') ?? 0,
      tglIn: json['tgl_in']?.toString(),
      tglOut: json['tgl_out']?.toString(),
      terlambat: int.tryParse('${json['terlambat'] ?? 0}') ?? 0,
    );
  }
}

class RekapPage extends StatefulWidget {
  final int id_user;

  const RekapPage({super.key, required this.id_user});

  @override
  State<RekapPage> createState() => _RekapPageState();
}

class _RekapPageState extends State<RekapPage> {
  bool isError = false;
  bool isLoading = true;

  String selectedFilter = '1';

  List<RiwayatModel> riwayat = [];

  int tepatWaktu = 0;
  int terlambat = 0;
  int absenone = 0;

  late final ScrollController _scrollController;

  bool showBackToTopButton = false;

  late Map<String, String> filterOptions;

  late final DateFormat _dateFormatter;

  @override
  void initState() {
    super.initState();

    initializeDateFormatting('id');

    _dateFormatter = DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id');

    filterOptions = getFilterOptions();

    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);

    fetchRiwayat();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();

    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final shouldShow = _scrollController.offset >= 400;

    if (shouldShow != showBackToTopButton && mounted) {
      setState(() {
        showBackToTopButton = shouldShow;
      });
    }
  }

  Map<String, String> getFilterOptions() {
    final now = DateTime.now();

    final dateFormat = DateFormat('MMM yyyy', 'id');

    final twoMonthsAgo = DateTime(now.year, now.month - 2);

    final oneMonthAgo = DateTime(now.year, now.month - 1);

    final currentMonth = DateTime(now.year, now.month);

    final options = <String, String>{
      '1': '1 Minggu Terakhir',
      '2': '2 Minggu Terakhir',
      '3':
          '21 ${dateFormat.format(twoMonthsAgo)} - 20 ${dateFormat.format(oneMonthAgo)}',
      '4':
          '21 ${dateFormat.format(oneMonthAgo)} - 20 ${dateFormat.format(currentMonth)}',
      '6': '3 Bulan Terakhir',
      '7': 'Selama Tahun ${now.year}',
    };

    if (now.day > 20) {
      options['5'] = '21 ${dateFormat.format(currentMonth)} - Sekarang';
    }

    options['8'] = 'Dinas Luar Selama Tahun ${now.year}';

    options['9'] = 'Ijin Selama Tahun ${now.year}';

    return options;
  }

  Future<void> fetchRiwayat() async {
    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url =
        '${ApiService.baseUrl}/kepegawaian/rekap/${widget.id_user}/$selectedFilter';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        final List<dynamic> show = jsonResponse['show'] ?? [];

        final parsedRiwayat = show
            .whereType<Map<String, dynamic>>()
            .map((item) => RiwayatModel.fromJson(item))
            .toList();

        setState(() {
          isError = false;

          riwayat = parsedRiwayat;

          tepatWaktu = int.tryParse('${jsonResponse['tepatWaktu'] ?? 0}') ?? 0;

          terlambat = int.tryParse('${jsonResponse['terlambat'] ?? 0}') ?? 0;

          absenone = int.tryParse('${jsonResponse['absenOne'] ?? 0}') ?? 0;
        });
      } else {
        debugPrint('Gagal memuat data riwayat: ${response.body}');

        setState(() {
          isError = true;
          riwayat = [];
        });

        _showApiErrorPopup('Periksa koneksi atau hubungi admin.');
      }
    } catch (e) {
      debugPrint('Exception fetchRiwayat: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        isError = true;
      });

      _showApiErrorPopup('Periksa koneksi atau hubungi admin.');
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  void _showApiErrorPopup(String message) {
    if (!mounted) {
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (ctx) {
        final isDark = CupertinoTheme.brightnessOf(ctx) == Brightness.dark;

        return CupertinoAlertDialog(
          title: const Text(
            'Gagal Memuat Data',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text(
                'Tutup',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text(
                'Muat Ulang',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                fetchRiwayat();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekapitulasi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: isDark
                        ? CupertinoColors.white
                        : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Riwayat dan ringkasan absensi Anda',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderIcon(
            isDark: isDark,
            icon: CupertinoIcons.chart_bar_alt_fill,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon({required bool isDark, required IconData icon}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: isDark
            ? CupertinoColors.systemGrey6.withOpacity(0.15)
            : CupertinoColors.white.withOpacity(0.85),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withOpacity(0.08)
              : CupertinoColors.white.withOpacity(0.9),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: 21,
        color: isDark ? CupertinoColors.systemBlue : const Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildInfoHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.arrowtriangle_down_circle_fill,
            size: 15,
            color: isDark
                ? CupertinoColors.systemGrey2
                : CupertinoColors.systemGrey,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Data diurutkan dari absensi terakhir',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? CupertinoColors.systemGrey2
                    : CupertinoColors.systemGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    String title,
    String value,
    Color color, {
    required bool isDark,
    bool loading = false,
  }) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 78),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.white.withOpacity(0.07)
              : CupertinoColors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? CupertinoColors.white.withOpacity(0.07)
                : CupertinoColors.white.withOpacity(0.95),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? CupertinoColors.systemGrey2
                    : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 5),
            if (loading)
              const SizedBox(
                height: 20,
                child: CupertinoActivityIndicator(radius: 9),
              )
            else
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPicker(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        onPressed: _showFilterSheet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.white.withOpacity(0.07)
                : CupertinoColors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isDark
                  ? CupertinoColors.white.withOpacity(0.07)
                  : CupertinoColors.white.withOpacity(0.95),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.systemBlue.withOpacity(0.15)
                      : CupertinoColors.systemBlue.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.calendar,
                  size: 17,
                  color: CupertinoColors.systemBlue,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rentang Waktu',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      filterOptions[selectedFilter] ?? 'Pilih Filter',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? CupertinoColors.white
                            : const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_down,
                size: 16,
                color: isDark
                    ? CupertinoColors.systemGrey2
                    : CupertinoColors.systemGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (sheetContext) {
        return CupertinoActionSheet(
          title: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Pilih Rentang Waktu',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
          actions: [
            ...filterOptions.entries.map((entry) {
              final isSelected = selectedFilter == entry.key;

              return CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();

                  if (selectedFilter == entry.key) {
                    return;
                  }

                  setState(() {
                    selectedFilter = entry.key;
                  });

                  fetchRiwayat();
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        CupertinoIcons.check_mark,
                        size: 18,
                        color: CupertinoColors.systemBlue,
                      ),
                  ],
                ),
              );
            }),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(sheetContext).pop();
            },
            child: const Text(
              'Batal',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
          ),
        );
      },
    );
  }

  String formatTanggal(String? datetime) {
    if (datetime == null || datetime.trim().isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(datetime);

    if (date == null) {
      return datetime;
    }

    return '${_dateFormatter.format(date)} WIB';
  }

  String _getStatusLabel(RiwayatModel item) {
    if (item.jenis == 1 && item.terlambat == 0 && item.tglOut != null) {
      return 'Tepat Waktu';
    }

    if (item.jenis == 1 && item.terlambat > 0) {
      return 'Terlambat';
    }

    if (item.jenis == 1 && item.tglOut == null) {
      return 'Absen 1x';
    }

    if (item.jenis == 4) {
      return 'Dinas Luar';
    }

    return 'Ijin / Tidak Masuk';
  }

  IconData _getStatusIcon(RiwayatModel item) {
    if (item.jenis == 1 && item.terlambat == 0 && item.tglOut != null) {
      return CupertinoIcons.check_mark_circled_solid;
    }

    if (item.jenis == 1 && item.terlambat > 0) {
      return CupertinoIcons.clock_solid;
    }

    if (item.jenis == 1 && item.tglOut == null) {
      return CupertinoIcons.exclamationmark_circle_fill;
    }

    if (item.jenis == 4) {
      return CupertinoIcons.exclamationmark_circle_fill;
    }

    return CupertinoIcons.check_mark_circled_solid;
  }

  Color _getStatusColor(RiwayatModel item) {
    if (item.jenis == 1 && item.terlambat == 0 && item.tglOut != null) {
      return CupertinoColors.activeGreen;
    }

    if (item.jenis == 1 && item.terlambat > 0) {
      return CupertinoColors.systemRed;
    }

    if (item.jenis == 1 && item.tglOut == null) {
      return CupertinoColors.systemOrange;
    }

    if (item.jenis == 4) {
      return CupertinoColors.systemMint;
    }

    return CupertinoColors.systemYellow;
  }

  Widget _buildRiwayatItem(RiwayatModel item, bool isDark) {
    final iconData = _getStatusIcon(item);
    final iconColor = _getStatusColor(item);
    final label = _getStatusLabel(item);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.white.withOpacity(0.07)
            : CupertinoColors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withOpacity(0.07)
              : CupertinoColors.white.withOpacity(0.95),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        minSize: 0,
        borderRadius: BorderRadius.circular(18),
        onPressed: () {
          _openDetail(item);
        },
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(isDark ? 0.14 : 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(iconData, size: 21, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shift ${item.shift} • $label',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatTanggal(item.tglIn),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? CupertinoColors.systemGrey2
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: isDark
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(RiwayatModel item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

        return Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.systemGrey6
                  : CupertinoColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const CupertinoActivityIndicator(radius: 12),
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => DetailRekapAbsensiPage(idAbsensi: item.idAbsensi),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? CupertinoColors.white.withOpacity(0.07)
                    : CupertinoColors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isError
                    ? CupertinoIcons.exclamationmark_triangle
                    : CupertinoIcons.doc_text_search,
                size: 28,
                color: isError
                    ? CupertinoColors.systemRed
                    : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isError
                  ? 'Data Absensi Gagal Ditampilkan'
                  : 'Data Absensi Tidak Ada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? CupertinoColors.systemGrey2
                    : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 5),
            if (isError)
              Text(
                'Silakan coba muat ulang.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CupertinoActivityIndicator(radius: 14));
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF080B12)
          : const Color(0xFFF5F8FF),
      body: Stack(
        children: [
          // =========================================================
          // BACKGROUND
          // =========================================================
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF080B12), Color(0xFF111827)]
                      : const [Color(0xFFF1F6FF), Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // =========================================================
          // MAIN CONTENT
          // =========================================================
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: topPadding),

                // Header
                _buildHeader(isDark),

                // Info
                _buildInfoHeader(isDark),

                // Filter
                _buildFilterPicker(context, isDark),

                const SizedBox(height: 12),

                // ===================================================
                // STATISTIC
                // ===================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildStatBox(
                        'Tepat Waktu',
                        isError ? 'xx' : '${tepatWaktu}x',
                        CupertinoColors.activeGreen,
                        isDark: isDark,
                        loading: isLoading,
                      ),
                      const SizedBox(width: 8),
                      _buildStatBox(
                        'Terlambat',
                        isError ? 'xx' : '${terlambat}x',
                        CupertinoColors.systemRed,
                        isDark: isDark,
                        loading: isLoading,
                      ),
                      const SizedBox(width: 8),
                      _buildStatBox(
                        'Absen 1x',
                        isError ? 'xx' : '${absenone}x',
                        CupertinoColors.systemOrange,
                        isDark: isDark,
                        loading: isLoading,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ===================================================
                // LIST
                // ===================================================
                Expanded(
                  child: isLoading
                      ? _buildLoadingState()
                      : riwayat.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.separated(
                          controller: _scrollController,

                          // Tambahan bottom padding
                          // agar tidak tertutup
                          // FloatingLiquidNavigationBar.
                          padding: const EdgeInsets.fromLTRB(20, 2, 20, 125),

                          physics: const BouncingScrollPhysics(),

                          itemCount: riwayat.length,

                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 9),

                          itemBuilder: (context, index) {
                            return _buildRiwayatItem(riwayat[index], isDark);
                          },
                        ),
                ),
              ],
            ),
          ),

          // =========================================================
          // BACK TO TOP
          // =========================================================
          if (showBackToTopButton)
            Positioned(
              right: 20,
              bottom: 98,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: _scrollToTop,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.systemGrey.withOpacity(0.85)
                        : CupertinoColors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.white.withOpacity(0.08)
                          : CupertinoColors.white,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_up,
                    size: 19,
                    color: isDark
                        ? CupertinoColors.white
                        : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
