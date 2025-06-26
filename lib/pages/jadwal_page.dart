import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Jadwal Dinas')),
      child: SafeArea(
        child: Center(
          child: Text(
            'Coming soon.',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
          ),
        ),
      ),
    );
  }
}
