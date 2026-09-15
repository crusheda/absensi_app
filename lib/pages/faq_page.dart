import 'package:flutter/cupertino.dart';

import '../services/api_service.dart';
import 'FullscreenImagePage.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  late Future<List<dynamic>> _faqFuture;

  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _faqFuture = ApiService.getFaq();
  }

  Future<void> _refreshFaq() async {
    setState(() {
      _faqFuture = ApiService.getFaq();
      _expandedIndex = null;
    });

    await _faqFuture;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF080A0F)
        : const Color(0xFFF5F7FA);

    final foregroundColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.black;

    final secondaryColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.systemGrey;

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
              child: FutureBuilder<List<dynamic>>(
                future: _faqFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoading(isDark: isDark);
                  }

                  if (snapshot.hasError) {
                    return _buildError(
                      isDark: isDark,
                      secondaryColor: secondaryColor,
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmpty(
                      isDark: isDark,
                      secondaryColor: secondaryColor,
                    );
                  }

                  final faqList = snapshot.data!;

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 125),
                    itemCount: faqList.length,
                    itemBuilder: (context, index) {
                      final faq = faqList[index];

                      return _buildFaqItem(
                        faq: faq,
                        index: index,
                        isDark: isDark,
                        foregroundColor: foregroundColor,
                        secondaryColor: secondaryColor,
                      );
                    },
                  );
                },
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAQ',
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
                  'Pertanyaan yang sering ditanyakan',
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
            onPressed: () {
              _refreshFaq();
            },
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
              child: Icon(
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

  Widget _buildFaqItem({
    required dynamic faq,
    required int index,
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    final isExpanded = _expandedIndex == index;

    final question = '${faq['question'] ?? '-'}';

    final answer = (faq['answer'] ?? '').toString().replaceAll(r'\n', '\n');

    final extra = faq['extra']?.toString() ?? '';

    final filename = faq['filename']?.toString() ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11151C) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? CupertinoColors.activeBlue.withValues(alpha: 0.45)
              : isDark
              ? const Color(0xFF242A33)
              : const Color(0xFFE7EAF0),
        ),
      ),
      child: Column(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 12, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isExpanded
                          ? CupertinoIcons.question_circle_fill
                          : CupertinoIcons.question,
                      size: 17,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Text(
                      question,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor,
                        decoration: TextDecoration.none,
                        height: 1.35,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      size: 15,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _buildFaqAnswer(
              faq: faq,
              answer: answer,
              extra: extra,
              filename: filename,
              isDark: isDark,
              foregroundColor: foregroundColor,
              secondaryColor: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqAnswer({
    required dynamic faq,
    required String answer,
    required String extra,
    required String filename,
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
          ),

          const SizedBox(height: 13),

          Text(
            answer.isEmpty ? '-' : answer,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              height: 1.55,
              color: foregroundColor,
              decoration: TextDecoration.none,
            ),
          ),

          if (extra.isNotEmpty) ...[
            const SizedBox(height: 14),

            Text(
              'Nb.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: secondaryColor,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 5),

            _buildExtraContent(
              extra: extra,
              isDark: isDark,
              foregroundColor: foregroundColor,
            ),
          ],

          if (filename.isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.paperclip,
                    size: 14,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filename,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: foregroundColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtraContent({
    required String extra,
    required bool isDark,
    required Color foregroundColor,
  }) {
    final lower = extra.toLowerCase();

    final isImage =
        extra.startsWith('http') &&
        (lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.gif') ||
            lower.endsWith('.webp'));

    if (!isImage) {
      return Text(
        extra,
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          height: 1.5,
          color: foregroundColor,
          decoration: TextDecoration.none,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => FullscreenImagePage(imageUrl: extra),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 260),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          extra,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Gagal memuat gambar',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: CupertinoColors.systemGrey,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }

            return const SizedBox(
              height: 160,
              child: Center(child: CupertinoActivityIndicator()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading({required bool isDark}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 13),
          const SizedBox(height: 12),
          Text(
            'Memuat FAQ...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: isDark
                  ? CupertinoColors.systemGrey2
                  : CupertinoColors.systemGrey,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError({required bool isDark, required Color secondaryColor}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 28,
                color: CupertinoColors.systemRed,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'FAQ gagal dimuat',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Periksa koneksi internet Anda lalu coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                color: secondaryColor,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 14),

            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              onPressed: _refreshFaq,
              child: const Text(
                'Coba Lagi',
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

  Widget _buildEmpty({required bool isDark, required Color secondaryColor}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF171B22)
                    : const Color(0xFFF0F2F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.question,
                size: 30,
                color: secondaryColor,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'Belum ada FAQ',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Tidak ada pertanyaan yang tersedia saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                color: secondaryColor,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
