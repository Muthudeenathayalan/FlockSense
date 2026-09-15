import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';

/// Wizard-based Shed Creation & Editing Screen.
/// Matches the design system, card components, and wizard step flow of FarmSetupScreen and BatchFormScreen.
class ShedFormScreen extends StatefulWidget {
  const ShedFormScreen({
    super.key,
    required this.farmId,
    this.existing,
    this.farm,
  });

  final String farmId;
  final ShedModel? existing;
  final FarmModel? farm;

  @override
  State<ShedFormScreen> createState() => _ShedFormScreenState();
}

class _ShedFormScreenState extends State<ShedFormScreen> {
  final _pageController = PageController();
  final _basicsFormKey = GlobalKey<FormState>();
  final _sizeFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _breadthController = TextEditingController();
  final _capacityController = TextEditingController();
  final _notesController = TextEditingController();

  String _sizeUnit = 'ft';
  int _step = 0;
  bool _saving = false;
  FarmModel? _farm;

  static const _quickNames = <String>[
    'Shed 1',
    'Shed 2',
    'Shed 3',
    'Shed 4',
    'Brooding Shed',
    'Finisher House',
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _farm = widget.farm;
    _initValues();
    _loadFarmAndShedCountIfNeeded();
  }

  void _initValues() {
    final s = widget.existing;
    if (s != null) {
      _nameController.text = s.name;
      _lengthController.text = _toDisplay(s.lengthFt);
      _breadthController.text = _toDisplay(s.widthFt);
      _capacityController.text = s.capacity?.toString() ?? '';
      _notesController.text = s.notes ?? '';
    } else if (_farm != null) {
      _sizeUnit = _farm!.sizeUnit;
    }
  }

