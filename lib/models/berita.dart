class Berita {
  final int id;
  final String judul;
  final String slug;
  final String? gambar;

  final String? gambarLampiran1;
  final String? gambarLampiran2;
  final String? gambarLampiran3;
  final String? gambarLampiran4;
  final String? gambarLampiran5;

  final String? ringkasan;
  final String? isi;
  final String? penulis;
  final bool isPublished;
  final DateTime? publishedAt;
  final int views;

  Berita({
    required this.id,
    required this.judul,
    required this.slug,
    required this.gambar,

    required this.gambarLampiran1,
    required this.gambarLampiran2,
    required this.gambarLampiran3,
    required this.gambarLampiran4,
    required this.gambarLampiran5,

    required this.ringkasan,
    required this.isi,
    required this.penulis,
    required this.isPublished,
    required this.publishedAt,
    required this.views,
  });

  factory Berita.fromJson(Map<String, dynamic> json) {
    return Berita(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,

      judul: json['judul']?.toString() ?? '',

      slug: json['slug']?.toString() ?? '',

      gambar: json['gambar']?.toString(),

      gambarLampiran1: json['gambar_lampiran_1']?.toString(),

      gambarLampiran2: json['gambar_lampiran_2']?.toString(),

      gambarLampiran3: json['gambar_lampiran_3']?.toString(),

      gambarLampiran4: json['gambar_lampiran_4']?.toString(),

      gambarLampiran5: json['gambar_lampiran_5']?.toString(),

      ringkasan: json['ringkasan']?.toString(),

      isi: json['isi']?.toString(),

      penulis: json['penulis']?.toString(),

      isPublished: json['is_published'] == true || json['is_published'] == 1,

      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())
          : null,

      views: json['views'] is int
          ? json['views']
          : int.tryParse('${json['views']}') ?? 0,
    );
  }
}
