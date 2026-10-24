import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

/// Top-level isolate function for off-thread image resize and JPEG compression.
Future<void> _processImageOffThread(Map<String, dynamic> args) async {
  final String srcPath = args['srcPath'] as String;
  final String destPath = args['destPath'] as String;
  final int maxDim = args['maxDim'] as int? ?? 1024;
  final int quality = args['quality'] as int? ?? 70;

  final bytes = await File(srcPath).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    // Fallback: copy file as-is if image format cannot be decoded
    await File(srcPath).copy(destPath);
    return;
  }

  // Resize so max dimension is at most maxDim (maintaining aspect ratio)
  img.Image processed = decoded;
  if (decoded.width > maxDim || decoded.height > maxDim) {
    if (decoded.width >= decoded.height) {
      processed = img.copyResize(decoded, width: maxDim);
    } else {
      processed = img.copyResize(decoded, height: maxDim);
    }
  }

  final compressedJpg = img.encodeJpg(processed, quality: quality);
  await File(destPath).writeAsBytes(compressedJpg, flush: true);
}

class PhotoService {
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();

  /// Captures from Camera or picks from Gallery cleanly with 1024px / 70% JPEG compression.
  static Future<String?> captureOrPickPhoto({
    required BuildContext context,
    required ImageSource source,
    String? currentPhotoPath,
  }) async {
    // 1. For Camera: check permission in context
    if (source == ImageSource.camera) {
      final cameraStatus = await Permission.camera.status;

      if (cameraStatus.isPermanentlyDenied) {
        if (context.mounted) {
          await _showPermissionSettingsDialog(
            context,
            title: 'Camera Access Needed',
            message:
                'Dateora needs camera access to snap photos of product labels. Please enable Camera in App Settings.',
          );
        }
        return null;
      }

      if (!cameraStatus.isGranted) {
        final requested = await Permission.camera.request();
        if (!requested.isGranted) {
          if (requested.isPermanentlyDenied && context.mounted) {
            await _showPermissionSettingsDialog(
              context,
              title: 'Camera Access Needed',
              message:
                  'Camera access was denied. Please allow camera permission in App Settings to take photos.',
            );
          }
          return null;
        }
      }
    }

    try {
      // 2. Capture/Pick via ImagePicker with max 1024 px on long side and JPEG quality 70
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (pickedFile == null) return null;

      // 3. Save to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'dateora_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final fileName = 'photo_${_uuid.v4()}.jpg';
      final savedFile = File(p.join(photosDir.path, fileName));

      // Process and compress off the UI thread via compute
      await compute(_processImageOffThread, {
        'srcPath': pickedFile.path,
        'destPath': savedFile.path,
        'maxDim': 1024,
        'quality': 70,
      });

      // 4. Delete old replaced photo file if it exists
      if (currentPhotoPath != null) {
        await deletePhotoFile(currentPhotoPath);
      }

      return savedFile.path;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access image: $e')),
        );
      }
      return null;
    }
  }

  /// Ensures an existing image file is compressed to max 1024px / quality 70 before server upload.
  static Future<File> compressForUpload(File file) async {
    try {
      if (!await file.exists()) return file;

      final tempDir = await getTemporaryDirectory();
      final compressedPath = p.join(tempDir.path, 'upload_${_uuid.v4()}.jpg');

      await compute(_processImageOffThread, {
        'srcPath': file.path,
        'destPath': compressedPath,
        'maxDim': 1024,
        'quality': 70,
      });

      final compressedFile = File(compressedPath);
      if (await compressedFile.exists()) {
        return compressedFile;
      }
    } catch (_) {}
    return file;
  }

  /// Deletes a photo file locally from the file system.
  static Future<void> deletePhotoFile(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return;
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Shows Settings dialog only when permission is permanently denied.
  static Future<void> _showPermissionSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