  Future<void> _loadFarmAndShedCountIfNeeded() async {
    try {
      if (_farm == null) {
        final f = await FarmService.getFarmById(widget.farmId);
        if (mounted && f != null) {
          setState(() {
            _farm = f;
            if (!_isEdit) _sizeUnit = f.sizeUnit;
          });
        }
      }

      // If creating a new shed and name is empty, auto-suggest based on existing shed count
      if (!_isEdit && _nameController.text.trim().isEmpty) {
        final existingSheds = await ShedService.getShedsByFarmId(widget.farmId);
        if (mounted && _nameController.text.trim().isEmpty) {
          final nextNum = existingSheds.length + 1;
          setState(() {
            _nameController.text = 'Shed $nextNum';
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _lengthController.dispose();
    _breadthController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _lengthInput =>
      double.tryParse(_lengthController.text.trim()) ?? 0;
  double get _breadthInput =>
      double.tryParse(_breadthController.text.trim()) ?? 0;
  double get _areaInSelectedUnit => _lengthInput * _breadthInput;

  double get _lengthFt =>
      _sizeUnit == 'm' ? _meterToFt(_lengthInput) : _lengthInput;
  double get _breadthFt =>
      _sizeUnit == 'm' ? _meterToFt(_breadthInput) : _breadthInput;
  double get _areaFt => _lengthFt * _breadthFt;

  /// Recommended broiler stocking capacity:
  /// - EC Tunnel Ventilated: ~0.75 sq ft / bird
  /// - Open-Sided Curtain: ~1.2 sq ft / bird
  int get _recommendedCapacity {
    if (_areaFt <= 0) return 0;
    final isEC = _farm?.farmType.toUpperCase() == 'EC';
    final densitySqFt = isEC ? 0.75 : 1.2;
    return (_areaFt / densitySqFt).round();
  }

  void _applyRecommendedCapacity() {
    final rec = _recommendedCapacity;
    if (rec > 0) {
      setState(() {
        _capacityController.text = rec.toString();
      });
    }
  }

  void _nextStep() {
    if (_step == 0) {
      final valid = _basicsFormKey.currentState?.validate() ?? false;
      if (!valid) return;
      setState(() => _step = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    final valid = _sizeFormKey.currentState?.validate() ?? false;
    if (!valid) return;
    _save();
  }

  void _backStep() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step = 0);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final lengthFt = _lengthFt;
      final widthFt = _breadthFt;
      final capacity = int.tryParse(_capacityController.text.trim());
      final notes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      if (_isEdit) {
        await ShedService.updateShed(widget.farmId, widget.existing!.id, {
          'name': name,
          'shedName': name,
          'lengthFt': lengthFt,
          'widthFt': widthFt,
          'totalSqFt': lengthFt * widthFt,
          'capacity': capacity,
          'notes': notes,
        });
      } else {
        await ShedService.createShed(
          farmId: widget.farmId,
          name: name,
          lengthFt: lengthFt,
          widthFt: widthFt,
          capacity: capacity,
          notes: notes,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save shed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _isEdit;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Shed' : 'Add New Shed'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _WizardHeader(step: _step),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStepBasics(),
                _buildStepDimensions(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _backStep,
                    child: Text(_step == 0 ? 'Cancel' : 'Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _nextStep,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_step == 1 ? (isEdit ? 'Save Changes' : 'Create Shed') : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBasics() {
    return Form(
      key: _basicsFormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _SectionCard(
            title: 'Shed identification',
            subtitle: 'Give this poultry house a clear name.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Shed name *',
                    hintText: 'e.g. Shed 1, Brooder House',
                    prefixIcon: Icon(Icons.domain_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Shed name is required';
                    }
                    if (val.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'Quick suggestions:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickNames.map((name) {
                    final selected = _nameController.text.trim() == name;
                    return ActionChip(
                      label: Text(name),
                      avatar: selected
                          ? const Icon(Icons.check, size: 14, color: AppColors.primary)
                          : null,
                      backgroundColor: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : null,
                      onPressed: () {
                        setState(() {
                          _nameController.text = name;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Equipment details (Optional)',
                    hintText: 'e.g. Tunnel ventilated, 4 exhaust fans, auto-feeders',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDimensions() {
    return Form(
      key: _sizeFormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _SectionCard(
            title: 'Shed dimensions & capacity',
            subtitle: 'Area and bird capacity are calculated automatically.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('ft (Feet)'),
                      selected: _sizeUnit == 'ft',
                      onSelected: (_) {
                        setState(() => _sizeUnit = 'ft');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('m (Meters)'),
                      selected: _sizeUnit == 'm',
                      onSelected: (_) {
                        setState(() => _sizeUnit = 'm');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Length ($_sizeUnit) *',
                          hintText: _sizeUnit == 'ft' ? 'e.g. 100' : 'e.g. 30',
                          prefixIcon: const Icon(Icons.straighten_rounded),
                        ),
                        validator: (v) {
                          final val = double.tryParse(v ?? '');
                          if (val == null || val <= 0) return 'Enter valid length';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _breadthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Breadth ($_sizeUnit) *',
                          hintText: _sizeUnit == 'ft' ? 'e.g. 30' : 'e.g. 9',
                          prefixIcon: const Icon(Icons.square_foot_rounded),
                        ),
                        validator: (v) {
                          final val = double.tryParse(v ?? '');
                          if (val == null || val <= 0) return 'Enter valid width';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Area Display Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Floor Area',
                            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_areaInSelectedUnit.toStringAsFixed(1)} ${_sizeUnit}²',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      if (_sizeUnit == 'm')
                        Text(
                          '(${_areaFt.toStringAsFixed(0)} ft²)',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Smart Capacity Recommendation Box
                if (_recommendedCapacity > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Recommended Capacity: ~${_recommendedCapacity} birds',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _farm?.farmType.toUpperCase() == 'EC'
                              ? 'Based on 0.75 ft²/bird for Environmentally Controlled (EC) sheds.'
                              : 'Based on 1.2 ft²/bird for standard open broiler housing.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _applyRecommendedCapacity,
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Apply Recommended', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bird Capacity (Optional)',
                    hintText: 'e.g. 2500',
                    prefixIcon: Icon(Icons.pets_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static double _meterToFt(double value) => value * 3.28084;
  static double _ftToMeter(double value) => value / 3.28084;

  static String _toDisplay(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(context, 0, 'Basics', step >= 0),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: step > 0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        const SizedBox(width: 8),
        _dot(context, 1, 'Size & Capacity', step >= 1),
      ],
    );
  }

  Widget _dot(BuildContext context, int index, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: active
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 12,
              color: active
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
