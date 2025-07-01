import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import 'fullscreen_image_viewer.dart';

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
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // ✅ no subdomains
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
    required String date,
    required String time,
    required String info,
    Color titleColor = CupertinoColors.black,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
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
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(CupertinoIcons.calendar, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        date,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.black,
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
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.black,
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
                        "$info WIB",
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPhotoBox(String label, String? imageUrl, int index) {
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
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.black,
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Detail Absensi'),
        previousPageTitle: 'Kembali',
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
                    _buildCupertinoBox(
                      latlong: absensiDetail!['latlong_in'] ?? '',
                      title: "Berangkat",
                      date: absensiDetail!['tgl_in'] ?? '-',
                      time: absensiDetail!['jam_in'] ?? '-',
                      info:
                          "Keterlambatan: \n${absensiDetail!['terlambat'] ?? '-'}",
                      titleColor: CupertinoColors.activeGreen,
                    ),
                    const SizedBox(height: 16),
                    _buildCupertinoBox(
                      latlong: absensiDetail!['latlong_out'] ?? '',
                      title: "Pulang",
                      date: absensiDetail!['tgl_out'] ?? '-',
                      time: absensiDetail!['jam_out'] ?? '-',
                      info:
                          "Bekerja selama: \n${absensiDetail!['durasi_kerja'] ?? '-'}",
                      titleColor: CupertinoColors.destructiveRed,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniPhotoBox(
                            "Absensi Berangkat",
                            absensiDetail!['foto_in'],
                            0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniPhotoBox(
                            "Absensi Pulang",
                            absensiDetail!['foto_out'],
                            1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
