import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';

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
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  // ============================================================
  // JENIS ABSENSI
  // ============================================================

  String _getJenisLabel(String jenis) {
    switch (jenis) {
      case '1':
        return 'Masuk Jaga Shift';

      case '2':
        return 'Tidak Diketahui!';

      case '3':
        return 'Ijin / Tidak Masuk';

      case '4':
        return 'Dinas Luar';

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
        return CupertinoColors.systemOrange;

      case '4':
        return CupertinoColors.systemMint;

      default:
        return CupertinoColors.systemGrey;
    }
  }

  // ============================================================
  // FETCH DETAIL
  // ============================================================

  Future<void> fetchDetail() async {
    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
      isError = false;
    });

    final url = Uri.parse(
      '${ApiService.baseUrl}/absensi/detail/${widget.idAbsensi}',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is Map<String, dynamic>) {
          setState(() {
            absensiDetail = decoded;
            isLoading = false;
            isError = false;
          });
        } else {
          setState(() {
            absensiDetail = null;
            isLoading = false;
            isError = true;
          });
        }
      } else {
        setState(() {
          absensiDetail = null;
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Exception fetchDetail: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        absensiDetail = null;
        isLoading = false;
        isError = true;
      });
    }
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? CupertinoColors.white.withOpacity(0.07)
                    : CupertinoColors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? CupertinoColors.white.withOpacity(0.07)
                      : CupertinoColors.white.withOpacity(0.95),
                ),
              ),
              child: Icon(
                CupertinoIcons.chevron_left,
                size: 20,
                color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Absensi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: isDark
                        ? CupertinoColors.white
                        : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Informasi lengkap riwayat absensi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _buildIdBadge(dynamic id, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.white.withOpacity(0.07)
            : CupertinoColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withOpacity(0.07)
              : CupertinoColors.white.withOpacity(0.95),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.number,
            size: 13,
            color: isDark
                ? CupertinoColors.systemGrey2
                : CupertinoColors.systemGrey,
          ),
          const SizedBox(width: 5),
          Text(
            'ID#$id',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? CupertinoColors.systemGrey2
                  : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJenisBadge(String jenis, bool isDark) {
    final color = _getJenisColor(jenis);
    final label = _getJenisLabel(jenis);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.check_mark_circled_solid, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildLeafletMap(String latlong, bool isDark) {
    if (latlong.isEmpty || !latlong.contains(',')) {
      return Container(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        child: Center(
          child: Icon(
            CupertinoIcons.map,
            size: 28,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
          ),
        ),
      );
    }

    final parts = latlong.split(',');

    if (parts.length < 2) {
      return Container(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        child: const Center(child: Icon(CupertinoIcons.map)),
      );
    }

    final lat = double.tryParse(parts[0].trim());

    final lon = double.tryParse(parts[1].trim());

    if (lat == null || lon == null) {
      return Container(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        child: const Center(child: Icon(CupertinoIcons.map)),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(lat, lon),
        initialZoom: 17,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
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
              width: 42,
              height: 42,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.systemRed.withOpacity(0.14),
                ),
                child: const Icon(
                  CupertinoIcons.location_solid,
                  color: CupertinoColors.systemRed,
                  size: 27,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    final effectiveIconColor =
        iconColor ??
        (isDark ? CupertinoColors.systemGrey2 : CupertinoColors.systemGrey);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: effectiveIconColor.withOpacity(isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: effectiveIconColor),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? CupertinoColors.systemGrey2
                      : CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value.isEmpty ? '-' : value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? CupertinoColors.white
                      : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ATTENDANCE CARD
  // ============================================================

  Widget _buildAttendanceCard({
    required bool isDark,
    required String title,
    required String latlong,
    required String date,
    required String time,
    String? shift,
    String? infoTitle1,
    String? infoValue1,
    String? infoTitle2,
    String? infoValue2,
    String? lemburTitle,
    String? lemburValue,
    required Color accentColor,
  }) {
    final hasInfo1 = infoValue1 != null && infoValue1.trim().isNotEmpty;

    final hasInfo2 = infoValue2 != null && infoValue2.trim().isNotEmpty;

    final hasLembur = lemburValue != null && lemburValue.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.white.withOpacity(0.065)
            : CupertinoColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withOpacity(0.07)
              : CupertinoColors.white.withOpacity(0.95),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // TITLE
            // ----------------------------------------------------
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(isDark ? 0.15 : 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    title == 'Berangkat'
                        ? CupertinoIcons.arrow_up_right
                        : CupertinoIcons.arrow_down_left,
                    size: 19,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      if (shift != null && shift.trim().isNotEmpty)
                        Text(
                          shift,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? CupertinoColors.systemGrey2
                                : CupertinoColors.systemGrey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            // ----------------------------------------------------
            // MAP
            // ----------------------------------------------------
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                height: 175,
                width: double.infinity,
                child: _buildLeafletMap(latlong, isDark),
              ),
            ),

            const SizedBox(height: 13),

            // ----------------------------------------------------
            // DATE & TIME
            // ----------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    isDark: isDark,
                    icon: CupertinoIcons.calendar,
                    label: 'Tanggal',
                    value: date,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoRow(
                    isDark: isDark,
                    icon: CupertinoIcons.time,
                    label: 'Waktu',
                    value: '$time WIB',
                    iconColor: accentColor,
                  ),
                ),
              ],
            ),

            // ----------------------------------------------------
            // INFO 1
            // ----------------------------------------------------
            if (hasInfo1) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                isDark: isDark,
                icon: CupertinoIcons.timer,
                label: infoTitle1!.replaceAll('\n', ''),
                value: infoValue1!,
              ),
            ],

            // ----------------------------------------------------
            // INFO 2
            // ----------------------------------------------------
            if (hasInfo2) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                isDark: isDark,
                icon: CupertinoIcons.stopwatch,
                label: infoTitle2!.replaceAll('\n', ''),
                value: infoValue2!,
              ),
            ],

            // ----------------------------------------------------
            // LEMBUR
            // ----------------------------------------------------
            if (hasLembur) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                isDark: isDark,
                icon: CupertinoIcons.clock,
                label: lemburTitle!.replaceAll('\n', ''),
                value: lemburValue!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PHOTO
  // ============================================================

  Widget _buildMiniPhotoBox({
    required String label,
    required String? imageUrl,
    required int index,
    required bool isDark,
  }) {
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.white.withOpacity(0.065)
            : CupertinoColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withOpacity(0.07)
              : CupertinoColors.white.withOpacity(0.95),
        ),
      ),
      padding: const EdgeInsets.all(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.camera,
                  size: 14,
                  color: isDark
                      ? CupertinoColors.systemGrey2
                      : CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: hasImage
                ? () {
                    final imageUrls = <String>[
                      absensiDetail!['foto_in']?.toString() ?? '',
                      absensiDetail!['foto_out']?.toString() ?? '',
                    ];

                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => FullscreenImageViewer(
                          imageUrls: imageUrls,
                          initialIndex: index,
                        ),
                      ),
                    );
                  }
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                height: 145,
                width: double.infinity,
                child: hasImage
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded || frame != null) {
                                return child;
                              }

                              return _buildPhotoLoading(isDark);
                            },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPhotoError(isDark);
                        },
                      )
                    : _buildPhotoEmpty(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoLoading(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF252B36) : const Color(0xFFE5E7EB),
      highlightColor: isDark
          ? const Color(0xFF343B48)
          : const Color(0xFFF9FAFB),
      child: Container(color: CupertinoColors.systemGrey5),
    );
  }

  Widget _buildPhotoError(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.photo,
              size: 27,
              color: isDark
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
            const SizedBox(height: 5),
            Text(
              'Foto tidak dapat dimuat',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                color: isDark
                    ? CupertinoColors.systemGrey2
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoEmpty(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.photo,
              size: 27,
              color: isDark
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
            const SizedBox(height: 5),
            Text(
              'Tidak ada foto',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                color: isDark
                    ? CupertinoColors.systemGrey2
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // KETERANGAN
  // ============================================================

  Widget _buildKeteranganBox(String keterangan, bool isDark) {
    final value = keterangan.trim().isEmpty ? '-' : keterangan.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.white.withOpacity(0.065)
            : CupertinoColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withOpacity(0.07)
              : CupertinoColors.white.withOpacity(0.95),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.systemBlue.withOpacity(0.12)
                  : CupertinoColors.systemBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              CupertinoIcons.doc_text,
              size: 16,
              color: CupertinoColors.systemBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keterangan Absensi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? CupertinoColors.white
                        : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    height: 1.45,
                    color: isDark
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withOpacity(
                  isDark ? 0.14 : 0.08,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 30,
                color: CupertinoColors.systemRed,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Gagal Memuat Detail',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Periksa koneksi internet Anda kemudian coba kembali.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: isDark
                    ? CupertinoColors.systemGrey2
                    : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 18),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              color: CupertinoColors.systemBlue,
              borderRadius: BorderRadius.circular(13),
              onPressed: fetchDetail,
              child: const Text(
                'Muat Ulang',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 14),
          const SizedBox(height: 10),
          Text(
            'Memuat detail absensi...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              color: isDark
                  ? CupertinoColors.systemGrey2
                  : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? const Color(0xFF080B12)
          : const Color(0xFFF5F8FF),
      child: Stack(
        children: [
          // ========================================================
          // BACKGROUND
          // ========================================================
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

          // ========================================================
          // CONTENT
          // ========================================================
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: isLoading
                  ? _buildLoadingState(isDark)
                  : isError || absensiDetail == null
                  ? _buildErrorState(isDark)
                  : Column(
                      children: [
                        // Header
                        _buildHeader(isDark),

                        // Badge
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Row(
                            children: [
                              _buildIdBadge(absensiDetail!['id'], isDark),
                              const SizedBox(width: 7),
                              Flexible(
                                child: _buildJenisBadge(
                                  absensiDetail!['jenis']?.toString() ?? '',
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Scroll content
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 2, 20, 35),
                            children: [
                              // ==================================================
                              // BERANGKAT
                              // ==================================================
                              _buildAttendanceCard(
                                isDark: isDark,
                                title: 'Berangkat',
                                latlong:
                                    absensiDetail!['latlong_in']?.toString() ??
                                    '',
                                shift: 'Jaga ${absensiDetail!['shift'] ?? ''}',
                                date:
                                    absensiDetail!['tgl_in']?.toString() ?? '-',
                                time:
                                    absensiDetail!['jam_in']?.toString() ?? '-',
                                infoTitle1: 'Keterlambatan',
                                infoValue1:
                                    absensiDetail!['terlambat']?.toString() ??
                                    '-',
                                accentColor: CupertinoColors.activeGreen,
                              ),

                              const SizedBox(height: 12),

                              // ==================================================
                              // PULANG
                              // ==================================================
                              _buildAttendanceCard(
                                isDark: isDark,
                                title: 'Pulang',
                                latlong:
                                    absensiDetail!['latlong_out']?.toString() ??
                                    '',
                                date:
                                    absensiDetail!['tgl_out']?.toString() ??
                                    '-',
                                time:
                                    absensiDetail!['jam_out']?.toString() ??
                                    '-',
                                infoTitle2: 'Bekerja Selama',
                                infoValue2:
                                    absensiDetail!['durasi_kerja']
                                        ?.toString() ??
                                    '-',
                                lemburTitle: 'Lembur Selama',
                                lemburValue:
                                    absensiDetail!['lembur']?.toString() ?? '',
                                accentColor: CupertinoColors.systemRed,
                              ),

                              const SizedBox(height: 12),

                              // ==================================================
                              // FOTO
                              // ==================================================
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildMiniPhotoBox(
                                      label: 'Foto Berangkat',
                                      imageUrl: absensiDetail!['foto_in'],
                                      index: 0,
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildMiniPhotoBox(
                                      label: 'Foto Pulang',
                                      imageUrl: absensiDetail!['foto_out'],
                                      index: 1,
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // ==================================================
                              // KETERANGAN
                              // ==================================================
                              _buildKeteranganBox(
                                absensiDetail!['keterangan']?.toString() ?? '',
                                isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
