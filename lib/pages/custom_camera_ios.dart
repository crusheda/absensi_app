import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomCameraIOS extends StatefulWidget {
  final CameraDescription frontCamera;
  final CameraDescription rearCamera;
  final bool allowSwitchCamera;

  const CustomCameraIOS({
    super.key,
    required this.frontCamera,
    required this.rearCamera,
    required this.allowSwitchCamera,
  });

  @override
  State<CustomCameraIOS> createState() => _CustomCameraIOSState();
}

class _CustomCameraIOSState extends State<CustomCameraIOS> {
  CameraController? _controller;
  bool _isRear = false;
  bool _isFlash = false;
  bool _isCapturing = false;
  File? _capturedFile;

  @override
  void initState() {
    super.initState();
    _isRear = widget.allowSwitchCamera ? false : false; // default front
    _startCamera(widget.frontCamera);
  }

  Future<void> _startCamera(CameraDescription description) async {
    if (_controller != null) {
      final oldController = _controller!;
      _controller = null;
      await oldController.dispose();
    }

    final newController = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await newController.initialize();
    await newController.setFlashMode(FlashMode.off);

    if (mounted) {
      setState(() {
        _controller = newController;
        _isFlash = false;
      });
    }
  }

  bool _isSwitching = false;

  void _toggleCamera() async {
    if (_isSwitching) return;

    setState(() {
      _isSwitching = true;
      _isRear = !_isRear;
    });

    await _startCamera(_isRear ? widget.rearCamera : widget.frontCamera);

    if (mounted) {
      setState(() {
        _isSwitching = false;
      });
    }
  }

  void _toggleFlash() async {
    if (_controller == null) return;

    try {
      final newFlashState = !_isFlash;

      await _controller!.setFlashMode(
        newFlashState ? FlashMode.torch : FlashMode.off,
      );

      if (mounted) {
        setState(() {
          _isFlash = newFlashState;
        });
      }
    } catch (e) {
      debugPrint("Flash not supported: $e");
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final rawFile = await _controller!.takePicture();
      File file = File(rawFile.path);

      if (!_isRear) {
        file = await _flipImageHorizontal(file);
      }

      if (!mounted) return;

      setState(() {
        _capturedFile = file; // Simpan untuk preview
        _isCapturing = false;
      });
    } catch (e) {
      debugPrint("Take picture failed: $e");
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<File> _flipImageHorizontal(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final flipped = img.flipHorizontal(image);
    final flippedBytes = img.encodeJpg(flipped);
    return file.writeAsBytes(flippedBytes);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final targetAspectRatio = 4 / 3;
    final previewHeight = screenWidth / targetAspectRatio;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      child: Stack(
        children: [
          // ✅ Preview Kamera atau Foto
          if (_capturedFile == null) ...[
            Center(
              child: SizedBox(
                width: screenWidth,
                height: previewHeight,
                child: FittedBox(
                  fit: BoxFit.cover, // atau BoxFit.contain => pilih sendiri
                  child: SizedBox(
                    width: _controller!.value.previewSize!.height,
                    height: _controller!.value.previewSize!.width,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            ),
          ] else ...[
            Center(
              child: SizedBox(
                width: screenWidth,
                height: previewHeight,
                child: FittedBox(
                  fit: BoxFit.cover, // atau contain
                  child: SizedBox(
                    width: _controller!.value.previewSize!.height,
                    height: _controller!.value.previewSize!.width,
                    child: Image.file(
                      _capturedFile!,
                      fit: BoxFit.cover, // biar mirip preview
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ✅ Swap kamera & Flash
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Bagian KIRI
                Row(
                  children: [
                    // TOMBOL KEMBALI
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.back,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                        size: 28,
                      ),
                      onPressed: () {
                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "E-Absensi",
                      style: TextStyle(
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                        fontSize: 18,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // Bagian KANAN
                Row(
                  children: [
                    // TOMBOL SWAP KAMERA
                    if (widget.allowSwitchCamera)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(
                          CupertinoIcons.switch_camera,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          size: 28,
                        ),
                        onPressed: _toggleCamera,
                      ),
                    if (_isRear)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(
                          _isFlash
                              ? CupertinoIcons.bolt_fill
                              : CupertinoIcons.bolt_slash,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          size: 28,
                        ),
                        onPressed: _toggleFlash,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ✅ Tombol bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60, left: 20, right: 20),
              child: _capturedFile == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Foto Selfie hanya sebagai\nbukti bahwa Anda telah\nmelakukan Absensi",
                            style: TextStyle(
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                              fontSize: 16,
                              decoration: TextDecoration.none,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const SizedBox(width: 60),
                        GestureDetector(
                          onTap: _takePicture,
                          child: AnimatedScale(
                            scale: _isCapturing ? 0.9 : 1.0,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.secondarySystemFill,
                                border: Border.all(
                                  color: CupertinoColors.activeBlue,
                                  width: 4,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.camera_fill,
                                  color: CupertinoColors.black,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                            size: 50,
                          ),
                          onPressed: () {
                            setState(() {
                              _capturedFile = null;
                            });
                          },
                        ),
                        const SizedBox(width: 60),
                        CupertinoButton(
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                            size: 50,
                          ),
                          onPressed: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                Navigator.of(
                                  context,
                                ).pop(XFile(_capturedFile!.path));
                              }
                            });
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
