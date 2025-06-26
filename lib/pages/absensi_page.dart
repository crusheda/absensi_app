// Final Absensi Page dengan desain kotak seperti pada gambar terakhir
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../models/absensi_enum.dart';

class AbsensiPage extends StatefulWidget {
  final int id_user;
  final String nip;
  const AbsensiPage({super.key, required this.nip, required this.id_user});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  static const lokasiAbsensi = LatLng(-7.677851238136329, 110.83968584828327);
  static const radiusKantorMeter = 30.0;

  bool _izinLokasiDitolak = false;
  bool _notifikasiSudahDikirim = false;
  bool _isMocked = false;
  bool _notifikasiFakeGpsSudahDikirim = false;
  bool isTombolAktif = false;
  bool _sudahValidasiAwal = false;
  bool aktifBerangkat = false;
  bool aktifPulang = false;
  bool aktifIjin = false;
  String jadwalNama = 'Libur/Tidak Masuk';
  String jadwalJam = '-';
  String jadwalKeterangan = '';

  final MapController mapController = MapController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Position? _position;
  StreamSubscription<Position>? _positionStream;
  File? _imageFile;
  late Timer _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _initNotification();
    _requestNotificationPermission();
    // _requestCameraPermission();
    _startLocationStream();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _updateTime() {
    final now = DateTime.now();
    final formatted = DateFormat(
      'EEEE, d MMM yyyy\nHH:mm:ss WIB',
      'id_ID',
    ).format(now);
    if (mounted) setState(() => _currentTime = formatted);
  }

