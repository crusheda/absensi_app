import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import 'fullscreen_image_viewer.dart';
import 'package:shimmer/shimmer.dart';

class DetailRekapAbsensiPage extends StatefulWidget {
  final int idAbsensi;
  const DetailRekapAbsensiPage({super.key, required this.idAbsensi});

  @override
  State<DetailRekapAbsensiPage> createState() => _DetailRekapAbsensiPageState();
}

class _DetailRekapAbsensiPageState extends State<DetailRekapAbsensiPage> {
  Map<String, dynamic>? absensiDetail;
  bool isLoading = true;

  String _getJenisLabel(String jenis) {
    switch (jenis) {
      case '1':
        return 'Masuk Jaga Shift';
      case '2':
        return 'Tidak Diketahui!';
      case '3':
        return 'Ijin/Tidak Masuk';
      default:
        return 'Tidak Diketahui!';
    }
  }

  Color _getJenisColor(String jenis) {
    switch (jenis) {
      case '1':
        return CupertinoColors.systemIndigo;
      case '2':
        return CupertinoColors.activeGreen;
      case '3':
        return CupertinoColors.activeOrange;
      default:
        return CupertinoColors.systemGrey;
    }
  }

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

  Widget _buildIdBadge(int id) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 87, 87, 87),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'ID#$id',
        style: const TextStyle(
          decoration: TextDecoration.none,
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.systemGrey4,
        ),
      ),
    );
  }

  Widget _buildJenisBadge(String jenis) {
    final label = _getJenisLabel(jenis);
    final color = _getJenisColor(jenis);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          decoration: TextDecoration.none,
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLeafletMap(String latlong) {
    if (latlong.isEmpty || !latlong.contains(',')) {
      return const Icon(CupertinoIcons.map);
    }
    final parts = latlong.split(',');
    final lat = double.tryParse(parts[0].trim()) ?? 0.0;
    final lon = double.tryParse(parts[1].trim()) ?? 0.0;

    return SizedBox(
      height: 150,
      child: FlutterMap(
        options: MapOptions(center: LatLng(lat, lon), zoom: 15.0),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=IB6iMrip0bVW8LFGT5Hs',
            userAgentPackageName: 'com.sakudewa.absensi',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(lat, lon),
                width: 40,
                height: 40,
                child: const Icon(
                  CupertinoIcons.location_solid,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoBox({
    required String latlong,
    required String title,
    String? shift,
    required String date,
    required String time,
    required int jenis,
    String? infoTitle1,
    String? infoValue1,
    String? infoTitle2,
    String? infoValue2,
    String? lemburTitle,
    String? lemburValue,
    Color titleColor = CupertinoColors.black,
  }) {
    print('jenis: ${absensiDetail!['jenis']}');
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.tertiaryLabel
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildLeafletMap(latlong),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),

                if (shift != null && shift.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.bell, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shift,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? CupertinoColors.systemGrey4
                                : CupertinoColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(CupertinoIcons.calendar, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        date,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? CupertinoColors.systemGrey4
                              : CupertinoColors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(CupertinoIcons.time, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Pukul $time WIB",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? CupertinoColors.systemGrey4
                              : CupertinoColors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                if (infoValue1 != null && infoValue1.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.timer, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: "$infoTitle1 ",
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? CupertinoColors.systemGrey4
                                  : CupertinoColors.black,
                            ),
                            children: [
                              TextSpan(
                                text: infoValue1,
                                style: const TextStyle(
                                  decoration: TextDecoration.none,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (infoValue2 != null && infoValue2.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.stopwatch, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: "$infoTitle2 ",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                              color: isDark
                                  ? CupertinoColors.systemGrey4
                                  : CupertinoColors.black,
                            ),
                            children: [
                              TextSpan(
                                text: infoValue2,
                                style: const TextStyle(
                                  decoration: TextDecoration.none,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (lemburValue != null && lemburValue.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.metronome, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: "$lemburTitle ",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                              color: isDark
                                  ? CupertinoColors.systemGrey4
                                  : CupertinoColors.black,
                            ),
                            children: [
                              TextSpan(
                                text: lemburValue,
                                style: const TextStyle(
                                  decoration: TextDecoration.none,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeteranganBox(String keterangan) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.tertiaryLabel
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Keterangan Absensi :",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
              color: isDark
                  ? CupertinoColors.systemGrey4
                  : CupertinoColors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            keterangan.isNotEmpty ? keterangan : "-",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              decoration: TextDecoration.none,
              color: isDark
                  ? CupertinoColors.systemGrey4
                  : CupertinoColors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPhotoBox(String label, String? imageUrl, int index) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Column(
      children: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min, // agar tidak full width
            children: [
              const Icon(
                CupertinoIcons.camera,
                size: 18,
                color: CupertinoColors.black,
              ),
              const SizedBox(width: 6), // jarak antara ikon dan teks
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            final List<String> imageUrls = [
              absensiDetail!['foto_in'] ?? '',
              absensiDetail!['foto_out'] ?? '',
            ];

            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => FullscreenImageViewer(
                  imageUrls: imageUrls,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl ?? '',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return child;
                } else {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Shimmer.fromColors(
                        baseColor: CupertinoColors.systemGrey4,
                        highlightColor: CupertinoColors.systemGrey6,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          color: CupertinoColors.systemGrey4,
                        ),
                      ),
                      const Text(
                        "Memuat Foto...",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  );
                }
              },
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(CupertinoIcons.photo),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Detail Absensi',
          style: TextStyle(
            color: CupertinoTheme.brightnessOf(context) == Brightness.dark
                ? CupertinoColors.white
                : CupertinoColors.black,
          ),
        ),
        previousPageTitle: 'Kembali',
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : absensiDetail == null
            ? const Center(child: Text('Gagal memuat data'))
            : Column(
                children: [
                  // BADGE DI ATAS
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIdBadge(absensiDetail!['id'] ?? 0),
                        const SizedBox(width: 8),
                        _buildJenisBadge(absensiDetail!['jenis'].toString()),
                      ],
                    ),
                  ),
                  // ISI KONTEN (dibungkus Expanded agar scrollable)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: ListView(
                        children: [
                          _buildCupertinoBox(
                            latlong: absensiDetail!['latlong_in'] ?? '',
                            title: "Berangkat",
                            shift: "Jaga ${absensiDetail!['shift'] ?? ''}",
                            date: absensiDetail!['tgl_in'] ?? '-',
                            time: absensiDetail!['jam_in'] ?? '-',
                            infoTitle1: "Keterlambatan:\n",
                            infoValue1: absensiDetail!['terlambat'] ?? '-',
                            titleColor: CupertinoColors.activeGreen,
                            jenis: absensiDetail!['jenis'] ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildCupertinoBox(
                            latlong: absensiDetail!['latlong_out'] ?? '',
                            title: "Pulang",
                            date: absensiDetail!['tgl_out'] ?? '-',
                            time: absensiDetail!['jam_out'] ?? '-',
                            titleColor: CupertinoColors.destructiveRed,
                            jenis: absensiDetail!['jenis'] ?? '',
                            infoTitle2: "Bekerja selama:\n",
                            infoValue2: absensiDetail!['durasi_kerja'] ?? '-',
                            lemburTitle: "Lembur selama:\n",
                            lemburValue: absensiDetail!['lembur'] ?? '',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMiniPhotoBox(
                                  "Foto Berangkat",
                                  absensiDetail!['foto_in'],
                                  0,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMiniPhotoBox(
                                  "Foto Pulang",
                                  absensiDetail!['foto_out'],
                                  1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildKeteranganBox(
                            absensiDetail!['keterangan'] ?? '',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
