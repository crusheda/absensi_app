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
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AbsensiPage extends StatefulWidget {
  final int id_user;
  final String nip;
  const AbsensiPage({super.key, required this.nip, required this.id_user});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  static const kantorPos = LatLng(-7.5104256, 110.5887232);
  static const radiusKantorMeter = 100.0;
  bool _izinLokasiDitolak = false;
  bool _notifikasiSudahDikirim = false;
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
    _startLocationStream();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
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
        _notifikasiSudahDikirim = true; // cegah kirim ulang
        _tampilkanNotifikasiLokasiGagal();
      }

      return;
    }

    setState(() {
      _izinLokasiDitolak = false;
    });

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 0,
          ),
        ).listen((pos) {
          if (mounted) setState(() => _position = pos);
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
      kantorPos.latitude,
      kantorPos.longitude,
    );
  }

  Future<void> _ambilFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
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
      'Perizinan Lokasi Gagal',
      'Aktifkan lokasi agar dapat melakukan absensi.',
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
                      : kantorPos,
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
                        point: kantorPos,
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
                                        if (distance > 10000) {
                                          return "Anda berada Jauh dari Radius Kantor (> 10km)";
                                        } else if (insideRadius) {
                                          return "Anda berada di Dalam Radius Kantor.";
                                        } else {
                                          return "Anda berada ${distance.toStringAsFixed(0)}m di Luar Radius Kantor.";
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
                                children: const [
                                  Text(
                                    "Jadwal Reguler",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text("08:00 - 15:00 WIB"),
                                  Text(
                                    "pagi kantor (pk)",
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
                                  Text(
                                    _currentTime.split('\n').last,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
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
                                  (_position != null && !_izinLokasiDitolak)
                                  ? () => _ambilFoto()
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
                                  (_position != null && !_izinLokasiDitolak)
                                  ? () => _ambilFoto()
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
                                  (_position != null && !_izinLokasiDitolak)
                                  ? () => _ambilFoto()
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
