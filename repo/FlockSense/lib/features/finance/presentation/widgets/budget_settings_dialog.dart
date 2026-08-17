import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/finance/data/models/finance_budget_model.dart';
import 'package:flock_sense/features/finance/data/services/finance_service.dart';

class BudgetSettingsDialog extends StatefulWidget {
  final FinanceBudgetModel currentBudget;

  const BudgetSettingsDialog({super.key, required this.currentBudget});

  @override
  State<BudgetSettingsDialog> createState() => _BudgetSettingsDialogState();
}

class _BudgetSettingsDialogState extends State<BudgetSettingsDialog> {
  late TextEditingController _monthlyController;
  late TextEditingController _feedController;
  late TextEditingController _medicineController;

  @override
  void initState() {
    super.initState();
    _monthlyController = TextEditingController(text: widget.currentBudget.monthlyBudget.toStringAsFixed(0));
    _feedController = TextEditingController(text: widget.currentBudget.feedBudget.toStringAsFixed(0));
    _medicineController = TextEditingController(text: widget.currentBudget.medicineBudget.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _monthlyController.dispose();
    _feedController.dispose();
    _medicineController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final monthly = double.tryParse(_monthlyController.text) ?? 150000.0;
    final feed = double.tryParse(_feedController.text) ?? 100000.0;
    final med = double.tryParse(_medicineController.text) ?? 20000.0;

    final updated = FinanceBudgetModel(
      id: widget.currentBudget.id,
      farmId: widget.currentBudget.farmId,
      monthYear: DateFormat('yyyy-MM').format(DateTime.now()),
      monthlyBudget: monthly,
      feedBudget: feed,
      medicineBudget: med,
      updatedAt: DateTime.now(),
    );

    await FinanceService.setBudget(updated);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configure Monthly Budgets'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set spending thresholds for the active month. Visual warnings will trigger when spending limits are exceeded.',
              style: TextStyle(fontSize: 11, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _monthlyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Monthly Operating Budget (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _feedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Feed Spending Threshold (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _medicineController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Medicine & Health Threshold (₹)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
          onPressed: _save,
          child: const Text('Save Budgets'),
        ),
      ],
    );
  }
}
