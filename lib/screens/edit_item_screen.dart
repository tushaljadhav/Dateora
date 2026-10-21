
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/item.dart';
import '../models/status_evaluation.dart';
import '../providers/items_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_expiry_scan_service.dart';
import '../services/photo_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/photo_picker_sheet.dart';
import '../widgets/primary_button.dart';

class EditItemScreen extends StatefulWidget {
  final Item item;

  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  late String _selectedCategory;
  late DateTime _expiryDate;
  String? _photoPath;
  late Set<int> _reminderOffsets;
  bool _isSaving = false;
  bool _isScanningAi = false;
  ScanResult? _lastScanResult;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(text: widget.item.quantity?.toString() ?? '');
    _unitController = TextEditingController(text: widget.item.unit ?? '');
    _locationController = TextEditingController(text: widget.item.location ?? '');
    _notesController = TextEditingController(text: widget.item.notes ?? '');

    _selectedCategory = widget.item.category;
    _expiryDate = StatusEvaluation.parseDate(widget.item.expiryDate);
    _photoPath = widget.item.photoUri;
    _reminderOffsets = widget.item.reminderOffsets.toSet();
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

  Future<void> _openPhotoSheet() async {
    final picked = await PhotoPickerSheet.show(
      context,
      currentPhotoPath: _photoPath,
    );

    if (picked == '__remove__') {
      await _removePhoto();
    } else if (picked != null) {
      setState(() => _photoPath = picked);
    }
  }

  Future<void> _removePhoto() async {
    if (_photoPath != null) {
      await PhotoService.deletePhotoFile(_photoPath);
      setState(() => _photoPath = null);
    }
  }

