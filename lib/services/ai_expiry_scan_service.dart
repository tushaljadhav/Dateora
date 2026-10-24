import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'device_service.dart';
import 'photo_service.dart';

/// Configuration constants for Dateora AI Vision processing.
class AiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dateora.onrender.com/api',
  );
  static const int timeoutSeconds = 18; // 18s fail-fast timeout for proxy
  static const int maxScansPerDay = 8;
  static const double temperature = 0.1;
}

/// Typed Exceptions for clean client-side error handling
class RateLimitException implements Exception {
  final String message;
  final int remaining;
  const RateLimitException(this.message, {this.remaining = 0});
  @override
  String toString() => message;
}

class AiUnavailableException implements Exception {
  final String message;
  const AiUnavailableException(this.message);
  @override
  String toString() => message;
}

class InvalidInputException implements Exception {
  final String message;
  const InvalidInputException(this.message);
  @override
  String toString() => message;
}

/// Abstract transport layer contract.
abstract class AiTransport {
  Future<Map<String, dynamic>> sendVisionRequest({
    required List<File> images,
    required String prompt,
    String? model,
    String? apiKey,
    Map<String, dynamic>? responseSchema,
  });

  Future<Map<String, dynamic>> testConnection({
    String? model,
    String? apiKey,
  });
}

/// Production Proxy transport communicating strictly through the Dateora Node.js backend proxy.
class ProxyTransport implements AiTransport {
  final String baseUrl;
  final String? authToken;
  final http.Client _client;

  ProxyTransport({
    String? baseUrl,
    this.authToken,
    http.Client? client,
  })  : baseUrl = baseUrl ?? AiConfig.apiBaseUrl,
        _client = client ?? http.Client();

  @override
  Future<Map<String, dynamic>> sendVisionRequest({
    required List<File> images,
    required String prompt,
    String? model,
    String? apiKey,
    Map<String, dynamic>? responseSchema,
  }) async {
    final cleanBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final url = cleanBase.endsWith('/api')
        ? Uri.parse('$cleanBase/ai/scan')
        : Uri.parse('$cleanBase/api/ai/scan');

    final deviceId = await DeviceService.getDeviceId();
    final headers = {
      'Content-Type': 'application/json',
      'X-Device-Id': deviceId,
      if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };

    final List<Map<String, dynamic>> imagePayloads = [];
    for (final img in images) {
      if (await img.exists()) {
        final compressed = await PhotoService.compressForUpload(img);
        final bytes = await compressed.readAsBytes();
        final ext = p.extension(compressed.path).toLowerCase();
        String mimeType = 'image/jpeg';
        if (ext == '.png') {
          mimeType = 'image/png';
        } else if (ext == '.webp') {
          mimeType = 'image/webp';
        }

        imagePayloads.add({
          'name': p.basename(compressed.path),
          'mimeType': mimeType,
          'data': base64Encode(bytes),
        });
      }
    }

    final body = jsonEncode({
      'images': imagePayloads,
      'prompt': prompt,
    });

    final http.Response response;
    try {
      response = await _client
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: AiConfig.timeoutSeconds));
    } on TimeoutException {
      throw const SocketException('Server response timed out after 60 seconds.');
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    try {
      final errBody = jsonDecode(response.body) as Map<String, dynamic>;
      final code = errBody['error'] as String?;
      final msg = errBody['message'] as String? ?? 'Proxy returned HTTP ${response.statusCode}';
      final remaining = errBody['remaining'] as int? ?? 0;

      if (code == 'RATE_LIMITED' || response.statusCode == 429) {
        throw RateLimitException(msg, remaining: remaining);
      }
      if (code == 'AI_UNAVAILABLE' || response.statusCode >= 500) {
        throw AiUnavailableException(msg);
      }
      if (code == 'INVALID_INPUT' || response.statusCode == 400) {
        throw InvalidInputException(msg);
      }
      throw HttpException(msg);
    } catch (e) {
      if (e is RateLimitException || e is AiUnavailableException || e is InvalidInputException) {
        rethrow;
      }
      throw HttpException('Proxy Error: HTTP ${response.statusCode}');
    }
  }

  @override
  Future<Map<String, dynamic>> testConnection({
    String? model,
    String? apiKey,
  }) async {
    final cleanBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final url = cleanBase.endsWith('/api')
        ? Uri.parse('$cleanBase/ai/health')
        : Uri.parse('$cleanBase/api/ai/health');

    try {
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Proxy backend connected successfully!'};
      }
      return {'success': false, 'message': 'Proxy returned HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to proxy: $e'};
    }
  }
}

