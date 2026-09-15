import 'dart:io';

import 'package:absensi_app/models/absensi_enum.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomCameraIOS extends StatefulWidget {
  final CameraDescription frontCamera;
  final CameraDescription rearCamera;
  final bool allowSwitchCamera;
  final AbsensiJenis jenis;
  final double? latitude;
  final double? longitude;

  const CustomCameraIOS({
    super.key,
    required this.frontCamera,
    required this.rearCamera,
    required this.allowSwitchCamera,
    required this.jenis,
    this.latitude,
    this.longitude,
  });

  @override
  State<CustomCameraIOS> createState() => _CustomCameraIOSState();
}

class _CustomCameraIOSState extends State<CustomCameraIOS> {
  CameraController? _controller;

  bool _isRear = false;
  bool _isFlash = false;
  bool _isCapturing = false;
  bool _isSwitching = false;

  File? _capturedFile;

  @override
  void initState() {
    super.initState();

    // Default kamera depan.
    _isRear = false;

    _startCamera(widget.frontCamera);
  }

  Future<void> _startCamera(CameraDescription description) async {
    final oldController = _controller;

    _controller = null;

    if (mounted) {
      setState(() {});
    }

    if (oldController != null) {
      await oldController.dispose();
    }

    final newController = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await newController.initialize();
      await newController.setFlashMode(FlashMode.off);

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        _controller = newController;
        _isFlash = false;
      });
    } catch (e) {
      debugPrint('Camera initialization failed: $e');

      await newController.dispose();

      if (!mounted) return;

      setState(() {
        _controller = null;
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_isSwitching) return;

    setState(() {
      _isSwitching = true;
      _isRear = !_isRear;
      _capturedFile = null;
    });

    await _startCamera(_isRear ? widget.rearCamera : widget.frontCamera);

    if (!mounted) return;

    setState(() {
      _isSwitching = false;
    });
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      final newFlashState = !_isFlash;

      await controller.setFlashMode(
        newFlashState ? FlashMode.torch : FlashMode.off,
      );

      if (!mounted) return;

      setState(() {
        _isFlash = newFlashState;
      });
    } catch (e) {
      debugPrint('Flash not supported: $e');
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final rawFile = await controller.takePicture();

      File file = File(rawFile.path);

      // Kamera depan di-flip agar hasil foto
      // sesuai tampilan mirror preview.
      if (!_isRear) {
        file = await _flipImageHorizontal(file);
      }

      if (!mounted) return;

      setState(() {
        _capturedFile = file;
        _isCapturing = false;
      });
    } catch (e) {
      debugPrint('Take picture failed: $e');

      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<File> _flipImageHorizontal(File file) async {
    final bytes = await file.readAsBytes();

    final image = img.decodeImage(bytes);

    if (image == null) {
      return file;
    }

    final flipped = img.flipHorizontal(image);

    final flippedBytes = img.encodeJpg(flipped);

    return file.writeAsBytes(flippedBytes);
  }

  void _cancelPreview() {
    setState(() {
      _capturedFile = null;
    });
  }

  void _confirmPicture() {
    final file = _capturedFile;

    if (file == null) return;

    Navigator.of(context).pop(XFile(file.path));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return const CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    const targetAspectRatio = 4 / 3;

    final previewHeight = screenWidth / targetAspectRatio;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(
            controller: controller,
            screenWidth: screenWidth,
            previewHeight: previewHeight,
          ),

          _buildTopGradient(),

          _buildHeader(),

          _buildTimeMarkOverlay(),

          if (_capturedFile == null)
            _buildCaptureButton()
          else
            _buildPreviewActions(),

          if (_isSwitching || _isCapturing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildTimeMarkOverlay() {
    final lat = widget.latitude;
    final long = widget.longitude;

    final bool wajibWajah =
        widget.jenis == AbsensiJenis.berangkat ||
        widget.jenis == AbsensiJenis.pulang;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 125,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xCC000000),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x44FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.location_fill,
                    size: 14,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'LAT ${lat?.toStringAsFixed(6) ?? '-'}  '
                      'LONG ${long?.toStringAsFixed(6) ?? '-'}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'E-ABSENSI RS PKU MUHAMMADIYAH',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.white,
                  decoration: TextDecoration.none,
                ),
              ),

              if (wajibWajah) ...[
                const SizedBox(height: 7),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      CupertinoIcons.person_crop_circle_fill,
                      size: 14,
                      color: Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.jenis == AbsensiJenis.berangkat
                            ? 'Wajah wajib terlihat jelas. '
                                  'Lepaskan masker atau penutup wajah '
                                  'saat mengambil foto.'
                            : 'Pastikan wajah terlihat jelas '
                                  'saat mengambil foto.',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          height: 1.35,
                          color: Color(0xFFF3F4F6),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview({
    required CameraController controller,
    required double screenWidth,
    required double previewHeight,
  }) {
    if (_capturedFile == null) {
      return Center(
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize!.height,
                height: controller.value.previewSize!.width,
                child: CameraPreview(controller),
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: screenWidth,
        height: previewHeight,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize!.height,
            height: controller.value.previewSize!.width,
            child: Image.file(_capturedFile!, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildTopGradient() {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 170,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB8000000), Color(0x55000000), Color(0x00000000)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              _buildCameraButton(
                icon: CupertinoIcons.back,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.jenis.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _capturedFile == null
                          ? 'Ambil foto untuk absensi'
                          : 'Periksa foto sebelum digunakan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFD1D5DB),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              if (_capturedFile == null && widget.allowSwitchCamera)
                _buildCameraButton(
                  icon: CupertinoIcons.switch_camera,
                  onPressed: _toggleCamera,
                ),

              if (_capturedFile == null && widget.allowSwitchCamera && _isRear)
                const SizedBox(width: 8),

              if (_capturedFile == null && _isRear)
                _buildCameraButton(
                  icon: _isFlash
                      ? CupertinoIcons.bolt_fill
                      : CupertinoIcons.bolt_slash,
                  iconColor: _isFlash
                      ? const Color(0xFFFBBF24)
                      : CupertinoColors.white,
                  onPressed: _toggleFlash,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = CupertinoColors.white,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0x55FFFFFF)),
        ),
        child: Icon(icon, size: 19, color: iconColor),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Center(
            child: GestureDetector(
              onTap: _isCapturing ? null : _takePicture,
              child: AnimatedScale(
                scale: _isCapturing ? 0.88 : 1.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Container(
                  width: 78,
                  height: 78,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.white,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CupertinoColors.activeBlue,
                      border: Border.all(
                        color: CupertinoColors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.camera_fill,
                      color: CupertinoColors.white,
                      size: 29,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewActions() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPreviewAction(
                icon: CupertinoIcons.xmark,
                label: 'Ulangi',
                color: CupertinoColors.destructiveRed,
                onPressed: _cancelPreview,
              ),

              const SizedBox(width: 42),

              _buildPreviewAction(
                icon: CupertinoIcons.checkmark,
                label: 'Gunakan',
                color: CupertinoColors.activeBlue,
                onPressed: _confirmPicture,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xE6000000),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.65),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: const Color(0x44000000),
          child: const Center(child: CupertinoActivityIndicator(radius: 14)),
        ),
      ),
    );
  }
}
