import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/api_service.dart';
import 'rekap_detail_page.dart';

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
  String selectedFilter = '1';
  List<RiwayatModel> riwayat = [];
  int tepatWaktu = 0;
  int terlambat = 0;
  int absenone = 0;

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
  }

  Future<void> fetchRiwayat() async {
    final url =
        '${ApiService.baseUrl}/kepegawaian/rekap/${widget.id_user}/$selectedFilter';
    try {
      final response = await http.get(Uri.parse(url));
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
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (BuildContext context) => CupertinoActionSheet(
              title: const Text('Pilih Rentang Waktu'),
              actions: filterOptions.entries.map((entry) {
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
                      Text(entry.value),
                      if (selectedFilter == entry.key)
                        const Icon(CupertinoIcons.check_mark, size: 18),
                    ],
                  ),
                );
              }).toList(),
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                isDefaultAction: true,
                child: const Text('Batal'),
              ),
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
                style: const TextStyle(
                  color: CupertinoColors.black,
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Rekapitulasi Absensi'),
      ),
      child: SafeArea(
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatBox(
                    "Tepat Waktu",
                    "${tepatWaktu}x",
                    CupertinoColors.activeGreen,
                  ),
                  const SizedBox(width: 8),
                  _buildStatBox(
                    "Terlambat",
                    "${terlambat}x",
                    CupertinoColors.systemRed,
                  ),
                  const SizedBox(width: 8),
                  _buildStatBox(
                    "Absen 1x",
                    "${absenone}x",
                    CupertinoColors.systemOrange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: (riwayat?.isEmpty ?? true)
                  ? const Center(
                      child: Text(
                        "Data Absensi tidak ada",
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: riwayat.length,
                      padding: const EdgeInsets.all(16),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = riwayat[index];
                        return CupertinoButton(
                          padding: const EdgeInsets.all(12),
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () async {
                            showCupertinoDialog(
                              context: context,
                              builder: (_) => const CupertinoAlertDialog(
                                content: CupertinoActivityIndicator(),
                              ),
                            );
                            await Future.delayed(Duration(milliseconds: 300));
                            Navigator.pop(context); // close dialog
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => DetailRekapAbsensiPage(
                                  idAbsensi: item.idAbsensi,
                                ),
                              ),
                            );
                          },

                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.sun_max,
                                color: CupertinoColors.systemBlue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          if (item.jenis == 1) ...[
                                            TextSpan(
                                              text: "Shift ${item.shift} ",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Color(0xFF2E2E2E),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (item.terlambat == 1 &&
                                                item.tglOut != null)
                                              const TextSpan(
                                                text: "(Terlambat)",
                                                style: TextStyle(
                                                  color:
                                                      CupertinoColors.systemRed,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                            else if (item.tglOut == null)
                                              const TextSpan(
                                                text: "(Absen 1x)",
                                                style: TextStyle(
                                                  color: CupertinoColors
                                                      .systemYellow,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                            else if (item.terlambat == 0 &&
                                                item.tglIn != null &&
                                                item.tglOut != null)
                                              const TextSpan(
                                                text: "(Tepat Waktu)",
                                                style: TextStyle(
                                                  color: CupertinoColors
                                                      .activeGreen,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ] else if (item.jenis == 3) ...[
                                            const TextSpan(
                                              text: "Ijin / Tidak Masuk",
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Color(0xFF2E2E2E),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatTanggal(item.tglIn) ?? '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_forward,
                                color: Color(0xFF2E2E2E),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