/// Direct transport communicating straight with Google's Gemini Vision API.
/// Instant 1-2s response without intermediate proxy cold start.
class DirectGeminiTransport implements AiTransport {
  final String apiKey;
  final String model;
  final http.Client _client;

  DirectGeminiTransport({
    required this.apiKey,
    this.model = 'gemini-3.5-flash',
    http.Client? client,
  })  : _client = client ?? http.Client();

  @override
  Future<Map<String, dynamic>> sendVisionRequest({
    required List<File> images,
    required String prompt,
    String? model,
    String? apiKey,
    Map<String, dynamic>? responseSchema,
  }) async {
    final effectiveKey = (apiKey != null && apiKey.trim().isNotEmpty) ? apiKey.trim() : this.apiKey;
    final effectiveModel = (model != null && model.trim().isNotEmpty) ? model.trim() : this.model;

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$effectiveModel:generateContent?key=$effectiveKey',
    );

    final List<Map<String, dynamic>> parts = [
      {'text': prompt},
    ];

    for (final img in images) {
      if (await img.exists()) {
        final compressed = await PhotoService.compressForUpload(img);
        final bytes = await compressed.readAsBytes();
        final ext = p.extension(compressed.path).toLowerCase();
        String mimeType = 'image/jpeg';
        if (ext == '.png') {
          mimeType = 'image/png';
        } else if (ext == '.webp') {
          mimeType = 'image/webp';
        }

        parts.add({
          'inlineData': {
            'mimeType': mimeType,
            'data': base64Encode(bytes),
          },
        });
      }
    }

    final body = jsonEncode({
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'temperature': AiConfig.temperature,
        'responseMimeType': 'application/json',
      },
    });

    final http.Response response;
    try {
      response = await _client
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 22));
    } on TimeoutException {
      throw const SocketException('Direct Gemini API timed out after 22 seconds.');
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 429) {
      throw const RateLimitException('Gemini API rate limit reached. Please wait a minute before retrying.');
    } else if (response.statusCode == 400 || response.statusCode == 403) {
      final errBody = jsonDecode(response.body);
      final msg = errBody?['error']?['message'] ?? 'Invalid Gemini API key or request.';
      throw InvalidInputException(msg.toString());
    } else {
      throw HttpException('Gemini API Error: HTTP ${response.statusCode}');
    }
  }

  @override
  Future<Map<String, dynamic>> testConnection({
    String? model,
    String? apiKey,
  }) async {
    final effectiveKey = (apiKey != null && apiKey.trim().isNotEmpty) ? apiKey.trim() : this.apiKey;
    final effectiveModel = (model != null && model.trim().isNotEmpty) ? model.trim() : this.model;

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$effectiveModel:generateContent?key=$effectiveKey',
    );

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping test. Reply with JSON {"status": "ok"}'}
              ]
            }
          ],
          'generationConfig': {'responseMimeType': 'application/json'},
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Google Gemini API key is valid and connected!'};
      }
      return {'success': false, 'message': 'Gemini returned HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to Gemini: $e'};
    }
  }
}

