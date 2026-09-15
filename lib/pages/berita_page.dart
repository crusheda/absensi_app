import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/berita.dart';
import '../services/api_service.dart';
import 'detail_berita_page.dart';

class BeritaPage extends StatefulWidget {
  const BeritaPage({super.key});

  @override
  State<BeritaPage> createState() => _BeritaPageState();
}

class _BeritaPageState extends State<BeritaPage> {
  final ScrollController _scrollController = ScrollController();

  final List<Berita> _berita = [];

  int _page = 1;
  final int _perPage = 10;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    _loadBerita();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMoreBerita();
    }
  }

  Future<void> _loadBerita() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = 1;
      _hasMore = true;
      _berita.clear();
    });

    try {
      final result = await ApiService.getBeritaPaginated(
        page: 1,
        perPage: _perPage,
      );

      if (!mounted) return;

      setState(() {
        _berita.addAll(result);
        _isLoading = false;

        if (result.length < _perPage) {
          _hasMore = false;
        }
      });
    } catch (e) {
      debugPrint('Error load berita: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat berita.';
      });
    }
  }

  Future<void> _loadMoreBerita() async {
    if (_isLoadingMore || !_hasMore || _isLoading) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _page + 1;

    try {
      final result = await ApiService.getBeritaPaginated(
        page: nextPage,
        perPage: _perPage,
      );

      if (!mounted) return;

      setState(() {
        if (result.isNotEmpty) {
          _berita.addAll(result);
          _page = nextPage;
        }

        if (result.length < _perPage) {
          _hasMore = false;
        }

        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error load more berita: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshBerita() async {
    await _loadBerita();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF080B12)
        : const Color(0xFFF5F8FF);

    final foregroundColor = isDark
        ? CupertinoColors.white
        : const Color(0xFF111827);

    final secondaryColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(
              isDark: isDark,
              foregroundColor: foregroundColor,
              secondaryColor: secondaryColor,
            ),
            Expanded(
              child: _buildBody(
                isDark: isDark,
                foregroundColor: foregroundColor,
                secondaryColor: secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Berita',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                    decoration: TextDecoration.none,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Informasi dan berita terbaru',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: secondaryColor,
                    decoration: TextDecoration.none,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _isLoading ? null : _refreshBerita,
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
              child: _isLoading
                  ? const CupertinoActivityIndicator(radius: 9)
                  : const Icon(
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

  Widget _buildBody({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    if (_isLoading && _berita.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    if (_errorMessage != null && _berita.isEmpty) {
      return _buildError(
        isDark: isDark,
        foregroundColor: foregroundColor,
        secondaryColor: secondaryColor,
      );
    }

    if (_berita.isEmpty) {
      return _buildEmpty(
        isDark: isDark,
        foregroundColor: foregroundColor,
        secondaryColor: secondaryColor,
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refreshBerita),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index >= _berita.length) {
                return _buildLoadingMore(isDark: isDark);
              }

              final item = _berita[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildBeritaCard(
                  item: item,
                  isDark: isDark,
                  foregroundColor: foregroundColor,
                  secondaryColor: secondaryColor,
                ),
              );
            }, childCount: _berita.length + (_isLoadingMore ? 1 : 0)),
          ),
        ),
      ],
    );
  }

  Widget _buildBeritaCard({
    required Berita item,
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    final imageUrl = item.gambar != null && item.gambar!.trim().isNotEmpty
        ? '${ApiService.simrsUrl}/storage/${item.gambar!.trim()}'
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => DetailBeritaPage(beritaId: item.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF11161F) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF202631) : const Color(0xFFE7EBF2),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF1F2937).withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 8.5,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) {
                    return Container(
                      color: isDark
                          ? const Color(0xFF171D27)
                          : const Color(0xFFEFF3F8),
                      child: const Center(child: CupertinoActivityIndicator()),
                    );
                  },
                  errorWidget: (context, url, error) {
                    return _buildImagePlaceholder(isDark: isDark);
                  },
                ),
              )
            else
              _buildImagePlaceholder(isDark: isDark),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.publishedAt != null)
                    Text(
                      _formatDate(item.publishedAt!),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: secondaryColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    item.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: foregroundColor,
                      decoration: TextDecoration.none,
                      height: 1.3,
                    ),
                  ),
                  if (item.ringkasan != null &&
                      item.ringkasan!.trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      item.ringkasan!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: secondaryColor,
                        decoration: TextDecoration.none,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.person,
                        size: 13,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.penulis?.trim().isNotEmpty == true
                              ? item.penulis!.trim()
                              : 'Admin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: secondaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(CupertinoIcons.eye, size: 13, color: secondaryColor),
                      const SizedBox(width: 5),
                      Text(
                        '${item.views}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: secondaryColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: secondaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder({required bool isDark}) {
    return AspectRatio(
      aspectRatio: 16 / 8.5,
      child: Container(
        color: isDark ? const Color(0xFF171D27) : const Color(0xFFEFF3F8),
        child: Center(
          child: Icon(
            CupertinoIcons.news,
            size: 34,
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMore({required bool isDark}) {
    if (!_isLoadingMore) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: CupertinoActivityIndicator(radius: 10)),
    );
  }

  Widget _buildEmpty({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.news, size: 48, color: secondaryColor),
            const SizedBox(height: 14),
            Text(
              'Belum ada berita',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Belum ada berita yang tersedia saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: secondaryColor,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 14),
            Text(
              'Gagal memuat berita',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: secondaryColor,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(14),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              onPressed: _loadBerita,
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${bulan[date.month - 1]} ${date.year}';
  }
}
