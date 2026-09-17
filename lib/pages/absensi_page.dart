import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/api_service.dart';
import '../main.dart';
import '../models/absensi_enum.dart';
import 'custom_camera_ios.dart';

class AbsensiPage extends StatefulWidget {
  final int id_user;
  final String nip;
  final VoidCallback? onAbsensiBerhasil;

  const AbsensiPage({
    super.key,
    required this.nip,
    required this.id_user,
    this.onAbsensiBerhasil,
  });

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> with WidgetsBindingObserver {
  static const radiusKantorMeter = 30.0;

  LatLng? lokasiAbsensi = const LatLng(-7.677851238136329, 110.83968584828327);

  bool _sedangSubmitAbsensi = false;
  bool _sedangAmbilLokasi = false;
  bool _isRefreshingLocation = false;
  bool _izinLokasiDitolak = false;
  bool _notifikasiSudahDikirim = false;
  bool _isMocked = false;
  bool _notifikasiFakeGpsSudahDikirim = false;
  bool _isJaringanDialogVisible = false;
  bool isTombolAktif = false;
  bool _sudahValidasiAwal = false;
  bool? _lastInsideRadius;
  bool _alreadyInitialized = false;

  bool aktifBerangkat = false;
  bool aktifPulang = false;
  bool aktifIjin = false;

  String jadwalNama = '';
  String jadwalJam = '';
  String jadwalKeterangan = '';
  String msgAbsensi = '';

  DateTime? _lastRefreshLocation;
  static const Duration _refreshCooldown = Duration(seconds: 15);

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

    WidgetsBinding.instance.addObserver(this);

    _initializeAsync();
    _updateTime();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();

    final formatted = DateFormat(
      'EEEE, d MMM yyyy\nHH:mm:ss WIB',
      'id_ID',
    ).format(now);

    if (mounted) {
      setState(() {
        _currentTime = formatted;
      });
    }
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

  // ============================================================
  // LOCATION
  // ============================================================

  void _startLocationStream() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (_sedangAmbilLokasi) return;

    _sedangAmbilLokasi = true;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (!mounted) return;

      setState(() {
        _izinLokasiDitolak = true;
        _position = null;
      });

      if (!_notifikasiSudahDikirim) {
        _notifikasiSudahDikirim = true;
        _tampilkanNotifikasiLokasiGagal();
      }

      _sedangAmbilLokasi = false;
      return;
    }

