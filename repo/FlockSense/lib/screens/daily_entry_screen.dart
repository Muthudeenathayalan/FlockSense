import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/models/daily_record.dart';
import 'package:flock_sense/models/flock.dart';
import 'package:flock_sense/services/firestore_service.dart';

class DailyEntryScreen extends StatefulWidget {
  final Flock flock;

  const DailyEntryScreen({required this.flock, super.key});

  @override
  State<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends State<DailyEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _openingCountController = TextEditingController();
  final _mortalityController = TextEditingController();
  final _cullsController = TextEditingController();
  final _feedController = TextEditingController();
  final _avgWeightController = TextEditingController();
  bool _isSaving = false;
  String? _statusMessage;

  final DateTime _entryDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = _entryDate.toLocal().toString().split(' ').first;
    _openingCountController.text = widget.flock.openingCount.toString();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _openingCountController.dispose();
    _mortalityController.dispose();
    _cullsController.dispose();
    _feedController.dispose();
    _avgWeightController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _statusMessage = 'You must be signed in to add a daily record.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    final openingCount = int.parse(_openingCountController.text.trim());
    final mortality = int.parse(_mortalityController.text.trim());
    final culls = int.parse(_cullsController.text.trim());
    final closingCount = openingCount - mortality - culls;
    final feedConsumedKg = double.parse(_feedController.text.trim());

    final record = DailyRecord(
      id: '',
      flockId: widget.flock.id,
      date: _dateController.text,
      openingCount: openingCount,
      mortality: mortality,
      culls: culls,
      closingCount: closingCount,
      feedConsumedKg: feedConsumedKg,
      avgWeightGrams: _avgWeightController.text.trim().isEmpty ? null : double.parse(_avgWeightController.text.trim()),
      createdAt: DateTime.now(),
    );

    try {
      await FirestoreService(uid: uid).addDailyRecord(widget.flock.id, record);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() {
        _statusMessage = 'Unable to save record: ${error.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Daily Entry')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text('Enter daily flock data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _openingCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Opening count', border: OutlineInputBorder()),
                  validator: (value) => int.tryParse(value ?? '') == null ? 'Enter a valid opening count' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mortalityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Mortality', border: OutlineInputBorder()),
                  validator: (value) => int.tryParse(value ?? '') == null ? 'Enter a valid mortality count' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cullsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Culls', border: OutlineInputBorder()),
                  validator: (value) => int.tryParse(value ?? '') == null ? 'Enter a valid culls count' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _feedController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Feed consumed (kg)', border: OutlineInputBorder()),
                  validator: (value) => double.tryParse(value ?? '') == null ? 'Enter a valid feed amount' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _avgWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Average weight (g)', border: OutlineInputBorder()),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_statusMessage!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveRecord,
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save record'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