  void _initNotification() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    final initSettings = InitializationSettings(android: androidInit);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Cek payload
        if (response.payload == 'open_location_settings') {
          AppSettings.openAppSettings(); // Buka pengaturan aplikasi
        } else if (response.payload == 'open_camera_settings') {
          AppSettings.openAppSettings();
        }
      },
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _startLocationStream() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      setState(() {
        _izinLokasiDitolak = true;
        _position = null;
      });

      if (!_notifikasiSudahDikirim) {
        _notifikasiSudahDikirim = true;
        _tampilkanNotifikasiLokasiGagal();
      }
      return;
    }

    setState(() {
      _izinLokasiDitolak = false;
    });

    try {
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _position = current;
        _isMocked = current.isMocked; // fake GPS?
      });

      if (_isMocked) {
        _tampilkanNotifikasiFakeGps();
      }
    } catch (e) {
      print("Gagal mendapatkan posisi awal: $e");
    }

    if (!_sudahValidasiAwal && _position != null) {
      _sudahValidasiAwal = true;
      try {
        final data = await ApiService.cekValidasiTombol(
          id_user: widget.id_user,
          latitude: _position!.latitude,
          longitude: _position!.longitude,
        );
        setState(() {
          aktifBerangkat = data['berangkat'];
          aktifPulang = data['pulang'];
          aktifIjin = data['ijin'];

          jadwalNama = data['nama'];
          jadwalJam = data['jam'];
          jadwalKeterangan = data['keterangan'];
        });
      } catch (e) {
        print('Gagal memvalidasi tombol absensi: $e');
      }
    }

    DateTime? _lastValidation;
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0, // jika user pindah minimal 0 meter
          ),
        ).listen((pos) {
          if (mounted) {
            setState(() {
              _position = pos;
              _isMocked = pos.isMocked;
            });

            if (_position != null) {
              final now = DateTime.now();
              if (_lastValidation == null ||
                  now.difference(_lastValidation!) > Duration(seconds: 15)) {
                _lastValidation = now;
                _cekValidasiTombol(); // panggil ulang API
              }
            }
            if (_isMocked && !_notifikasiSudahDikirim) {
              _notifikasiSudahDikirim = true;
              _notifikasiFakeGpsSudahDikirim = true;
              _tampilkanNotifikasiFakeGps();
            }
          }
        });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer.cancel();
    super.dispose();
  }

  double _calculateJarak() {
    if (_position == null ||
        (_position!.latitude == 0 && _position!.longitude == 0)) {
      return 0;
    }
    return Geolocator.distanceBetween(
      _position!.latitude,
      _position!.longitude,
      lokasiAbsensi.latitude,
      lokasiAbsensi.longitude,
    );
  }

  // Future<void> _ambilFoto() async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.camera);
  //   if (pickedFile != null) {
  //     setState(() => _imageFile = File(pickedFile.path));
  //   }
  // }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid && await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _tampilkanNotifikasiLokasiGagal() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'lokasi_channel',
          'Peringatan Lokasi',
          channelDescription: 'Notifikasi saat perizinan lokasi gagal',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails notifDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Perhatian! Perizinan Lokasi Gagal',
      'Aktifkan izin lokasi / GPS pada device Anda agar dapat melakukan absensi.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lokasi_channel',
          'Peringatan Lokasi',
          channelDescription: 'Notifikasi saat perizinan lokasi gagal',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: 'open_location_settings', // <--- Tambahkan ini
    );
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        _tampilkanNotifikasiIzinKamera();
      }
    } else if (status.isPermanentlyDenied) {
      _tampilkanNotifikasiIzinKamera();
      openAppSettings(); // Buka langsung ke pengaturan aplikasi
    }
  }

  Future<void> _tampilkanNotifikasiIzinKamera() async {
    const androidDetails = AndroidNotificationDetails(
      'kamera_channel',
      'Peringatan Kamera',
      channelDescription: 'Notifikasi saat izin kamera ditolak',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      2,
      'Perhatian! Perizinan Kamera Ditolak',
      'Aktifkan izin kamera agar bisa mengambil foto saat absensi.',
      notificationDetails,
      payload: 'open_camera_settings',
    );
  }

  Future<void> _tampilkanNotifikasiFakeGps() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fake_gps_channel',
          'Deteksi Fake GPS',
          channelDescription:
              'Notifikasi jika pengguna menggunakan lokasi palsu',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Fake GPS Detected',
        );

    const NotificationDetails notifDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      1,
      'Deteksi Lokasi Palsu',
      'Aplikasi mendeteksi bahwa Anda menggunakan Fake GPS.',
      notifDetails,
      payload: 'fake_gps_detected',
    );
  }

  Future<void> _cekValidasiTombol() async {
    if (_position == null) return;

    final hasil = await ApiService.cekValidasiTombol(
      id_user: widget.id_user,
      latitude: _position!.latitude,
      longitude: _position!.longitude,
    );

    setState(() {
      aktifBerangkat = hasil['berangkat']!;
      aktifPulang = hasil['pulang']!;
      aktifIjin = hasil['ijin']!;
    });
  }

  Future<void> _showCameraModal() async {
    await _requestCameraPermission();

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final originalFile = File(pickedFile.path);

      // ⬇️ Kompres dan resize gambar dulu
      final file = await _compressAndResizeImage(originalFile);

      if (file == null) {
        print("Gagal kompres foto");
        return;
      }

      final lat = _position?.latitude;
      final long = _position?.longitude;

      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Konfirmasi Absensi"),
          content: Column(
            children: [
              const SizedBox(height: 12),
              Image.file(file, height: 180),
              const SizedBox(height: 12),
              Text("Lat: ${lat ?? '-'}\nLong: ${long ?? '-'}"),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text("Submit"),
              onPressed: () {
                Navigator.pop(context);
                // _submitAbsensi(file, lat, long);
                _submitAbsensi(file, lat, long, AbsensiJenis.berangkat);
              },
            ),
          ],
        ),
      );
    }
  }

  Future<File?> _compressAndResizeImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 20, // Sesuaikan kualitas
      minWidth: 720, // Ubah jika perlu
      minHeight: 960,
      format: CompressFormat.jpeg,
    );

    if (result == null) return null;
    return File(result.path);
  }

  Future<void> _submitAbsensi(
    File file,
    double? lat,
    double? long,
    AbsensiJenis jenis,
  ) async {
    if (lat == null || long == null) {
      _showAlert('Gagal', 'Lokasi tidak tersedia.');
      return;
    }

    // Tampilkan loading
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text("Mengirim Absensi..."),
        content: Padding(
          padding: EdgeInsets.only(top: 16),
          child: CupertinoActivityIndicator(radius: 14),
        ),
      ),
    );

    try {
      final result = await ApiService.kirimAbsensi(
        id_user: widget.id_user.toString(),
        nip: widget.nip,
        imageFile: file,
        latitude: lat,
        longitude: long,
        jenis: jenis.kode, // gunakan kode dari enum
      );

      if (context.mounted) Navigator.pop(context); // Tutup loading

      if (result['code'] == 200) {
        await flutterLocalNotificationsPlugin.show(
          0,
          'Yeayy!! Kamu Hebat!',
          result['message'],
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'absen_channel',
              'Notifikasi E-Absensi',
              channelDescription: 'Notifikasi setelah berhasil absensi',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );

        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            Future.delayed(const Duration(seconds: 3), () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
            return CupertinoAlertDialog(
              title: const Text("Yeayy!! Kamu Hebat!"),
              content: Text(result['message']),
            );
          },
        );
      } else {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text('Gagal Absensi - Code ${result['code']}'),
            content: Text(result['message']),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Tutup loading

      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Error"),
          content: Text("Terjadi kesalahan: $e"),
          actions: [
            CupertinoDialogAction(
              child: const Text("Tutup"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = _calculateJarak();
    final insideRadius = distance <= radiusKantorMeter;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: CupertinoPageScaffold(
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  center: _position != null
                      ? LatLng(_position!.latitude, _position!.longitude)
                      : lokasiAbsensi,
                  zoom: 18,
                  interactiveFlags:
                      InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.absensi',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: lokasiAbsensi,
                        color: Colors.blue.withOpacity(0.2),
                        borderStrokeWidth: 2,
                        borderColor: Colors.blue,
                        radius: radiusKantorMeter,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      if (_position != null)
                        Marker(
                          width: 200,
                          height: 80,
                          point: LatLng(
                            _position!.latitude,
                            _position!.longitude,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${distance.toStringAsFixed(1)} m',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  PolylineLayer(
                    polylines: [
                      if (_position != null)
                        Polyline(
                          points: [
                            LatLng(_position!.latitude, _position!.longitude),
                            lokasiAbsensi,
                          ],
                          color: Colors.blue,
                          strokeWidth: 4,
                        ),
                    ],
                  ),
                ],
              ),

              if (_izinLokasiDitolak)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.1),
                      border: Border.all(color: CupertinoColors.systemRed),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.info,
                          color: CupertinoColors.systemRed,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Perizinan lokasi gagal. Aktifkan lokasi untuk melanjutkan absensi.",
                            style: TextStyle(color: CupertinoColors.systemRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Floating Panel
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Panel Informasi
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(CupertinoIcons.location, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child:
                                    (_position == null && !_izinLokasiDitolak)
                                    ? Row(
                                        children: const [
                                          CupertinoActivityIndicator(
                                            radius: 10,
                                          ),
                                          SizedBox(width: 8),
                                          Text("Sedang mendeteksi lokasi..."),
                                        ],
                                      )
                                    : _izinLokasiDitolak
                                    ? const Text(
                                        "Perizinan lokasi ditolak",
                                        style: TextStyle(
                                          color: CupertinoColors.systemRed,
                                        ),
                                      )
                                    : Text(() {
                                        if (distance >= 1000) {
                                          final km = (distance / 1000)
                                              .toStringAsFixed(2);
                                          return "Anda berada $km km jauh dari Radius Rumah Sakit";
                                        } else if (insideRadius) {
                                          return "Anda berada di Dalam Radius Rumah Sakit (< 30m)";
                                        } else {
                                          return "Anda berada ${distance.toStringAsFixed(0)} m di Luar Radius Rumah Sakit";
                                        }
                                      }(), style: const TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.scope, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _position != null
                                    ? "Akurat sejauh ${_position!.accuracy.toStringAsFixed(0)} m"
                                    : "-",
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    jadwalNama,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(jadwalJam),
                                  Text(
                                    jadwalKeterangan,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currentTime.split('\n').first,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    _currentTime.split('\n').last,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Panel Tombol
                    Container(
                      margin: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                              onPressed:
                                  (_position != null &&
                                      !_izinLokasiDitolak &&
                                      aktifPulang)
                                  ? () => _showCameraModal()
                                  : null,
                              child: const Text(
                                "PULANG",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                              onPressed:
                                  (_position != null &&
                                      !_izinLokasiDitolak &&
                                      aktifIjin)
                                  ? () => _showCameraModal()
                                  : null,
                              child: const Text(
                                "IJIN",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(10),
                              onPressed:
                                  (_position != null &&
                                      !_izinLokasiDitolak &&
                                      aktifBerangkat)
                                  ? () => _showCameraModal()
                                  : null,

                              child: const Text(
                                "BERANGKAT",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
