import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dart:ui';

class ProfilePage extends StatefulWidget {
  final String fotoProfil;
  const ProfilePage({super.key, required this.fotoProfil});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String nama = '';
  String nip = '';
  String? alamat;
  String? alamatDom;
  String? noHp;
  String? email;
  String? fotoUrl;
  bool _showFullScreen = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    // ambil token & id_user dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final idUser = prefs.getInt('id_user') ?? 0;
    final bool isFotoAda = widget.fotoProfil.trim().isNotEmpty;

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/setting/profil/$idUser'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['user'];
      setState(() {
        nama = data['nama'] ?? '';
        nip = data['nip'] ?? '';
        alamat = data['alamat_ktp'] ?? '-';
        alamatDom = data['alamat_dom'] ?? '-';
        noHp = data['no_hp'] ?? '-';
        email = data['email'] ?? '-';
        fotoUrl = (widget.fotoProfil.trim().isNotEmpty)
            ? '${ApiService.simrsUrl}/storage/${widget.fotoProfil.replaceFirst('public/', '')}'
            : null;
      });
    }
  }

  Widget _blurCircle(Color color) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: const SizedBox(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CupertinoNavigationBar(
              middle: Text(
                'Profil Saya',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? CupertinoColors.systemGrey2
                      : CupertinoColors.black,
                ),
              ),
              previousPageTitle: 'Kembali',
              backgroundColor: Colors.transparent,
              border: null,
            ),
          ),
          Positioned.fill(
            top: kToolbarHeight,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (fotoUrl != null && fotoUrl!.isNotEmpty) {
                          setState(() => _showFullScreen = true);
                        }
                      },
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 200,
                          maxHeight: 200,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: CupertinoColors.systemGrey4,
                          image: fotoUrl != null && fotoUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(fotoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : const DecorationImage(
                                  image: AssetImage('assets/user.png'),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _cupertinoBoxRow('Nama', nama, isDark),
                    _cupertinoBoxRow('NIP', nip, isDark),
                    _cupertinoBoxRow('Alamat', alamat ?? '-', isDark),

                    // Tambahkan Domisili jika ada
                    if (alamatDom != null && alamatDom!.trim().isNotEmpty) ...[
                      _cupertinoBoxRow('Domisili', alamatDom!, isDark),
                    ],

                    _cupertinoBoxRow('No. HP', noHp ?? '-', isDark),
                    _cupertinoBoxRow('Email', email ?? '-', isDark),
                  ],
                ),
              ),
            ),
          ),
          // FULLSCREEN FOTO
          if (_showFullScreen)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        child: Image.network(fotoUrl!, fit: BoxFit.contain),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      right: 20,
                      child: GestureDetector(
                        onTap: () => setState(() => _showFullScreen = false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.clear,
                            color: isDark ? Colors.black : Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cupertinoBoxRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isDark
                      ? CupertinoColors.systemGrey2
                      : CupertinoColors.systemGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
