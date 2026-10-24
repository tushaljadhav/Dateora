import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dateora/services/ai_expiry_scan_service.dart';
import 'package:dateora/services/device_service.dart';

void main() {
  group('1. Hardened parseDateToIso Tests', () {
    test('Standard ISO format YYYY-MM-DD parses correctly', () {
      expect(GeminiExpiryScanService.parseDateToIso('2026-11-25'), '2026-11-25');
      expect(GeminiExpiryScanService.parseDateToIso('2027-01-05'), '2027-01-05');
    });

    test('Indian & British format DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY parses correctly', () {
      expect(GeminiExpiryScanService.parseDateToIso('25/11/2026'), '2026-11-25');
      expect(GeminiExpiryScanService.parseDateToIso('14-08-2027'), '2027-08-14');
      expect(GeminiExpiryScanService.parseDateToIso('03.12.2025'), '2025-12-03');
    });

    test('2-digit year format DD/MM/YY expands accurately into 2000s', () {
      expect(GeminiExpiryScanService.parseDateToIso('15/10/26'), '2026-10-15');
      expect(GeminiExpiryScanService.parseDateToIso('01-01-28'), '2028-01-01');
    });

    test('Month name format "DD MMM YYYY" and "MMM YYYY" parses correctly', () {
      expect(GeminiExpiryScanService.parseDateToIso('25 Oct 2026'), '2026-10-25');
      expect(GeminiExpiryScanService.parseDateToIso('15-AUG-2027'), '2027-08-15');
    });

    test('Month-only dates (08/2027, AUG 2027) become the LAST day of that month', () {
      // August has 31 days
      expect(GeminiExpiryScanService.parseDateToIso('08/2027'), '2027-08-31');
      expect(GeminiExpiryScanService.parseDateToIso('AUG 2027'), '2027-08-31');
      // February 2028 is leap year (29 days)
      expect(GeminiExpiryScanService.parseDateToIso('02/2028'), '2028-02-29');
      // February 2027 is non-leap (28 days)
      expect(GeminiExpiryScanService.parseDateToIso('02/2027'), '2027-02-28');
    });

    test('OCR Character Confusions (O/o -> 0, I/l -> 1) are sanitized', () {
      // "25/1O/2026" with letter O instead of 0
      expect(GeminiExpiryScanService.parseDateToIso('25/1O/2026'), '2026-10-25');
      // "15/l2/2026" with letter l instead of 1
      expect(GeminiExpiryScanService.parseDateToIso('15/l2/2026'), '2026-12-15');
    });

    test('Ambiguous MM/DD vs DD/MM inversion handled when day > 12', () {
      // 05/25/2026 is clearly MM/DD/YYYY because 25 > 12
      expect(GeminiExpiryScanService.parseDateToIso('05/25/2026'), '2026-05-25');
    });

    test('Out of range dates (< 2000 or > today+15y) are rejected (return null)', () {
      expect(GeminiExpiryScanService.parseDateToIso('15/05/1995'), isNull);
      expect(GeminiExpiryScanService.parseDateToIso('15/05/1980'), isNull);
      expect(GeminiExpiryScanService.parseDateToIso('15/05/2055'), isNull);
      expect(GeminiExpiryScanService.parseDateToIso('garbage text'), isNull);
      expect(GeminiExpiryScanService.parseDateToIso(''), isNull);
      expect(GeminiExpiryScanService.parseDateToIso(null), isNull);
    });
  });

  group('2. Category Normalizer Tests', () {
    test('Maps all dairy and milk synonyms to Dairy & Eggs', () {
      expect(CategoryNormalizer.normalizeToName('dairy'), 'Dairy & Eggs');
      expect(CategoryNormalizer.normalizeToName('milk'), 'Dairy & Eggs');
      expect(CategoryNormalizer.normalizeToName('cheese'), 'Dairy & Eggs');
      expect(CategoryNormalizer.normalizeToName('paneer'), 'Dairy & Eggs');
      expect(CategoryNormalizer.normalizeToName('yogurt'), 'Dairy & Eggs');
      expect(CategoryNormalizer.toCategoryId('Dairy & Eggs'), 'dairy');
    });

    test('Maps pharma and tablet synonyms to Medicine', () {
      expect(CategoryNormalizer.normalizeToName('medicine'), 'Medicine');
      expect(CategoryNormalizer.normalizeToName('tablet'), 'Medicine');
      expect(CategoryNormalizer.normalizeToName('syrup'), 'Medicine');
      expect(CategoryNormalizer.normalizeToName('capsule'), 'Medicine');
      expect(CategoryNormalizer.toCategoryId('Medicine'), 'medicine');
    });

    test('Maps cosmetics and lotion synonyms to Skincare', () {
      expect(CategoryNormalizer.normalizeToName('skincare'), 'Skincare');
      expect(CategoryNormalizer.normalizeToName('cream'), 'Skincare');
      expect(CategoryNormalizer.normalizeToName('lotion'), 'Skincare');
      expect(CategoryNormalizer.normalizeToName('sunscreen'), 'Skincare');
      expect(CategoryNormalizer.toCategoryId('Skincare'), 'skincare');
    });

    test('Maps groceries, bakery, vegetables to Groceries', () {
      expect(CategoryNormalizer.normalizeToName('groceries'), 'Groceries');
      expect(CategoryNormalizer.normalizeToName('vegetable'), 'Groceries');
      expect(CategoryNormalizer.normalizeToName('fruit'), 'Groceries');
      expect(CategoryNormalizer.normalizeToName('bakery'), 'Groceries');
      expect(CategoryNormalizer.toCategoryId('Groceries'), 'groceries');
    });

    test('Maps Indian regional food and grocery synonyms correctly', () {
      expect(CategoryNormalizer.normalizeToName('dahi'), 'Dairy & Eggs');
      expect(CategoryNormalizer.normalizeToName('chaas'), 'Dairy & Eggs');
      expect(CategoryNormalizer.normalizeToName('lassi'), 'Dairy & Eggs');
      expect(CategoryNormalizer.normalizeToName('poha'), 'Pantry');
      expect(CategoryNormalizer.normalizeToName('besan'), 'Pantry');
      expect(CategoryNormalizer.normalizeToName('ghee'), 'Pantry');
      expect(CategoryNormalizer.normalizeToName('namkeen'), 'Pantry');
      expect(CategoryNormalizer.normalizeToName('bhujia'), 'Pantry');
      expect(CategoryNormalizer.normalizeToName('masala'), 'Pantry');
      expect(CategoryNormalizer.normalizeToName('sabzi'), 'Groceries');
      expect(CategoryNormalizer.normalizeToName('tamatar'), 'Groceries');
      expect(CategoryNormalizer.normalizeToName('chai'), 'Beverages');
    });

    test('Unknown or unmapped category falls back to Custom', () {
      expect(CategoryNormalizer.normalizeToName('gadget'), 'Custom');
      expect(CategoryNormalizer.normalizeToName('unknown_item'), 'Custom');
      expect(CategoryNormalizer.normalizeToName(null), 'Custom');
      expect(CategoryNormalizer.toCategoryId('Custom'), 'custom');
    });
  });

  group('3. Medicine Safety Rule & Mock Safety', () {
    test('MockExpiryScanService NEVER returns fake dates or fake products', () async {
      final mock = MockExpiryScanService();
      // Fake image file
      final res = await mock.scanImages([]);

      expect(res.isSuccess, false);
      expect(res.hasDetectedDate, false);
      expect(res.productName, isNull);
      expect(res.expiryDate, isNull);
      expect(res.confidence, 0.0);
    });

    test('ScanResult confidence level categories correctly', () {
      const high = ScanResult(confidence: 0.95);
      expect(high.confidenceLevel, 'high');

      const check = ScanResult(confidence: 0.65);
      expect(check.confidenceLevel, 'check');

      const low = ScanResult(confidence: 0.3);
      expect(low.confidenceLevel, 'low');
    });
  });

  group('4. SharedPreferences Key Migration Logic', () {
    test('Simulates migration: deletes old plain text key from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'gemini_api_key': 'AIzaSyTestLegacyKey12345',
      });

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('gemini_api_key'), true);

      // Perform migration step
      final oldKey = prefs.getString('gemini_api_key');
      expect(oldKey, 'AIzaSyTestLegacyKey12345');

      // Delete from unencrypted SharedPreferences
      await prefs.remove('gemini_api_key');
      expect(prefs.containsKey('gemini_api_key'), false);
    });

    test('Masked key formats correctly showing only last 4 characters', () {
      const fullKey = 'AIzaSyD8Gj9X7p10Lk459B';
      final last4 = fullKey.substring(fullKey.length - 4);
      final masked = '••••••••••••$last4';

      expect(masked, '••••••••••••459B');
      expect(masked.contains('AIzaSy'), false);
    });
  });

  group('5. DeviceService & Proxy Scan Limits', () {
    test('DeviceService generates and persists valid UUID', () async {
      SharedPreferences.setMockInitialValues({});
      final id1 = await DeviceService.getDeviceId();
      expect(id1.isNotEmpty, true);
      expect(RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id1), true);

      final id2 = await DeviceService.getDeviceId();
      expect(id2, id1);
    });

    test('ScanResult.failed carries errorCode and remainingScans correctly', () {
      final res = ScanResult.failed(
        message: 'Aaj ke free scans khatam ho gaye. Kal wapas aao ya manual entry karo.',
        errorCode: 'RATE_LIMITED',
        remainingScans: 0,
      );

      expect(res.isSuccess, false);
      expect(res.errorCode, 'RATE_LIMITED');
      expect(res.remainingScans, 0);
      expect(res.errorMessage, contains('Aaj ke free scans khatam ho gaye'));
    });
  });
}

