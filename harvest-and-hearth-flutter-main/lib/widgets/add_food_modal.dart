import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/simulated_clock.dart';
import '../providers/app_provider.dart';
import '../models/food_item.dart';
import '../constants/categories.dart';
import '../utils/date_helper.dart';
import '../screens/barcode_scanner_screen.dart';

const _uuid = Uuid();

class AddFoodModal extends StatefulWidget {
  /// If provided, the modal opens in edit mode pre-filled with this item.
  final FoodItem? editItem;

  const AddFoodModal({super.key, this.editItem});

  bool get _isEdit => editItem != null;

  @override
  State<AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends State<AddFoodModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _warningDaysCtrl = TextEditingController();

  late FoodCategory _category;
  late StorageType _storage;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    final e = widget.editItem;
    if (e != null) {
      _nameCtrl.text = e.name;
      _quantityCtrl.text =
          e.quantity % 1 == 0 ? e.quantity.toInt().toString() : e.quantity.toString();
      _unitCtrl.text = e.unit;
      _warningDaysCtrl.text = (e.warningDays ?? 3).toString();
      _category = e.category;
      _storage = e.storage;
      _expiryDate = e.expiryDate;
    } else {
      _quantityCtrl.text = '1';
      _unitCtrl.text = 'pcs';
      _warningDaysCtrl.text = '3';
      _category = FoodCategory.vegetables;
      _storage = StorageType.fridge;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _unitCtrl.dispose();
    _warningDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final t = context.read<AppProvider>().t;
    final code = await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BarcodeScannerScreen(t: t),
      ),
    );
    if (!mounted) return;
    if (code != null && code.isNotEmpty) {
      setState(() => _nameCtrl.text = code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('food_scan_success'))),
      );
    }
  }

  Future<void> _pickExpiryDate() async {
    final initial =
        _expiryDate ?? SimulatedClock.now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: SimulatedClock.now.subtract(const Duration(days: 30)),
      lastDate: SimulatedClock.now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _clearExpiryDate() => setState(() => _expiryDate = null);

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.tryParse(_quantityCtrl.text) ?? 1;
    final warningDays = int.tryParse(_warningDaysCtrl.text) ?? 3;
    final provider = context.read<AppProvider>();

    if (widget._isEdit) {
      final updated = widget.editItem!.copyWith(
        name: _nameCtrl.text.trim(),
        category: _category,
        storage: _storage,
        quantity: quantity,
        unit: _unitCtrl.text.trim(),
        expiryDate: _expiryDate,
        warningDays: warningDays,
      );
      provider.updateFood(widget.editItem!.id, updated);
    } else {
      final item = FoodItem(
        id: _uuid.v4(),
        name: _nameCtrl.text.trim(),
        category: _category,
        storage: _storage,
        quantity: quantity,
        unit: _unitCtrl.text.trim(),
        addedDate: SimulatedClock.now,
        expiryDate: _expiryDate,
        warningDays: warningDays,
      );
      provider.addFood(item);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  widget._isEdit ? t('food_edit_title') : t('add_food'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Barcode scan button (add mode only)
                if (!widget._isEdit) ...[
                  OutlinedButton.icon(
                    onPressed: _openScanner,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(t('food_barcode')),
                  ),
                  const SizedBox(height: 16),
                ],

                // Food name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: t('food_name'),
                    hintText: t('food_name_hint'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? t('food_name_required')
                      : null,
                ),
                const SizedBox(height: 12),

                // Category
                DropdownButtonFormField<FoodCategory>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: t('food_category'),
                    border: const OutlineInputBorder(),
                  ),
                  items: AppCategories.all.map((info) {
                    return DropdownMenuItem(
                      value: info.category,
                      child: Row(
                        children: [
                          Icon(info.icon, color: info.color, size: 20),
                          const SizedBox(width: 8),
                          Text(t(info.translationKey)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 12),

                // Storage
                Row(
                  children: [
                    Expanded(
                      child: _StorageChip(
                        label: t('storage_fridge'),
                        icon: Icons.kitchen_rounded,
                        selected: _storage == StorageType.fridge,
                        onTap: () =>
                            setState(() => _storage = StorageType.fridge),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StorageChip(
                        label: t('storage_freezer'),
                        icon: Icons.ac_unit_rounded,
                        selected: _storage == StorageType.freezer,
                        onTap: () =>
                            setState(() => _storage = StorageType.freezer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quantity + Unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: t('food_quantity'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _unitCtrl,
                        decoration: InputDecoration(
                          labelText: t('food_unit'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Expiry date
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickExpiryDate,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: t('food_expiry'),
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_month_outlined),
                          ),
                          child: Text(
                            _expiryDate == null
                                ? '—'
                                : DateHelper.format(_expiryDate!),
                          ),
                        ),
                      ),
                    ),
                    if (_expiryDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _clearExpiryDate,
                        icon: const Icon(Icons.clear_rounded),
                        tooltip: t('food_no_expiry'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Warning days
                TextFormField(
                  controller: _warningDaysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t('food_warning_days'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(t('food_cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(widget._isEdit
                            ? t('common_save')
                            : t('food_save')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StorageChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _StorageChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? cs.primary : cs.onSurfaceVariant,
                size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? cs.primary : cs.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
