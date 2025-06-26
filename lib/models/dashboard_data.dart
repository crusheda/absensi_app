import 'dart:convert';

class DashboardData {
  final Map<String, dynamic>? fotoProfil;
  final StatusPgw? statuspgw;
  final int hadir;
  final int absenOne;
  final int terlambat;
  final int ijin;
  final String namaShift;
  final String shift;
  final Jadwal? jadwal;

  DashboardData({
    required this.fotoProfil,
    required this.statuspgw,
    required this.hadir,
    required this.absenOne,
    required this.terlambat,
    required this.ijin,
    required this.namaShift,
    required this.shift,
    required this.jadwal,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      fotoProfil: json['foto_profil'] as Map<String, dynamic>?,
      statuspgw: StatusPgw.fromJson(json['statuspgw'] ?? {'nama_status': '-'}),
      hadir: json['hadir'] ?? 0,
      absenOne: json['absenOne'] ?? 0,
      terlambat: json['terlambat'] ?? 0,
      ijin: json['ijin'] ?? 0,
      namaShift: json['nama_shift'] ?? '',
      shift: json['shift'] ?? '',
      jadwal: json['jadwal'] != null
          ? Jadwal.fromJson(json['jadwal']) // ✅ PARSE DENGAN fromJson
          : null,
    );
  }
}

class StatusPgw {
  final String namaStatus;

  StatusPgw({required this.namaStatus});

  factory StatusPgw.fromJson(Map<String, dynamic> json) {
    return StatusPgw(namaStatus: json['nama_status'] ?? '-');
  }
}

class Jadwal {
  final int id;
  final int pegawaiId;
  final List<String> staf;
  final String bulan;
  final String tahun;
  final String? keterangan;
  final int progress;
  final int verif;
  final String? tglVerif;
  final int valid;
  final String? tglValid;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? fotoPegawai;
  final String unit;
  final String namaPegawai;
  final String namaVerif;
  final String namaValid;

  Jadwal({
    required this.id,
    required this.pegawaiId,
    required this.staf,
    required this.bulan,
    required this.tahun,
    this.keterangan,
    required this.progress,
    required this.verif,
    this.tglVerif,
    required this.valid,
    this.tglValid,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.fotoPegawai,
    required this.unit,
    required this.namaPegawai,
    required this.namaVerif,
    required this.namaValid,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
      id: json['id'],
      pegawaiId: json['pegawai_id'],
      staf: List<String>.from(jsonDecode(json['staf'] ?? '[]') as List),
      bulan: json['bulan'],
      tahun: json['tahun'],
      keterangan: json['keterangan'] ?? '',
      progress: json['progress'],
      verif: json['verif'] ?? '',
      tglVerif: json['tgl_verif'] ?? '',
      valid: json['valid'] ?? '',
      tglValid: json['tgl_valid'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'] ?? '',
      fotoPegawai: json['foto_pegawai'] ?? '',
      unit: json['unit'] ?? '',
      namaPegawai: json['nama_pegawai'] ?? '',
      namaVerif: json['nama_verif'] ?? '',
      namaValid: json['nama_valid'] ?? '',
    );
  }
}
