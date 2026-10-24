import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Full-screen live camera barcode scanner with torch toggle,
/// viewfinder cutout, debounce, camera permission check,
/// and fallback manual entry button.
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
  bool _isReadyToScan = false;
  Timer? _warmupTimer;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ],
      detectionSpeed: DetectionSpeed.noDuplicates,
      autoStart: false,
    );
    _checkCameraPermission();
  }

  void _startWarmupTimer() {
    _warmupTimer?.cancel();
    setState(() => _isReadyToScan = false);
    // 1.4-second stabilization pause so user can properly align barcode without partial captures
    _warmupTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _isReadyToScan = true);
      }
    });
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _cameraPermissionGranted = true;
        });
        _controller.start();
        _startWarmupTimer();
      }
    } else {
      final requested = await Permission.camera.request();
      if (mounted) {
        if (requested.isGranted) {
          setState(() {
            _cameraPermissionGranted = true;
          });
          _controller.start();
          _startWarmupTimer();
        } else {
          setState(() {
            _cameraPermissionGranted = false;
          });
          // Fallback directly to manual entry when camera permission is denied
          _showManualEntryDialog();
        }
      }
    }
  }

  @override
  void dispose() {
    _warmupTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // Ignore any frames during camera warm-up or after barcode is already captured
    if (!_isReadyToScan || _hasScanned) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      // Ensure barcode is numeric and at least 8 digits (standard EAN/UPC) to avoid partial scans
      if (code != null && code.length >= 8 && RegExp(r'^\d+$').hasMatch(code)) {
        _hasScanned = true;
        SoundService.playBarcodeBeep();
        _controller.stop();
        Navigator.of(context).pop(code);
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
              'Enter the 8 to 13-digit barcode number printed on packaging:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              maxLength: 14,
              decoration: InputDecoration(
                hintText: 'e.g. 8901030383848',
                labelText: 'Barcode Number',
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
      // If camera was denied and user cancelled manual entry, close scanner screen
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanBoxWidth = screenSize.width * 0.78;
    final scanBoxHeight = scanBoxWidth * 0.65;

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
                  // Green/Primary viewfinder border
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: scanBoxWidth,
                      height: scanBoxHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2.5),
                        borderRadius: BorderRadius.circular(16),
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
                    'Scan Barcode',
                    style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isReadyToScan ? AppColors.primaryStrong.withOpacity(0.9) : Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isReadyToScan ? Colors.white30 : Colors.amber.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isReadyToScan) ...[
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Align camera... Ready in 1 second',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.qr_code_scanner, size: 14, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Align full barcode inside the box',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        side: const BorderSide(color: Colors.white30),
                      ),
                    ),
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
                    label: const Text('Enter barcode manually'),
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
