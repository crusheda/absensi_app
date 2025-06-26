enum AbsensiJenis { berangkat, pulang, ijin }

extension AbsensiJenisExtension on AbsensiJenis {
  /// Kode yang dikirim ke backend Laravel (1: Berangkat, 2: Pulang, 3: Izin)
  String get kode {
    switch (this) {
      case AbsensiJenis.berangkat:
        return '1';
      case AbsensiJenis.pulang:
        return '2';
      case AbsensiJenis.ijin:
        return '3';
    }
  }

  /// Label untuk tampilan UI
  String get label {
    switch (this) {
      case AbsensiJenis.berangkat:
        return 'Absen Masuk';
      case AbsensiJenis.pulang:
        return 'Absen Pulang';
      case AbsensiJenis.ijin:
        return 'Izin Tidak Hadir';
    }
  }

  /// Warna khusus jika ingin ditambahkan untuk tiap jenis
  // Color get color => ...;

  /// Ikon khusus jika ingin ditambahkan untuk tiap jenis
  // IconData get icon => ...;
}
