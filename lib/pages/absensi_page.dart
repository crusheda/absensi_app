import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class AbsensiPage extends StatefulWidget {
  final String nip;
  const AbsensiPage({super.key, required this.nip});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  File? _imageFile;
  Position? _currentPosition;
  bool _isLoading = false;

  Future<void> _ambilFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _ambilLokasi() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    _currentPosition = await Geolocator.getCurrentPosition();
  }

  Future<void> _kirimAbsensi(String jenis) async {
    if (_imageFile == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto dan lokasi harus diambil dulu.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    final message = await ApiService.kirimAbsensi(
      nip: widget.nip,
      imageFile: _imageFile!,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      jenis: jenis,
    );

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _ambilFoto,
              child: const Text("Ambil Foto"),
            ),
            if (_imageFile != null) Image.file(_imageFile!, height: 200),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _ambilLokasi,
              child: const Text("Ambil Lokasi"),
            ),
            if (_currentPosition != null)
              Text(
                "Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}",
              ),

            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _kirimAbsensi("masuk"),
                    child: const Text("Absen Masuk"),
                  ),
                  ElevatedButton(
                    onPressed: () => _kirimAbsensi("pulang"),
                    child: const Text("Absen Pulang"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
