import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result from an Open Food Facts barcode lookup.
class BarcodeProduct {
  final String barcode;
  final String? productName;
  final String? brand;
  final String? category;
  final double? quantity;
  final String? unit;
  final String? imageUrl;

  const BarcodeProduct({
    required this.barcode,
    this.productName,
    this.brand,
    this.category,
    this.quantity,
    this.unit,
    this.imageUrl,
  });

  String get displayName {
    if (brand != null && brand!.isNotEmpty && productName != null && productName!.isNotEmpty) {
      return '$brand $productName';
    }
    return productName ?? brand ?? '';
  }
}

/// Free, public barcode lookup service using Open Food Facts (no API key required).
class OpenFoodFactsService {
  static const _timeout = Duration(seconds: 8);

  /// Looks up product metadata by barcode. Returns null if not found or network fails.
  static Future<BarcodeProduct?> lookupBarcode(String barcode) async {
    final cleanCode = barcode.trim();
    if (cleanCode.isEmpty) return null;

    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v0/product/$cleanCode.json',
    );

    try {
      final response = await http
          .get(
            url,
            headers: {
              'User-Agent': 'DateoraExpiryTracker/1.0.0 (flutter-app)',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['status'] != 1 || data['product'] == null) {
        return null;
      }

      final p = data['product'];
      final name = p['product_name'] ?? p['product_name_en'];
      final brand = p['brands'];
      final categoryTags = p['categories_tags'] as List?;
      String? category;
      if (categoryTags != null && categoryTags.isNotEmpty) {
        category = categoryTags.first.toString().replaceAll('en:', '');
      }

      // Quantity / Unit parsing from quantity string (e.g., "500 ml", "1 kg")
      final qtyStr = p['quantity']?.toString();
      double? quantity;
      String? unit;
      if (qtyStr != null && qtyStr.isNotEmpty) {
        final match = RegExp(r'^([\d\.]+)\s*([a-zA-Z]+)?').firstMatch(qtyStr.trim());
        if (match != null) {
          quantity = double.tryParse(match.group(1)!);
          unit = match.group(2);
        }
      }

      final imageUrl = p['image_front_small_url'] ?? p['image_url'];

      return BarcodeProduct(
        barcode: cleanCode,
        productName: name?.toString(),
        brand: brand?.toString(),
        category: category,
        quantity: quantity,
        unit: unit,
        imageUrl: imageUrl?.toString(),
      );
    } catch (_) {
      // Graceful fallback on network timeout or parse failure
      return null;
    }
  }
}
