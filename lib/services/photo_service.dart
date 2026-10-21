import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class PhotoService {
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();

  /// Captures from Camera or picks from Gallery cleanly without redundant dialogs.
  static Future<String?> captureOrPickPhoto({
    required BuildContext context,
    required ImageSource source,
    String? currentPhotoPath,
  }) async {
    // 1. For Camera: check permission cleanly without repetitive custom popups
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
      // 2. Capture/Pick via ImagePicker (HD 1920px, quality 88% for sharp dot-matrix & small font OCR)
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );

      if (pickedFile == null) return null;

      // 3. Save to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'dateora_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final ext = p.extension(pickedFile.path).isNotEmpty
          ? p.extension(pickedFile.path)
          : '.jpg';
      final fileName = 'photo_${_uuid.v4()}$ext';
      final savedFile = File(p.join(photosDir.path, fileName));

      await File(pickedFile.path).copy(savedFile.path);

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
