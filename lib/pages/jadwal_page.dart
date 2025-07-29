import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
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
  Map<String, String> refShift = {};
  Map<String, String> iconMap = {};
  Map<String, String> colorMap = {};
  Map<String, dynamic> flowData = {};
  bool isLoading = true;
  bool jadwalKosong = false;

  // Helper mapping icon
  IconData? getIconData(String? name) {
    switch (name) {
      case 'check_mark_circled_solid':
        return CupertinoIcons.check_mark_circled_solid;
      case 'check_mark_circled':
        return CupertinoIcons.check_mark_circled;
      case 'minus_circle_fill':
        return CupertinoIcons.minus_circle_fill;
      case 'clear_circled':
        return CupertinoIcons.clear_circled; // fallback, solid tidak ada
      default:
        return CupertinoIcons.question_circle; // fallback kalau tidak cocok
    }
  }

  // Helper mapping color
  Color? getColor(String? name) {
    switch (name) {
      case 'activeGreen':
        return CupertinoColors.activeGreen;
      case 'activeBlue':
        return CupertinoColors.activeBlue;
      case 'systemGrey2':
        return CupertinoColors.systemGrey2;
      case 'systemOrange':
        return CupertinoColors.systemOrange;
      case 'systemPink':
        return CupertinoColors.systemPink;
      case 'systemRed':
        return CupertinoColors.systemRed;
      case 'systemTeal':
        return CupertinoColors.systemTeal;
      case 'systemIndigo':
        return CupertinoColors.systemIndigo;
      default:
        return CupertinoColors.systemGrey; // fallback kalau nama tidak cocok
    }
  }

  @override
  void initState() {
    super.initState();
    fetchJadwal();
  }

  Future<void> fetchJadwal() async {
    setState(() {
      isLoading = true;
      jadwalKosong = false; // Reset dulu tiap fetch
    });

    final bulan = selectedDate.month.toString().padLeft(2, '0');
    final tahun = selectedDate.year;
    final url = '${ApiService.baseUrl}/jadwal/${widget.id_user}/$bulan/$tahun';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cek isi jadwal
        if (data['jadwal'] == null || (data['jadwal'] as Map).isEmpty) {
          setState(() {
            jadwalKosong = true;
          });
        } else {
          setState(() {
            jadwalData = Map<String, String>.from(data['jadwal']);
            refShift = Map<String, String>.from(data['ref_shift']);
            iconMap = Map<String, String>.from(data['icon']);
            colorMap = Map<String, String>.from(data['color']);
            flowData = Map<String, dynamic>.from(data['flow']);
            jadwalKosong = false; // Ada data, bukan kosong
          });
        }
      } else {
        debugPrint('Gagal mengambil jadwal');
        setState(() {
          jadwalKosong = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        jadwalKosong = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDetail(String status) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Detail Jadwal"),
        content: Text("Keterangan: ${refShift[status] ?? status}"),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Tutup"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget buildDateCell(DateTime date, bool isCurrentMonth) {
    final key = date.day.toString().padLeft(2, '0');
    final status = isCurrentMonth ? jadwalData[key] : null;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    Icon? icon;

    if (status != null) {
      final iconName = iconMap[status];
      final colorName = colorMap[status];

      final iconData = getIconData(iconName);
      final iconColor = getColor(colorName);

      if (iconData != null && iconColor != null) {
        icon = Icon(iconData, color: iconColor, size: 12);
      }
    }

    return GestureDetector(
      onTap: status != null ? () => _showDetail(status) : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.secondaryLabel
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? (isCurrentMonth
                          ? CupertinoColors.white
                          : CupertinoColors.systemGrey)
                    : (isCurrentMonth
                          ? CupertinoColors.black
                          : CupertinoColors.systemGrey),
              ),
            ),
            const SizedBox(height: 2),
            if (icon != null) icon,
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

    List<DateTime> calendarDates = [];
    for (int i = daysBefore; i > 0; i--) {
      calendarDates.add(
        DateTime(prevMonth.year, prevMonth.month, prevMonthDays - i + 1),
      );
    }
    for (int i = 1; i <= totalDays; i++) {
      calendarDates.add(DateTime(selectedDate.year, selectedDate.month, i));
    }
    int remaining = 7 - (calendarDates.length % 7);
    if (remaining < 7) {
      for (int i = 1; i <= remaining; i++) {
        calendarDates.add(DateTime(nextMonth.year, nextMonth.month, i));
      }
    }

    final weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final entries = refShift.entries.toList();
    final half = (entries.length / 2).ceil();
    final leftItems = entries.sublist(0, half);
    final rightItems = entries.sublist(half);

    if (jadwalKosong) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 40),
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 30,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 18),
            const Text(
              "Jadwal tidak ada",
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.secondaryLabel
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? CupertinoColors.black
                    : CupertinoColors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekdays
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 6),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 7,
                padding: EdgeInsets.zero,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                physics: const NeverScrollableScrollPhysics(),
                children: calendarDates
                    .map(
                      (date) =>
                          buildDateCell(date, date.month == selectedDate.month),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.secondaryLabel
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? CupertinoColors.black
                    : CupertinoColors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Keterangan Shift",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: leftItems.map((entry) {
                        final code = entry.key;
                        final label = entry.value;
                        final iconData = getIconData(iconMap[code]);
                        final iconColor = getColor(colorMap[code]);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                iconData ?? CupertinoIcons.question_circle,
                                size: 14,
                                color: iconColor ?? CupertinoColors.systemGrey,
                              ),
                              const SizedBox(width: 4),
                              Flexible(child: Text(label)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rightItems.map((entry) {
                        final code = entry.key;
                        final label = entry.value;
                        final iconData = getIconData(iconMap[code]);
                        final iconColor = getColor(colorMap[code]);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                iconData ?? CupertinoIcons.question_circle,
                                size: 14,
                                color: iconColor ?? CupertinoColors.systemGrey,
                              ),
                              const SizedBox(width: 4),
                              Flexible(child: Text(label)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.secondaryLabel
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? CupertinoColors.black
                    : CupertinoColors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Keterangan Jadwal",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...flowData.entries.map((entry) {
                final key = entry.key;
                final value = entry.value;

                if (key == 'Daftar Staf' && value is List) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Daftar Staf (Diurutkan sesuai Abjad) : ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...value.map<Widget>(
                          (staf) => Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 2),
                            child: Text(
                              "- $staf",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            "$key",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: Text(
                            ": $value",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showMonthPicker() async {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    int selectedMonth = selectedDate.month;
    int selectedYear = selectedDate.year;

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => SafeArea(
        child: Container(
          height: 310,
          color: isDark
              ? CupertinoColors.black.withOpacity(0.8)
              : CupertinoColors.systemBackground,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Pilihan Filter Bulan & Tahun',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
              ),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedMonth - 1,
                        ),
                        onSelectedItemChanged: (index) {
                          selectedMonth = index + 1;
                        },
                        children: List.generate(
                          12,
                          (index) => Center(
                            child: Text(
                              "${index + 1}".padLeft(2, '0'),
                              style: TextStyle(
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: DateTime.now().year - selectedYear,
                        ),
                        onSelectedItemChanged: (index) {
                          selectedYear = DateTime.now().year - index;
                        },
                        children: List.generate(
                          3, // 10 tahun ke belakang
                          (index) => Center(
                            child: Text(
                              "${DateTime.now().year - index}",
                              style: TextStyle(
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                child: const Text("Terapkan"),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    selectedDate = DateTime(selectedYear, selectedMonth);
                  });
                  fetchJadwal();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy', 'id');
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Jadwal Saya',
          style: TextStyle(
            color: CupertinoTheme.brightnessOf(context) == Brightness.dark
                ? CupertinoColors.systemGrey2
                : CupertinoColors.black,
          ),
        ),
        backgroundColor: CupertinoTheme.brightnessOf(context) == Brightness.dark
            ? CupertinoColors.transparent
            : CupertinoColors.systemGrey4.withOpacity(0.1),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _showMonthPicker,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(formatter.format(selectedDate)),
                          const SizedBox(width: 6),
                          const Icon(CupertinoIcons.calendar),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              isLoading
                  ? const Expanded(
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  : Expanded(
                      child: jadwalKosong
                          ? buildCalendar()
                          : SingleChildScrollView(child: buildCalendar()),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
