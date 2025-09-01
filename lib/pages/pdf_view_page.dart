import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewPage extends StatefulWidget {
  final String assetPath; // bisa juga URL jika mau
  const PdfViewPage({super.key, required this.assetPath});

  @override
  State<PdfViewPage> createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  final PdfViewerController _pdfController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;

  // Fungsi share PDF dari asset
  Future<void> _sharePdf() async {
    try {
      final bytes = await rootBundle.load(widget.assetPath);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.assetPath.split('/').last}');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], text: 'PDF E-Absensi');
    } catch (e) {
      debugPrint("Error sharing PDF: $e");
    }
  }

  // Fungsi reload PDF
  void _reloadPdf() {
    _pdfController.jumpToPage(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Tata Cara E-Absensi",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.systemGrey2 : CupertinoColors.black,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.arrow_2_circlepath),
              onPressed: _reloadPdf,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.share),
              onPressed: _sharePdf,
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              top: true,
              bottom: false,
              child: SfPdfViewer.asset(
                widget.assetPath,
                controller: _pdfController,
                onDocumentLoaded: (details) {
                  setState(() {
                    _totalPages = details.document.pages.count;
                  });
                },
                onPageChanged: (details) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            bottom: false, // matikan safe area bawaan bawah
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
              ), // geser sedikit ke atas
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: isDark
                    ? CupertinoColors.darkBackgroundGray
                    : CupertinoColors.systemGrey6,
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.left_chevron),
                        onPressed: () {
                          if (_currentPage > 1) _pdfController.previousPage();
                        },
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Halaman $_currentPage / $_totalPages',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.none,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.right_chevron),
                        onPressed: () {
                          if (_currentPage < _totalPages)
                            _pdfController.nextPage();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
