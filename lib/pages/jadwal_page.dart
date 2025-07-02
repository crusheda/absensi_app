import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchJadwal();
  }

  Future<void> fetchJadwal() async {
    setState(() => isLoading = true);
    final bulan = selectedDate.month.toString().padLeft(2, '0');
    final tahun = selectedDate.year;
    final url = '${ApiService.baseUrl}/jadwal/${widget.id_user}/$bulan/$tahun';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => jadwalData = Map<String, String>.from(data['jadwal']));
      } else {
        debugPrint('Gagal mengambil jadwal');
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDetail(String status) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Detail Jadwal"),
        content: Text("Keterangan: ${statusLabel(status)}"),
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

  String statusLabel(String code) {
    switch (code) {
      case 'H':
        return 'Masuk Shift Siang';
      case 'L':
        return 'Libur';
      case 'CU':
        return 'Cuti Umum';
      case 'CM':
        return 'Cuti Melahirkan';
      case 'C':
        return 'Cuti';
      case 'CD':
        return 'Cuti Dispensasi';
      case 'A':
        return 'Alpha';
      default:
        return code;
    }
  }

  Widget buildDateCell(DateTime date, bool isCurrentMonth) {
    final key = date.day.toString().padLeft(2, '0');
    final status = isCurrentMonth ? jadwalData[key] : null;
    Icon? icon;

    if (status == 'H') {
      icon = const Icon(
        CupertinoIcons.check_mark_circled_solid,
        color: CupertinoColors.activeGreen,
        size: 12,
      );
    } else if (status == 'L') {
      icon = const Icon(
        CupertinoIcons.minus_circle_fill,
        color: CupertinoColors.systemRed,
        size: 12,
      );
    } else if (status != null) {
      icon = const Icon(
        CupertinoIcons.check_mark_circled,
        color: CupertinoColors.systemGrey2,
        size: 12,
      );
    }

    return GestureDetector(
      onTap: status != null ? () => _showDetail(status) : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
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
                color: isCurrentMonth
                    ? CupertinoColors.black
                    : CupertinoColors.systemGrey,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: CupertinoColors.systemGrey4,
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
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: CupertinoColors.systemGrey4,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Keterangan :",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                ),
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    size: 14,
                    color: CupertinoColors.activeGreen,
                  ),
                  SizedBox(width: 4),
                  Text("Masuk Shift"),
                  SizedBox(width: 12),
                  Icon(
                    CupertinoIcons.check_mark_circled,
                    size: 14,
                    color: CupertinoColors.systemGrey2,
                  ),
                  SizedBox(width: 4),
                  Text("Masuk Shift (Lainnya)"),
                  SizedBox(width: 12),
                  Icon(
                    CupertinoIcons.minus_circle_fill,
                    size: 14,
                    color: CupertinoColors.systemRed,
                  ),
                  SizedBox(width: 4),
                  Text("Libur/Cuti"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMonthPicker() async {
    DateTime tempDate = selectedDate;
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selectedDate,
                maximumDate: DateTime.now().add(const Duration(days: 365)),
                onDateTimeChanged: (date) => tempDate = date,
              ),
            ),
            CupertinoButton(
              child: const Text("Terapkan"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  selectedDate = tempDate;
                });
                fetchJadwal();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy', 'id');
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Jadwal Saya')),
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
                      child: SingleChildScrollView(child: buildCalendar()),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
