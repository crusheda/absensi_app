import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final String nip;
  const DashboardPage({super.key, required this.nip});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Jadwal Masuk untuk NIP: $nip"));
  }
}
