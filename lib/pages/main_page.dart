import 'dart:math' as math;
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'jadwal_page.dart';
import 'dashboard_page.dart';
import 'absensi_page.dart';
import 'rekap_page.dart';
import 'setting_page.dart';
import 'main_page_controller.dart';

class MainPage extends StatefulWidget {
  final int id_user;
  final String name;
  final String nama;
  final String nip;
  final String fotoProfil;

  const MainPage({
    super.key,
    required this.id_user,
    required this.name,
    required this.nama,
    required this.nip,
    required this.fotoProfil,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  int rekapRefreshKey = 0;

  bool _permissionDialogShowing = false;

  @override
  void initState() {
    super.initState();

    MainPageController.changeTab = (int index) {
      if (!mounted) return;

      if (index < 0 || index > 4) return;

      _changeTab(index);
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPermissionDisclosureIfNeeded();
    });
  }

  void _onAbsensiBerhasil() {
    if (!mounted) return;

    setState(() {
      rekapRefreshKey++;
    });
  }

  @override
  void dispose() {
    MainPageController.changeTab = null;
    super.dispose();
  }

  void _changeTab(int index) {
    if (index < 0 || index > 4) return;

    if (index == currentIndex) return;

    setState(() {
      currentIndex = index;
    });
  }

  void _swipeNavigation(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() < 250) return;

    if (velocity < 0 && currentIndex < 4) {
      _changeTab(currentIndex + 1);
    } else if (velocity > 0 && currentIndex > 0) {
      _changeTab(currentIndex - 1);
    }
  }

  Future<void> _showPermissionDisclosureIfNeeded() async {
    if (!mounted) return;
    if (_permissionDialogShowing) return;

    // ============================================================
    // CEK STATUS SEMUA PERMISSION
    // ============================================================

    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.locationWhenInUse.status;

    PermissionStatus notificationStatus = PermissionStatus.granted;

    if (Platform.isAndroid || Platform.isIOS) {
      notificationStatus = await Permission.notification.status;
    }

    final cameraGranted = cameraStatus.isGranted;
    final locationGranted = locationStatus.isGranted;
    final notificationGranted = notificationStatus.isGranted;

    // ============================================================
    // JIKA SEMUA SUDAH DIIZINKAN
    // MAKA TIDAK PERLU MENAMPILKAN DISCLOSURE
    // ============================================================

    if (cameraGranted && locationGranted && notificationGranted) {
      return;
    }

    _permissionDialogShowing = true;

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) {
      _permissionDialogShowing = false;
      return;
    }

    // ============================================================
    // DIALOG PROMINENT DISCLOSURE
    // ============================================================

    final result = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark =
            CupertinoTheme.brightnessOf(dialogContext) == Brightness.dark;

