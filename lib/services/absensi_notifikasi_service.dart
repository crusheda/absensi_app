import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import 'package:timezone/timezone.dart' as tz;

class AbsensiNotifikasiService {
  static Future<void> scheduleAbsensiReminder(int user) async {
    final url = Uri.parse("${ApiService.baseUrl}/reminder/shift?id_user=$user");

    try {
      print('[REMINDER] Memanggil API $url...');
      final response = await http.get(url);
      print('[REMINDER] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse jam masuk dari API
        final jamMasuk = DateTime.parse("${data['tanggal']} ${data['push']}");
        final scheduledTime = tz.TZDateTime.from(jamMasuk, tz.local);
        final now = tz.TZDateTime.now(tz.local);

        print("[REMINDER] Sekarang: $now");
        print("[REMINDER] Jadwal notifikasi: $scheduledTime");

        // Inisialisasi plugin notifikasi
        final plugin = FlutterLocalNotificationsPlugin();

        const androidDetails = AndroidNotificationDetails(
          'absen_channel',
          'Pengingat Absensi',
          channelDescription: 'Notifikasi pengingat sebelum jam masuk shift',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
        print(
          "[REMINDER] Selisih detik: ${scheduledTime.difference(now).inSeconds}",
        );

        // Tentukan apakah tampilkan langsung atau dijadwalkan
        if (scheduledTime.isBefore(now) ||
            scheduledTime.isAtSameMomentAs(now)) {
          print(
            "[REMINDER] Waktu notifikasi sudah lewat atau sekarang, tampilkan langsung.",
          );
          await plugin.show(
            0,
            'Pengingat Absensi',
            'Jaga ${data['shift']} akan dimulai.\nAbsen Masuk pukul ${data['jam']}!',
            const NotificationDetails(android: androidDetails),
          );
        } else {
          print("[REMINDER] Waktu masih di masa depan, dijadwalkan.");
          await plugin.zonedSchedule(
            0,
            'Pengingat Absensi',
            'Jaga ${data['shift']} akan dimulai 1 jam lagi.\nAbsen Masuk pukul ${data['jam']}!',
            scheduledTime,
            const NotificationDetails(android: androidDetails),
            androidAllowWhileIdle: true,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          print("[REMINDER] Notifikasi berhasil dijadwalkan!");
        }
      } else {
        print(
          "[REMINDER] Gagal memuat data shift. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("API Gagal : $e");
    }
  }
}