    if (mounted) {
      setState(() {
        _izinLokasiDitolak = false;
      });
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _position = current;
          _isMocked = current.isMocked;

          if (_position != null) {
            mapController.move(
              LatLng(
                _position!.latitude - 0.00075,
                _position!.longitude - 0.00015,
              ),
              18.0,
            );
          }
        });
      }

      if (_isMocked) {
        _tampilkanNotifikasiFakeGps();
      }
    } catch (e) {
      debugPrint("Gagal mendapatkan posisi awal: $e");
    }

    if (!_sedangSubmitAbsensi && !_sudahValidasiAwal && _position != null) {
      _sudahValidasiAwal = true;

      if (lokasiAbsensi == null) {
        debugPrint('lokasiAbsensi null, tidak bisa hitung jarak');
        _sedangAmbilLokasi = false;
        return;
      }

      final jarak = Geolocator.distanceBetween(
        _position!.latitude,
        _position!.longitude,
        lokasiAbsensi!.latitude,
        lokasiAbsensi!.longitude,
      );

      _lastInsideRadius = jarak <= radiusKantorMeter;

      try {
        final data = await ApiService.cekValidasiTombol(
          id_user: widget.id_user,
          latitude: _position!.latitude,
          longitude: _position!.longitude,
          jarak: jarak,
        );

        if (!mounted) return;

        setState(() {
          aktifBerangkat = data['berangkat'] ?? false;
          aktifPulang = data['pulang'] ?? false;
          aktifIjin = data['ijin'] ?? false;

          jadwalNama = data['nama'] ?? '';
          jadwalJam = data['jam'] ?? '';
          jadwalKeterangan = data['keterangan'] ?? '';
          msgAbsensi = data['message'] ?? '';
        });

        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });

            return CupertinoAlertDialog(
              title: const Text('Informasi Absensi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(msgAbsensi, textAlign: TextAlign.start),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Tutup'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } catch (e) {
        debugPrint('Gagal memvalidasi tombol absensi: $e');
      }
    }

    DateTime? lastValidation;

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        ).listen((pos) async {
          if (!mounted) return;

          setState(() {
            _position = pos;
            _isMocked = pos.isMocked;
          });

          if (_position != null && lokasiAbsensi != null) {
            final now = DateTime.now();
            final jarakSekarang = Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              lokasiAbsensi!.latitude,
              lokasiAbsensi!.longitude,
            );
            final insideSekarang = jarakSekarang <= radiusKantorMeter;
            final radiusBerubah =
                _lastInsideRadius != null &&
                insideSekarang != _lastInsideRadius;

            if (lastValidation == null ||
                now.difference(lastValidation!) > const Duration(seconds: 15) ||
                radiusBerubah) {
              lastValidation = now;
              _lastInsideRadius = insideSekarang;

              try {
                await _cekValidasiTombol();
              } catch (e) {
                debugPrint("Gagal validasi tombol di stream: $e");
              }
            } else {
              _lastInsideRadius = insideSekarang;
            }
          }

          if (_isMocked && !_notifikasiFakeGpsSudahDikirim) {
            _notifikasiFakeGpsSudahDikirim = true;
            _tampilkanNotifikasiFakeGps();
          }
        });

    _sedangAmbilLokasi = false;
  }

  double _calculateJarak() {
    if (_position == null ||
        (_position!.latitude == 0 && _position!.longitude == 0) ||
        lokasiAbsensi == null) {
      return 0;
    }

    return Geolocator.distanceBetween(
      _position!.latitude,
      _position!.longitude,
      lokasiAbsensi!.latitude,
      lokasiAbsensi!.longitude,
    );
  }

  Future<void> _refreshLocation() async {
    debugPrint('Tombol Refresh Lokasi Atas ditekan');

    final now = DateTime.now();

    if (_lastRefreshLocation != null) {
      final elapsed = now.difference(_lastRefreshLocation!);

      if (elapsed < _refreshCooldown) {
        final remaining = _refreshCooldown.inSeconds - elapsed.inSeconds;

        if (mounted) {
          _showAlert(
            'Silakan menunggu..',
            'Refresh lokasi dapat dilakukan kembali dalam $remaining detik.',
          );
        }

        return;
      }
    }

    if (_isRefreshingLocation) {
      return;
    }

    _lastRefreshLocation = now;

    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (mounted) {
        setState(() {
          _izinLokasiDitolak = true;
        });
      }

      debugPrint("Izin lokasi tidak diberikan, batal refresh.");

      return;
    }

    if (mounted) {
      setState(() {
        _isRefreshingLocation = true;
      });
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _position = current;
        _isMocked = current.isMocked;
      });

      try {
        if (_position != null) {
          mapController.move(
            LatLng(
              _position!.latitude - 0.00075,
              _position!.longitude - 0.00015,
            ),
            18.0,
          );
        }
      } catch (e) {
        debugPrint('Gagal memindahkan map: $e');
      }

      if (_isMocked) {
        _tampilkanNotifikasiFakeGps();
      }

      await _ambilLokasiKantor();

      if (lokasiAbsensi != null) {
        final jarak = Geolocator.distanceBetween(
          current.latitude,
          current.longitude,
          lokasiAbsensi!.latitude,
          lokasiAbsensi!.longitude,
        );

        _lastInsideRadius = jarak <= radiusKantorMeter;
        _sudahValidasiAwal = true;

        await _cekValidasiTombol();

        await _positionStream?.cancel();
        _positionStream = null;
        _startLocationStream();
      }
    } on SocketException catch (_) {
      debugPrint('Gagal memvalidasi tombol absensi: _refreshLocation');
    } on http.ClientException catch (_) {
      debugPrint('Gagal memvalidasi tombol absensi: _refreshLocation');
    } catch (e) {
      debugPrint("Gagal refresh lokasi: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingLocation = false;
        });
      }
    }
  }

  Future<void> _ambilLokasiKantor() async {
    try {
      final lokasi = await ApiService.getLokasiKantor();

      if (!mounted) return;

      setState(() {
        lokasiAbsensi = lokasi;
      });
    } catch (e) {
      debugPrint("Gagal ambil lokasi kantor: $e");
    }
  }

  // ============================================================
  // PERMISSION & NOTIFICATION
  // ============================================================

  Future<void> _initNotification() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    final initSettings = InitializationSettings(android: androidInit);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == 'open_location_settings' ||
            response.payload == 'open_camera_settings') {
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

  Future<PermissionStatus> _requestNotificationPermission() async {
    PermissionStatus status = PermissionStatus.denied;

    if (Platform.isAndroid) {
      status = await Permission.notification.status;

      if (status.isDenied) {
        status = await Permission.notification.request();
      }
    }

    return status;
  }

  Future<PermissionStatus> _requestLocationPermission() async {
    PermissionStatus status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    return status;
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
      openAppSettings();
    }
  }

  Future<void> _initializeAsync() async {
    if (_alreadyInitialized) return;

    _alreadyInitialized = true;

    await _initNotification();

    final notifStatus = await _requestNotificationPermission();

    await Future.delayed(const Duration(milliseconds: 300));

    if (notifStatus.isGranted) {
      final locationStatus = await _requestLocationPermission();

      if (locationStatus.isGranted) {
        debugPrint('Lokasi diizinkan');
      } else {
        debugPrint('Lokasi ditolak atau dibatalkan');
      }
    } else {
      debugPrint('Notifikasi ditolak, skip izin lokasi');
    }

    await _ambilLokasiKantor();

    if (lokasiAbsensi != null) {
      _startLocationStream();
    }
  }

  Future<void> _tampilkanNotifikasiLokasiGagal() async {
    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Perhatian! Perizinan Lokasi Gagal',
      body:
          'Aktifkan izin lokasi / GPS pada device Anda agar dapat melakukan absensi.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'notif_lokasi_absensi',
          'Peringatan Lokasi',
          channelDescription: 'Notifikasi saat perizinan lokasi gagal',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: 'open_location_settings',
    );
  }

  Future<void> _tampilkanNotifikasiIzinKamera() async {
    await flutterLocalNotificationsPlugin.show(
      id: 2,
      title: 'Perhatian! Perizinan Kamera Ditolak',
      body: 'Aktifkan izin kamera agar bisa mengambil foto saat absensi.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'notif_kamera_absensi',
          'Peringatan Kamera',
          channelDescription: 'Notifikasi saat izin kamera ditolak',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: 'open_camera_settings',
    );
  }

  Future<void> _tampilkanNotifikasiFakeGps() async {
    await flutterLocalNotificationsPlugin.show(
      id: 1,
      title: 'STOP KECURANGAN! Anda terdeteksi menggunakan Lokasi Palsu!',
      body:
          'Aplikasi mendeteksi bahwa Anda menggunakan/mengatur lokasi dari aplikasi Fake GPS atau sejenisnya. Dilarang mengaktifkan aplikasi tersebut atau Anda siap menerima Risiko sesuai kebijakan yang telah ditentukan oleh bagian SDI.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'notif_fakegps_absensi',
          'Deteksi Fake GPS',
          channelDescription:
              'Notifikasi jika pengguna menggunakan lokasi palsu',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: 'fake_gps_detected',
    );
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  Future<void> _cekValidasiTombol() async {
    if (_position == null || lokasiAbsensi == null) {
      return;
    }

    try {
      final jarak = Geolocator.distanceBetween(
        _position!.latitude,
        _position!.longitude,
        lokasiAbsensi!.latitude,
        lokasiAbsensi!.longitude,
      );

      final hasil = await ApiService.cekValidasiTombol(
        id_user: widget.id_user,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        jarak: jarak,
      );

      if (!mounted) return;

      setState(() {
        aktifBerangkat = hasil['berangkat'] ?? false;
        aktifPulang = hasil['pulang'] ?? false;
        aktifIjin = hasil['ijin'] ?? false;

        jadwalNama = hasil['nama'] ?? '';
        jadwalJam = hasil['jam'] ?? '';
        jadwalKeterangan = hasil['keterangan'] ?? '';
      });
    } catch (e) {
      debugPrint('Gagal memvalidasi tombol absensi: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('TimeoutException')) {
        if (mounted) {
          setState(() {
            aktifBerangkat = false;
            aktifPulang = false;
            aktifIjin = false;
          });
        }

        _showJaringanErrorDialog();
      }
    }
  }

  // ============================================================
  // NETWORK DIALOG
  // ============================================================

  void _showJaringanErrorDialog() {
    if (_isJaringanDialogVisible) return;

    _isJaringanDialogVisible = true;

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: CupertinoColors.systemRed.withOpacity(0.92),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 20, 18, 8),
                child: Icon(
                  CupertinoIcons.wifi_exclamationmark,
                  color: CupertinoColors.white,
                  size: 34,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Jaringan Tidak Stabil',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Text(
                  'Koneksi ke server gagal.\nPastikan Wi-Fi atau data seluler kamu aktif dan stabil.',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 13,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1, color: CupertinoColors.white),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: CupertinoColors.white.withOpacity(0.18),
                  onPressed: () {
                    Navigator.pop(context);

                    _isJaringanDialogVisible = false;
                  },
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _isJaringanDialogVisible = false;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isJaringanDialogVisible) {
        Navigator.of(context, rootNavigator: true).pop();

        _isJaringanDialogVisible = false;
      }
    });
  }

  // ============================================================
  // CAMERA
  // ============================================================

  late List<CameraDescription> cameras = [];

  Widget _buildDialogTitle(AbsensiJenis jenis) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    Color accent;

    String label;

    if (jenis == AbsensiJenis.berangkat) {
      accent = const Color(0xFF2563EB);
      label = 'Absensi';
    } else if (jenis == AbsensiJenis.pulang) {
      accent = const Color(0xFFEF4444);
      label = 'Absensi';
    } else if (jenis == AbsensiJenis.dinasLuar) {
      accent = const Color(0xFFF59E0B);
      label = 'Dinas Luar';
    } else {
      accent = const Color(0xFF6366F1);
      label = 'Ijin';
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
          fontSize: 18,
        ),
        children: [
          const TextSpan(text: 'Konfirmasi '),
          TextSpan(
            text: label,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Future<void> _showCameraModal(AbsensiJenis jenis) async {
    await _requestCameraPermission();

    _sedangSubmitAbsensi = true;

    if (cameras.isEmpty) {
      cameras = await availableCameras();
    }

    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final rearCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final bool butuhKeterangan =
        jenis == AbsensiJenis.ijin || jenis == AbsensiJenis.dinasLuar;

    final pickedFile = await Navigator.of(context).push<XFile?>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => CustomCameraIOS(
          frontCamera: frontCamera,
          rearCamera: rearCamera,
          allowSwitchCamera:
              jenis == AbsensiJenis.berangkat ||
              jenis == AbsensiJenis.pulang ||
              jenis == AbsensiJenis.ijin ||
              jenis == AbsensiJenis.dinasLuar,
          jenis: jenis,
          latitude: _position?.latitude,
          longitude: _position?.longitude,
        ),
      ),
    );

    if (pickedFile != null) {
      final originalFile = File(pickedFile.path);

      late File file;

      if (jenis == AbsensiJenis.berangkat || jenis == AbsensiJenis.pulang) {
        final compressed = await _compressAndResizeImage(originalFile);

        if (compressed == null) {
          debugPrint("Gagal kompres foto");

          _sedangSubmitAbsensi = false;
          return;
        }

        file = compressed;
      } else {
        file = originalFile;
      }

      final lat = _position?.latitude;
      final long = _position?.longitude;

      final TextEditingController keteranganController =
          TextEditingController();

      final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

      showCupertinoDialog(
        context: context,
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final keterangan = keteranganController.text.trim();

              final canSubmit = !butuhKeterangan || keterangan.isNotEmpty;

              return CupertinoAlertDialog(
                title: _buildDialogTitle(jenis),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        file,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        "Lat: ${lat ?? '-'}\n"
                        "Long: ${long ?? '-'}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.5,
                          color: isDark
                              ? CupertinoColors.systemGrey2
                              : CupertinoColors.systemGrey,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),

                    if (butuhKeterangan) ...[
                      const SizedBox(height: 12),

                      Text(
                        jenis == AbsensiJenis.dinasLuar
                            ? 'Keterangan Dinas Luar'
                            : 'Keterangan Ijin',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Wajib diisi',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9.5,
                          color: CupertinoColors.systemRed,
                          decoration: TextDecoration.none,
                        ),
                      ),

                      const SizedBox(height: 6),

                      CupertinoTextField(
                        controller: keteranganController,
                        maxLines: 3,
                        placeholder: jenis == AbsensiJenis.dinasLuar
                            ? 'Contoh: Dinas luar ke...'
                            : 'Contoh: Keperluan ijin...',
                        onChanged: (_) {
                          setDialogState(() {});
                        },
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          fontSize: 11,
                        ),
                        placeholderStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.placeholderText,
                          fontSize: 11,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                      ),

                      const SizedBox(height: 4),

                      AnimatedOpacity(
                        opacity: canSubmit ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: const Text(
                          'Keterangan wajib diisi sebelum Submit.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: CupertinoColors.systemRed,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Batal'),
                    onPressed: () {
                      Navigator.pop(context);

                      if (mounted) {
                        setState(() {
                          _sedangSubmitAbsensi = false;
                        });
                      }
                    },
                  ),

                  CupertinoDialogAction(
                    isDefaultAction: canSubmit,
                    onPressed: canSubmit
                        ? () async {
                            final keterangan = butuhKeterangan
                                ? keteranganController.text.trim()
                                : '';

                            if (butuhKeterangan && keterangan.isEmpty) {
                              return;
                            }

                            Navigator.pop(context);

                            await _submitAbsensi(
                              file,
                              lat,
                              long,
                              jenis,
                              keterangan,
                            );

                            await _refreshLocation();

                            if (!mounted) return;

                            setState(() {
                              _sedangSubmitAbsensi = false;
                            });
                          }
                        : null,
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: canSubmit
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      _sedangSubmitAbsensi = false;
    }
  }

  Future<File?> _compressAndResizeImage(File file) async {
    final dir = await getTemporaryDirectory();

    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 20,
      minWidth: 720,
      minHeight: 960,
      format: CompressFormat.jpeg,
    );

    if (result == null) return null;

    return File(result.path);
  }

  // ============================================================
  // SUBMIT ABSENSI
  // ============================================================

  Future<void> _submitAbsensi(
    File file,
    double? lat,
    double? long,
    AbsensiJenis jenis,
    String keterangan,
  ) async {
    if (lat == null || long == null) {
      _showAlert('Gagal', 'Lokasi tidak tersedia.');
      return;
    }

    bool isCompleted = false;

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

    Future.delayed(const Duration(seconds: 30), () {
      if (!isCompleted && mounted) {
        Navigator.pop(context);

        flutterLocalNotificationsPlugin.show(
          id: 0,
          title: 'Absensi Gagal!',
          body:
              'Proses absensi lebih dari 30 detik. Silakan periksa koneksi jaringan Anda dan coba lagi.',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'notif_absensi',
              'Notifikasi E-Absensi',
              channelDescription: 'Timeout absensi',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );

        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text("Gagal"),
            content: const Text(
              "Proses absensi gagal! Pengiriman data Absensi memakan waktu terlalu lama. Silakan periksa koneksi jaringan Anda dan coba mengulangi Absensi kembali.",
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup"),
              ),
            ],
          ),
        );
      }
    });

    try {
      final result = await ApiService.kirimAbsensi(
        id_user: widget.id_user.toString(),
        nip: widget.nip,
        imageFile: file,
        latitude: lat,
        longitude: long,
        jenis: jenis.kode,
        keterangan: keterangan,
        isFakeGps: _isMocked,
      );

      if (!mounted) return;

      Navigator.pop(context);

      isCompleted = true;

      if (result['code'] == 200) {
        // ============================================================
        // ABSENSI BERHASIL
        // ============================================================

        // Beritahu MainPage bahwa absensi berhasil.
        // MainPage kemudian akan memicu refresh RekapPage.
        widget.onAbsensiBerhasil?.call();

        await flutterLocalNotificationsPlugin.show(
          id: 0,
          title: result['title'] ?? 'Yeayy!! Kamu Berhasil!',
          body: result['message'] ?? '',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'notif_absensi',
              'Notifikasi E-Absensi',
              channelDescription: 'Notifikasi berhasil absensi',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      } else if (result['code'] == 401) {
        await flutterLocalNotificationsPlugin.show(
          id: 0,
          title: 'Maaf, Gagal Terhubung ke Server!',
          body:
              'Tidak dapat mengirim data absensi. Pastikan koneksi jaringan aktif dan stabil lalu silakan mengulangi Absensi kembali.',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'notif_absensi',
              'Notifikasi E-Absensi',
              channelDescription: 'Koneksi ditolak atau token tidak valid',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );

        showCupertinoDialog(
          context: context,
          builder: (_) => _ErrorGlassDialog(
            title: 'Gagal Absensi!\nKoneksi Jaringan Ditolak',
            message:
                'Tidak dapat mengirim data absensi karena koneksi ke server gagal atau jaringan tidak stabil.\nSilakan periksa koneksi jaringan Anda dan ulangi Absensi sekali lagi.',
            buttonText: 'Ulangi Sekali Lagi',
          ),
        );
      } else {
        await flutterLocalNotificationsPlugin.show(
          id: 0,
          title: result['title'] ?? 'Ahh Maaf!! Kode Error ${result['code']}!',
          body: result['message'] ?? '',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'notif_absensi',
              'Notifikasi E-Absensi',
              channelDescription: 'Notifikasi gagal absensi',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );

        showCupertinoDialog(
          context: context,
          builder: (_) => _ErrorGlassDialog(
            title: result['title'] ?? 'Gagal Absensi - Code ${result['code']}',
            message: result['message'] ?? '',
            buttonText: 'Tutup',
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      isCompleted = true;

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

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _positionStream?.cancel();
    _timer.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed, refresh page');

      if (!_alreadyInitialized) return;

      final permission = await Geolocator.checkPermission();

      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        _refreshLocation();
      } else {
        debugPrint("Diblokir: Izin lokasi ditolak, tidak refresh.");
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (lokasiAbsensi == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final distance = _calculateJarak();

    final insideRadius = distance <= radiusKantorMeter;

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    const bottomContentPadding = 89.0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: CupertinoPageScaffold(
        child: Stack(
          children: [
            // ==================================================
            // MAP
            // ==================================================
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: _position != null
                    ? LatLng(_position!.latitude, _position!.longitude)
                    : lokasiAbsensi!,
                initialZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                // =========================
                // OPENSTREETMAP
                // =========================
                ColorFiltered(
                  colorFilter: isDark
                      ? const ColorFilter.matrix([
                          -1,
                          0,
                          0,
                          0,
                          255,
                          0,
                          -1,
                          0,
                          0,
                          255,
                          0,
                          0,
                          -1,
                          0,
                          255,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ])
                      : const ColorFilter.matrix([
                          1,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                  child: TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sakudewa.absensi',
                  ),
                ),

                // Radius GPS user
                CircleLayer(
                  circles: [
                    if (_position != null)
                      CircleMarker(
                        point: LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        radius: _position!.accuracy,
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.blue.withOpacity(0.08),
                        borderStrokeWidth: 1,
                        borderColor: isDark
                            ? Colors.white.withOpacity(0.35)
                            : Colors.blue.withOpacity(0.40),
                      ),

                    // Radius kantor
                    if (lokasiAbsensi != null)
                      CircleMarker(
                        point: lokasiAbsensi!,
                        radius: radiusKantorMeter,
                        useRadiusInMeter: true,
                        color: insideRadius
                            ? const Color(0xFF22C55E).withOpacity(0.14)
                            : const Color(0xFF2563EB).withOpacity(0.14),
                        borderColor: insideRadius
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF2563EB),
                        borderStrokeWidth: 2,
                      ),
                  ],
                ),

                // Marker
                MarkerLayer(
                  markers: [
                    if (lokasiAbsensi != null)
                      Marker(
                        width: 180,
                        height: 90,
                        point: lokasiAbsensi!,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.90),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.building_2_fill,
                                    color: Color(0xFF2563EB),
                                    size: 15,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Lokasi Absensi',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1E293B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Icon(
                              CupertinoIcons.location_solid,
                              color: Color(0xFF2563EB),
                              size: 34,
                            ),
                          ],
                        ),
                      ),

                    if (_position != null)
                      Marker(
                        width: 150,
                        height: 90,
                        point: LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A).withOpacity(0.88)
                                    : Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${distance.toStringAsFixed(1)} m',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Icon(
                              CupertinoIcons.location_solid,
                              color: _isMocked
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444),
                              size: 38,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Garis posisi → kantor
                PolylineLayer(
                  polylines: [
                    if (_position != null)
                      Polyline(
                        points: [
                          LatLng(_position!.latitude, _position!.longitude),
                          lokasiAbsensi!,
                        ],
                        color: insideRadius
                            ? const Color(0xFF22C55E).withOpacity(0.65)
                            : const Color(0xFF2563EB).withOpacity(0.65),
                        strokeWidth: 3,
                      ),
                  ],
                ),
              ],
            ),

            // ==================================================
            // TOP STATUS
            // ==================================================
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GlassStatusChip(
                    icon: insideRadius
                        ? CupertinoIcons.checkmark_shield_fill
                        : CupertinoIcons.location_fill,
                    title: insideRadius ? 'Area Absensi' : 'Di Luar Radius',
                    subtitle: insideRadius
                        ? 'Lokasi valid'
                        : '${distance.toStringAsFixed(0)} m dari RS',
                    isDark: isDark,
                    success: insideRadius,
                  ),

                  GestureDetector(
                    onTap: _isRefreshingLocation ? null : _refreshLocation,
                    child: _GlassCircleButton(
                      isDark: isDark,
                      child: _isRefreshingLocation
                          ? CupertinoActivityIndicator(
                              radius: 10,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF2563EB),
                            )
                          : Icon(
                              CupertinoIcons.location_fill,
                              size: 19,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF2563EB),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // LOCATION DENIED
            // ==================================================
            if (_izinLokasiDitolak)
              Positioned(
                top: MediaQuery.of(context).padding.top + 78,
                left: 16,
                right: 16,
                child: _GlassWarningCard(
                  isDark: isDark,
                  title: 'Lokasi diperlukan',
                  message: 'Aktifkan lokasi untuk melanjutkan absensi.',
                ),
              ),

            // ============================================================
            // BOTTOM CONTENT
            // ============================================================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomContentPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ======================================================
                    // INFORMATION CARD
                    // ======================================================
                    Container(
                      margin: const EdgeInsets.fromLTRB(14, 8, 14, 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.25 : 0.12,
                            ),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A).withOpacity(0.82)
                                  : Colors.white.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.13)
                                    : Colors.white.withOpacity(0.75),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ------------------------------------------
                                // LOCATION
                                // ------------------------------------------
                                Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: insideRadius
                                            ? const Color(
                                                0xFF22C55E,
                                              ).withOpacity(0.12)
                                            : const Color(
                                                0xFF2563EB,
                                              ).withOpacity(0.12),
                                      ),
                                      child: Icon(
                                        insideRadius
                                            ? CupertinoIcons
                                                  .checkmark_shield_fill
                                            : CupertinoIcons.location_fill,
                                        size: 17,
                                        color: insideRadius
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFF2563EB),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            insideRadius
                                                ? 'Anda berada di area absensi'
                                                : 'Anda berada di luar radius',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),

                                          const SizedBox(height: 2),

                                          Text(
                                            insideRadius
                                                ? 'Dalam radius RS • maksimal 30 meter'
                                                : distance >= 1000
                                                ? '${(distance / 1000).toStringAsFixed(2)} km dari lokasi RS'
                                                : '${distance.toStringAsFixed(0)} meter dari lokasi RS',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? Colors.white54
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: insideRadius
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (insideRadius
                                                        ? const Color(
                                                            0xFF22C55E,
                                                          )
                                                        : const Color(
                                                            0xFFF59E0B,
                                                          ))
                                                    .withOpacity(0.45),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // ------------------------------------------
                                // GPS ACCURACY
                                // ------------------------------------------
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.055)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.07)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.scope,
                                        size: 16,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF64748B),
                                      ),

                                      const SizedBox(width: 7),

                                      Expanded(
                                        child: Text(
                                          _position != null
                                              ? 'Akurasi GPS ${_position!.accuracy.toStringAsFixed(0)} m'
                                              : 'Mendeteksi akurasi GPS...',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),

                                      if (_isMocked)
                                        const Text(
                                          '⚠️ Fake GPS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFF59E0B),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 13),

                                // ------------------------------------------
                                // DIVIDER
                                // ------------------------------------------
                                Container(
                                  height: 1,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : const Color(0xFFE2E8F0),
                                ),

                                const SizedBox(height: 13),

                                // ------------------------------------------
                                // JADWAL + CLOCK
                                // ------------------------------------------
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.calendar_today,
                                                size: 13,
                                                color: isDark
                                                    ? Colors.white60
                                                    : const Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Jadwal Hari Ini',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isDark
                                                      ? Colors.white60
                                                      : const Color(0xFF64748B),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            jadwalNama.isEmpty
                                                ? '-'
                                                : jadwalNama,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),

                                          if (jadwalKeterangan.isNotEmpty)
                                            Text(
                                              jadwalKeterangan,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark
                                                    ? Colors.white54
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),

                                          if (jadwalJam.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Text(
                                                jadwalJam,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isDark
                                                      ? Colors.white60
                                                      : const Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      width: 1,
                                      height: 42,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : const Color(0xFFE2E8F0),
                                    ),

                                    const SizedBox(width: 15),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _currentTime.isEmpty
                                              ? '-'
                                              : _currentTime.split('\n').first,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark
                                                ? Colors.white60
                                                : const Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                        const SizedBox(height: 2),

                                        Text(
                                          _currentTime.isEmpty
                                              ? '--:--:--'
                                              : _currentTime.split('\n').last,
                                          style: TextStyle(
                                            fontSize: 20,
                                            letterSpacing: -0.5,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ======================================================
                    // ACTION BUTTON CARD
                    // ======================================================
                    Container(
                      margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withOpacity(0.88)
                            : Colors.white.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.white.withOpacity(0.75),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.28 : 0.13,
                            ),
                            blurRadius: 22,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'PULANG',
                              icon: CupertinoIcons.arrow_right_square,
                              color: const Color(0xFFEF4444),
                              enabled:
                                  _position != null &&
                                  !_izinLokasiDitolak &&
                                  aktifPulang,
                              onTap: () =>
                                  _showCameraModal(AbsensiJenis.pulang),
                              isDark: isDark,
                            ),
                          ),

                          const SizedBox(width: 7),

                          Expanded(
                            child: _ActionButton(
                              label: 'LAINNYA',
                              icon: CupertinoIcons.ellipsis_circle_fill,
                              color: const Color(0xFF6366F1),
                              enabled:
                                  _position != null &&
                                  !_izinLokasiDitolak &&
                                  aktifIjin,
                              onTap: () {
                                showCupertinoModalPopup(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      CupertinoActionSheet(
                                        title: Text(
                                          "Pilih Jenis",
                                          style: TextStyle(
                                            color: isDark
                                                ? CupertinoColors.white
                                                : CupertinoColors
                                                      .secondaryLabel,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        actions: [
                                          CupertinoActionSheetAction(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _showCameraModal(
                                                AbsensiJenis.ijin,
                                              );
                                            },
                                            child: const Text(
                                              "Ijin",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                          CupertinoActionSheetAction(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _showCameraModal(
                                                AbsensiJenis.dinasLuar,
                                              );
                                            },
                                            child: const Text(
                                              "Dinas Luar",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ],
                                        cancelButton:
                                            CupertinoActionSheetAction(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              isDefaultAction: true,
                                              child: const Text("Batal"),
                                            ),
                                      ),
                                );
                              },
                              isDark: isDark,
                            ),
                          ),

                          const SizedBox(width: 7),

                          Expanded(
                            child: _ActionButton(
                              label: 'BERANGKAT',
                              icon: CupertinoIcons.location_fill,
                              color: const Color(0xFF2563EB),
                              enabled:
                                  _position != null &&
                                  !_izinLokasiDitolak &&
                                  aktifBerangkat,
                              onTap: () =>
                                  _showCameraModal(AbsensiJenis.berangkat),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// UI HELPERS
// ================================================================

class _GlassStatusChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final bool success;

  const _GlassStatusChip({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    final accent = success ? const Color(0xFF22C55E) : const Color(0xFF2563EB);

    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withOpacity(0.78)
            : Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _GlassCircleButton({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withOpacity(0.80)
            : Colors.white.withOpacity(0.90),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.14)
              : Colors.white.withOpacity(0.80),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlassWarningCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String message;

  const _GlassWarningCard({
    required this.isDark,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.location_slash_fill,
            color: Color(0xFFEF4444),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const _InfoIcon({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool active;

  const _StatusDot({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);

    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color;

    final disabledColor = isDark
        ? Colors.white.withOpacity(0.07)
        : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.48,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      activeColor.withOpacity(0.95),
                      activeColor.withOpacity(0.72),
                    ],
                  )
                : null,
            color: enabled ? null : disabledColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: enabled
                  ? Colors.white.withOpacity(0.20)
                  : isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFCBD5E1),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: enabled
                    ? Colors.white
                    : isDark
                    ? Colors.white54
                    : const Color(0xFF64748B),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? Colors.white
                      : isDark
                      ? Colors.white54
                      : const Color(0xFF64748B),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorGlassDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const _ErrorGlassDialog({
    required this.title,
    required this.message,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 35),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Colors.white,
              size: 34,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.4,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.30)),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 13),
              onPressed: () => Navigator.pop(context),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  buttonText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
