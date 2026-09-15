class CutiRiwayat {
  final int bulan;
  final String namaBulan;
  final String tglMulai;
  final String tglSelesai;
  final String tanggal;
  final int jumlahHari;

  CutiRiwayat({
    required this.bulan,
    required this.namaBulan,
    required this.tglMulai,
    required this.tglSelesai,
    required this.tanggal,
    required this.jumlahHari,
  });

  factory CutiRiwayat.fromJson(Map<String, dynamic> json) {
    return CutiRiwayat(
      bulan: json['bulan'] ?? 0,
      namaBulan: json['nama_bulan'] ?? '',
      tglMulai: json['tgl_mulai'] ?? '',
      tglSelesai: json['tgl_selesai'] ?? '',
      tanggal: json['tanggal'] ?? '',
      jumlahHari: json['jumlah_hari'] ?? 0,
    );
  }
}

class CutiData {
  final int tahun;
  final int hakCuti;
  final int terpakai;
  final int tersedia;
  final List<CutiRiwayat> riwayat;

  CutiData({
    required this.tahun,
    required this.hakCuti,
    required this.terpakai,
    required this.tersedia,
    required this.riwayat,
  });

  factory CutiData.fromJson(Map<String, dynamic> json) {
    return CutiData(
      tahun: json['tahun'] ?? DateTime.now().year,
      hakCuti: json['hak_cuti'] ?? 12,
      terpakai: json['terpakai'] ?? 0,
      tersedia: json['tersedia'] ?? 12,
      riwayat: (json['riwayat'] as List? ?? [])
          .map((item) => CutiRiwayat.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
