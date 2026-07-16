import 'package:flutter/material.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';

class ShedFormScreen extends StatefulWidget {
  const ShedFormScreen({super.key, required this.farmId, this.existing});
  final String farmId;
  final ShedModel? existing;

  @override
  State<ShedFormScreen> createState() => _ShedFormScreenState();
}

class _ShedFormScreenState extends State<ShedFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _length;
  late final TextEditingController _width;
  late final TextEditingController _capacity;
  late final TextEditingController _notes;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _length = TextEditingController(
      text: s != null ? s.lengthFt.toString() : '',
    );
    _width = TextEditingController(text: s != null ? s.widthFt.toString() : '');
    _capacity = TextEditingController(text: s?.capacity?.toString() ?? '');
    _notes = TextEditingController(text: s?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _length.dispose();
    _width.dispose();
    _capacity.dispose();
    _notes.dispose();
    super.dispose();
  }

  double _parseDouble(String value) => double.tryParse(value.trim()) ?? 0.0;

  int? _parseInt(String value) =>
      value.trim().isEmpty ? null : int.tryParse(value.trim());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final lengthFt = _parseDouble(_length.text);
      final widthFt = _parseDouble(_width.text);
      final capacity = _parseInt(_capacity.text);
      final notes = _notes.text.trim().isNotEmpty ? _notes.text.trim() : null;

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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Shed' : 'New Shed')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_name, 'Shed name', required: true),
              const SizedBox(height: 16),
              _field(
                _length,
                'Length (ft)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                required: true,
                validator: (v) {
                  final value = double.tryParse(v ?? '');
                  if (value == null || value <= 0)
                    return 'Enter a valid length';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _field(
                _width,
                'Width (ft)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                required: true,
                validator: (v) {
                  final value = double.tryParse(v ?? '');
                  if (value == null || value <= 0) return 'Enter a valid width';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _field(
                _capacity,
                'Capacity (birds)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _field(_notes, 'Notes', maxLines: 3),
              const SizedBox(height: 16),
              _buildSizeInfo(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEdit ? 'Update Shed' : 'Save Shed'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeInfo() {
    final lengthFt = double.tryParse(_length.text.trim()) ?? 0.0;
    final widthFt = double.tryParse(_width.text.trim()) ?? 0.0;
    final totalSqFt = lengthFt > 0 && widthFt > 0 ? (lengthFt * widthFt) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Farm Size / Shed Size: ${lengthFt.toStringAsFixed(1)} × ${widthFt.toStringAsFixed(1)} = ${totalSqFt.toStringAsFixed(1)} sq.ft',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator:
          validator ??
          (required
              ? (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null
              : null),
    );
  }
}
