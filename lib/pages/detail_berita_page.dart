import 'package:absensi_app/pages/FullscreenImagePage.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/berita.dart';
import '../services/api_service.dart';

class DetailBeritaPage extends StatefulWidget {
  final int beritaId;

  const DetailBeritaPage({super.key, required this.beritaId});

  @override
  State<DetailBeritaPage> createState() => _DetailBeritaPageState();
}

class _DetailBeritaPageState extends State<DetailBeritaPage> {
  Berita? berita;

  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();

    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final result = await ApiService.getDetailBerita(widget.beritaId);

      if (!mounted) return;

      setState(() {
        berita = result;
        isLoading = false;
        isError = false;
      });
    } catch (e) {
      debugPrint('Error detail berita: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? const Color(0xFF080B12)
          : const Color(0xFFF5F8FF),
      child: SafeArea(
        bottom: false,
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : isError || berita == null
            ? _buildError(isDark)
            : _buildContent(isDark, berita!),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(bool isDark, Berita item) {
    final imageUrl = _buildImageUrl(item.gambar);

    return DefaultTextStyle.merge(
      style: const TextStyle(
        decoration: TextDecoration.none,
        fontFamily: 'Poppins',
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ======================================================
          // HEADER
          // ======================================================

          SliverToBoxAdapter(child: _buildHeader(isDark)),

          // ======================================================
          // GAMBAR UTAMA
          // ======================================================
          if (imageUrl != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => FullscreenImagePage(imageUrl: imageUrl),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildImageLoading(isDark),
                        errorWidget: (_, __, ___) => _buildImageError(isDark),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ======================================================
          // ARTICLE
          // ======================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // JUDUL
                  // ------------------------------------------------

                  Text(
                    item.judul,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF111827),
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ------------------------------------------------
                  // META
                  // ------------------------------------------------
                  Row(
                    children: [
                      if (item.publishedAt != null) ...[
                        Icon(
                          CupertinoIcons.calendar,
                          size: 13,
                          color: isDark
                              ? CupertinoColors.systemGrey2
                              : CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat(
                            'dd MMMM yyyy',
                            'id_ID',
                          ).format(item.publishedAt!),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9.5,
                            color: isDark
                                ? CupertinoColors.systemGrey2
                                : CupertinoColors.systemGrey,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        CupertinoIcons.eye,
                        size: 13,
                        color: isDark
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${item.views} dilihat',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9.5,
                          color: isDark
                              ? CupertinoColors.systemGrey2
                              : CupertinoColors.systemGrey,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),

                  // ------------------------------------------------
                  // PENULIS
                  // ------------------------------------------------
                  if (item.penulis != null &&
                      item.penulis!.trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.person,
                          size: 13,
                          color: isDark
                              ? CupertinoColors.systemGrey2
                              : CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.penulis!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? CupertinoColors.systemGrey2
                                : CupertinoColors.systemGrey,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // RINGKASAN
                  // ------------------------------------------------
                  if (item.ringkasan != null &&
                      item.ringkasan!.trim().isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.white.withOpacity(0.045)
                            : CupertinoColors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isDark
                              ? CupertinoColors.white.withOpacity(0.06)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        item.ringkasan!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.55,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF4B5563),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ------------------------------------------------
                  // ISI BERITA
                  // ------------------------------------------------
                  Text(
                    item.isi ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      height: 1.7,
                      color: isDark
                          ? Colors.white.withOpacity(0.82)
                          : const Color(0xFF374151),
                      decoration: TextDecoration.none,
                    ),
                  ),

                  // ------------------------------------------------
                  // LAMPIRAN
                  // ------------------------------------------------
                  _buildLampiranBerita(context, item, isDark),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Detail Berita',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: isDark ? CupertinoColors.white : const Color(0xFF111827),
                decoration: TextDecoration.none,
              ),
            ),
          ),

          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _loadDetail,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151A22) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF242A33)
                      : const Color(0xFFE7EAF0),
                ),
              ),
              child: const Icon(
                CupertinoIcons.refresh,
                size: 18,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LAMPIRAN
  // ============================================================

  Widget _buildLampiranBerita(BuildContext context, Berita item, bool isDark) {
    final lampiran = <String?>[
      item.gambarLampiran1,
      item.gambarLampiran2,
      item.gambarLampiran3,
      item.gambarLampiran4,
      item.gambarLampiran5,
    ].where((image) => image != null && image.trim().isNotEmpty).toList();

    if (lampiran.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),

        Text(
          'Lampiran',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? CupertinoColors.white : const Color(0xFF111827),
            decoration: TextDecoration.none,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(lampiran.length, (index) {
            final imageUrl = _buildImageUrl(lampiran[index]);

            if (imageUrl == null) {
              return const SizedBox.shrink();
            }

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == lampiran.length - 1 ? 0 : 6,
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => FullscreenImagePage(imageUrl: imageUrl),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildImageLoading(isDark),
                          errorWidget: (_, __, ___) => _buildImageError(isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ============================================================
  // IMAGE URL
  // ============================================================

  String? _buildImageUrl(String? image) {
    if (image == null || image.trim().isEmpty) {
      return null;
    }

    return '${ApiService.simrsUrl}/storage/${image.trim()}';
  }

  // ============================================================
  // IMAGE LOADING
  // ============================================================

  Widget _buildImageLoading(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF151A22) : const Color(0xFFEFF2F6),
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }

  // ============================================================
  // IMAGE ERROR
  // ============================================================

  Widget _buildImageError(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF151A22) : const Color(0xFFEFF2F6),
      child: Icon(
        CupertinoIcons.photo,
        size: 28,
        color: isDark ? Colors.white38 : Colors.black26,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 35,
              color: CupertinoColors.systemRed,
            ),

            const SizedBox(height: 12),

            Text(
              'Gagal memuat berita',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 15),

            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _loadDetail,
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
