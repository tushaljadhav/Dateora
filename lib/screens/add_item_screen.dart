import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/items_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_expiry_scan_service.dart';
import '../services/analytics_service.dart';
import '../services/open_food_facts_service.dart';
import '../services/permission_service.dart';
import '../services/photo_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/app_date_picker_dialog.dart';
import '../widgets/photo_picker_sheet.dart';
import '../widgets/primary_button.dart';
import 'barcode_scanner_screen.dart';

class AddItemScreen extends StatefulWidget {
  final String? initialPhotoPath;
  final bool autoTriggerAiScan;

  const AddItemScreen({
    super.key,
    this.initialPhotoPath,
    this.autoTriggerAiScan = false,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  // Required fields (<30s fast path)
  final _nameController = TextEditingController();
  String _selectedCategory = 'groceries';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));

  // Optional fields
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String _addedMethod = 'manual'; // 'manual', 'ai_scan', 'barcode'

  // Multi-photo support: Front Photo + Date Side Photo
  String? _photoPath;
  String? _secondaryPhotoPath;

  final Set<int> _reminderOffsets = {3};
  bool _showMoreDetails = false;
  bool _isSaving = false;
  DateTime? _lastSaveTimestamp;
  bool _isScanningAi = false;
  String _scanLoadingText = 'Analyzing packaging with AI...';
  Timer? _scanTimer;
  int? _remainingScans;

  // AI Review State
  ScanResult? _lastScanResult;
  final Set<String> _aiFilledFields = {};
  Map<String, dynamic>? _previousFormSnapshot;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.initialPhotoPath;

    // Warm up the Render backend container early (fire-and-forget)
    GeminiExpiryScanService.warmupServer();

    _setupFieldChangeListeners();

