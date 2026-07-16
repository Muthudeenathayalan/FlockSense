import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';

class BatchFormScreen extends StatefulWidget {
  const BatchFormScreen({super.key, required this.farmId, this.shedId});

  final String farmId;
  final String? shedId;

  @override
  State<BatchFormScreen> createState() => _BatchFormScreenState();
}

class _BatchFormScreenState extends State<BatchFormScreen> {
  final _pageController = PageController();
  final _stepOneKey = GlobalKey<FormState>();
  final _stepTwoKey = GlobalKey<FormState>();

  final _batchNameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _breadthController = TextEditingController();
  final _maleController = TextEditingController();
  final _femaleController = TextEditingController();
  final _hatchNameController = TextEditingController();
  final _integratorNameController = TextEditingController();

  String _sizeUnit = 'ft';
  String? _selectedFlockType;
  DateTime? _hatchDate;
  DateTime? _placementDate;
  int _step = 0;
  bool _saving = false;
  String? _countError;

  static const _flockTypes = <String>['Broiler', 'Layer', 'Breeder', 'Country'];

  double get _lengthInput =>
      double.tryParse(_lengthController.text.trim()) ?? 0;
  double get _breadthInput =>
      double.tryParse(_breadthController.text.trim()) ?? 0;
  double get _areaInSelectedUnit => _lengthInput * _breadthInput;

  int get _maleCount => int.tryParse(_maleController.text.trim()) ?? 0;
  int get _femaleCount => int.tryParse(_femaleController.text.trim()) ?? 0;
  int get _totalFlock => _maleCount + _femaleCount;

  double get _lengthFt =>
      _sizeUnit == 'm' ? _meterToFt(_lengthInput) : _lengthInput;
  double get _breadthFt =>
      _sizeUnit == 'm' ? _meterToFt(_breadthInput) : _breadthInput;

  @override
  void dispose() {
    _pageController.dispose();
    _batchNameController.dispose();
    _lengthController.dispose();
    _breadthController.dispose();
    _maleController.dispose();
    _femaleController.dispose();
    _hatchNameController.dispose();
    _integratorNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool hatch}) async {
    final initial = hatch
        ? (_hatchDate ?? DateTime.now())
        : (_placementDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (hatch) {
        _hatchDate = picked;
      } else {
        _placementDate = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final batch = await BatchService.createBatch(
        farmId: widget.farmId,
        shedId: widget.shedId,
        batchName: _batchNameController.text.trim(),
        lengthFt: _lengthFt,
        widthFt: _breadthFt,
        sizeUnit: _sizeUnit,
        hatchDate: _hatchDate!,
        placementDate: _placementDate!,
        maleCount: _maleCount,
        femaleCount: _femaleCount,
        breedOrFlockType: _selectedFlockType!,
        hatchName: _hatchNameController.text.trim().isEmpty
            ? null
            : _hatchNameController.text.trim(),
        integratorName: _integratorNameController.text.trim().isEmpty
            ? null
            : _integratorNameController.text.trim(),
        hatcheryName: _hatchNameController.text.trim().isEmpty
            ? null
            : _hatchNameController.text.trim(),
        supervisorName: _integratorNameController.text.trim().isEmpty
            ? null
            : _integratorNameController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BatchCommandCenterScreen(
            farmId: widget.farmId,
            batchId: batch.id,
            batchName: batch.batchName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save batch: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_step == 0) {
      final valid = _stepOneKey.currentState?.validate() ?? false;
      if (!valid || _selectedFlockType == null) return;
      if (_totalFlock <= 0) {
        setState(
          () => _countError = 'Total flock count must be greater than 0',
        );
        return;
      }
      setState(() => _countError = null);
      setState(() => _step = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    // Step 1: Validate dates before saving
    if (_hatchDate == null || _placementDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both hatch and placement dates'),
        ),
      );
      return;
    }
    if (_placementDate!.isBefore(_hatchDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Placement date cannot be earlier than hatch date'),
        ),
      );
      return;
    }
    final twoValid = _stepTwoKey.currentState?.validate() ?? false;
    if (!twoValid) return;

    _save();
  }

  void _back() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Batch')),
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
              children: [_stepOne(), _stepTwo()],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _back,
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _next,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_step == 1 ? 'Save Batch' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepOne() {
    return Form(
      key: _stepOneKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _SectionCard(
            title: 'Batch setup',
            subtitle: 'Define size, type, and flock counts.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _batchNameController,
                  decoration: const InputDecoration(labelText: 'Batch name'),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('ft'),
                      selected: _sizeUnit == 'ft',
                      onSelected: (_) => setState(() => _sizeUnit = 'ft'),
                    ),
                    ChoiceChip(
                      label: const Text('m'),
                      selected: _sizeUnit == 'm',
                      onSelected: (_) => setState(() => _sizeUnit = 'm'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Length ($_sizeUnit) *',
                        ),
                        validator: _positiveNumber,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _breadthController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Breadth ($_sizeUnit) *',
                        ),
                        validator: _positiveNumber,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Area: ${_areaInSelectedUnit.toStringAsFixed(2)} ${_sizeUnit}\u00b2',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Text(
                  'Flock type *',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: _flockTypes.map((type) {
                    return ChoiceChip(
                      label: Text(type),
                      selected: _selectedFlockType == type,
                      onSelected: (_) =>
                          setState(() => _selectedFlockType = type),
                    );
                  }).toList(),
                ),
                if (_selectedFlockType == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Select one flock type',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maleController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Male count *',
                        ),
                        validator: _nonNegativeRequired,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _femaleController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Female count *',
                        ),
                        validator: _nonNegativeRequired,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Total flock: $_totalFlock',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_countError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _countError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTwo() {
    return Form(
      key: _stepTwoKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _SectionCard(
            title: 'Dates & source',
            subtitle: 'Capture hatch and placement details.',
            child: Column(
              children: [
                _DateField(
                  label: 'Hatch date *',
                  date: _hatchDate,
                  onTap: () => _pickDate(hatch: true),
                  hasError: _step == 1 && _hatchDate == null,
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Placement / Delivery date *',
                  date: _placementDate,
                  onTap: () => _pickDate(hatch: false),
                  hasError: _step == 1 && _placementDate == null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hatchNameController,
                  decoration: const InputDecoration(labelText: 'Hatch name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _integratorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Integrator name',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid value';
    }
    return null;
  }

  String? _nonNegativeRequired(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) return 'Enter a valid number';
    return null;
  }

  static double _meterToFt(double value) => value * 3.28084;
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    required this.hasError,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? Theme.of(context).colorScheme.error
        : AppColors.border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surface,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date == null ? label : '$label: ${_format(date!)}',
                style: TextStyle(
                  color: date == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }

  static String _format(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _bubble(context, 0, 'Batch Info', step >= 0),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: step > 0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        const SizedBox(width: 8),
        _bubble(context, 1, 'Dates', step >= 1),
      ],
    );
  }

  Widget _bubble(BuildContext context, int index, String label, bool active) {
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
              color: active
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
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
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
