import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DataModel {
  final String label;
  final int value;
  DataModel(this.label, this.value);
}

class RiwayatModel {
  final IconData icon;
  final String shift;
  final String waktu;
  final int jenis;
  final String? tglIn;
  final String? tglOut;
  final int terlambat;

  RiwayatModel({
    required this.icon,
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

  final Map<String, String> filterOptions = {
    '1': '1 Minggu Terakhir',
    '2': '2 Minggu Terakhir',
    '3': '21 Mei - 20 Juni',
    '4': '21 Juni - 20 Juli',
    '5': '21 Juli - Sekarang',
    '6': '3 Bulan Terakhir',
    '7': 'Tahun 2025',
  };

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  Future<void> fetchRiwayat() async {
    final url =
        'http://192.168.254.80:8000/api/kepegawaian/rekap/${widget.id_user}/$selectedFilter';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> show = jsonResponse['show'] ?? [];

        setState(() {
          riwayat = show.map((item) => RiwayatModel.fromJson(item)).toList();
          tepatWaktu = jsonResponse['tepatWaktu'] ?? 0;
          terlambat = jsonResponse['terlambat'] ?? 0;
          absenone = jsonResponse['absenone'] ?? 0;
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
                      fetchRiwayat();
                    });
                  },
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: selectedFilter == entry.key
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
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
                filterOptions[selectedFilter]!,
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
        middle: Text('Rekap Absensi'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 200,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  primaryYAxis: NumericAxis(),
                  series: <CartesianSeries>[
                    ColumnSeries<DataModel, String>(
                      dataSource: chartData,
                      xValueMapper: (d, _) => d.label,
                      yValueMapper: (d, _) => d.value,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                    CupertinoColors.systemOrange,
                  ),
                  const SizedBox(width: 8),
                  _buildStatBox(
                    "Absen",
                    "${absenone}x",
                    CupertinoColors.systemRed,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: riwayat.length,
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = riwayat[index];
                  return CupertinoButton(
                    padding: const EdgeInsets.all(12),
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () {},
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
                                            color: CupertinoColors.systemRed,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else if (item.tglOut == null)
                                        const TextSpan(
                                          text: "(Absen 1x)",
                                          style: TextStyle(
                                            color: CupertinoColors.systemYellow,
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
                                            color: CupertinoColors.activeBlue,
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