    if (widget.autoTriggerAiScan && widget.initialPhotoPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scanExpiryWithAi();
      });
    }
  }

  void _setupFieldChangeListeners() {
    _nameController.addListener(() {
      if (_aiFilledFields.contains('name')) {
        setState(() => _aiFilledFields.remove('name'));
      }
    });
    _quantityController.addListener(() {
      if (_aiFilledFields.contains('quantity')) {
        setState(() => _aiFilledFields.remove('quantity'));
      }
    });
    _unitController.addListener(() {
      if (_aiFilledFields.contains('unit')) {
        setState(() => _aiFilledFields.remove('unit'));
      }
    });
    _locationController.addListener(() {
      if (_aiFilledFields.contains('location')) {
        setState(() => _aiFilledFields.remove('location'));
      }
    });
    _notesController.addListener(() {
      if (_aiFilledFields.contains('notes')) {
        setState(() => _aiFilledFields.remove('notes'));
      }
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _takeFormSnapshot() {
    _previousFormSnapshot = {
      'name': _nameController.text,
      'category': _selectedCategory,
      'expiryDate': _expiryDate,
      'quantity': _quantityController.text,
      'unit': _unitController.text,
      'location': _locationController.text,
      'notes': _notesController.text,
    };
  }

  void _undoAiAutoFill() {
    if (_previousFormSnapshot == null) return;
    setState(() {
      _nameController.text = _previousFormSnapshot!['name'] ?? '';
      _selectedCategory = _previousFormSnapshot!['category'] ?? 'groceries';
      _expiryDate = _previousFormSnapshot!['expiryDate'] ?? DateTime.now().add(const Duration(days: 7));
      _quantityController.text = _previousFormSnapshot!['quantity'] ?? '';
      _unitController.text = _previousFormSnapshot!['unit'] ?? '';
      _locationController.text = _previousFormSnapshot!['location'] ?? '';
      _notesController.text = _previousFormSnapshot!['notes'] ?? '';
      _aiFilledFields.clear();
      _lastScanResult = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI auto-fill reverted.')),
    );
  }

  Future<void> _handleNewPhoto(String path, {bool isSecondary = false}) async {
    if (isSecondary) {
      setState(() => _secondaryPhotoPath = path);
    } else {
      setState(() => _photoPath = path);
    }
    await _scanExpiryWithAi();
  }

  Future<void> _openPhotoSheet({bool isSecondary = false}) async {
    final current = isSecondary ? _secondaryPhotoPath : _photoPath;
    final picked = await PhotoPickerSheet.show(
      context,
      currentPhotoPath: current,
    );

    if (picked == '__remove__') {
      if (isSecondary) {
        if (_secondaryPhotoPath != null) {
          await PhotoService.deletePhotoFile(_secondaryPhotoPath);
          setState(() => _secondaryPhotoPath = null);
        }
      } else {
        await _removePhoto();
      }
    } else if (picked != null) {
      await _handleNewPhoto(picked, isSecondary: isSecondary);
    }
  }

  Future<void> _removePhoto() async {
    if (_photoPath != null) {
      await PhotoService.deletePhotoFile(_photoPath);
      setState(() => _photoPath = null);
    }
  }

  Future<bool> _ensureAiConsent(SettingsProvider settings) async {
    if (settings.aiConsentGiven) return true;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primaryStrong, size: 24),
            SizedBox(width: 8),
            Text('AI Vision Privacy'),
          ],
        ),
        content: const Text(
          'Dateora analyzes product packaging photos using Google Gemini AI.\n\n'
          '• Photos are sent securely to Google AI to read expiry & label data.\n'
          '• No personally identifiable data or GPS location is transmitted.\n'
          '• All item records remain stored safely on your device.\n\n'
          'Do you agree to enable AI analysis?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Agree & Continue'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      await settings.setAiConsentGiven(true);
      return true;
    }
    return false;
  }

  /// Runs AI Expiry Date detection on photographed packaging (supports 1 or 2 images).
  Future<void> _scanExpiryWithAi() async {
    if (_photoPath == null && _secondaryPhotoPath == null) {
      await _openPhotoSheet(isSecondary: false);
      if (!mounted || _photoPath == null) return;
    }

    if (!mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (!settings.aiScanEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Scanner is disabled in Settings.')),
        );
      }
      return;
    }

    // 1. First-use consent verification
    final consentGranted = await _ensureAiConsent(settings);
    if (!consentGranted) return;

    _scanTimer?.cancel();
    setState(() {
      _isScanningAi = true;
      _scanLoadingText = 'Analyzing packaging with AI...';
    });

    // Friendly Render cold-start notification after 8 seconds
    _scanTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isScanningAi) {
        setState(() {
          _scanLoadingText = 'Server jaag raha hai, 30-40 second lag sakte hain...';
        });
      }
    });

    try {
      final List<File> imageFiles = [];
      if (_photoPath != null && File(_photoPath!).existsSync()) {
        imageFiles.add(File(_photoPath!));
      }
      if (_secondaryPhotoPath != null && File(_secondaryPhotoPath!).existsSync()) {
        imageFiles.add(File(_secondaryPhotoPath!));
      }

      final String? userKey = settings.geminiApiKey.isNotEmpty ? settings.geminiApiKey : null;
      final ExpiryScanService scanService = GeminiExpiryScanService(defaultApiKey: userKey);
      final result = await scanService.scanImages(imageFiles, apiKey: userKey);

      if (!mounted) return;

      if (result.remainingScans != null) {
        setState(() => _remainingScans = result.remainingScans);
      }

      // Check for daily scan limit reached
      if (result.errorCode == 'RATE_LIMITED') {
        setState(() => _remainingScans = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 5),
            backgroundColor: AppColors.statusDanger,
            content: Text('Aaj ke free scans khatam ho gaye. Kal wapas aao ya manual entry karo.'),
          ),
        );
        return;
      }

      // Check for cold-start timeout or network connectivity issue
      if (result.errorCode == 'TIMEOUT' || result.errorCode == 'NETWORK') {
        _showRetryOrManualDialog();
        return;
      }

      final hasValidDate = result.hasDetectedDate &&
          result.expiryDate != null &&
          DateTime.tryParse(result.expiryDate!) != null;
      final hasValidProduct = result.productName != null &&
          result.productName!.trim().isNotEmpty &&
          result.productName != 'Scanned Item' &&
          result.productName != 'Product';

      AnalyticsService.instance.logAiScanUsed(success: result.isSuccess);

      if (result.isSuccess && (hasValidDate || hasValidProduct)) {
        _addedMethod = 'ai_scan';
        _takeFormSnapshot();
        await settings.incrementDailyScanCount();
        if (!mounted) return;

        setState(() {
          _lastScanResult = result;

          if (hasValidDate) {
            _expiryDate = DateTime.parse(result.expiryDate!);
            _aiFilledFields.add('date');
          }

          if (hasValidProduct) {
            _nameController.text = result.productName!;
            _aiFilledFields.add('name');
          }

          if (result.categoryId.isNotEmpty && result.categoryId != 'custom') {
            _selectedCategory = result.categoryId;
            _aiFilledFields.add('category');
          }

          if (result.quantity != null) {
            _quantityController.text = result.quantity!.toString();
            _aiFilledFields.add('quantity');
          }

          if (result.unit != null && result.unit!.isNotEmpty) {
            _unitController.text = result.unit!;
            _aiFilledFields.add('unit');
          }

          if (result.location != null && result.location!.isNotEmpty) {
            _locationController.text = result.location!;
            _aiFilledFields.add('location');
          }

          if (result.notes != null && result.notes!.isNotEmpty) {
            _notesController.text = result.notes!;
            _aiFilledFields.add('notes');
          }
        });

        if (hasValidDate) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primaryStrong,
              content: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI Auto-filled: ${result.productName ?? "Item"} • ${DateFormat("dd MMM yyyy").format(_expiryDate)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Graceful partial auto-fill notice when only product is detected
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 5),
              backgroundColor: const Color(0xFFD97706),
              content: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI detected: "${result.productName}"!\nExpiry date photo mein clear nahi mili — please date select karein ya Slot 2 mein date photo lein.',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        // Fallback / unreadable notice
        final msg = result.errorMessage ?? "Photo se details read nahi ho paayi. Please achhi roshni mein photo lein ya manually enter karein.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } on SocketException {
      if (mounted) _showRetryOrManualDialog();
    } catch (e) {
      if (mounted) {
        final errText = e.toString();
        if (errText.contains('SocketException') || errText.contains('Network') || errText.contains('offline')) {
          _showRetryOrManualDialog();
        } else if (e is AiUnavailableException || errText.contains('not configured on the server')) {
          _showServerKeyOrLocalKeyDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.statusDanger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: Text('AI Scan: $e'),
            ),
          );
        }
      }
    } finally {
      _scanTimer?.cancel();
      if (mounted) setState(() => _isScanningAi = false);
    }
  }

  void _showServerKeyOrLocalKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: AppColors.primaryStrong),
            SizedBox(width: 8),
            Text('API Key Needed'),
          ],
        ),
        content: const Text(
          'Render cloud backend par GEMINI_API_KEY set nahi hai.\n\nDirect Google Gemini se instant (1-2s) auto-fill karne ke liye apni free API key yahan daalein, ya Render dashboard mein "GEMINI_API_KEY" environment variable add karein.',
          style: TextStyle(fontSize: 13, height: 1.4),
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
              Navigator.pop(ctx);
              _showApiKeyBottomSheet();
            },
            child: const Text('Add API Key'),
          ),
        ],
      ),
    );
  }



  void _showApiKeyBottomSheet() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final keyController = TextEditingController(text: settings.geminiApiKey);
    bool isTesting = false;
    String? statusMessage;
    bool isSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
          final bottomInset = MediaQuery.of(modalCtx).viewInsets.bottom;

          return Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryStrong.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.key_rounded, color: AppColors.primaryStrong, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Gemini API Key',
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Direct fast scan (1-2s) via Google AI Studio',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Cloud server sleep ho jane par AI slow hota hai. Google AI Studio se free API key lekar yahan save karein — direct scan 1-2 second mein ho jayega:',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(
                    hintText: 'AIzaSy...',
                    labelText: 'Gemini API Key',
                    prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: keyController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setModalState(() => keyController.clear()),
                          )
                        : null,
                  ),
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        size: 16,
                        color: isSuccess ? AppColors.statusSuccess : AppColors.statusDanger,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSuccess ? AppColors.statusSuccess : AppColors.statusDanger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isTesting
                            ? null
                            : () async {
                                final key = keyController.text.trim();
                                if (key.isEmpty) {
                                  setModalState(() {
                                    statusMessage = 'Pehle API key enter karein.';
                                    isSuccess = false;
                                  });
                                  return;
                                }
                                setModalState(() {
                                  isTesting = true;
                                  statusMessage = 'Testing connection with Google...';
                                  isSuccess = false;
                                });
                                final res = await GeminiExpiryScanService.testApiKey(key);
                                setModalState(() {
                                  isTesting = false;
                                  isSuccess = res['success'] == true;
                                  statusMessage = res['message']?.toString();
                                });
                              },
                        child: isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Test Key'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryStrong,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final key = keyController.text.trim();
                          await settings.setGeminiApiKey(key);
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primaryStrong,
                              content: Text(key.isNotEmpty
                                  ? 'Gemini API key saved! Scanning now...'
                                  : 'API key cleared. Using proxy.'),
                            ),
                          );
                          if (key.isNotEmpty && (_photoPath != null || _secondaryPhotoPath != null)) {
                            _scanExpiryWithAi();
                          }
                        },
                        child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRetryOrManualDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.statusWarning),
            SizedBox(width: 8),
            Text('Scan Timed Out'),
          ],
        ),
        content: const Text(
          'Render cloud proxy slow hai ya cold start mein hai. Direct Google Gemini connect karne ke liye apni free API key daal sakte hain (instant 1-2s scan), ya Retry karein.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showApiKeyBottomSheet();
            },
            child: const Text('Add API Key'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Manual Entry'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryStrong,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _scanExpiryWithAi();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }


  Future<void> _showBarcodeLookupDialog() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode == null || barcode.isEmpty) return;

    final info = await OpenFoodFactsService.lookupBarcode(barcode);
    AnalyticsService.instance.logBarcodeScanUsed(success: info != null);
    if (!mounted) return;

    if (info != null) {
      _addedMethod = 'barcode';
      setState(() {
        final fullName = info.displayName;
        if (fullName.isNotEmpty) {
          _nameController.text = fullName;
          _aiFilledFields.add('name');
        }
        if (info.category != null && info.category!.isNotEmpty) {
          _selectedCategory = info.category!;
          _aiFilledFields.add('category');
        }
        if (info.quantity != null) {
          _quantityController.text = info.quantity!.toString();
          _aiFilledFields.add('quantity');
        }
        if (info.unit != null && info.unit!.isNotEmpty) {
          _unitController.text = info.unit!;
          _aiFilledFields.add('unit');
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryStrong,
          content: Text('Found "${info.displayName}" from Open Food Facts!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not found in Open Food Facts. Please enter details manually.'),
        ),
      );
    }
  }

  Future<void> _selectCustomDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _expiryDate,
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _aiFilledFields.remove('date');
      });
    }
  }

  void _saveItem() async {
    if (_isSaving) return;

    final now = DateTime.now();
    if (_lastSaveTimestamp != null && now.difference(_lastSaveTimestamp!).inMilliseconds < 1500) {
      return;
    }
    _lastSaveTimestamp = now;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);

      final dateStr = DateFormat('yyyy-MM-dd').format(_expiryDate);
      final double? qty = _quantityController.text.trim().isNotEmpty
          ? double.tryParse(_quantityController.text.trim())
          : null;
      final double? price = _priceController.text.trim().isNotEmpty
          ? double.tryParse(_priceController.text.trim())
          : null;

      await itemsProvider.addItem(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        expiryDate: dateStr,
        price: price,
        quantity: qty,
        unit: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : null,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        photoUri: _photoPath,
        reminderOffsets: _reminderOffsets.toList(),
      );

      AnalyticsService.instance.logItemAdded(
        method: _addedMethod,
        category: _selectedCategory,
      );

      // Contextual notification permission prompt after saving the first item
      if (mounted) {
        await PermissionService.checkAndPromptNotificationPermissionAfterFirstSave(context);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryStrong,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added "${_nameController.text.trim()}" successfully!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusDanger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              'Error adding item: $e',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          'Add New Product',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Barcode Lookup',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _showBarcodeLookupDialog,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.sm,
          ),
          children: [
            // ─── 0. Quick Barcode Auto-Fill (Prominent Top Option) ───
            _buildBarcodeTopCard(isDark),

            const SizedBox(height: AppSpacing.md),

            // ─── 1. Dedicated Two Photos Section (1 Product Image + 1 Dates Image) ───
            _buildTwoPhotosSection(isDark),

            const SizedBox(height: AppSpacing.md),

            // ─── 3. AI Detection Review Pill ───
            if (_lastScanResult != null) ...[
              _buildAiResultPill(isDark),
              const SizedBox(height: AppSpacing.md),
            ],

            // ─── 4. Product Name Input (Clean & Focused) ───
            _buildNameInputCard(isDark),

            const SizedBox(height: AppSpacing.md),

            // ─── 5. Visual Category Grid / Selector ───
            _buildCategorySelector(isDark),

            const SizedBox(height: AppSpacing.md),

            // ─── 6. Expiry Date & Quick Presets ───
            _buildExpiryDateCard(isDark),

            const SizedBox(height: AppSpacing.md),

            // ─── 7. Additional Details (Clean Collapsible Accordion) ───
            _buildMoreDetailsAccordion(isDark),

            const SizedBox(height: AppSpacing.xl),

            // ─── 8. Primary Save Action ───
            PrimaryButton(
              text: 'Save Product',
              icon: Icons.check_circle_rounded,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveItem,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // ─── Component Builders ───

  Widget _buildTwoPhotosSection(bool isDark) {
    final hasAnyPhoto = _photoPath != null || _secondaryPhotoPath != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryStrong.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_a_photo_rounded, size: 16, color: AppColors.primaryStrong),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Photos (2 Slots)',
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      '1 Product front + 1 Expiry date side for AI auto-fill',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Two Slots Row
          Row(
            children: [
              // Slot 1: Product Front Image
              Expanded(
                child: _buildPhotoSlotCard(
                  title: '1. Product Image',
                  subtitle: 'Front & brand name',
                  icon: Icons.inventory_2_outlined,
                  photoPath: _photoPath,
                  isDark: isDark,
                  onTap: () => _openPhotoSheet(isSecondary: false),
                  onRemove: _removePhoto,
                ),
              ),
              const SizedBox(width: 10),
              // Slot 2: Expiry Date Image
              Expanded(
                child: _buildPhotoSlotCard(
                  title: '2. Dates Image',
                  subtitle: 'Back seal / date stamp',
                  icon: Icons.calendar_today_rounded,
                  photoPath: _secondaryPhotoPath,
                  isDark: isDark,
                  onTap: () => _openPhotoSheet(isSecondary: true),
                  onRemove: () async {
                    if (_secondaryPhotoPath != null) {
                      await PhotoService.deletePhotoFile(_secondaryPhotoPath);
                      setState(() => _secondaryPhotoPath = null);
                    }
                  },
                ),
              ),
            ],
          ),

          // Gentle 2-Photo Slot Reminder Tip for local/Indian packaging
          if (_photoPath != null && _secondaryPhotoPath == null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232519) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined, size: 15, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Local packets par expiry date piche crimp ya seal par hoti hai. AI se accurate date padhwane ke liye Slot 2 mein date photo zaroor lagayein.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Daily Scans Remaining Counter badge
          if (_remainingScans != null) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primaryStrong),
                    const SizedBox(width: 4),
                    Text(
                      '$_remainingScans scans left today',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Action Button: Auto-Fill with AI Scan
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryStrong,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              onPressed: _isScanningAi ? null : () => _scanExpiryWithAi(),
              icon: _isScanningAi
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                _isScanningAi
                    ? _scanLoadingText
                    : (hasAnyPhoto ? 'Scan Attached Photos with AI' : 'Take Photos & Auto-Fill with AI'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlotCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? photoPath,
    required bool isDark,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final hasPhoto = photoPath != null && File(photoPath).existsSync();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        height: 135,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : const Color(0xFFF7FAF7),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: hasPhoto
                ? AppColors.primaryStrong.withOpacity(0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: hasPhoto ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(photoPath),
                    fit: BoxFit.cover,
                  ),
                  // Dark bottom gradient overlay with label & change button
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.edit_rounded, color: Colors.white70, size: 12),
                        ],
                      ),
                    ),
                  ),
                  // Top close button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryStrong.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 22, color: AppColors.primaryStrong),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryStrong.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '+ Add Photo',
                        style: TextStyle(
                          color: AppColors.primaryStrong,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAiResultPill(bool isDark) {
    final res = _lastScanResult!;
    final hasDate = res.hasDetectedDate && res.expiryDate != null;

    final pillBg = hasDate
        ? (isDark ? const Color(0xFF14291D) : AppColors.statusSuccessBg)
        : (isDark ? const Color(0xFF2E200B) : const Color(0xFFFEF3C7));
    final pillBorder = hasDate
        ? AppColors.statusSuccess.withOpacity(0.4)
        : const Color(0xFFF59E0B).withOpacity(0.5);
    final iconColor = hasDate ? AppColors.statusSuccess : const Color(0xFFD97706);
    final textColor = hasDate
        ? AppColors.statusSuccess
        : (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E));

    final titleText = hasDate
        ? 'AI Autofilled • ${res.isEstimated ? "Estimated Date" : "Read from Pack"}'
        : 'AI Product Detected • Expiry date needed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: pillBorder),
      ),
      child: Row(
        children: [
          Icon(hasDate ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titleText,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          InkWell(
            onTap: _undoAiAutoFill,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Undo',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.statusDanger,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeTopCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2D24), const Color(0xFF16221B)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.primaryStrong.withOpacity(isDark ? 0.35 : 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStrong.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: _showBarcodeLookupDialog,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryStrong.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primaryStrong,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Barcode Scan',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scan packet barcode for instant name & details',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryStrong,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameInputCard(bool isDark) {
    final isFilled = _aiFilledFields.contains('name');
    final isBarcode = _addedMethod == 'barcode';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Product Name *', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
              if (isFilled) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryStrong.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryStrong.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBarcode ? Icons.qr_code_2_rounded : Icons.auto_awesome_rounded,
                        size: 13,
                        color: AppColors.primaryStrong,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isBarcode ? 'Barcode auto-filled' : 'AI auto-filled',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryStrong,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            minLines: 2,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: isFilled,
              fillColor: isFilled
                  ? (isDark ? const Color(0xFF132A1C) : const Color(0xFFF0FDF4))
                  : null,
              hintText: 'e.g. Amul Fresh Cream 250ml, Crocin 650, Cetaphil Cleanser',
              hintStyle: AppTextStyles.caption.copyWith(fontSize: 13),
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.shopping_bag_outlined, color: AppColors.primaryStrong, size: 20),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primaryStrong),
                  onPressed: _showBarcodeLookupDialog,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: BorderSide(
                  color: isFilled ? AppColors.primaryStrong : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isFilled ? 1.6 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: BorderSide(
                  color: isFilled ? AppColors.primaryStrong : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isFilled ? 1.6 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: const BorderSide(color: AppColors.primaryStrong, width: 2.0),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter a product name';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    final selectedCat = CategoryModel.getById(_selectedCategory);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Category *', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selectedCat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(selectedCat.icon, size: 12, color: selectedCat.color),
                    const SizedBox(width: 4),
                    Text(
                      selectedCat.name,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: selectedCat.color,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Symmetrical and adaptive category chips with zero truncation
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CategoryModel.presetCategories.map((cat) {
              final isSelected = _selectedCategory == cat.id;

              return InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () {
                  setState(() {
                    _selectedCategory = cat.id;
                    _aiFilledFields.remove('category');
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withOpacity(0.16)
                        : (isDark ? AppColors.darkSurface : AppColors.lightBg),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isSelected ? cat.color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 15,
                        color: isSelected ? cat.color : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? cat.color : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryDateCard(bool isDark) {
    final isAi = _aiFilledFields.contains('date');
    final dateFormatted = DateFormat('dd MMM yyyy').format(_expiryDate);
    final dayOfWeek = DateFormat('EEEE').format(_expiryDate);
    final daysLeft = _expiryDate.difference(DateTime.now()).inDays;

    final Color badgeColor;
    final String countdownText;
    if (daysLeft < 0) {
      badgeColor = AppColors.statusDanger;
      countdownText = 'Expired ${-daysLeft}d ago';
    } else if (daysLeft == 0) {
      badgeColor = AppColors.statusDanger;
      countdownText = 'Expires today';
    } else if (daysLeft <= 3) {
      badgeColor = AppColors.statusWarning;
      countdownText = '$daysLeft days left';
    } else {
      badgeColor = AppColors.statusSafe;
      countdownText = '$daysLeft days left';
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (clean title + AI sparkle badge)
          Row(
            children: [
              Text('Expiry Date *', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
              if (isAi) ...[
                const SizedBox(width: 8),
                _buildAiSparkleBadge(),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Main Interactive Date Tile
          InkWell(
            onTap: _selectCustomDate,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.primary.withOpacity(0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primaryStrong.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.calendar_month_rounded, color: AppColors.primaryStrong, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormatted,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.primaryDark,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              dayOfWeek,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                countdownText,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.primary.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_calendar_rounded,
                      size: 18,
                      color: AppColors.primaryStrong,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Presets Row (+3d, +1w, +1m, +3m, +6m, +1y)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickDateChip('+3 Days', const Duration(days: 3), isDark),
                const SizedBox(width: 6),
                _buildQuickDateChip('+1 Week', const Duration(days: 7), isDark),
                const SizedBox(width: 6),
                _buildQuickDateChip('+1 Month', const Duration(days: 30), isDark),
                const SizedBox(width: 6),
                _buildQuickDateChip('+3 Months', const Duration(days: 90), isDark),
                const SizedBox(width: 6),
                _buildQuickDateChip('+6 Months', const Duration(days: 180), isDark),
                const SizedBox(width: 6),
                _buildQuickDateChip('+1 Year', const Duration(days: 365), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateChip(String label, Duration duration, bool isDark) {
    final targetDate = DateTime.now().add(duration);
    final isSelected = _expiryDate.year == targetDate.year &&
        _expiryDate.month == targetDate.month &&
        _expiryDate.day == targetDate.day;

    return InkWell(
      onTap: () {
        setState(() {
          _expiryDate = targetDate;
          _aiFilledFields.remove('date');
        });
      },
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryStrong.withOpacity(0.16)
              : (isDark ? AppColors.darkSurface : AppColors.lightBg),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? AppColors.primaryStrong : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primaryStrong : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreDetailsAccordion(bool isDark) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _showMoreDetails,
          onExpansionChanged: (expanded) => setState(() => _showMoreDetails = expanded),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.primaryStrong, size: 18),
          ),
          title: Text(
            'Additional Details',
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            'Quantity, Storage Location & Notes',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),

                  // Price (₹) Field
                  Text(
                    'Price (₹)',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'e.g. 65 (optional)',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Quantity & Unit in one row
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantity', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: '1',
                                prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Unit', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _unitController,
                              decoration: InputDecoration(
                                hintText: 'pcs / ml / kg',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Storage Location
                  Text('Storage Location', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Fridge, Pantry Shelf, Medicine Box',
                      prefixIcon: const Icon(Icons.place_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),

                  // Quick Location Chips
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: ['Fridge', 'Pantry', 'Cabinet', 'Bathroom'].map((loc) {
                      return InkWell(
                        onTap: () => setState(() => _locationController.text = loc),
                        child: Chip(
                          labelPadding: EdgeInsets.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          label: Text(loc, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                          backgroundColor: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Reminders
                  Text('Remind Me Before Expiry', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildReminderChip('Same day', 0),
                      _buildReminderChip('1 day before', 1),
                      _buildReminderChip('3 days before', 3),
                      _buildReminderChip('7 days before', 7),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Notes
                  Text('Notes', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Keep refrigerated after opening',
                      prefixIcon: const Icon(Icons.edit_note_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),

                  // Quick Auto-Suggestion Chips for Notes (tap to fill, zero typing needed)
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'Keep refrigerated',
                      'Store in airtight jar',
                      'Opened on purchase',
                      'Consume within 5 days',
                      'Store in dry place',
                    ].map((sugg) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            final current = _notesController.text.trim();
                            if (current.isEmpty) {
                              _notesController.text = sugg;
                            } else if (!current.contains(sugg)) {
                              _notesController.text = '$current, $sugg';
                            }
                          });
                        },
                        child: Chip(
                          labelPadding: EdgeInsets.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          label: Text('+ $sugg', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                          backgroundColor: isDark ? AppColors.darkSurface : AppColors.primarySoft,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSparkleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 10, color: AppColors.primaryDark),
          SizedBox(width: 3),
          Text(
            'AI filled',
            style: TextStyle(fontSize: 9, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderChip(String label, int days) {
    final isSelected = _reminderOffsets.contains(days);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? AppColors.textOnPrimary
              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primaryStrong : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _reminderOffsets.add(days);
          } else {
            _reminderOffsets.remove(days);
          }
        });
      },
    );
  }
}
