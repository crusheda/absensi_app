import 'package:flutter/material.dart';

class RekapPage extends StatelessWidget {
  final String nip;
  const RekapPage({super.key, required this.nip});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Grafik riwayat absensi $nip"));
  }
}
