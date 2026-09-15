import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show BoxDecoration, BoxShape, Colors;

class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller;
  late int _currentIndex;

  final List<String> labels = ['Foto Absen Masuk', 'Foto Absen Keluar'];

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex.clamp(
      0,
      widget.imageUrls.isEmpty ? 0 : widget.imageUrls.length - 1,
    );

    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getLabel(int index) {
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }

    return 'Bukti Foto Absensi';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF05070B)
        : const Color(0xFFF5F7FA);

    final foregroundColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.black;

    final secondaryColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.systemGrey;

    if (widget.imageUrls.isEmpty) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(
                context,
                isDark: isDark,
                foregroundColor: foregroundColor,
              ),
              Expanded(
                child: Center(
                  child: _buildEmptyState(
                    isDark: isDark,
                    secondaryColor: secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(
              context,
              isDark: isDark,
              foregroundColor: foregroundColor,
            ),

            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: widget.imageUrls.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      if (!mounted) return;

                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildImage(
                        widget.imageUrls[index],
                        isDark: isDark,
                      );
                    },
                  ),

                  if (widget.imageUrls.length > 1)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _buildCounter(
                        isDark: isDark,
                        foregroundColor: foregroundColor,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            _buildPhotoTitle(
              isDark: isDark,
              foregroundColor: foregroundColor,
              secondaryColor: secondaryColor,
            ),

            const SizedBox(height: 10),

            if (widget.imageUrls.length > 1) _buildIndicator(isDark: isDark),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required bool isDark,
    required Color foregroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Row(
        children: [
          _GlassButton(
            icon: CupertinoIcons.chevron_back,
            onTap: () => Navigator.of(context).pop(),
            isDark: isDark,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bukti Foto Absensi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${_currentIndex + 1} dari ${widget.imageUrls.length}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF11151C) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF252B35) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(40),
            clipBehavior: Clip.none,
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return _buildLoading(
                    isDark: isDark,
                    progress: loadingProgress,
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildImageError(isDark: isDark);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading({
    required bool isDark,
    required ImageChunkEvent progress,
  }) {
    final expected = progress.expectedTotalBytes;
    final loaded = progress.cumulativeBytesLoaded;

    final value = expected != null && expected > 0 ? loaded / expected : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CupertinoActivityIndicator(
          radius: 13,
          color: isDark
              ? CupertinoColors.systemGrey2
              : CupertinoColors.systemGrey,
        ),

        const SizedBox(height: 14),

        Text(
          'Memuat foto...',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark
                ? CupertinoColors.systemGrey2
                : CupertinoColors.systemGrey,
            decoration: TextDecoration.none,
          ),
        ),

        if (value != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: 100,
            child: CupertinoActivityIndicator(
              radius: 5,
              color: isDark
                  ? CupertinoColors.systemGrey2
                  : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageError({required bool isDark}) {
    final secondaryColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.systemGrey;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2028) : const Color(0xFFEFF1F5),
            shape: BoxShape.circle,
          ),
          child: Icon(CupertinoIcons.photo, size: 32, color: secondaryColor),
        ),

        const SizedBox(height: 14),

        Text(
          'Foto tidak dapat dimuat',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: secondaryColor,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required Color secondaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF171B22) : const Color(0xFFEFF1F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.photo_on_rectangle,
              size: 36,
              color: secondaryColor,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Tidak ada foto',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Bukti foto absensi tidak tersedia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: secondaryColor,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTitle({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Column(
      children: [
        Text(
          _getLabel(_currentIndex),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: foregroundColor,
            decoration: TextDecoration.none,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          'Geser untuk melihat foto lainnya',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.5,
            fontWeight: FontWeight.w400,
            color: secondaryColor,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator({required bool isDark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.imageUrls.length, (index) {
        final isActive = index == _currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? CupertinoColors.activeBlue
                : (isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _buildCounter({required bool isDark, required Color foregroundColor}) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xCC11151C) : const Color(0xE6FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0x332FFFFFF) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _GlassButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171B22) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDark ? const Color(0xFF292F39) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(
          icon,
          size: 19,
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
        ),
      ),
    );
  }
}
