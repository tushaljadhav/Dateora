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

  /// Formatted display name with smart brand deduplication (e.g. handles "Smith and Jones" vs "Smith & Jones")
  String get displayName {
    final b = brand?.trim() ?? '';
    final p = productName?.trim() ?? '';
    if (b.isEmpty) return p;
    if (p.isEmpty) return b;

    // Normalize strings for comparison (remove punctuation, normalize '&' to 'and', collapse spaces)
    String normalize(String s) => s
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final normB = normalize(b);
    final normP = normalize(p);

    if (normP.startsWith(normB) || normP.contains(normB)) {
      return p;
    }
    return '$b $p';
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
      final rawCategory = p['categories']?.toString();

      // Normalize into Dateora preset category IDs: groceries, dairy, pantry, beverages, medicine, skincare, household
      final category = mapToPresetCategory(rawCategory, name?.toString(), categoryTags);

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

  /// Maps Open Food Facts categories and product names directly to Dateora's preset category IDs:
  /// 'groceries', 'medicine', 'skincare', 'dairy', 'household', 'beverages', 'pantry'
  static String mapToPresetCategory(String? rawCategory, String? productName, List? tags) {
    final combined = [
      if (rawCategory != null) rawCategory,
      if (productName != null) productName,
      if (tags != null) ...tags.map((t) => t.toString()),
    ].join(' ').toLowerCase();

    // 1. Dairy & Eggs
    if (combined.contains('dairy') ||
        combined.contains('dairies') ||
        combined.contains('milk') ||
        combined.contains('cheese') ||
        combined.contains('butter') ||
        combined.contains('paneer') ||
        combined.contains('curd') ||
        combined.contains('yogurt') ||
        combined.contains('dahi') ||
        combined.contains('ghee') ||
        combined.contains('cream') ||
        combined.contains('egg')) {
      return 'dairy';
    }

    // 2. Beverages / Drinks
    if (combined.contains('beverage') ||
        combined.contains('drink') ||
        combined.contains('juice') ||
        combined.contains('tea') ||
        combined.contains('coffee') ||
        combined.contains('chai') ||
        combined.contains('water') ||
        combined.contains('soda') ||
        combined.contains('cola')) {
      return 'beverages';
    }

    // 3. Pantry & Cooking Staples (Pastes, Spices, Masala, Oil, Flour, Dal)
    if (combined.contains('paste') || // e.g. Ginger Garlic Paste, Tomato Paste
        combined.contains('spice') ||
        combined.contains('masala') ||
        combined.contains('sauce') ||
        combined.contains('ketchup') ||
        combined.contains('oil') ||
        combined.contains('vinegar') ||
        combined.contains('pickle') ||
        combined.contains('achar') ||
        combined.contains('flour') ||
        combined.contains('atta') ||
        combined.contains('besan') ||
        combined.contains('maida') ||
        combined.contains('suji') ||
        combined.contains('rice') ||
        combined.contains('chawal') ||
        combined.contains('dal') ||
        combined.contains('pulses') ||
        combined.contains('lentil') ||
        combined.contains('salt') ||
        combined.contains('sugar') ||
        combined.contains('condiment') ||
        combined.contains('seasoning') ||
        combined.contains('pantry')) {
      return 'pantry';
    }

    // 4. Medicine / Healthcare
    if (combined.contains('medicine') ||
        combined.contains('tablet') ||
        combined.contains('capsule') ||
        combined.contains('syrup') ||
        combined.contains('pharma') ||
        combined.contains('paracetamol')) {
      return 'medicine';
    }

    // 5. Skincare & Personal Care
    if (combined.contains('skin') ||
        combined.contains('lotion') ||
        combined.contains('shampoo') ||
        combined.contains('soap') ||
        combined.contains('face wash') ||
        combined.contains('cosmetic')) {
      return 'skincare';
    }

    // 6. Household
    if (combined.contains('household') ||
        combined.contains('detergent') ||
        combined.contains('dishwash') ||
        combined.contains('cleaner') ||
        combined.contains('tissue') ||
        combined.contains('wipe')) {
      return 'household';
    }

    // Default for packaged foods, snacks, biscuits, etc.
    return 'groceries';
  }
}