  /// AI Expiry detection helper for existing item photo
  Future<void> _scanExpiryWithAi() async {
    if (_photoPath == null) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final apiKey = settings.geminiApiKey;

    setState(() => _isScanningAi = true);

    try {
      final file = File(_photoPath!);
      final ExpiryScanService scanService = GeminiExpiryScanService(defaultApiKey: apiKey);

      final result = await scanService.scanImage(file, apiKey: apiKey);

      if (!mounted) return;

      final hasValidDate = result.hasDetectedDate &&
          result.expiryDate != null &&
          DateTime.tryParse(result.expiryDate!) != null;
      final hasValidProduct = result.productName != null &&
          result.productName!.trim().isNotEmpty &&
          result.productName != 'Scanned Item' &&
          result.productName != 'Product';

      if (result.isSuccess && (hasValidDate || hasValidProduct)) {
        setState(() {
          _lastScanResult = result;
          if (hasValidDate) {
            _expiryDate = DateTime.parse(result.expiryDate!);
          }
          if (hasValidProduct) {
            _nameController.text = result.productName!;
          }
          if (result.categoryId.isNotEmpty && result.categoryId != 'custom') {
            _selectedCategory = result.categoryId;
          }
          if (result.quantity != null) {
            _quantityController.text = result.quantity!.toString();
          }
          if (result.unit != null && result.unit!.isNotEmpty) {
            _unitController.text = result.unit!;
          }
          if (result.location != null && result.location!.isNotEmpty) {
            _locationController.text = result.location!;
          }
          if (result.notes != null && result.notes!.isNotEmpty) {
            _notesController.text = result.notes!;
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
                      'Gemini AI updated: ${result.productName ?? "Item"} • ${DateFormat("dd MMM yyyy").format(_expiryDate)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFD97706),
              content: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI detected "${result.productName}". Expiry date not found in photo — please adjust date manually.',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't detect clear details from photo, please adjust manually."),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusDanger,
            content: Text('AI Scan Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanningAi = false);
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
      setState(() => _expiryDate = picked);
    }
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    final dateStr = DateFormat('yyyy-MM-dd').format(_expiryDate);
    final qty = double.tryParse(_quantityController.text.trim());

    final updated = widget.item.copyWith(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      expiryDate: dateStr,
      photoUri: _photoPath,
      quantity: qty,
      unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      reminderOffsets: _reminderOffsets.toList()..sort(),
    );

    try {
      await itemsProvider.updateItem(
        updated,
        dailyNotificationTime: settingsProvider.dailyNotificationTime,
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
                  'Updated "${updated.name}" successfully!',
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
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormatted = DateFormat('dd MMM yyyy').format(_expiryDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Item',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.md,
          ),
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Item Name *',
                prefixIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryStrong),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Item name is required';
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Category Selection
            Row(
              children: [
                Text(
                  'Category *',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  CategoryModel.getById(_selectedCategory).name,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
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
                    setState(() => _selectedCategory = cat.id);
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

            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Text(
                  'Expiry Date *',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                if (_lastScanResult != null) ...[
                  const Spacer(),
                  _buildConfidenceBadge(_lastScanResult!),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: _selectCustomDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.primarySoft.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.primary,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryStrong.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primaryStrong,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expires On',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Text(
                          dateFormatted,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        'Change Date',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryStrong,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Reminders
            Text(
              'Remind Me Before',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _buildReminderChip('On expiry day', 0),
                _buildReminderChip('1 day before', 1),
                _buildReminderChip('3 days before', 3),
                _buildReminderChip('7 days before', 7),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Photo Card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 20,
                        color: AppColors.primaryStrong,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Product Photo',
                        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (_photoPath != null && File(_photoPath!).existsSync()) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Hero(
                            tag: 'item_photo_${widget.item.id}',
                            child: Image.file(
                              File(_photoPath!),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.black.withOpacity(0.65),
                                  radius: 18,
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                                    tooltip: 'Retake Photo',
                                    onPressed: _openPhotoSheet,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor: Colors.black.withOpacity(0.65),
                                  radius: 18,
                                  child: IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                                    tooltip: 'Remove Photo',
                                    onPressed: _removePhoto,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: _isScanningAi
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryStrong),
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryStrong, size: 18),
                        label: Text(
                          _isScanningAi ? 'Analyzing photo with AI...' : 'Re-scan date with AI',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.primaryStrong,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: _isScanningAi ? null : _scanExpiryWithAi,
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.photo_camera_rounded, size: 18),
                            label: const Text('Take Photo'),
                            onPressed: () async {
                              final path = await PhotoService.captureOrPickPhoto(
                                context: context,
                                source: ImageSource.camera,
                                currentPhotoPath: _photoPath,
                              );
                              if (path != null) setState(() => _photoPath = path);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.photo_library_rounded, size: 18),
                            label: const Text('Gallery'),
                            onPressed: () async {
                              final path = await PhotoService.captureOrPickPhoto(
                                context: context,
                                source: ImageSource.gallery,
                                currentPhotoPath: _photoPath,
                              );
                              if (path != null) setState(() => _photoPath = path);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Quantity & Unit
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Storage Location',
                prefixIcon: const Icon(Icons.place_outlined, color: AppColors.primaryStrong),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Update Primary Button
            PrimaryButton(
              text: 'Update Item',
              icon: Icons.check_rounded,
              isLoading: _isSaving,
              onPressed: _saveItem,
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderChip(String label, int days) {
    final isSelected = _reminderOffsets.contains(days);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? (isDark ? AppColors.primary : AppColors.primaryDark)
              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary),
        ),
      ),
      selected: isSelected,
      selectedColor: isDark
          ? AppColors.primaryStrong.withOpacity(0.3)
          : AppColors.primarySoft,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      checkmarkColor: AppColors.primaryStrong,
      side: BorderSide(
        color: isSelected
            ? AppColors.primaryStrong
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _reminderOffsets.add(days);
          } else {
            if (_reminderOffsets.length > 1) {
              _reminderOffsets.remove(days);
            }
          }
        });
      },
    );
  }

  Widget _buildConfidenceBadge(ScanResult result) {
    if (result.isEstimated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.statusWarningBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('Estimated', style: TextStyle(color: AppColors.statusWarning, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
    if (result.confidence >= 0.8) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.statusSuccessBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 11, color: AppColors.statusSuccess),
            SizedBox(width: 3),
            Text('High Confidence', style: TextStyle(color: AppColors.statusSuccess, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else if (result.confidence >= 0.5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.statusWarningBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded, size: 11, color: AppColors.statusWarning),
            SizedBox(width: 3),
            Text('Verify Date', style: TextStyle(color: AppColors.statusWarning, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.statusDangerBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 11, color: AppColors.statusDanger),
            SizedBox(width: 3),
            Text('Low Confidence', style: TextStyle(color: AppColors.statusDanger, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
  }
}
