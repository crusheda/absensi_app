import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();

    MainPageController.changeTab = (int index) {
      if (!mounted) return;

      if (index < 0 || index > 4) return;

      _changeTab(index);
    };
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

      AbsensiPage(id_user: widget.id_user, nip: widget.nip),

      RekapPage(id_user: widget.id_user),

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
                // TRANSPARENT GLASS
                // ========================================================
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.32),

                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.22)
                      : Colors.white.withOpacity(0.58),
                  width: 1,
                ),

                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.28)
                        : const Color(0xFF64748B).withOpacity(0.10),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(isDark ? 0.06 : 0.42),
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
                                    Colors.white.withOpacity(0.14),
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
                                    Colors.black.withOpacity(0.08),
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
                  // TRANSPARENT LIQUID GLASS
                  // ======================================================
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isDark
                        ? [
                            Colors.white.withOpacity(0.20),
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.04),
                          ]
                        : [
                            Colors.white.withOpacity(0.48),
                            Colors.white.withOpacity(0.26),
                            Colors.white.withOpacity(0.16),
                          ],
                  ),

                  border: Border.all(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.25)
                        : Colors.white.withOpacity(0.70),
                    width: 1,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.white.withOpacity(0.45),
                      blurRadius: 12,
                      spreadRadius: -2,
                      offset: const Offset(0, -2),
                    ),
                    BoxShadow(
                      color: widget.isDark
                          ? Colors.black.withOpacity(0.12)
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
                                  widget.isDark ? 0.20 : 0.58,
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
                                  widget.isDark ? 0.08 : 0.42,
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
                                      Colors.white.withOpacity(0.04),
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
        ? Colors.white.withOpacity(0.58)
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
                          ? Colors.white.withOpacity(0.16)
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
                fontSize: selected ? 8.5 : 7.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : inactiveColor,
                letterSpacing: selected ? -0.05 : 0,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