        return CupertinoAlertDialog(
          title: const Text(
            'Izin Aplikasi',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),

          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Text(
                  'E-Absensi memerlukan beberapa izin untuk '
                  'menjalankan fitur absensi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    height: 1.45,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),

                const SizedBox(height: 14),

                // ==================================================
                // STATUS CAMERA
                // ==================================================
                _buildPermissionStatusRow(
                  icon: CupertinoIcons.camera_fill,
                  title: 'Kamera',
                  granted: cameraGranted,
                  isDark: isDark,
                ),

                const SizedBox(height: 8),

                // ==================================================
                // STATUS LOCATION
                // ==================================================
                _buildPermissionStatusRow(
                  icon: CupertinoIcons.location_fill,
                  title: 'Lokasi / GPS',
                  granted: locationGranted,
                  isDark: isDark,
                ),

                const SizedBox(height: 8),

                // ==================================================
                // STATUS NOTIFICATION
                // ==================================================
                _buildPermissionStatusRow(
                  icon: CupertinoIcons.bell_fill,
                  title: 'Notifikasi',
                  granted: notificationGranted,
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                // ==================================================
                // PENJELASAN PERMISSION
                // ==================================================
                Text(
                  '• Kamera digunakan untuk mengambil foto saat '
                  'melakukan absensi.\n'
                  '• Lokasi digunakan untuk memverifikasi posisi '
                  'Anda saat melakukan absensi.\n'
                  '• Notifikasi digunakan untuk memberikan informasi '
                  'terkait absensi dan layanan aplikasi.',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    height: 1.5,
                    color: isDark
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Anda dapat memberikan izin sekarang atau '
                  'mengaktifkannya kemudian melalui Pengaturan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    height: 1.4,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2,
                  ),
                ),
              ],
            ),
          ),

          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Lewati',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),

            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Setuju',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    _permissionDialogShowing = false;

    if (!mounted) return;

    // ============================================================
    // USER MEMILIH SETUJU
    // ============================================================

    if (result == true) {
      await _requestAllPermissions();
    }

    // ============================================================
    // JIKA LEWATI:
    //
    // TIDAK ADA FLAG YANG DISIMPAN.
    //
    // Karena permission masih belum lengkap, saat aplikasi
    // dibuka kembali popup akan muncul lagi.
    // ============================================================
  }

  Widget _buildPermissionStatusRow({
    required IconData icon,
    required String title,
    required bool granted,
    required bool isDark,
  }) {
    final statusColor = granted
        ? CupertinoColors.systemGreen
        : CupertinoColors.systemRed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1E25) : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: statusColor),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),

          Icon(
            granted
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.xmark_circle_fill,
            size: 17,
            color: statusColor,
          ),

          const SizedBox(width: 5),

          Text(
            granted ? 'Sudah diberikan' : 'Belum diberikan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    if (!mounted) return;

    // ============================================================
    // 1. KAMERA
    // ============================================================

    var cameraStatus = await Permission.camera.status;

    if (cameraStatus.isDenied) {
      cameraStatus = await Permission.camera.request();
    }

    // ============================================================
    // 2. LOKASI
    // ============================================================

    var locationStatus = await Permission.locationWhenInUse.status;

    if (locationStatus.isDenied) {
      locationStatus = await Permission.locationWhenInUse.request();
    }

    // ============================================================
    // 3. NOTIFIKASI
    // ============================================================

    PermissionStatus notificationStatus = PermissionStatus.granted;

    if (Platform.isAndroid || Platform.isIOS) {
      notificationStatus = await Permission.notification.status;

      if (notificationStatus.isDenied) {
        notificationStatus = await Permission.notification.request();
      }
    }

    // ============================================================
    // CEK HASIL AKHIR
    // ============================================================

    final allGranted =
        cameraStatus.isGranted &&
        locationStatus.isGranted &&
        notificationStatus.isGranted;

    debugPrint(
      '========================================\n'
      'PERMISSION RESULT\n'
      'Camera       : $cameraStatus\n'
      'Location     : $locationStatus\n'
      'Notification : $notificationStatus\n'
      'All Granted  : $allGranted\n'
      '========================================',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        id_user: widget.id_user,
        name: widget.name,
        nama: widget.nama,
        nip: widget.nip,
        fotoProfil: widget.fotoProfil,
      ),

      JadwalPage(id_user: widget.id_user),

      AbsensiPage(
        id_user: widget.id_user,
        nip: widget.nip,
        isActive: currentIndex == 2,
        onAbsensiBerhasil: _onAbsensiBerhasil,
      ),

      RekapPage(id_user: widget.id_user, refreshKey: rekapRefreshKey),

      SettingPage(
        id_user: widget.id_user,
        name: widget.name,
        nama: widget.nama,
        nip: widget.nip,
        fotoProfil: widget.fotoProfil,
      ),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        // Body dapat berada di belakang floating navigation bar.
        extendBody: true,

        body: IndexedStack(index: currentIndex, children: pages),

        // ================================================================
        // FLOATING BOTTOM NAVIGATION
        // ================================================================
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: _swipeNavigation,
            child: FloatingLiquidNavigationBar(
              currentIndex: currentIndex,
              onTap: _changeTab,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FLOATING LIQUID GLASS NAVIGATION BAR
// ============================================================================

class FloatingLiquidNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingLiquidNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavigationItem> _items = [
    _NavigationItem(icon: CupertinoIcons.house_fill, label: 'Dashboard'),
    _NavigationItem(icon: CupertinoIcons.calendar, label: 'Jadwal'),
    _NavigationItem(icon: CupertinoIcons.camera_fill, label: 'Absensi'),
    _NavigationItem(icon: CupertinoIcons.chart_bar_fill, label: 'Rekap'),
    _NavigationItem(icon: CupertinoIcons.settings_solid, label: 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final itemWidth = totalWidth / _items.length;

        return ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),

                // ========================================================
                // DARK / LIGHT GLASS
                // ========================================================
                color: isDark
                    ? Colors.white.withOpacity(0.055)
                    : Colors.white.withOpacity(0.32),

                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.white.withOpacity(0.58),
                  width: 1,
                ),

                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.48)
                        : const Color(0xFF64748B).withOpacity(0.10),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(isDark ? 0.025 : 0.42),
                    blurRadius: 5,
                    spreadRadius: -1,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),

              child: Stack(
                children: [
                  // ======================================================
                  // TOP GLASS REFLECTION
                  // ======================================================
                  Positioned(
                    left: 10,
                    right: 10,
                    top: 1,
                    height: 21,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(23),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? [
                                    Colors.white.withOpacity(0.045),
                                    Colors.white.withOpacity(0.00),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.60),
                                    Colors.white.withOpacity(0.00),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ======================================================
                  // SUBTLE BOTTOM GLASS SHADE
                  // ======================================================
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 22,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(27),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.16),
                                  ]
                                : [
                                    Colors.transparent,
                                    const Color(0xFF2563EB).withOpacity(0.035),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ======================================================
                  // LIQUID ACTIVE PILL
                  // ======================================================
                  _LiquidGlassPill(
                    currentIndex: currentIndex,
                    itemWidth: itemWidth,
                    isDark: isDark,
                  ),

                  // ======================================================
                  // NAVIGATION ITEMS
                  // ======================================================
                  Row(
                    children: List.generate(_items.length, (index) {
                      final item = _items[index];

                      return Expanded(
                        child: _LiquidNavigationButton(
                          item: item,
                          selected: currentIndex == index,
                          isDark: isDark,
                          onTap: () => onTap(index),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// LIQUID GLASS PILL
// ============================================================================
class _LiquidGlassPill extends StatefulWidget {
  final int currentIndex;
  final double itemWidth;
  final bool isDark;

  const _LiquidGlassPill({
    required this.currentIndex,
    required this.itemWidth,
    required this.isDark,
  });

  @override
  State<_LiquidGlassPill> createState() => _LiquidGlassPillState();
}

class _LiquidGlassPillState extends State<_LiquidGlassPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();

    _previousIndex = widget.currentIndex;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _LiquidGlassPill oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;

      _controller
        ..stop()
        ..value = 0.0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _position(double t) {
    final start = _previousIndex * widget.itemWidth + 4;

    final end = widget.currentIndex * widget.itemWidth + 4;

    final curved = Curves.easeInOutCubic.transform(t);

    return lerpDouble(start, end, curved) ?? start;
  }

  double _liquidStretch(double t) {
    final stretch = math.sin(math.pi * t);

    return widget.itemWidth - 8 + (widget.itemWidth * 0.26 * stretch);
  }

  double _borderRadius(double t) {
    final stretch = math.sin(math.pi * t);

    return 20 + (7 * stretch);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        final left = _position(t);
        final width = _liquidStretch(t);
        final radius = _borderRadius(t);

        return Positioned(
          left: left,
          top: 5,
          bottom: 5,
          width: width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),

                  // ======================================================
                  // DARK / LIGHT ACTIVE GLASS
                  // ======================================================
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isDark
                        ? [
                            Colors.white.withOpacity(0.105),
                            Colors.white.withOpacity(0.045),
                            Colors.white.withOpacity(0.020),
                          ]
                        : [
                            Colors.white.withOpacity(0.48),
                            Colors.white.withOpacity(0.26),
                            Colors.white.withOpacity(0.16),
                          ],
                  ),

                  border: Border.all(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.white.withOpacity(0.70),
                    width: 1,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.025)
                          : Colors.white.withOpacity(0.45),
                      blurRadius: 12,
                      spreadRadius: -2,
                      offset: const Offset(0, -2),
                    ),
                    BoxShadow(
                      color: widget.isDark
                          ? Colors.black.withOpacity(0.22)
                          : const Color(0xFF2563EB).withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),

                child: Stack(
                  children: [
                    // ====================================================
                    // TOP SPECULAR HIGHLIGHT
                    // ====================================================
                    Positioned(
                      left: 7,
                      right: 7,
                      top: 1,
                      height: 15,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(
                                  widget.isDark ? 0.055 : 0.58,
                                ),
                                Colors.white.withOpacity(0.00),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ====================================================
                    // MOVING LIGHT REFLECTION
                    // ====================================================
                    Positioned(
                      left: 8 + (width - 30) * t,
                      top: 4,
                      child: IgnorePointer(
                        child: Container(
                          width: 22,
                          height: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(
                                  widget.isDark ? 0.025 : 0.42,
                                ),
                                Colors.white.withOpacity(0.00),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ====================================================
                    // INNER SOFT REFLECTION
                    // ====================================================
                    Positioned(
                      left: width * 0.15,
                      right: width * 0.15,
                      bottom: 3,
                      height: 7,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: LinearGradient(
                              colors: widget.isDark
                                  ? [
                                      Colors.white.withOpacity(0.015),
                                      Colors.transparent,
                                    ]
                                  : [
                                      const Color(
                                        0xFF2563EB,
                                      ).withOpacity(0.035),
                                      Colors.transparent,
                                    ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// NAVIGATION BUTTON
// ============================================================================
class _LiquidNavigationButton extends StatelessWidget {
  final _NavigationItem item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LiquidNavigationButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.48)
        : const Color(0xFF64748B);

    final activeColor = isDark ? Colors.white : const Color(0xFF2563EB);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ============================================================
            // ICON
            // ============================================================
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              width: selected ? 30 : 26,
              height: selected ? 30 : 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? (isDark
                          ? Colors.white.withOpacity(0.09)
                          : const Color(0xFF2563EB).withOpacity(0.08))
                    : Colors.transparent,
              ),
              child: Center(
                child: AnimatedScale(
                  scale: selected ? 1.0 : 0.90,
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: selected ? activeColor : inactiveColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 2),

            // ============================================================
            // LABEL
            // ============================================================
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: selected ? 8.5 : 7.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : inactiveColor,
                letterSpacing: selected ? -0.05 : 0,
                decoration: TextDecoration.none,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(decoration: TextDecoration.none),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NAVIGATION ITEM
// ============================================================================

class _NavigationItem {
  final IconData icon;
  final String label;

  const _NavigationItem({required this.icon, required this.label});
}

// ============================================================================
// HELPER
// ============================================================================

double? lerpDouble(double? a, double? b, double t) {
  if (a == null && b == null) {
    return null;
  }

  a ??= 0.0;
  b ??= 0.0;

  return a + (b - a) * t;
}
