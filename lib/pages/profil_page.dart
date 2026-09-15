import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/api_service.dart';

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

  bool _isLoading = true;
  bool _showFullScreen = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? '';
      final idUser = prefs.getInt('id_user') ?? 0;

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/setting/profil/$idUser'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['user'];

        setState(() {
          nama = data['nama'] ?? '';
          nip = data['nip'] ?? '';
          alamat = data['alamat_ktp'] ?? '-';
          alamatDom = data['alamat_dom'] ?? '-';
          noHp = data['no_hp'] ?? '-';
          email = data['email'] ?? '-';

          fotoUrl = widget.fotoProfil.trim().isNotEmpty
              ? '${ApiService.simrsUrl}/storage/${widget.fotoProfil.replaceFirst('public/', '')}'
              : null;

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
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
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(
                  context,
                  foregroundColor: foregroundColor,
                  secondaryColor: secondaryColor,
                ),

                Expanded(
                  child: _isLoading
                      ? _buildLoading(
                          isDark: isDark,
                          secondaryColor: secondaryColor,
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          child: Column(
                            children: [
                              _buildProfileHero(
                                isDark: isDark,
                                foregroundColor: foregroundColor,
                                secondaryColor: secondaryColor,
                              ),

                              const SizedBox(height: 20),

                              _buildSectionTitle(
                                'Informasi Pribadi',
                                secondaryColor,
                              ),

                              const SizedBox(height: 8),

                              _buildInfoCard(
                                isDark: isDark,
                                foregroundColor: foregroundColor,
                                secondaryColor: secondaryColor,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),

          if (_showFullScreen && fotoUrl != null && fotoUrl!.isNotEmpty)
            _buildFullscreenPhoto(isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                CupertinoIcons.chevron_back,
                size: 18,
                color: foregroundColor,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil Saya',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Informasi akun dan data pribadi',
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
        ],
      ),
    );
  }

  Widget _buildProfileHero({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11151C) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (fotoUrl != null && fotoUrl!.isNotEmpty) {
                setState(() {
                  _showFullScreen = true;
                });
              }
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF303744)
                          : const Color(0xFFE5E7EB),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: fotoUrl != null && fotoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: fotoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CupertinoActivityIndicator(),
                            ),
                            errorWidget: (_, __, ___) => Image.asset(
                              'assets/user.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset('assets/user.png', fit: BoxFit.cover),
                  ),
                ),

                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF11151C)
                          : CupertinoColors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.zoom_in,
                    size: 14,
                    color: CupertinoColors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Text(
            nama.isEmpty ? '-' : nama,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            nip.isEmpty ? '-' : nip,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.person_fill,
                  size: 11,
                  color: CupertinoColors.activeBlue,
                ),
                SizedBox(width: 5),
                Text(
                  'Profil Pengguna',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.activeBlue,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    final items = <Map<String, dynamic>>[
      {'icon': CupertinoIcons.person, 'label': 'Nama', 'value': nama},
      {'icon': CupertinoIcons.number, 'label': 'NIP', 'value': nip},
      {
        'icon': CupertinoIcons.house,
        'label': 'Alamat KTP',
        'value': alamat ?? '-',
      },
      {
        'icon': CupertinoIcons.location,
        'label': 'Domisili',
        'value': alamatDom ?? '-',
      },
      {'icon': CupertinoIcons.phone, 'label': 'No. HP', 'value': noHp ?? '-'},
      {'icon': CupertinoIcons.mail, 'label': 'Email', 'value': email ?? '-'},
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11151C) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];

            return Column(
              children: [
                _buildInfoRow(
                  icon: item['icon'] as IconData,
                  label: item['label'] as String,
                  value: item['value'] as String,
                  foregroundColor: foregroundColor,
                  secondaryColor: secondaryColor,
                  isDark: isDark,
                ),

                if (index != items.length - 1)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 64),
                    color: isDark
                        ? const Color(0xFF242A33)
                        : const Color(0xFFEAECEF),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color foregroundColor,
    required Color secondaryColor,
    required bool isDark,
  }) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 16, color: CupertinoColors.activeBlue),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: foregroundColor,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading({required bool isDark, required Color secondaryColor}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 14),
          const SizedBox(height: 14),
          Text(
            'Memuat profil...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: secondaryColor,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenPhoto({required bool isDark}) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF000000),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  panEnabled: true,
                  child: CachedNetworkImage(
                    imageUrl: fotoUrl!,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                      radius: 14,
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      CupertinoIcons.photo,
                      size: 64,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 12,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFullScreen = false;
                    });
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xCC1C1C1E),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 18,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
