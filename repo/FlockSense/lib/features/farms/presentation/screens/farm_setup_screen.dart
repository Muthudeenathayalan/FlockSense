import 'package:flutter/material.dart';
import 'package:flock_sense/core/services/location_service.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_command_center_screen.dart';

class FarmSetupScreen extends StatefulWidget {
  const FarmSetupScreen({super.key, this.initialFarm});

  final FarmModel? initialFarm;

  @override
  State<FarmSetupScreen> createState() => _FarmSetupScreenState();
}

class _FarmSetupScreenState extends State<FarmSetupScreen> {
  final _pageController = PageController();
  final _detailsFormKey = GlobalKey<FormState>();
  final _sizeFormKey = GlobalKey<FormState>();

  final _farmNameController = TextEditingController();
  final _areaController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _lengthController = TextEditingController();
  final _breadthController = TextEditingController();

  String? _selectedFarmType;
  String _sizeUnit = 'ft';
  bool _locationOverride = false;
  bool _resolvingLocation = false;
  bool _saving = false;
  int _step = 0;

  static const _farmTypes = <String>['EC', 'Open'];

  @override
  void initState() {
    super.initState();
    _hydrateFromInitial();
    if (widget.initialFarm == null) {
      _resolveLocation();
    }
  }

  void _hydrateFromInitial() {
    final farm = widget.initialFarm;
    if (farm == null) return;

    _farmNameController.text = farm.farmName;
    _selectedFarmType = farm.farmType;
    _areaController.text = farm.areaName ?? '';
    _districtController.text = farm.district ?? '';
    _stateController.text = farm.state ?? '';
    _countryController.text = farm.country ?? '';
    _sizeUnit = farm.sizeUnit;
    _locationOverride = !(farm.isLocationAuto);

    final length = _sizeUnit == 'm' ? _ftToMeter(farm.lengthFt) : farm.lengthFt;
    final breadth = _sizeUnit == 'm' ? _ftToMeter(farm.widthFt) : farm.widthFt;
    _lengthController.text = _toDisplay(length);
    _breadthController.text = _toDisplay(breadth);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _farmNameController.dispose();
    _areaController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _lengthController.dispose();
    _breadthController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    if (_locationOverride) return;
    setState(() => _resolvingLocation = true);
    try {
      final location = await LocationService.resolveCurrentLocation();
      if (!mounted || location == null) return;
      setState(() {
        _areaController.text = location.area;
        _districtController.text = location.district;
        _stateController.text = location.state;
        _countryController.text = location.country;
      });
    } catch (_) {
      // Non-blocking: user can continue with manual values.
    } finally {
      if (mounted) {
        setState(() => _resolvingLocation = false);
      }
    }
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

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final isEdit = widget.initialFarm != null;
      final addressParts = <String>[
        _areaController.text.trim(),
        _districtController.text.trim(),
        _stateController.text.trim(),
        _countryController.text.trim(),
      ].where((part) => part.isNotEmpty).toList();

      final farm = isEdit
          ? await FarmService.updateFarm(
              farmId: widget.initialFarm!.id,
              farmName: _farmNameController.text.trim(),
              farmType: _selectedFarmType!,
              areaName: _areaController.text.trim().isEmpty
                  ? null
                  : _areaController.text.trim(),
              district: _districtController.text.trim().isEmpty
                  ? null
                  : _districtController.text.trim(),
              state: _stateController.text.trim().isEmpty
                  ? null
                  : _stateController.text.trim(),
              country: _countryController.text.trim().isEmpty
                  ? null
                  : _countryController.text.trim(),
              address: addressParts.join(', '),
              lengthFt: _lengthFt,
              widthFt: _breadthFt,
              sizeUnit: _sizeUnit,
              isLocationAuto: !_locationOverride,
            )
          : await FarmService.createFarm(
              farmName: _farmNameController.text.trim(),
              farmType: _selectedFarmType!,
              address: addressParts.join(', '),
              areaName: _areaController.text.trim().isEmpty
                  ? null
                  : _areaController.text.trim(),
              district: _districtController.text.trim().isEmpty
                  ? null
                  : _districtController.text.trim(),
              state: _stateController.text.trim().isEmpty
                  ? null
                  : _stateController.text.trim(),
              country: _countryController.text.trim().isEmpty
                  ? null
                  : _countryController.text.trim(),
              lengthFt: _lengthFt,
              widthFt: _breadthFt,
              sizeUnit: _sizeUnit,
              isLocationAuto: !_locationOverride,
            );

      if (!mounted) return;
      if (isEdit) {
        Navigator.of(context).pop(farm);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FarmCommandCenterScreen(farm: farm),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save farm: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _nextStep() {
    if (_step == 0) {
      // Step 0: Validate farm name and farm type
      final nameValid = _detailsFormKey.currentState?.validate() ?? false;
      if (!nameValid || _selectedFarmType == null) return;
      setState(() => _step = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    // Step 1: Validate size/location form before saving
    final sizeValid = _sizeFormKey.currentState?.validate() ?? false;
    if (!sizeValid) return;
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialFarm != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEdit ? 'Edit Farm' : 'Create Farm')),
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
              children: [_buildStepDetails(), _buildStepSizeAndLocation()],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _backStep,
                    child: Text(_step == 0 ? 'Back' : 'Previous'),
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
                        : Text(
                            _step == 1
                                ? (isEdit ? 'Save' : 'Create Farm')
                                : 'Next',
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

  Widget _buildStepDetails() {
    return Form(
      key: _detailsFormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _SectionCard(
            title: 'Farm basics',
            subtitle: 'Only the minimum details are required.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _farmNameController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Farm name *'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Farm name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Farm type *',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: _farmTypes.map((type) {
                    final selected = _selectedFarmType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedFarmType = type),
                    );
                  }).toList(),
                ),
                if (_selectedFarmType == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Select one farm type',
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

  Widget _buildStepSizeAndLocation() {
    return Form(
      key: _sizeFormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _SectionCard(
            title: 'Location',
            subtitle: 'Use GPS to autofill, or override manually.',
            trailing: _resolvingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: _locationOverride ? null : _resolveLocation,
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Refresh location',
                  ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _locationOverride,
                  title: const Text('Override auto location'),
                  subtitle: const Text('Enable manual location entry'),
                  onChanged: (value) {
                    setState(() => _locationOverride = value);
                    if (!value) {
                      _resolveLocation();
                    }
                  },
                ),
                const SizedBox(height: 8),
                _locationField(
                  controller: _areaController,
                  label: 'Area',
                  enabled: _locationOverride,
                ),
                const SizedBox(height: 12),
                _locationField(
                  controller: _districtController,
                  label: 'District',
                  enabled: _locationOverride,
                ),
                const SizedBox(height: 12),
                _locationField(
                  controller: _stateController,
                  label: 'State',
                  enabled: _locationOverride,
                ),
                const SizedBox(height: 12),
                _locationField(
                  controller: _countryController,
                  label: 'Country',
                  enabled: _locationOverride,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Size',
            subtitle: 'Length and breadth are used to auto-calculate area.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          labelText: 'Length ($_sizeUnit)',
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
                          labelText: 'Breadth ($_sizeUnit)',
                        ),
                        validator: _positiveNumber,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Area: ${_areaInSelectedUnit.toStringAsFixed(2)} ${_sizeUnit}\u00b2',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(labelText: label),
    );
  }

  String? _positiveNumber(String? value) {
    final left = double.tryParse(_lengthController.text.trim());
    final right = double.tryParse(_breadthController.text.trim());
    final hasLeft = (left != null && left > 0);
    final hasRight = (right != null && right > 0);

    if (!hasLeft && !hasRight) {
      return null;
    }
    if (!hasLeft || !hasRight) {
      return 'Enter both values or leave both blank.';
    }
    return null;
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
        _dot(context, 1, 'Location & Size', step >= 1),
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
