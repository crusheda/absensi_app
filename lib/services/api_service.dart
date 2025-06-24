import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // static const String baseUrl = "https://absensi.simrsmu.com/api"; // Ganti ke URL kamu
  static const String baseUrl =
      "http://192.168.254.80:8000/api"; // Ganti ke URL kamu

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

    var response = await request.send();
    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      return jsonDecode(respStr)['message'] ?? 'Berhasil';
    } else {
      return 'Gagal absen: ${response.statusCode}';
    }
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final uri = Uri.parse('$baseUrl/login');

    final response = await http.post(
      uri,
      body: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'],
        'nip': data['user']['nip'],
      };
    } else {
      final data = jsonDecode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Login gagal'};
    }
  }
}
