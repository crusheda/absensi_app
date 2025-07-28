import 'package:flutter/cupertino.dart';

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
  late PageController _controller;
  late int _currentIndex;

  final List<String> labels = ["Foto Absen Masuk", "Foto Absen Keluar"];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? CupertinoColors.transparent
          : CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark
            ? CupertinoColors.transparent
            : CupertinoColors.white,
        middle: Text(
          "Bukti Foto Absensi",
          style: TextStyle(
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        previousPageTitle: 'Kembali',
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Center(
                      child: Image.network(
                        widget.imageUrls[index],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const CupertinoActivityIndicator();
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              CupertinoIcons.photo,
                              color: CupertinoColors.systemGrey,
                              size: 64,
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              labels.length > _currentIndex ? labels[_currentIndex] : "",
              style: TextStyle(
                decoration: TextDecoration.none,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontSize: 20,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            // Dot Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (index) {
                final isActive = index == _currentIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 10 : 6,
                  height: isActive ? 10 : 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
