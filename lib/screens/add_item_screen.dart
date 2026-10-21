import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/items_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_expiry_scan_service.dart';
import '../services/open_food_facts_service.dart';
import '../services/photo_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/photo_picker_sheet.dart';
import '../widgets/primary_button.dart';

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
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  // Multi-photo support: Front Photo + Date Side Photo
  String? _photoPath;
  String? _secondaryPhotoPath;

  final Set<int> _reminderOffsets = {3};
  bool _showMoreDetails = false;
  bool _isSaving = false;
  bool _isScanningAi = false;

  // AI Review State
  ScanResult? _lastScanResult;
  final Set<String> _aiFilledFields = {};
  Map<String, dynamic>? _previousFormSnapshot;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.initialPhotoPath;

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
    _nameController.dispose();
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

    // 2. Resolve Gemini API Key (handled seamlessly via background)
    final apiKey = settings.geminiApiKey;

    setState(() => _isScanningAi = true);

    try {
      final List<File> imageFiles = [];
      if (_photoPath != null && File(_photoPath!).existsSync()) {
        imageFiles.add(File(_photoPath!));
      }
      if (_secondaryPhotoPath != null && File(_secondaryPhotoPath!).existsSync()) {
        imageFiles.add(File(_secondaryPhotoPath!));
      }

      final ExpiryScanService scanService = GeminiExpiryScanService(defaultApiKey: apiKey);

      final result = await scanService.scanImages(imageFiles, apiKey: apiKey);

      if (!mounted) return;

      final hasValidDate = result.hasDetectedDate &&
          result.expiryDate != null &&
          DateTime.tryParse(result.expiryDate!) != null;
      final hasValidProduct = result.productName != null &&
          result.productName!.trim().isNotEmpty &&
          result.productName != 'Scanned Item' &&
          result.productName != 'Product';

      if (result.isSuccess && (hasValidDate || hasValidProduct)) {
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
      if (mounted) _promptOfflineQueue();
    } catch (e) {
      if (mounted) {
        final errText = e.toString();
        if (errText.contains('SocketException') || errText.contains('Network') || errText.contains('offline')) {
          _promptOfflineQueue();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.statusDanger,
              content: Text('AI Scan: $e'),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isScanningAi = false);
    }
  }



  void _promptOfflineQueue() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.statusWarning),
            SizedBox(width: 8),
            Text('You are Offline'),
          ],
        ),
        content: const Text(
          'Dateora could not connect to Gemini AI right now. You can enter details manually, or save this item as "Pending AI Scan" to run when back online.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Enter Manually'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _notesController.text = '[Pending AI Scan] ${_notesController.text}'.trim();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item marked as [Pending AI Scan].')),
              );
            },
            child: const Text('Mark Pending'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBarcodeLookupDialog() async {
    final barcodeController = TextEditingController();
    final barcode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryStrong),
            SizedBox(width: 8),
            Text('Barcode Lookup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the product barcode numbers from packaging to fetch product info from Open Food Facts.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: barcodeController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. 8901030383848',
                labelText: 'Barcode',
                prefixIcon: Icon(Icons.qr_code, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, barcodeController.text.trim()),
            child: const Text('Lookup'),
          ),
        ],
      ),
    );

    if (barcode == null || barcode.isEmpty) return;

    final info = await OpenFoodFactsService.lookupBarcode(barcode);
    if (!mounted) return;

    if (info != null) {
      setState(() {
        if (info.productName != null && info.productName!.isNotEmpty) {
          _nameController.text = info.productName!;
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
          content: Text('Found "${info.productName ?? "Product"}" from Open Food Facts!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product barcode not found in database.')),
      );
    }
  }

  Future<void> _selectCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryStrong,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _aiFilledFields.remove('date');
      });
    }
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);

      final dateStr = DateFormat('yyyy-MM-dd').format(_expiryDate);
      final double? qty = _quantityController.text.trim().isNotEmpty
          ? double.tryParse(_quantityController.text.trim())
          : null;

      await itemsProvider.addItem(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        expiryDate: dateStr,
        quantity: qty,
        unit: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : null,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        photoUri: _photoPath,
        reminderOffsets: _reminderOffsets.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryStrong,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Added "${_nameController.text.trim()}" successfully!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
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
              onPressed: _saveItem,
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
                    ? 'Analyzing with Gemini AI...'
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

  Widget _buildNameInputCard(bool isDark) {
    final isAi = _aiFilledFields.contains('name');
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Product Name *', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
              if (isAi) ...[
                const SizedBox(width: 8),
                _buildAiSparkleBadge(),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'e.g. Amul Milk, Crocin 650, Cetaphil Cleanser',
              hintStyle: AppTextStyles.caption.copyWith(fontSize: 13),
              prefixIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryStrong, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primaryStrong),
                onPressed: _showBarcodeLookupDialog,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: const BorderSide(color: AppColors.primaryStrong, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

          // Clean visual grid of categories
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: CategoryModel.presetCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.3,
            ),
            itemBuilder: (context, index) {
              final cat = CategoryModel.presetCategories[index];
              final isSelected = _selectedCategory == cat.id;

              return InkWell(
                borderRadius: BorderRadius.circular(AppRadius.button),
                onTap: () {
                  setState(() {
                    _selectedCategory = cat.id;
                    _aiFilledFields.remove('category');
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withOpacity(0.16)
                        : (isDark ? AppColors.darkSurface : AppColors.lightBg),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(
                      color: isSelected ? cat.color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat.icon,
                        size: 15,
                        color: isSelected ? cat.color : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          cat.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? cat.color : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryDateCard(bool isDark) {
    final isAi = _aiFilledFields.contains('date');
    final formattedDate = DateFormat('dd MMM yyyy (EEE)').format(_expiryDate);
    final daysLeft = _expiryDate.difference(DateTime.now()).inDays;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.primarySoft.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.primary,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryStrong.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_available_rounded, color: AppColors.primaryStrong, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          daysLeft > 0
                              ? 'Expires in $daysLeft days'
                              : (daysLeft == 0 ? 'Expires today' : 'Expired ${-daysLeft} days ago'),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: daysLeft <= 3 ? AppColors.statusWarning : AppColors.statusSuccess,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Text(
                      'Change',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryStrong,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Clean Quick Date Preset Buttons
          Row(
            children: [
              _buildPresetPill('+3 Days', 3),
              const SizedBox(width: 6),
              _buildPresetPill('+1 Wk', 7),
              const SizedBox(width: 6),
              _buildPresetPill('+1 Mo', 30),
              const SizedBox(width: 6),
              _buildPresetPill('+6 Mo', 180),
              const SizedBox(width: 6),
              _buildPresetPill('+1 Yr', 365),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetPill(String label, int daysFromNow) {
    final targetDate = DateTime.now().add(Duration(days: daysFromNow));
    final isSelected = _expiryDate.year == targetDate.year &&
        _expiryDate.month == targetDate.month &&
        _expiryDate.day == targetDate.day;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () {
          setState(() {
            _expiryDate = targetDate;
            _aiFilledFields.remove('date');
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryStrong
                : (isDark ? AppColors.darkSurface : AppColors.lightBg),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? AppColors.primaryStrong : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
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
