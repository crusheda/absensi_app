// TODO Implement this library.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/cuti_model.dart';
import '../services/api_service.dart';

class CutiPage extends StatefulWidget {
  final int idUser;

  const CutiPage({super.key, required this.idUser});

  @override
  State<CutiPage> createState() => _CutiPageState();
}

class _CutiPageState extends State<CutiPage> {
  late int _tahun;

  CutiData? _data;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _tahun = DateTime.now().year;

    _loadCuti();
  }

  Future<void> _loadCuti() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getCuti(
        idUser: widget.idUser,
        tahun: _tahun,
      );

      if (!mounted) return;

      setState(() {
        _data = CutiData.fromJson(result);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pilihTahun() async {
    final tahunSekarang = DateTime.now().year;

    int tahunDipilih = _tahun;

    final tahunHasil = await showCupertinoModalPopup<int>(
      context: context,
      builder: (context) {
        final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

        return Container(
          height: 280,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151A22) : CupertinoColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Pilih Tahun',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? CupertinoColors.white
                            : const Color(0xFF111827),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker.builder(
                  itemExtent: 42,
                  scrollController: FixedExtentScrollController(
                    initialItem: _tahun - 2020,
                  ),
                  childCount: tahunSekarang - 2020 + 1,
                  onSelectedItemChanged: (index) {
                    tahunDipilih = 2020 + index;
                  },
                  itemBuilder: (context, index) {
                    final tahun = 2020 + index;

                    return Center(
                      child: Text(
                        '$tahun',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: tahun == _tahun
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isDark
                              ? CupertinoColors.white
                              : const Color(0xFF111827),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () {
                    Navigator.pop(context, tahunDipilih);
                  },
                  child: const Text(
                    'Pilih',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (tahunHasil == null || tahunHasil == _tahun) {
      return;
    }

    setState(() {
      _tahun = tahunHasil;
    });

    await _loadCuti();
  }

  Future<void> _refresh() async {
    await _loadCuti();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    final foregroundColor = isDark
        ? CupertinoColors.white
        : const Color(0xFF111827);

    final secondaryColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0F14)
          : const Color(0xFFF6F8FB),
      child: SafeArea(
        bottom: false,
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            fontFamily: 'Poppins',
            decoration: TextDecoration.none,
          ),
          child: Column(
            children: [
              _buildHeader(
                isDark: isDark,
                foregroundColor: foregroundColor,
                secondaryColor: secondaryColor,
              ),
              Expanded(
                child: _buildBody(
                  isDark: isDark,
                  foregroundColor: foregroundColor,
                  secondaryColor: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? CupertinoColors.white.withOpacity(0.07)
                    : CupertinoColors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? CupertinoColors.white.withOpacity(0.07)
                      : CupertinoColors.white.withOpacity(0.95),
                ),
              ),
              child: Icon(
                CupertinoIcons.chevron_left,
                size: 20,
                color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuti',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                    decoration: TextDecoration.none,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ringkasan dan riwayat cuti Anda',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: secondaryColor,
                    decoration: TextDecoration.none,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _loadCuti,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151A22) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF242A33)
                      : const Color(0xFFE7EAF0),
                ),
              ),
              child: const Icon(
                CupertinoIcons.refresh,
                size: 18,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    if (_isLoading && _data == null) {
      return const Center(child: CupertinoActivityIndicator(radius: 13));
    }

    if (_errorMessage != null && _data == null) {
      return _buildError(
        isDark: isDark,
        foregroundColor: foregroundColor,
        secondaryColor: secondaryColor,
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refresh),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildYearFilter(
                isDark: isDark,
                foregroundColor: foregroundColor,
                secondaryColor: secondaryColor,
              ),
              const SizedBox(height: 16),
              if (_data != null)
                _buildSummary(
                  data: _data!,
                  isDark: isDark,
                  foregroundColor: foregroundColor,
                  secondaryColor: secondaryColor,
                ),
              const SizedBox(height: 26),
              _buildHistoryHeader(
                foregroundColor: foregroundColor,
                secondaryColor: secondaryColor,
              ),
              const SizedBox(height: 12),
              if (_data == null || _data!.riwayat.isEmpty)
                _buildEmpty(
                  isDark: isDark,
                  foregroundColor: foregroundColor,
                  secondaryColor: secondaryColor,
                )
              else
                ..._data!.riwayat.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildHistoryItem(
                      item: item,
                      isDark: isDark,
                      foregroundColor: foregroundColor,
                      secondaryColor: secondaryColor,
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildYearFilter({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tahun',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: secondaryColor,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: _pilihTahun,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151A22) : CupertinoColors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF242A33)
                    : const Color(0xFFE7EAF0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 10),
                Text(
                  '$_tahun',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                    decoration: TextDecoration.none,
                  ),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 15,
                  color: secondaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary({
    required CutiData data,
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Tersedia',
            value: data.tersedia,
            subtitle: 'hari',
            icon: CupertinoIcons.calendar,
            iconColor: const Color(0xFF16A34A),
            isDark: isDark,
            foregroundColor: foregroundColor,
            secondaryColor: secondaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: 'Terpakai',
            value: data.terpakai,
            subtitle: 'hari',
            icon: CupertinoIcons.calendar_badge_minus,
            iconColor: const Color(0xFFF97316),
            isDark: isDark,
            foregroundColor: foregroundColor,
            secondaryColor: secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A22) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF111827).withOpacity(0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: foregroundColor,
                  decoration: TextDecoration.none,
                  height: 1,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: secondaryColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader({
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Row(
      children: [
        Text(
          'Riwayat Cuti',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: foregroundColor,
            decoration: TextDecoration.none,
          ),
        ),
        const Spacer(),
        if (_data != null)
          Text(
            '${_data!.riwayat.length} periode',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
              decoration: TextDecoration.none,
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required CutiRiwayat item,
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A22) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.calendar_badge_plus,
              size: 19,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.jumlahHari == 1
                      ? 'Cuti 1 hari'
                      : 'Cuti ${item.jumlahHari} hari',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.tanggal,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: secondaryColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.jumlahHari} hari',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A34A),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A22) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.calendar, size: 34, color: secondaryColor),
          const SizedBox(height: 12),
          Text(
            'Belum ada cuti',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tidak ada riwayat cuti pada tahun $_tahun.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              color: secondaryColor,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 42,
              color: isDark ? CupertinoColors.white : const Color(0xFF111827),
            ),
            const SizedBox(height: 14),
            Text(
              'Gagal memuat data cuti',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                color: secondaryColor,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 18),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(13),
              onPressed: _loadCuti,
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
