import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/api_service.dart';

class JadwalPage extends StatefulWidget {
  final int id_user;

  const JadwalPage({super.key, required this.id_user});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  DateTime selectedDate = DateTime.now();

  Map<String, String> jadwalData = {};
  Map<String, dynamic> rekanKerja = {};
  Map<String, String> refShift = {};
  Map<String, String> refJam = {};
  Map<String, String> iconMap = {};
  Map<String, String> colorMap = {};
  Map<String, dynamic> flowData = {};

  // Data libur nasional dari API.
  List<Map<String, dynamic>> refLiburNasional = [];

  bool isLoading = true;
  bool jadwalKosong = false;

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '').trim();

    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }

    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }

    return CupertinoColors.systemGrey;
  }

  Color getColor(String kodeShift) {
    final hex = colorMap[kodeShift] ?? '#9E9E9E';
    return hexToColor(hex);
  }

  /// Mengambil data libur nasional berdasarkan tanggal.
  Map<String, dynamic>? getHoliday(DateTime date) {
    for (final holiday in refLiburNasional) {
      final tahun = int.tryParse('${holiday['tahun']}');
      final bulan = int.tryParse('${holiday['bulan']}');
      final tgl = int.tryParse('${holiday['tgl']}');

      if (tahun == date.year && bulan == date.month && tgl == date.day) {
        return holiday;
      }
    }

    return null;
  }

  Widget buildShiftCircle(String? status, Map<String, String> colors) {
    if (status == null || status.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorHex = colors[status] ?? '#9E9E9E';
    final shiftColor = hexToColor(colorHex);

    return Container(
      constraints: const BoxConstraints(minWidth: 25, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: shiftColor,
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          status,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.white,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget buildLegendCircle(String code, Color? color) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? CupertinoColors.systemGrey,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        code,
        maxLines: 1,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: CupertinoColors.white,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchJadwal();
  }

  Future<void> fetchJadwal() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        jadwalKosong = false;
      });
    }

    final bulan = selectedDate.month.toString().padLeft(2, '0');
    final tahun = selectedDate.year;

    final url = '${ApiService.baseUrl}/jadwal2/${widget.id_user}/$bulan/$tahun';

    try {
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final rawJadwal = data['jadwal'];

        if (rawJadwal == null || (rawJadwal is Map && rawJadwal.isEmpty)) {
          setState(() {
            jadwalData = {};
            rekanKerja = {};
            refShift = {};
            refJam = {};
            iconMap = {};
            colorMap = {};
            flowData = {};
            refLiburNasional = [];
            jadwalKosong = true;
          });
        } else {
          setState(() {
            jadwalData = Map<String, String>.from(data['jadwal'] ?? {});

            rekanKerja = Map<String, dynamic>.from(data['rekan_kerja'] ?? {});

            refShift = Map<String, String>.from(data['ref_shift'] ?? {});

            refJam = Map<String, String>.from(data['ref_jam'] ?? {});

            iconMap = Map<String, String>.from(data['icon'] ?? {});

            colorMap = Map<String, String>.from(data['color'] ?? {});

            flowData = Map<String, dynamic>.from(data['flow'] ?? {});

            refLiburNasional = (data['ref_libur_nasional'] as List? ?? [])
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();

            jadwalKosong = false;
          });
        }
      } else {
        setState(() {
          jadwalKosong = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetch jadwal: $e');

      if (!mounted) return;

      setState(() {
        jadwalKosong = true;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDetail(String tanggal, String status) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final rawRekan = rekanKerja[tanggal];

    List<dynamic> rekan = [];

    if (rawRekan is List) {
      rekan = rawRekan;
    } else if (rawRekan is String && rawRekan.isNotEmpty) {
      rekan = [rawRekan];
    }

    final namaRekan = rekan.isNotEmpty ? rekan.join(', ') : '-';

    final namaShift = refShift[status] ?? status;
    final jam = refJam[status];

    final holiday = getHoliday(
      DateTime(
        selectedDate.year,
        selectedDate.month,
        int.tryParse(tanggal) ?? 0,
      ),
    );

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: Text(
            'Detail Shift',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogInfo(
                  icon: CupertinoIcons.rectangle_3_offgrid,
                  label: 'Shift',
                  value: namaShift,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildDialogInfo(
                  icon: CupertinoIcons.clock,
                  label: 'Jam',
                  value: jam != null && jam.isNotEmpty ? '$jam WIB' : '-',
                  isDark: isDark,
                ),
                if (jam != null && jam.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDialogInfo(
                    icon: CupertinoIcons.person_2_fill,
                    label: 'Rekan Kerja',
                    value: namaRekan,
                    isDark: isDark,
                  ),
                ],
                if (holiday != null) ...[
                  const SizedBox(height: 10),
                  _buildDialogInfo(
                    icon: CupertinoIcons.calendar,
                    label: 'Libur Nasional',
                    value: '${holiday['deskripsi'] ?? '-'}',
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Tutup',
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
  }

  Widget _buildDialogInfo({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: CupertinoColors.activeBlue),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label\n',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDateCell(DateTime date, bool isCurrentMonth, bool isToday) {
    final key = date.day.toString().padLeft(2, '0');

    final status = isCurrentMonth ? jadwalData[key] : null;

    final holiday = isCurrentMonth ? getHoliday(date) : null;

    final isHoliday = holiday != null;

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final backgroundColor = isHoliday
        ? (isDark ? const Color(0xFF30251A) : const Color(0xFFFFF7E8))
        : (isDark ? const Color(0xFF171B22) : CupertinoColors.white);

    final textColor = !isCurrentMonth
        ? (isDark ? const Color(0xFF4B5563) : CupertinoColors.systemGrey3)
        : (isDark ? CupertinoColors.white : CupertinoColors.black);

    final borderColor = isToday
        ? CupertinoColors.activeBlue
        : isHoliday
        ? (isDark ? const Color(0xFFE09B32) : const Color(0xFFF2B84B))
        : (isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0));

    return GestureDetector(
      onTap: status != null && status.isNotEmpty
          ? () => _showDetail(key, status)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isToday || isHoliday ? 1.5 : 0.8,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 23,
              height: 23,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isToday)
                    Container(
                      width: 23,
                      height: 23,
                      decoration: const BoxDecoration(
                        color: CupertinoColors.activeBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? CupertinoColors.white : textColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            if (status != null && status.isNotEmpty)
              buildShiftCircle(status, colorMap)
            else
              const SizedBox(height: 20),
            if (isHoliday) ...[
              const SizedBox(height: 2),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildCalendar() {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);

    final totalDays = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;

    final startWeekday = firstDay.weekday;
    final daysBefore = startWeekday - 1;

    final prevMonth = DateTime(selectedDate.year, selectedDate.month - 1);

    final prevMonthDays = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;

    final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);

    final calendarDates = <DateTime>[];

    for (int i = daysBefore; i > 0; i--) {
      calendarDates.add(
        DateTime(prevMonth.year, prevMonth.month, prevMonthDays - i + 1),
      );
    }

    for (int i = 1; i <= totalDays; i++) {
      calendarDates.add(DateTime(selectedDate.year, selectedDate.month, i));
    }

    final remaining = (7 - calendarDates.length % 7) % 7;

    for (int i = 1; i <= remaining; i++) {
      calendarDates.add(DateTime(nextMonth.year, nextMonth.month, i));
    }

    const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final entries = refShift.entries.toList();

    final half = (entries.length / 2).ceil();

    final leftItems = entries.sublist(0, half);

    final rightItems = entries.sublist(half);

    if (jadwalKosong) {
      return _buildEmptySchedule(isDark: isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarCard(
          isDark: isDark,
          weekdays: weekdays,
          calendarDates: calendarDates,
        ),

        if (refLiburNasional.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildNationalHolidayCard(isDark: isDark),
        ],

        const SizedBox(height: 14),

        _buildShiftLegendCard(
          isDark: isDark,
          leftItems: leftItems,
          rightItems: rightItems,
        ),

        if (flowData.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildScheduleInfoCard(isDark: isDark),
        ],
      ],
    );
  }

  Widget _buildCalendarCard({
    required bool isDark,
    required List<String> weekdays,
    required List<DateTime> calendarDates,
  }) {
    final cardColor = isDark ? const Color(0xFF11151C) : CupertinoColors.white;

    final secondaryColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.systemGrey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: weekdays.map((day) {
              final isWeekend = day == 'Sab' || day == 'Min';

              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isWeekend
                          ? CupertinoColors.systemRed
                          : secondaryColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,

              // Dibuat lebih tinggi agar tidak overflow.
              childAspectRatio: 0.68,
            ),
            itemCount: calendarDates.length,
            itemBuilder: (context, index) {
              final date = calendarDates[index];

              return buildDateCell(
                date,
                date.month == selectedDate.month,
                isSameDate(date, DateTime.now()),
              );
            },
          ),

          const SizedBox(height: 10),

          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Icon(
                CupertinoIcons.hand_draw_fill,
                size: 12,
                color: secondaryColor,
              ),
              Text(
                'Ketuk tanggal untuk melihat detail shift',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9.5,
                  color: secondaryColor,
                  decoration: TextDecoration.none,
                ),
              ),
              if (refLiburNasional.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'Libur Nasional',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    color: secondaryColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNationalHolidayCard({required bool isDark}) {
    final cardColor = isDark ? const Color(0xFF11151C) : CupertinoColors.white;

    final titleColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    final secondaryColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.systemGrey;

    final sortedHolidays = [...refLiburNasional]
      ..sort((a, b) {
        final aDate = DateTime(
          int.tryParse('${a['tahun']}') ?? 0,
          int.tryParse('${a['bulan']}') ?? 0,
          int.tryParse('${a['tgl']}') ?? 0,
        );

        final bDate = DateTime(
          int.tryParse('${b['tahun']}') ?? 0,
          int.tryParse('${b['bulan']}') ?? 0,
          int.tryParse('${b['tgl']}') ?? 0,
        );

        return aDate.compareTo(bDate);
      });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.calendar,
                  size: 17,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Libur Nasional',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...sortedHolidays.map((holiday) {
            final day = int.tryParse('${holiday['tgl']}') ?? 0;

            final month = int.tryParse('${holiday['bulan']}') ?? 0;

            final year = int.tryParse('${holiday['tahun']}') ?? 0;

            final description = '${holiday['deskripsi'] ?? 'Libur Nasional'}'
                .trim();

            final date = DateTime(year, month, day);

            final formattedDate = DateFormat(
              'EEEE, dd MMMM yyyy',
              'id',
            ).format(date);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShiftLegendCard({
    required bool isDark,
    required List<MapEntry<String, String>> leftItems,
    required List<MapEntry<String, String>> rightItems,
  }) {
    final cardColor = isDark ? const Color(0xFF11151C) : CupertinoColors.white;

    final titleColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.calendar,
                  size: 17,
                  color: CupertinoColors.activeBlue,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Keterangan Shift',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),

          if (refShift.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Tidak ada keterangan shift.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: isDark
                      ? CupertinoColors.systemGrey2
                      : CupertinoColors.systemGrey,
                  decoration: TextDecoration.none,
                ),
              ),
            )
          else ...[
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: leftItems
                        .map(
                          (entry) => _buildLegendItem(
                            code: entry.key,
                            label: entry.value,
                            isDark: isDark,
                          ),
                        )
                        .toList(),
                  ),
                ),

                if (rightItems.isNotEmpty) const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    children: rightItems
                        .map(
                          (entry) => _buildLegendItem(
                            code: entry.key,
                            label: entry.value,
                            isDark: isDark,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String code,
    required String label,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildLegendCircle(code, getColor(code)),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfoCard({required bool isDark}) {
    final cardColor = isDark ? const Color(0xFF11151C) : CupertinoColors.white;

    final foregroundColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.black;

    final secondaryColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.systemGrey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.info_circle_fill,
                  size: 17,
                  color: CupertinoColors.activeBlue,
                ),
              ),

              const SizedBox(width: 10),

              Text(
                'Keterangan Jadwal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...flowData.entries.map((entry) {
            final key = entry.key;
            final value = entry.value;

            if (key == 'Daftar Staf' && value is List) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Staf',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: foregroundColor,
                        decoration: TextDecoration.none,
                      ),
                    ),

                    const SizedBox(height: 7),

                    ...value.map<Widget>((staf) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '•',
                              style: TextStyle(
                                color: CupertinoColors.activeBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(width: 7),

                            Expanded(
                              child: Text(
                                '$staf',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10.5,
                                  color: foregroundColor,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      '$key',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: foregroundColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule({required bool isDark}) {
    final secondaryColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.systemGrey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11151C) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2028) : const Color(0xFFF0F2F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.calendar,
              size: 32,
              color: secondaryColor,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Jadwal tidak ada',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Tidak terdapat jadwal pada bulan yang dipilih.',
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

  Future<void> _showMonthPicker() async {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    int selectedMonth = selectedDate.month;
    int selectedYear = selectedDate.year;

    final currentYear = DateTime.now().year;

    await showCupertinoModalPopup(
      context: context,
      builder: (popupContext) {
        return Container(
          height: 330,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF11151C)
                : CupertinoColors.systemBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 8),

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A404A)
                        : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Pilih Bulan & Tahun',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                    decoration: TextDecoration.none,
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 42,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedMonth - 1,
                          ),
                          onSelectedItemChanged: (index) {
                            selectedMonth = index + 1;
                          },
                          children: List.generate(12, (index) {
                            return Center(
                              child: Text(
                                '${index + 1}'.padLeft(2, '0'),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: isDark
                                      ? CupertinoColors.white
                                      : CupertinoColors.black,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 150,
                        color: isDark
                            ? const Color(0xFF242A33)
                            : const Color(0xFFE5E7EB),
                      ),

                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 42,
                          scrollController: FixedExtentScrollController(
                            initialItem: currentYear - selectedYear,
                          ),
                          onSelectedItemChanged: (index) {
                            selectedYear = currentYear - index;
                          },
                          children: List.generate(10, (index) {
                            return Center(
                              child: Text(
                                '${currentYear - index}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: isDark
                                      ? CupertinoColors.white
                                      : CupertinoColors.black,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(15),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () {
                        Navigator.pop(popupContext);

                        setState(() {
                          selectedDate = DateTime(selectedYear, selectedMonth);
                        });

                        fetchJadwal();
                      },
                      child: const Text(
                        'Terapkan',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy', 'id');

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
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(
              foregroundColor: foregroundColor,
              secondaryColor: secondaryColor,
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 125),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSelector(
                      isDark: isDark,
                      foregroundColor: foregroundColor,
                      secondaryColor: secondaryColor,
                      formatter: formatter,
                    ),

                    const SizedBox(height: 14),

                    if (isLoading)
                      _buildLoading(isDark: isDark)
                    else
                      buildCalendar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required Color foregroundColor,
    required Color secondaryColor,
  }) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal Saya',
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
                  'Lihat jadwal kerja dan shift Anda',
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
            onPressed: isLoading ? null : () => fetchJadwal(),
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
              child: Icon(
                CupertinoIcons.refresh,
                size: 18,
                color: isLoading
                    ? secondaryColor.withValues(alpha: 0.45)
                    : CupertinoColors.activeBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector({
    required bool isDark,
    required Color foregroundColor,
    required Color secondaryColor,
    required DateFormat formatter,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _showMonthPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF11151C) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                CupertinoIcons.calendar,
                size: 18,
                color: CupertinoColors.activeBlue,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Periode Jadwal',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9.5,
                      color: secondaryColor,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    formatter.format(selectedDate),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: foregroundColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),

            Icon(CupertinoIcons.chevron_down, size: 15, color: secondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading({required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11151C) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF242A33) : const Color(0xFFE7EAF0),
        ),
      ),
      child: const Column(
        children: [
          CupertinoActivityIndicator(radius: 14),
          SizedBox(height: 14),
          Text(
            'Memuat jadwal...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: CupertinoColors.systemGrey,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