/// Normalizes raw AI category classifications to exact 9 preset category names.
class CategoryNormalizer {
  static const Map<String, String> _synonyms = {
    // Dairy & Eggs
    'dairy': 'Dairy & Eggs',
    'milk': 'Dairy & Eggs',
    'cheese': 'Dairy & Eggs',
    'paneer': 'Dairy & Eggs',
    'yogurt': 'Dairy & Eggs',
    'butter': 'Dairy & Eggs',
    'curd': 'Dairy & Eggs',
    'dahi': 'Dairy & Eggs',
    'lassi': 'Dairy & Eggs',
    'chaas': 'Dairy & Eggs',
    'buttermilk': 'Dairy & Eggs',
    'malai': 'Dairy & Eggs',
    'egg': 'Dairy & Eggs',
    'eggs': 'Dairy & Eggs',
    'dairy & eggs': 'Dairy & Eggs',

    // Medicine
    'medicine': 'Medicine',
    'tablet': 'Medicine',
    'tablets': 'Medicine',
    'capsule': 'Medicine',
    'capsules': 'Medicine',
    'syrup': 'Medicine',
    'pharma': 'Medicine',
    'pharmaceutical': 'Medicine',
    'pill': 'Medicine',
    'pills': 'Medicine',
    'ointment': 'Medicine',
    'drug': 'Medicine',

    // Skincare
    'skincare': 'Skincare',
    'cream': 'Skincare',
    'face cream': 'Skincare',
    'lotion': 'Skincare',
    'serum': 'Skincare',
    'face wash': 'Skincare',
    'sunscreen': 'Skincare',
    'cosmetics': 'Skincare',
    'makeup': 'Skincare',
    'shampoo': 'Skincare',
    'soap': 'Skincare',

    // Groceries
    'groceries': 'Groceries',
    'grocery': 'Groceries',
    'vegetable': 'Groceries',
    'vegetables': 'Groceries',
    'fruit': 'Groceries',
    'fruits': 'Groceries',
    'produce': 'Groceries',
    'bakery': 'Groceries',
    'bread': 'Groceries',
    'sabzi': 'Groceries',
    'onion': 'Groceries',
    'pyaz': 'Groceries',
    'potato': 'Groceries',
    'aloo': 'Groceries',
    'tomato': 'Groceries',
    'tamatar': 'Groceries',

    // Beverages
    'beverages': 'Beverages',
    'beverage': 'Beverages',
    'juice': 'Beverages',
    'soda': 'Beverages',
    'drink': 'Beverages',
    'tea': 'Beverages',
    'chai': 'Beverages',
    'coffee': 'Beverages',
    'water': 'Beverages',
    'sharbat': 'Beverages',

    // Pantry
    'pantry': 'Pantry',
    'flour': 'Pantry',
    'atta': 'Pantry',
    'maida': 'Pantry',
    'suji': 'Pantry',
    'rava': 'Pantry',
    'besan': 'Pantry',
    'poha': 'Pantry',
    'rice': 'Pantry',
    'chawal': 'Pantry',
    'dal': 'Pantry',
    'lentils': 'Pantry',
    'spice': 'Pantry',
    'spices': 'Pantry',
    'masala': 'Pantry',
    'haldi': 'Pantry',
    'mirch': 'Pantry',
    'oil': 'Pantry',
    'tel': 'Pantry',
    'ghee': 'Pantry',
    'sauce': 'Pantry',
    'cereal': 'Pantry',
    'pasta': 'Pantry',
    'noodles': 'Pantry',
    'snack': 'Pantry',
    'snacks': 'Pantry',
    'namkeen': 'Pantry',
    'bhujia': 'Pantry',
    'papad': 'Pantry',
    'biscuit': 'Pantry',
    'biscuits': 'Pantry',
    'pickle': 'Pantry',
    'achar': 'Pantry',

    // Household
    'household': 'Household',
    'detergent': 'Household',
    'cleaner': 'Household',
    'dishwash': 'Household',
    'cleaning': 'Household',

    // Documents
    'documents': 'Documents',
    'document': 'Documents',
    'id': 'Documents',
    'passport': 'Documents',
    'warranty': 'Documents',
    'card': 'Documents',

    // Custom
    'custom': 'Custom',
    'other': 'Custom',
  };

  /// Normalizes to one of the exact 9 preset category display names.
  static String normalizeToName(String? raw) {
    if (raw == null) return 'Custom';
    final clean = raw.trim().toLowerCase();
    return _synonyms[clean] ?? 'Custom';
  }

  /// Maps a display name or category ID to the standard internal category ID string.
  static String toCategoryId(String categoryName) {
    switch (categoryName) {
      case 'Dairy & Eggs':
        return 'dairy';
      case 'Medicine':
        return 'medicine';
      case 'Skincare':
        return 'skincare';
      case 'Groceries':
        return 'groceries';
      case 'Beverages':
        return 'beverages';
      case 'Pantry':
        return 'pantry';
      case 'Household':
        return 'household';
      case 'Documents':
        return 'documents';
      default:
        return 'custom';
    }
  }
}

