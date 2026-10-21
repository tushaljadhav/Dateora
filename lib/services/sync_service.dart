// DISABLED in v1: cloud sync has no auth. Re-enable only with login + user_id.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../models/item.dart';

class SyncService {
  static const String apiBase = 'https://dateora.onrender.com/api';

  static Future<Map<String, dynamic>> pushToRemote() async {
    try {
      final items = await DatabaseHelper.instance.getAllItems();
      final body = jsonEncode({
        'items': items.map((e) => e.toApiJson()).toList(),
        'settings': {},
      });

      final response = await http.post(
        Uri.parse('$apiBase/sync/push'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'itemsSynced': data['itemsSynced']};
      } else {
        return {'success': false, 'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> pullFromRemote() async {
    try {
      final response = await http.get(Uri.parse('$apiBase/sync/pull'));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        List remoteItems = [];
        if (data['data'] != null && data['data']['items'] is List) {
          remoteItems = data['data']['items'];
        } else if (data['items'] is List) {
          remoteItems = data['items'];
        }

        int pulled = 0;
        for (final itemJson in remoteItems) {
          final item = Item.fromMap(Map<String, dynamic>.from(itemJson));
          await DatabaseHelper.instance.insertItem(item);
          pulled++;
        }

        return {'success': true, 'itemsPulled': pulled};
      } else {
        return {'success': false, 'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
