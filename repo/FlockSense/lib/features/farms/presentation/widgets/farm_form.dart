import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

// All 38 Tamil Nadu districts
const _tnDistricts = [
  'Ariyalur',
  'Chengalpattu',
  'Chennai',
  'Coimbatore',
  'Cuddalore',
  'Dharmapuri',
  'Dindigul',
  'Erode',
  'Kallakurichi',
  'Kanchipuram',
  'Kanyakumari',
  'Karur',
  'Krishnagiri',
  'Madurai',
  'Mayiladuthurai',
  'Nagapattinam',
  'Namakkal',
  'Nilgiris',
  'Perambalur',
  'Pudukkottai',
  'Ramanathapuram',
  'Ranipet',
  'Salem',
  'Sivaganga',
  'Tenkasi',
  'Thanjavur',
  'Theni',
  'Thoothukudi',
  'Tiruchirappalli',
  'Tirunelveli',
  'Tirupathur',
  'Tiruppur',
  'Tiruvallur',
  'Tiruvannamalai',
  'Tiruvarur',
  'Vellore',
  'Villupuram',
  'Virudhunagar',
];

const _farmTypes = ['EC', 'Open'];
const _flockTypes = ['Broiler', 'Layer', 'Breeder', 'Country'];

typedef FarmFormSubmit =
    void Function(
      String farmName,
      String farmType,
      String flockType,
      String address,
      String? areaName,
      String? district,
      String? state,
      String? farmerName,
      String? phoneNumber,
      String? notes,
      double lengthFt,
      double widthFt,
      int? capacity,
    );

/// 3-step wizard farm form.
///  Step 1 — Basics    : name · farm-type chips · flock-type chips
///  Step 2 — Location  : farmer · phone · area · district (searchable)
///  Step 3 — Size      : length × width → auto area · capacity · notes
///
/// BUG FIX: the old form declared _farmerNameController, _phoneController,
/// _lengthController, _widthController and _notesController at class level
/// AND embedded them in both an ExpansionTile section AND in standalone
/// AppCard sections below it — the same controller used in two live
/// TextFormFields at the same time, causing "duplicate key" assertion
/// failures and "controller used in two fields" runtime errors.
/// This rewrite uses each controller exactly once.
class FarmForm extends StatefulWidget {
  const FarmForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
  });

  final FarmFormSubmit onSubmit;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<FarmForm> createState() => _FarmFormState();
}