/// Structured result returned from AI expiry & packaging analysis.
class ScanResult {
  final String? productName;
  final String category; // Normalized name
  final String categoryId; // Internal ID (groceries, dairy, etc.)
  final String? expiryDate; // Strict ISO format: YYYY-MM-DD
  final bool isEstimated; // True if shelf life estimated rather than printed
  final String? printedDate; // Raw printed date if read from pack
  final String? batchNumber;
  final String? mfgDate;
  final int? paoMonths; // Period after opening (PAO symbol, e.g., 12M)
  final double? quantity;
  final String? unit;
  final String? location;
  final String? notes;
  final double confidence; // 0.0 to 1.0
  final String? rawText;
  final bool hasDetectedDate;
  final bool isAlreadyExpired;
  final bool isSuccess;
  final String? errorMessage;
  final String? errorCode; // RATE_LIMITED, AI_UNAVAILABLE, INVALID_INPUT, TIMEOUT, NETWORK
  final int? remainingScans; // Remaining daily scans from backend

  const ScanResult({
    this.productName,
    this.category = 'Custom',
    this.categoryId = 'custom',
    this.expiryDate,
    this.isEstimated = false,
    this.printedDate,
    this.batchNumber,
    this.mfgDate,
    this.paoMonths,
    this.quantity,
    this.unit,
    this.location,
    this.notes,
    this.confidence = 0.0,
    this.rawText,
    this.hasDetectedDate = false,
    this.isAlreadyExpired = false,
    this.isSuccess = true,
    this.errorMessage,
    this.errorCode,
    this.remainingScans,
  });

  /// Confidence level classification.
  String get confidenceLevel {
    if (confidence >= 0.8) return 'high';
    if (confidence >= 0.5) return 'check';
    return 'low';
  }

  ScanResult copyWith({
    String? productName,
    String? category,
    String? categoryId,
    String? expiryDate,
    bool? isEstimated,
    String? printedDate,
    String? batchNumber,
    String? mfgDate,
    int? paoMonths,
    double? quantity,
    String? unit,
    String? location,
    String? notes,
    double? confidence,
    String? rawText,
    bool? hasDetectedDate,
    bool? isAlreadyExpired,
    bool? isSuccess,
    String? errorMessage,
    String? errorCode,
    int? remainingScans,
  }) {
    return ScanResult(
      productName: productName ?? this.productName,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      expiryDate: expiryDate ?? this.expiryDate,
      isEstimated: isEstimated ?? this.isEstimated,
      printedDate: printedDate ?? this.printedDate,
      batchNumber: batchNumber ?? this.batchNumber,
      mfgDate: mfgDate ?? this.mfgDate,
      paoMonths: paoMonths ?? this.paoMonths,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
      hasDetectedDate: hasDetectedDate ?? this.hasDetectedDate,
      isAlreadyExpired: isAlreadyExpired ?? this.isAlreadyExpired,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      remainingScans: remainingScans ?? this.remainingScans,
    );
  }

  factory ScanResult.failed({
    required String message,
    String? errorCode,
    int? remainingScans,
  }) => ScanResult(
        isSuccess: false,
        errorMessage: message,
        errorCode: errorCode,
        remainingScans: remainingScans,
        confidence: 0.0,
      );

  factory ScanResult.empty() => const ScanResult(
        isSuccess: false,
        confidence: 0.0,
      );
}

/// Abstract contract for AI Expiry Date detection.
abstract class ExpiryScanService {
  Future<ScanResult> scanImages(List<File> images, {String? apiKey});
  Future<ScanResult> scanImage(File image, {String? apiKey});
}

/// Production Google Gemini Multimodal Vision AI Scanner communicating via backend proxy.
class GeminiExpiryScanService implements ExpiryScanService {
  final String? defaultApiKey;
  final AiTransport transport;

  /// In-memory cache by image SHA-256 hash so re-scanning identical images avoids API charges.
  static final Map<String, ScanResult> _resultCache = {};

  GeminiExpiryScanService({
    this.defaultApiKey,
    AiTransport? transport,
  }) : transport = transport ?? ProxyTransport();

  /// Fire-and-forget lightweight health ping to warm up Render cold start early
  static void warmupServer() {
    try {
      final clean = AiConfig.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final url = clean.endsWith('/api')
          ? Uri.parse('$clean/health')
          : Uri.parse('$clean/api/health');
      http.get(url).timeout(const Duration(seconds: 5)).then((_) {}).catchError((_) {});
    } catch (_) {}
  }

