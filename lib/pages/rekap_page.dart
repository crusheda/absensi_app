import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, showDialog;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/api_service.dart';
import 'rekap_detail_page.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

class DataModel {
  final String label;
  final int value;
  DataModel(this.label, this.value);
}

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
      idAbsensi: json['id'] ?? '-',
      shift: json['nm_shift'] ?? '-',
      waktu: json['tgl_in'] ?? '-',
      jenis: json['jenis'] ?? 0,
      tglIn: json['tgl_in'],
      tglOut: json['tgl_out'],
      terlambat: json['terlambat'] ?? 0,
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
  bool isLoading = true;
  String selectedFilter = '1';
  List<RiwayatModel> riwayat = [];
  int tepatWaktu = 0;
  int terlambat = 0;
  int absenone = 0;
  late ScrollController _scrollController;
  bool showBackToTopButton = false;

  final List<DataModel> chartData = [
    DataModel('Mei', 5),
    DataModel('Juni', 4),
    DataModel('Juli', 6),
  ];

  late Map<String, String> filterOptions;

  Map<String, String> getFilterOptions() {
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM yyyy', 'id');

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

    // Jika tanggal sekarang > 20, tambahkan opsi "21 Bulan Ini - Sekarang"
    if (now.day > 20) {
      options['5'] = '21 ${dateFormat.format(currentMonth)} - Sekarang';
    }

    return options;
  }

  @override
  void initState() {
    super.initState();
    filterOptions = getFilterOptions();
    fetchRiwayat();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.offset >= 400 && !showBackToTopButton) {
          setState(() => showBackToTopButton = true);
        } else if (_scrollController.offset < 400 && showBackToTopButton) {
          setState(() => showBackToTopButton = false);
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showApiErrorPopup(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Gagal Memuat Data"),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Tutup"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Muat Ulang"),
            onPressed: () {
              Navigator.of(ctx).pop();
              fetchRiwayat();
            },
          ),
        ],
      ),
    );
  }

  Future<void> fetchRiwayat() async {
    setState(() => isLoading = true);

    final url =
        '${ApiService.baseUrl}/kepegawaian/rekap/${widget.id_user}/$selectedFilter';
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> show = jsonResponse['show'] ?? [];

        setState(() {
          riwayat = show.map((item) => RiwayatModel.fromJson(item)).toList();
          tepatWaktu = jsonResponse['tepatWaktu'] ?? 0;
          terlambat = jsonResponse['terlambat'] ?? 0;
          absenone = jsonResponse['absenOne'] ?? 0;
        });
      } else {
        print("Gagal memuat data riwayat: ${response.body}");
        _showApiErrorPopup("Periksa koneksi atau hubungi admin.");
      }
    } catch (e) {
      print("Exception: $e");
    } finally {
      setState(() => isLoading = false);
      // _showApiErrorPopup("Periksa koneksi atau hubungi admin.");
    }
  }

  Widget _buildStatBox(
    String title,
    String value,
    Color color, {
    bool loading = false,
  }) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.secondaryLabel
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? CupertinoColors.black
                  : CupertinoColors.systemGrey4,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? CupertinoColors.systemGrey4
                    : CupertinoColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            loading
                ? const CupertinoActivityIndicator(radius: 10)
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPicker(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: isDark ? CupertinoColors.systemGrey6 : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (BuildContext context) => CupertinoActionSheet(
              title: DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? CupertinoColors.white
                      : CupertinoColors.darkBackgroundGray,
                ),
                child: Text('Pilih Rentang Waktu', textAlign: TextAlign.center),
              ),
              actions: [
                ...filterOptions.entries.map((entry) {
                  return CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        selectedFilter = entry.key;
                      });
                      fetchRiwayat();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.value, style: TextStyle()),
                        if (selectedFilter == entry.key)
                          const Icon(CupertinoIcons.check_mark, size: 18),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12), // Spacer ke atas agar tidak mentok
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context),
                  isDefaultAction: true,
                  child: const Text('Batal'),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                filterOptions[selectedFilter] ?? 'Pilih Filter',
                style: TextStyle(
                  color: CupertinoTheme.brightnessOf(context) == Brightness.dark
                      ? CupertinoColors.systemGrey2
                      : CupertinoColors.systemGrey,
                  fontSize: 15,
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_down,
                color: CupertinoColors.systemGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatTanggal(String? datetime) {
    if (datetime == null) return '-';

    final date = DateTime.tryParse(datetime);
    if (date == null) return datetime;

    initializeDateFormatting('id'); // Pastikan dipanggil sekali saat init

    final formatter = DateFormat("EEEE, dd MMMM yyyy HH:mm", "id");
    return "${formatter.format(date)} WIB";
  }

  @override
  Widget build(BuildContext context) {
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

          // ✅ NAVBAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CupertinoNavigationBar(
              middle: Text(
                'Rekapitulasi Absensi',
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

          // ✅ CONTENT
          Positioned.fill(
            top: 44 + MediaQuery.of(context).padding.top, // tinggi navbar
            child: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: const [
                      Icon(
                        CupertinoIcons.arrowtriangle_down_circle,
                        size: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Data diurutkan dari absensi terakhir",
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildFilterPicker(context),
                const SizedBox(height: 12),

                // ✅ Box Statistik
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatBox(
                        "Tepat Waktu",
                        "${tepatWaktu}x",
                        CupertinoColors.activeGreen,
                        loading: isLoading,
                      ),
                      const SizedBox(width: 8),
                      _buildStatBox(
                        "Terlambat",
                        "${terlambat}x",
                        CupertinoColors.systemRed,
                        loading: isLoading,
                      ),
                      const SizedBox(width: 8),
                      _buildStatBox(
                        "Absen 1x",
                        "${absenone}x",
                        CupertinoColors.systemOrange,
                        loading: isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ List atau Loading
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CupertinoActivityIndicator(radius: 14),
                        )
                      : (riwayat.isEmpty
                            ? Center(
                                child: Text(
                                  "Data Absensi tidak ada",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? CupertinoColors.systemGrey4
                                        : CupertinoColors.systemGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: _scrollController,
                                itemCount: riwayat.length,
                                padding: const EdgeInsets.all(16),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = riwayat[index];

                                  IconData iconData;
                                  Color iconColor;
                                  String label;

                                  if (item.jenis == 1 &&
                                      item.terlambat == 0 &&
                                      item.tglOut != null) {
                                    iconData =
                                        CupertinoIcons.check_mark_circled_solid;
                                    iconColor = CupertinoColors.activeGreen;
                                    label = "Tepat Waktu";
                                  } else if (item.jenis == 1 &&
                                      item.terlambat > 0) {
                                    iconData = CupertinoIcons.clock_solid;
                                    iconColor = CupertinoColors.systemRed;
                                    label = "Terlambat";
                                  } else if (item.jenis == 1 &&
                                      item.tglOut == null) {
                                    iconData = CupertinoIcons
                                        .exclamationmark_circle_fill;
                                    iconColor = CupertinoColors.systemOrange;
                                    label = "Absen 1x";
                                  } else {
                                    iconData =
                                        CupertinoIcons.check_mark_circled_solid;
                                    iconColor = CupertinoColors.systemYellow;
                                    label = "Ijin / Tidak Masuk";
                                  }

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? CupertinoColors.secondaryLabel
                                          : CupertinoColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDark
                                              ? CupertinoColors.black
                                              : CupertinoColors.systemGrey4,
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.all(12),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isDark
                                          ? CupertinoColors.transparent
                                          : CupertinoColors.white,
                                      onPressed: () async {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) => Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? CupertinoColors
                                                          .secondaryLabel
                                                    : CupertinoColors
                                                          .systemGrey6,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isDark
                                                        ? CupertinoColors.black
                                                        : CupertinoColors
                                                              .systemGrey,
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              width: 70,
                                              height: 70,
                                              child:
                                                  const CupertinoActivityIndicator(
                                                    radius: 12,
                                                  ),
                                            ),
                                          ),
                                        );

                                        await Future.delayed(
                                          const Duration(milliseconds: 500),
                                        );

                                        if (context.mounted)
                                          Navigator.pop(context);

                                        Navigator.of(context).push(
                                          CupertinoPageRoute(
                                            builder: (context) =>
                                                DetailRekapAbsensiPage(
                                                  idAbsensi: item.idAbsensi,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          Icon(iconData, color: iconColor),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Shift ${item.shift} • $label",
                                                  style: TextStyle(
                                                    color: iconColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  formatTanggal(item.tglIn),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark
                                                        ? CupertinoColors
                                                              .systemGrey4
                                                        : CupertinoColors
                                                              .systemGrey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            CupertinoIcons.chevron_forward,
                                            color: isDark
                                                ? CupertinoColors.systemGrey4
                                                : Color(0xFF2E2E2E),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )),
                ),
              ],
            ),
          ),

          // ✅ Tombol ke atas jika scroll panjang
          if (showBackToTopButton)
            Positioned(
              bottom: 24,
              right: 24,
              child: CupertinoButton(
                padding: const EdgeInsets.all(10),
                color: CupertinoColors.systemGrey,
                borderRadius: BorderRadius.circular(30),
                child: const Icon(
                  CupertinoIcons.arrow_up,
                  color: CupertinoColors.white,
                ),
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // 🔹 Helper untuk membuat blur circle
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
