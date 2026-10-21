import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../database/database_helper.dart';
import '../models/item.dart';

class ExportService {
  static const int currentSchemaVersion = 1;

  static Future<void> exportData() async {
    final items = await DatabaseHelper.instance.getAllItems();
    final payload = {
      'schemaVersion': currentSchemaVersion,
      'appName': 'Dateora',
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items.map((e) => e.toMap()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    await Share.share(jsonStr, subject: 'Dateora Backup Data');
  }

  static Future<Map<String, dynamic>> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return {'success': false, 'cancelled': true};
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content);

      if (data is! Map || data['items'] is! List) {
        return {'success': false, 'error': 'Invalid backup format'};
      }

      final List itemsList = data['items'];
      int imported = 0;
      for (final itemMap in itemsList) {
        try {
          final Map<String, dynamic> mapped = Map<String, dynamic>.from(itemMap as Map);
          if (mapped['status'] == 'finished') {
            mapped['status'] = 'used';
          }
          final item = Item.fromMap(mapped);
          await DatabaseHelper.instance.insertItem(item);
          imported++;
        } catch (_) {}
      }

      return {'success': true, 'count': imported};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