  /// Validates backend proxy connection or direct Gemini API key.
  static Future<Map<String, dynamic>> testApiKey([String? apiKey]) async {
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      final direct = DirectGeminiTransport(apiKey: apiKey.trim());
      return direct.testConnection();
    }
    final proxy = ProxyTransport();
    return proxy.testConnection();
  }

  @override
  Future<ScanResult> scanImage(File image, {String? apiKey}) {
    return scanImages([image], apiKey: apiKey);
  }

  @override
  Future<ScanResult> scanImages(List<File> images, {String? apiKey}) async {
    final validImages = images.where((f) => f.existsSync()).toList();
    if (validImages.isEmpty) {
      return ScanResult.failed(message: 'No valid image file found to analyze.');
    }

    // 1. Check in-memory image hash cache
    final cacheKey = await _computeImagesHash(validImages);
    if (_resultCache.containsKey(cacheKey)) {
      return _resultCache[cacheKey]!;
    }

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final promptText = '''
You are Dateora AI — a high-accuracy product expiry & packaging specialist.
Analyze the provided product packaging photo(s) carefully. You may receive 1 photo (front) or 2 photos (front + date side).

Today's Reference Date: $todayStr

TASK INSTRUCTIONS:
1. PRODUCT NAME:
   - Extract a clean, concise name including Brand + Product Variant + Pack Size (e.g., "Amul Taaza Toned Milk 500ml", "Crocin 650mg Paracetamol", "Balaji Wafers Masala 50g", "Tata Sampann Toor Dal 1kg", "MDH Deggi Mirch 100g", "Aashirvaad Shudh Chakki Atta 5kg").
   - Support Indian, regional FMCG brands and Hinglish terms (e.g., Atta, Besan, Poha, Paneer, Ghee, Namkeen, Bhujia, Papad, Masala, Dal, Chai).
   - If the item is unbranded, loose fresh produce, or bakery (e.g. fresh fruits, vegetables, loose grains, bakery bread), identify it visually (e.g., "Fresh Red Apples", "Whole Wheat Bread", "Farm Eggs 6-Pack", "Loose Almonds / Badam").
   - NEVER return generic "Scanned Item" or "Product" if any text, label, or food item is discernible in the photos.

2. CATEGORY: Classify into EXACTLY one of: "Groceries", "Medicine", "Skincare", "Dairy & Eggs", "Household", "Documents", "Beverages", "Pantry", "Custom".

3. EXPIRY DATE DETECTION:
   - Carefully inspect inkjet dot-matrix printing, crimp seals, pouch folds, bottle caps, carton tops, bottoms of cans, and blister foil margins.
   - Look for printed keywords: "EXP", "USE BY", "BEST BEFORE", "B.B.", "E:", "EXP.DT.", "USE BEFORE", "EXPIRY".
   - Standard Indian packaging format is DD/MM/YYYY or MM/YYYY. Normalize clearly printed dates to "YYYY-MM-DD".
   - For Month-Only dates (e.g., "08/2027", "AUG 2027"), return the LAST DAY of that month ("2027-08-31").
   - Dot-Matrix / Relative Shelf-Life Calculation: Many Indian packets state "Best before X months from packaging/manufacture" alongside a "PKD" or "MFD" date (e.g. "PKD 02/2026", "Best before 6 months from manufacture"). Calculate the exact expiry date (e.g. 6 months after Feb 2026 = "2026-08-31") and return it in "expiry_date_printed".
   - "expiry_date_estimated": Use ONLY for loose food, fresh produce, fruits, bakery with NO printed date. Estimate safe shelf-life days from today ($todayStr) and explain in notes.
   - CRITICAL SAFETY RULE: For category "Medicine", NEVER estimate an expiry date. If no printed date is visible on the blister/bottle, return null for both expiry_date_printed and expiry_date_estimated.
   - If printed expiry date is not visible (e.g. user only photographed the front of the pack) or unreadable, return null for expiry_date_printed. DO NOT GUESS for packaged goods or medicines. (The app will still auto-fill the product name and category).

4. METADATA:
   - Extract "batch_number" (e.g. "B.No 9402A", "LOT 23") if visible.
   - Extract "mfg_date" (YYYY-MM-DD or MM/YYYY) if visible.
   - Extract "pao_months" (Period After Opening, e.g., 6, 12, 24 from the open jar symbol) for skincare/cosmetics.
   - Extract "quantity" (number) and "unit" (e.g., "ml", "g", "tablets", "kg", "pcs").
   - Suggest "location" (e.g., "Fridge", "Medicine Box", "Pantry", "Bathroom", "Kitchen Counter").

5. CONFIDENCE: Score between 0.0 and 1.0 (>=0.8 if printed date or brand is razor sharp, 0.5-0.79 if relative or partially faint, <0.5 if low confidence).

Return strictly a valid JSON object matching the requested schema.
''';

    final String? effectiveApiKey = (apiKey != null && apiKey.trim().isNotEmpty)
        ? apiKey.trim()
        : (defaultApiKey != null && defaultApiKey!.trim().isNotEmpty ? defaultApiKey!.trim() : null);

    AiTransport effectiveTransport = transport;
    if (effectiveApiKey != null && effectiveApiKey.isNotEmpty) {
      effectiveTransport = DirectGeminiTransport(apiKey: effectiveApiKey);
    }

    Map<String, dynamic>? rawResponse;
    try {
      rawResponse = await effectiveTransport.sendVisionRequest(
        images: validImages,
        prompt: promptText,
      );
    } on RateLimitException catch (e) {
      return ScanResult.failed(
        message: e.message,
        errorCode: 'RATE_LIMITED',
        remainingScans: e.remaining,
      );
    } on AiUnavailableException catch (e) {
      return ScanResult.failed(
        message: e.message,
        errorCode: 'AI_UNAVAILABLE',
      );
    } on InvalidInputException catch (e) {
      return ScanResult.failed(
        message: e.message,
        errorCode: 'INVALID_INPUT',
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('timeout') || errStr.contains('timed out')) {
        return ScanResult.failed(
          message: effectiveApiKey != null
              ? 'Gemini API connection timed out. Please check your internet.'
              : 'Proxy server response nahi de raha hai (Render free-tier cold start). Direct 1-second scanning ke liye Settings mein free Gemini API key add karein.',
          errorCode: 'TIMEOUT',
        );
      }
      return ScanResult.failed(
        message: 'Could not connect to AI scanning service ($e). Please check your internet or add Gemini API key in Settings.',
        errorCode: 'NETWORK',
      );
    }


    final int? remaining = rawResponse['remaining'] as int?;
    final parsedResult = _parseGeminiResponse(rawResponse).copyWith(remainingScans: remaining);
    _resultCache[cacheKey] = parsedResult;
    return parsedResult;
  }

  ScanResult _parseGeminiResponse(Map<String, dynamic> data) {
    String? rawJsonString;

    final candidatePart = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (candidatePart != null && candidatePart.toString().trim().isNotEmpty) {
      rawJsonString = candidatePart.toString().trim();
    } else if (data.containsKey('product_name') || data.containsKey('category')) {
      rawJsonString = jsonEncode(data);
    }

    if (rawJsonString == null) {
      return ScanResult.failed(
        message: 'No analysis returned by Gemini Vision. Please retake the photo with good lighting.',
      );
    }

    String cleaned = rawJsonString;
    if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
    if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
    if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
    cleaned = cleaned.trim();

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return ScanResult.failed(
        message: 'Could not parse AI response. Please ensure packaging text is visible.',
      );
    }

    // Category normalization
    final rawCategory = parsed['category']?.toString();
    final categoryName = CategoryNormalizer.normalizeToName(rawCategory);
    final categoryId = CategoryNormalizer.toCategoryId(categoryName);

    // Safety rule for Medicine: NEVER allow estimated expiry
    final rawPrintedDate = parsed['expiry_date_printed']?.toString();
    String? rawEstimatedDate = parsed['expiry_date_estimated']?.toString();
    if (categoryId == 'medicine') {
      rawEstimatedDate = null;
    }

    String? targetDateRaw = rawPrintedDate;
    bool isEstimated = false;

    if (targetDateRaw == null || targetDateRaw.trim().isEmpty) {
      if (rawEstimatedDate != null && rawEstimatedDate.trim().isNotEmpty) {
        targetDateRaw = rawEstimatedDate;
        isEstimated = true;
      }
    }

    final normalizedDate = parseDateToIso(targetDateRaw);
    final hasDate = normalizedDate != null;

    // Check if already expired
    bool isExpired = false;
    if (hasDate) {
      final parsedDt = DateTime.tryParse(normalizedDate);
      if (parsedDt != null) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        isExpired = parsedDt.isBefore(todayStart);
      }
    }

    double? qty;
    if (parsed['quantity'] != null) {
      qty = double.tryParse(parsed['quantity'].toString());
    }

    double confidence = 0.85;
    if (parsed['confidence'] != null) {
      confidence = double.tryParse(parsed['confidence'].toString()) ?? 0.85;
    }

    int? pao;
    if (parsed['pao_months'] != null) {
      pao = int.tryParse(parsed['pao_months'].toString());
    }

    return ScanResult(
      productName: parsed['product_name']?.toString() ?? 'Scanned Item',
      category: categoryName,
      categoryId: categoryId,
      expiryDate: normalizedDate,
      isEstimated: isEstimated,
      printedDate: rawPrintedDate,
      batchNumber: parsed['batch_number']?.toString(),
      mfgDate: parsed['mfg_date']?.toString(),
      paoMonths: pao,
      quantity: qty,
      unit: parsed['unit']?.toString(),
      location: parsed['location']?.toString(),
      notes: parsed['notes']?.toString(),
      confidence: confidence,
      rawText: candidatePart.toString(),
      hasDetectedDate: hasDate,
      isAlreadyExpired: isExpired,
      isSuccess: true,
    );
  }

  /// Hashes image file bytes using SHA-256 for instant cache lookups.
  static Future<String> _computeImagesHash(List<File> images) async {
    final List<int> allBytes = [];
    for (final img in images) {
      if (await img.exists()) {
        allBytes.addAll(await img.readAsBytes());
      }
    }
    return sha256.convert(allBytes).toString();
  }

  /// Hardened date parser handling DD/MM/YYYY, DD-MM-YY, DD.MM.YYYY, DD MMM YYYY,
  /// MMM YYYY, MM/YYYY, OCR confusions (O->0, I/l->1), and reject dates < 2000 or > today+15y.
  static String? parseDateToIso(dynamic raw) {
    if (raw == null) return null;
    String text = raw.toString().trim();
    if (text.isEmpty) return null;

    // Clean common OCR character confusions in numeric date fragments (without affecting words like Oct):
    text = text.replaceAllMapped(
      RegExp(r'(?<=\d)[oO](?=[\/\-\.]|\d|$)|(?<=[\/\-\.])[oO](?=[\/\-\.]|\d|$)'),
      (m) => '0',
    );
    text = text.replaceAllMapped(
      RegExp(r'(?<=\d)[Il](?=[\/\-\.]|\d|$)|(?<=[\/\-\.])[Il](?=[\/\-\.]|\d|$)'),
      (m) => '1',
    );

    final now = DateTime.now();
    final maxValidYear = now.year + 15;

    // 1. Strict ISO: YYYY-MM-DD
    final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      if (_isValidDate(y, m, d, maxValidYear)) {
        return _formatIso(y, m, d);
      }
      return null;
    }

    // 2. YYYY/MM/DD or YYYY.MM.DD
    final ymdMatch = RegExp(r'^(\d{4})[\/\.](\d{1,2})[\/\.](\d{1,2})$').firstMatch(text);
    if (ymdMatch != null) {
      final y = int.parse(ymdMatch.group(1)!);
      final m = int.parse(ymdMatch.group(2)!);
      final d = int.parse(ymdMatch.group(3)!);
      if (_isValidDate(y, m, d, maxValidYear)) {
        return _formatIso(y, m, d);
      }
      return null;
    }

    // 3. DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY or 2-digit year (DD/MM/YY)
    final dmyMatch = RegExp(r'^(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})$').firstMatch(text);
    if (dmyMatch != null) {
      int p1 = int.parse(dmyMatch.group(1)!);
      int p2 = int.parse(dmyMatch.group(2)!);
      int y = int.parse(dmyMatch.group(3)!);

      // Expand 2-digit year: 26 -> 2026, 99 -> 1999 (rejected by range check)
      if (y < 100) {
        y += 2000;
      }

      int day = p1;
      int month = p2;

      // Handle MM/DD inversion if first number is month and second is > 12
      if (p1 <= 12 && p2 > 12) {
        month = p1;
        day = p2;
      }

      if (_isValidDate(y, month, day, maxValidYear)) {
        return _formatIso(y, month, day);
      }
      return null;
    }

    // 4. Month-Year only: MM/YYYY, MM-YYYY, MM.YYYY or MM/YY
    final myMatch = RegExp(r'^(\d{1,2})[\/\-\.](\d{2,4})$').firstMatch(text);
    if (myMatch != null) {
      final m = int.parse(myMatch.group(1)!);
      int y = int.parse(myMatch.group(2)!);
      if (y < 100) y += 2000;

      if (m >= 1 && m <= 12 && y >= 2000 && y <= maxValidYear) {
        final lastDay = _getLastDayOfMonth(y, m);
        return _formatIso(y, m, lastDay);
      }
      return null;
    }

    // 5. Month name variations: "15 Oct 2026", "Oct 15 2026", "AUG 2027", "28-OCT-26"
    final months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
    };
    final monthRegex = RegExp(r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\b', caseSensitive: false);
    final monthMatch = monthRegex.firstMatch(text);

    if (monthMatch != null) {
      final monthToken = monthMatch.group(1)!.toLowerCase();
      final monthNum = months[monthToken] ?? 1;

      // Extract year (prioritize 4-digit 20XX over 2-digit to avoid matching day numbers)
      final fourDigitYear = RegExp(r'\b(20\d{2})\b').firstMatch(text);
      final twoDigitYear = RegExp(r'(?<=\s|\-)([2-3]\d)\b').firstMatch(text);
      final yearMatch = fourDigitYear ?? twoDigitYear;

      if (yearMatch != null) {
        int y = int.parse(yearMatch.group(1)!);
        if (y < 100) y += 2000;

        // Check if day is present
        final stripped = text.replaceAll(monthMatch.group(0)!, '').replaceAll(yearMatch.group(0)!, '');
        final dayMatch = RegExp(r'\b([0-3]?[0-9])\b').firstMatch(stripped);

        int day;
        if (dayMatch != null && dayMatch.group(1)!.isNotEmpty) {
          day = int.parse(dayMatch.group(1)!);
          if (day < 1 || day > 31) day = _getLastDayOfMonth(y, monthNum);
        } else {
          // Month-only date (e.g. "AUG 2027") -> Last day of month
          day = _getLastDayOfMonth(y, monthNum);
        }

        if (_isValidDate(y, monthNum, day, maxValidYear)) {
          return _formatIso(y, monthNum, day);
        }
      }
    }

    // 6. Generic DateTime.tryParse fallback
    final dt = DateTime.tryParse(text);
    if (dt != null && _isValidDate(dt.year, dt.month, dt.day, maxValidYear)) {
      return _formatIso(dt.year, dt.month, dt.day);
    }

    return null;
  }

  static bool _isValidDate(int year, int month, int day, int maxYear) {
    if (year < 2000 || year > maxYear) return false;
    if (month < 1 || month > 12) return false;
    final lastDay = _getLastDayOfMonth(year, month);
    return day >= 1 && day <= lastDay;
  }

  static int _getLastDayOfMonth(int year, int month) {
    // DateTime(year, month + 1, 0) gives the last day of month
    return DateTime(year, month + 1, 0).day;
  }

  static String _formatIso(int year, int month, int day) {
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}

/// Offline Mock Implementation.
/// SAFETY RULE: NEVER returns fake products or fake dates!
/// Returns a graceful offline status requiring user confirmation.
class MockExpiryScanService implements ExpiryScanService {
  @override
  Future<ScanResult> scanImage(File image, {String? apiKey}) {
    return scanImages([image], apiKey: apiKey);
  }

  @override
  Future<ScanResult> scanImages(List<File> images, {String? apiKey}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Never returns fake data in production. Safe offline fallback.
    return const ScanResult(
      productName: null,
      category: 'Custom',
      categoryId: 'custom',
      expiryDate: null,
      isEstimated: false,
      notes: 'Offline Mode: Please enter expiry date and product name manually.',
      confidence: 0.0,
      hasDetectedDate: false,
      isSuccess: false,
      errorMessage: 'Offline Mode: Scanner requires an internet connection.',
    );
  }
}
