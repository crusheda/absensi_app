import 'package:flutter/cupertino.dart';

class FullscreenImageViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController(initialPage: initialIndex);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Bukti Foto Absensi"),
        previousPageTitle: 'Kembali',
        // trailing: GestureDetector(
        //   child: const Icon(CupertinoIcons.clear),
        //   onTap: () => Navigator.pop(context),
        // ),
      ),
      child: PageView.builder(
        controller: controller,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(CupertinoIcons.photo),
              ),
            ),
          );
        },
      ),
    );
  }
}
