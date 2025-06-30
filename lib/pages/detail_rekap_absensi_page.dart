import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'dart:convert';

class DetailRekapAbsensiPage extends StatefulWidget {
  final int idAbsensi;
  const DetailRekapAbsensiPage({super.key, required this.idAbsensi});

  @override
  State<DetailRekapAbsensiPage> createState() => _DetailRekapAbsensiPageState();
}

class _DetailRekapAbsensiPageState extends State<DetailRekapAbsensiPage> {
  Map<String, dynamic>? absensiDetail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    final url = Uri.parse(
      '${ApiService.baseUrl}/absensi/detail/${widget.idAbsensi}',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        absensiDetail = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildMapCard(
    String title,
    String date,
    String time,
    String imageUrl, {
    String? label,
    Color? labelColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(CupertinoIcons.calendar, size: 16),
            const SizedBox(width: 4),
            Text(date),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const Icon(CupertinoIcons.time, size: 16),
            const SizedBox(width: 4),
            Text("Pukul $time"),
          ],
        ),
        if (label != null && labelColor != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              label,
              style: TextStyle(color: labelColor, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Detail Absensi'),
        previousPageTitle: 'Rekap',
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : absensiDetail == null
            ? const Center(child: Text('Gagal memuat data'))
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Absensi ID#${absensiDetail!['id']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            absensiDetail!['status'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status : ${absensiDetail!['shift']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Absen Masuk
                    _buildMapCard(
                      'Absen Berangkat',
                      absensiDetail!['tgl_in'],
                      absensiDetail!['jam_in'],
                      absensiDetail!['map_in_url'],
                      label: "Keterlambatan : ${absensiDetail!['terlambat']}",
                      labelColor: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(height: 16),

                    // Absen Pulang
                    _buildMapCard(
                      'Absen Pulang',
                      absensiDetail!['tgl_out'],
                      absensiDetail!['jam_out'],
                      absensiDetail!['map_out_url'],
                      label:
                          "Bekerja selama : ${absensiDetail!['durasi_kerja']}\nLembur selama : ${absensiDetail!['lembur']}",
                      labelColor: CupertinoColors.systemRed,
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      "Keterangan",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      absensiDetail!['keterangan'] ?? '-',
                      style: const TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