class _FarmFormState extends State<FarmForm>
    with SingleTickerProviderStateMixin {
  // ── PageController for wizard ────────────────────────────────────────────
  final _pageCtrl = PageController();
  int _step = 0;

  // ── Step 1 controllers ───────────────────────────────────────────────────
  final _step1Key = GlobalKey<FormState>();
  final _farmNameCtrl = TextEditingController();
  String? _farmType;
  String? _flockType;

  // ── Step 2 controllers ───────────────────────────────────────────────────
  // Each declared ONCE — used in exactly one TextFormField (bug fix).
  final _step2Key = GlobalKey<FormState>();
  final _farmerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _districtSearchCtrl = TextEditingController();
  String? _selectedDistrict;
  List<String> _filteredDistricts = _tnDistricts;

  // ── Step 3 controllers ───────────────────────────────────────────────────
  final _step3Key = GlobalKey<FormState>();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _validationError;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _farmerNameCtrl.text = user.displayName ?? '';
      _phoneCtrl.text = user.phoneNumber ?? '';
    }
    _districtSearchCtrl.addListener(_filterDistricts);
    _lengthCtrl.addListener(() => setState(() {}));
    _widthCtrl.addListener(() => setState(() {}));
  }

  void _filterDistricts() {
    final q = _districtSearchCtrl.text.toLowerCase();
    setState(() {
      _filteredDistricts = q.isEmpty
          ? _tnDistricts
          : _tnDistricts.where((d) => d.toLowerCase().contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _farmNameCtrl.dispose();
    _farmerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    _districtSearchCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _capacityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _lengthFt => double.tryParse(_lengthCtrl.text.trim()) ?? 0;
  double get _widthFt => double.tryParse(_widthCtrl.text.trim()) ?? 0;
  double get _areaSqFt => _lengthFt * _widthFt;

  // ── Navigation ────────────────────────────────────────────────────────────
  void _nextStep() {
    if (_step == 0) {
      if (!_step1Key.currentState!.validate()) return;
      if (_farmType == null) {
        _setError('Select a farm type.');
        return;
      }
      if (_flockType == null) {
        _setError('Select a flock type.');
        return;
      }
    } else if (_step == 1) {
      if (!_step2Key.currentState!.validate()) return;
    }
    _setError(null);
    setState(() => _step++);
    _pageCtrl.animateToPage(
      _step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    _setError(null);
    setState(() => _step--);
    _pageCtrl.animateToPage(
      _step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _setError(String? e) => setState(() => _validationError = e);

  void _submit() {
    if (!_step3Key.currentState!.validate()) return;
    _setError(null);

    final areaName = _areaCtrl.text.trim();
    final farmerName = _farmerNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final address = [
      areaName,
      _selectedDistrict,
      'Tamil Nadu',
    ].where((s) => s?.isNotEmpty ?? false).join(', ');

    widget.onSubmit(
      _farmNameCtrl.text.trim(),
      _farmType!,
      _flockType!,
      address,
      areaName.isNotEmpty ? areaName : null,
      _selectedDistrict,
      'Tamil Nadu',
      farmerName.isNotEmpty ? farmerName : null,
      phone.isNotEmpty ? phone : null,
      notes.isNotEmpty ? notes : null,
      _lengthFt,
      _widthFt,
      int.tryParse(_capacityCtrl.text.trim()),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final displayError = _validationError ?? widget.errorMessage;

    return Column(
      children: [
        // ── Step indicator ──────────────────────────────────────────────────
        _StepIndicator(current: _step, total: 3),

        // ── Pages ───────────────────────────────────────────────────────────
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [_buildStep1(), _buildStep2(), _buildStep3()],
          ),
        ),

        // ── Error ──────────────────────────────────────────────────────────
        if (displayError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayError,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Nav buttons ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.isLoading ? null : _prevStep,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: _step == 0 ? 1 : 2,
                child: FilledButton(
                  onPressed: widget.isLoading
                      ? null
                      : (_step < 2 ? _nextStep : _submit),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: widget.isLoading && _step == 2
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _step < 2 ? 'Continue →' : 'Create Farm',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 1: Basics ────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepHeader(
              'Farm basics',
              'Name your farm and select its type',
              Icons.holiday_village_outlined,
            ),
            const SizedBox(height: 20),

            // Farm name
            TextFormField(
              controller: _farmNameCtrl,
              enabled: !widget.isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDec('Farm name', Icons.edit_outlined),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Farm name is required.' : null,
            ),
            const SizedBox(height: 20),

            // Farm type chips
            _chipSection(
              label: 'Farm type',
              subtitle: 'Select the type of housing',
              items: _farmTypes,
              icons: [Icons.factory_outlined, Icons.wb_sunny_outlined],
              selected: _farmType,
              onSelect: (v) => setState(() => _farmType = v),
            ),
            const SizedBox(height: 20),

            // Flock type chips
            _chipSection(
              label: 'Flock type',
              subtitle: 'What birds will you raise?',
              items: _flockTypes,
              icons: [
                Icons.egg_outlined,
                Icons.layers_outlined,
                Icons.diversity_3_outlined,
                Icons.nature_outlined,
              ],
              selected: _flockType,
              onSelect: (v) => setState(() => _flockType = v),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Location ──────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepHeader(
              'Location & contact',
              'Where is this farm located?',
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 20),

            // Farmer name — used ONCE (bug fix: was used in 2 places before)
            TextFormField(
              controller: _farmerNameCtrl,
              enabled: !widget.isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDec(
                'Farmer / Owner name',
                Icons.person_outline,
              ),
            ),
            const SizedBox(height: 14),

            // Phone — used ONCE (bug fix)
            TextFormField(
              controller: _phoneCtrl,
              enabled: !widget.isLoading,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDec('Phone number', Icons.phone_outlined),
            ),
            const SizedBox(height: 14),

            // Area
            TextFormField(
              controller: _areaCtrl,
              enabled: !widget.isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDec(
                'Village / Area name',
                Icons.pin_drop_outlined,
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Area name is required.' : null,
            ),
            const SizedBox(height: 14),

            // District searchable picker
            _districtPicker(),
            const SizedBox(height: 14),

            // State (fixed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'State: Tamil Nadu',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Fixed',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _districtPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _districtSearchCtrl,
          enabled: !widget.isLoading,
          decoration: InputDecoration(
            labelText: _selectedDistrict != null
                ? 'District: $_selectedDistrict  (tap to change)'
                : 'Search district *',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _selectedDistrict != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _selectedDistrict = null;
                      _districtSearchCtrl.clear();
                    }),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          validator: (_) =>
              _selectedDistrict == null ? 'District is required.' : null,
        ),
        if (_districtSearchCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _filteredDistricts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No match',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredDistricts.length,
                    itemBuilder: (_, i) => ListTile(
                      dense: true,
                      title: Text(_filteredDistricts[i]),
                      onTap: () {
                        setState(() {
                          _selectedDistrict = _filteredDistricts[i];
                        });
                        _districtSearchCtrl.clear();
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  // ── Step 3: Size & notes ──────────────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Form(
        key: _step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepHeader(
              'Farm size & notes',
              'Enter dimensions and any extra details',
              Icons.straighten_outlined,
            ),
            const SizedBox(height: 20),

            // Length — used ONCE (bug fix: was used in Advanced + Farm area cards)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lengthCtrl,
                    enabled: !widget.isLoading,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: _inputDec('Length (ft)', Icons.swap_horiz),
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _widthCtrl,
                    enabled: !widget.isLoading,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: _inputDec('Width (ft)', Icons.swap_vert),
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0) return 'Required';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            // Live area calculation chip
            if (_areaSqFt > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.emeraldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total area: ${_areaSqFt.toStringAsFixed(1)} ft²  ≈  ${(_areaSqFt * 0.0929).toStringAsFixed(1)} m²',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Capacity — used ONCE (bug fix)
            TextFormField(
              controller: _capacityCtrl,
              enabled: !widget.isLoading,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDec(
                'Bird capacity (optional)',
                Icons.pets_outlined,
              ),
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return null;
                final n = int.tryParse(v!.trim());
                if (n == null || n <= 0) return 'Enter a valid number.';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Notes — used ONCE (bug fix)
            TextFormField(
              controller: _notesCtrl,
              enabled: !widget.isLoading,
              maxLines: 4,
              decoration: _inputDec(
                'Notes (optional)',
                Icons.notes_outlined,
              ).copyWith(alignLabelWithHint: true),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _stepHeader(String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chipSection({
    required String label,
    required String subtitle,
    required List<String> items,
    required List<IconData> icons,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isSelected = selected == item;
            return GestureDetector(
              onTap: widget.isLoading ? null : () => onSelect(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.border,
                    width: isSelected ? 0 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      i < icons.length ? icons[i] : Icons.circle,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check, color: Colors.white, size: 14),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  );
}

/// Step progress indicator shown at the top of the wizard.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    const labels = ['Basics', 'Location', 'Size'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: List.generate(total, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        decoration: BoxDecoration(
                          color: done || active
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active
                              ? AppColors.primary
                              : (done
                                    ? AppColors.emerald
                                    : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < total - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}
