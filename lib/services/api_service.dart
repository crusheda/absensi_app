import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti sesuai URL API Laravel kamu
  static const String baseUrl = "http://192.168.254.80:8000/api";

  /// Kirim absensi dengan foto dan lokasi
  static Future<String> kirimAbsensi({
    required String nip,
    required File imageFile,
    required double latitude,
    required double longitude,
    required String jenis,
  }) async {
    final uri = Uri.parse('$baseUrl/absensi');

    var request = http.MultipartRequest('POST', uri)
      ..fields['nip'] = nip
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..fields['jenis'] = jenis
      ..files.add(await http.MultipartFile.fromPath('foto', imageFile.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['message'] ?? 'Berhasil';
      } else {
        return 'Gagal absen: ${response.statusCode}';
      }
    } catch (e) {
      return 'Terjadi kesalahan saat mengirim absensi';
    }
  }

  /// Login pengguna dan simpan token jika berhasil
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final uri = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        uri,
        headers: {'Accept': 'application/json'},
        body: {'username': username, 'password': password},
      );

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Simpan token jika tersedia
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
        }

        return {
          'success': true,
          'message': data['message'],
          'nip': data['user']['nip'],
          'name': data['user']['name'],
          'nama': data['user']['nama'],
          'foto_profil': data['user']['foto_profil'] ?? '',
        };
      } else {
        // Tetap coba decode meskipun status bukan 200
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Login gagal',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Login gagal (response tidak valid)',
          };
        }
      }
    } catch (e) {
      print("Error saat login: $e");
      return {'success': false, 'message': 'Terjadi kesalahan saat login'};
    }
  }

  /// Logout dan hapus token dari penyimpanan lokal
  static Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final uri = Uri.parse('$baseUrl/logout');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        await prefs.remove('token');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Ambil token saat ini dari penyimpanan lokal (jika diperlukan)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
