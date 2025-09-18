import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // dipakai untuk ExpansionTile
import '../services/api_service.dart';
import 'FullscreenImagePage.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  late Future<List<dynamic>> _faqFuture;

  @override
  void initState() {
    super.initState();
    _faqFuture = ApiService.getFaq();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Frequently Asked Questions",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: isDark ? CupertinoColors.systemGrey : CupertinoColors.black,
          ),
        ),
      ),
      child: Stack(
        children: [
          // 🎨 Background gradient + blur
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      CupertinoTheme.brightnessOf(context) == Brightness.dark
                      ? [Colors.black, Colors.grey.shade900]
                      : [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -50,
            child: _blurCircle(Colors.blueAccent.withOpacity(0.2)),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _blurCircle(Colors.purpleAccent.withOpacity(0.2)),
          ),

          // ✅ Konten utama
          SafeArea(
            child: FutureBuilder<List<dynamic>>(
              future: _faqFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CupertinoActivityIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada FAQ tersedia"));
                }

                final faqList = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: faqList.length,
                  itemBuilder: (context, index) {
                    final faq = faqList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.secondaryLabel
                            : CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          faq['question'] ?? '-',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? CupertinoColors.systemGrey4
                                : Colors.black87,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          Align(
                            alignment: Alignment
                                .centerLeft, // ⬅️ paksa semua konten mulai kiri
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ✅ Answer
                                Text(
                                  (faq['answer'] ?? '').replaceAll("\\n", "\n"),
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? CupertinoColors.systemGrey4
                                        : Colors.black87,
                                  ),
                                ),
                                // ✅ Extra (Keterangan)
                                if (faq['extra'] != null &&
                                    faq['extra'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    "Nb.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: isDark
                                          ? CupertinoColors.systemGrey4
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // cek apakah extra adalah URL gambar
                                  if (faq['extra'].toString().startsWith(
                                        "http",
                                      ) &&
                                      (faq['extra'].toString().endsWith(
                                            ".png",
                                          ) ||
                                          faq['extra'].toString().endsWith(
                                            ".jpg",
                                          ) ||
                                          faq['extra'].toString().endsWith(
                                            ".jpeg",
                                          ) ||
                                          faq['extra'].toString().endsWith(
                                            ".gif",
                                          ) ||
                                          faq['extra'].toString().endsWith(
                                            ".webp",
                                          )))
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => FullscreenImagePage(
                                              imageUrl: faq['extra'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          faq['extra'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Text(
                                                    "Gagal memuat gambar",
                                                  ),
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      faq['extra'],
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? CupertinoColors.systemGrey4
                                            : Colors.black87,
                                      ),
                                    ),
                                ],

                                // ✅ Lampiran
                                if (faq['filename'] != null &&
                                    faq['filename'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    "Lampiran: ${faq['filename']}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _blurCircle(Color color) {
  return Container(
    width: 150,
    height: 150,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
