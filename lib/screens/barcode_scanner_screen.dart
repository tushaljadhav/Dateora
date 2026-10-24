import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Full-screen live camera barcode & QR scanner with torch toggle,
/// viewfinder cutout, instant recognition, and manual entry fallback.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final MobileScannerController _controller;
  bool _isTorchOn = false;
  bool _hasScanned = false;
  bool _cameraPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    // Default controller supports all common 1D & 2D formats (EAN, UPC, Code 128, Code 39, ITF, QR, etc.)
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      autoStart: true,
    );
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) {
        setState(() => _cameraPermissionGranted = true);
        try {
          _controller.start();
        } catch (_) {}
      }
    } else {
      final requested = await Permission.camera.request();
      if (mounted) {
        if (requested.isGranted) {
          setState(() => _cameraPermissionGranted = true);
          try {
            _controller.start();
          } catch (_) {}
        } else {
          setState(() => _cameraPermissionGranted = false);
          _showManualEntryDialog();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        _hasScanned = true;
        SoundService.playBarcodeBeep();
        try {
          _controller.stop();
        } catch (_) {}
        if (mounted) {
          Navigator.of(context).pop(code);
        }
        break;
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) {
        setState(() {
          _isTorchOn = !_isTorchOn;
        });
      }
    } catch (_) {}
  }

  Future<void> _showManualEntryDialog() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.keyboard_alt_outlined, color: AppColors.primaryStrong),
            SizedBox(width: 8),
            Text('Enter Barcode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter barcode digits or packaging code:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.text,
              autofocus: true,
              maxLength: 24,
              decoration: InputDecoration(
                hintText: 'e.g. 8901030383848',
                labelText: 'Barcode Code',
                prefixIcon: const Icon(Icons.qr_code_2, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryStrong,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final code = textController.text.trim();
              if (code.isNotEmpty) {
                SoundService.playBarcodeBeep();
                Navigator.pop(ctx, code);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      _hasScanned = true;
      Navigator.of(context).pop(result);
    } else if (!_cameraPermissionGranted && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanBoxWidth = screenSize.width * 0.82;
    final scanBoxHeight = scanBoxWidth * 0.60;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View or Permission Denied Message
          if (_cameraPermissionGranted)
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
                    const SizedBox(height: 16),
                    Text(
                      'Camera permission is needed to scan barcodes directly.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _showManualEntryDialog,
                      icon: const Icon(Icons.keyboard_alt_outlined),
                      label: const Text('Enter Barcode Manually'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Dark Overlay with Cutout (Viewfinder)
          if (_cameraPermissionGranted)
            Positioned.fill(
              child: Stack(
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.65),
                      BlendMode.srcOut,
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            backgroundBlendMode: BlendMode.dstOut,
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: scanBoxWidth,
                            height: scanBoxHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Green viewfinder border with shadow
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: scanBoxWidth,
                      height: scanBoxHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryStrong, width: 2.5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryStrong.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 3. Top Bar (Close and Torch toggle)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    tooltip: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Scan Barcode / QR',
                    style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  if (_cameraPermissionGranted)
                    IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isTorchOn ? Colors.amber : Colors.white,
                        size: 26,
                      ),
                      tooltip: 'Toggle Flash',
                      onPressed: _toggleTorch,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // 4. Viewfinder Instructions & Manual Entry Button
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primaryStrong.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white30, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Point camera at barcode on packaging',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.18),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        side: const BorderSide(color: Colors.white30),
                      ),
                    ),
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
                    label: const Text('Enter code manually'),
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
