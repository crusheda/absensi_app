import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti sesuai URL API Laravel kamu
  // static const String baseUrl = "http://192.168.254.80:8000/api";
  static const String baseUrl = "http://192.168.1.35:8000/api";
  // static const String baseUrl = "https://absensi.simrsmu.com/api";
  static const String simrsUrl = "https://simrsmu.com";

  static Future<LatLng> getLokasiKantor() async {
    final response = await http.get(Uri.parse('$baseUrl/lokasi-kantor'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return LatLng(data['latitude'], data['longitude']);
    } else {
      throw Exception('Gagal mengambil lokasi kantor');
    }
  }

  static Future<Map<String, dynamic>> cekValidasiTombol({
    required int id_user,
    required double latitude,
    required double longitude,
    required double jarak,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/validasi'),
      body: {
        'id_user': id_user.toString(),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'jarak': jarak.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'berangkat': data['berangkat'] ?? false,
        'pulang': data['pulang'] ?? false,
        'ijin': data['ijin'] ?? false,
        // 'absenclear': data['absenclear'] ?? false,
        'nama': data['nama'] ?? '-',
        'jam': data['jam'] ?? '-',
        'keterangan': data['keterangan'] ?? '-',
        'message': data['message'] ?? '',
      };
    } else {
      throw Exception('Gagal memvalidasi tombol');
    }
  }

  /// Kirim absensi dengan foto dan lokasi
  static String mimeTypeFromExtension(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'jpeg';
      case '.png':
        return 'png';
      default:
        return 'jpeg'; // default fallback
    }
  }

  static Future<Map<String, dynamic>> kirimAbsensi({
    required String id_user,
    required String nip,
    required File imageFile,
    required double latitude,
    required double longitude,
    required String jenis,
    String? keterangan,
  }) async {
    final uri = Uri.parse('$baseUrl/absensi');
    final extension = mimeTypeFromExtension(imageFile.path);

    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..fields['id_user'] = id_user
      ..fields['nip'] = nip
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..fields['jenis'] = jenis;
    if (keterangan != null && keterangan.trim().isNotEmpty) {
      request.fields['keterangan'] = keterangan;
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'foto',
        imageFile.path,
        contentType: MediaType('image', extension),
      ),
    );

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      final data = jsonDecode(respStr);
      final jsonCode = data['code'] ?? 500;

      return {
        'code': jsonCode,
        'message': data['message'] ?? 'Tidak ada pesan',
        'data': data['data'] ?? {},
      };
    } catch (e) {
      return {
        'code': 401,
        'message': 'Terjadi kesalahan saat mengirim data: $e',
      };
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
          'id_user': data['user']['id_user'],
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
