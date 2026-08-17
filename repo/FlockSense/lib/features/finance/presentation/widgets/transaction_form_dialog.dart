import 'package:flutter/material.dart';
import 'package:flock_sense/features/finance/data/models/finance_transaction_model.dart';
import 'package:flock_sense/features/finance/data/services/finance_service.dart';

class TransactionFormDialog extends StatefulWidget {
  final FinanceTransactionType initialType;
  final String farmId;
  final String batchId;

  const TransactionFormDialog({
    super.key,
    required this.initialType,
    this.farmId = 'farm_default',
    this.batchId = 'batch_default',
  });

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late FinanceTransactionType _type;
  late String _category;
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController(text: '0');
  final TextEditingController _totalController = TextEditingController(text: '0');
  final TextEditingController _paidController = TextEditingController(text: '0');
  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _paymentMethod = 'Cash';
  PaymentStatus _paymentStatus = PaymentStatus.paid;
  DateTime _selectedDate = DateTime.now();

  static const _incomeCategories = ['Bird Sales', 'Egg Sales', 'Manure Sales', 'Equipment Sales', 'Other Income'];
  static const _expenseCategories = ['Feed', 'Medicine', 'Vaccination', 'Electricity', 'Water', 'Labour', 'Transport', 'Maintenance', 'Equipment', 'Other'];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = _type == FinanceTransactionType.income ? _incomeCategories.first : _expenseCategories.first;
    _invoiceController.text = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _partyController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    _paidController.dispose();
    _invoiceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final total = qty * price;
    if (total > 0) {
      _totalController.text = total.toStringAsFixed(0);
      if (_paymentStatus == PaymentStatus.paid) {
        _paidController.text = total.toStringAsFixed(0);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final total = double.tryParse(_totalController.text) ?? (qty * price);
    final paid = double.tryParse(_paidController.text) ?? (_paymentStatus == PaymentStatus.paid ? total : 0.0);

    final tx = FinanceTransactionModel(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      farmId: widget.farmId,
      batchId: widget.batchId,
      ownerId: 'user_default',
      type: _type,
      category: _category,
      date: _selectedDate,
      customerOrSupplier: _partyController.text.trim().isNotEmpty ? _partyController.text.trim() : 'General',
      quantity: qty,
      unitPrice: price,
      totalAmount: total,
      paymentMethod: _paymentMethod,
      paymentStatus: _paymentStatus,
      paidAmount: paid,
      invoiceNumber: _invoiceController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await FinanceService.createTransaction(tx);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == FinanceTransactionType.income ? _incomeCategories : _expenseCategories;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(
        _type == FinanceTransactionType.income ? 'Record Income Transaction' : 'Record Expense Transaction',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type Toggle
                SegmentedButton<FinanceTransactionType>(
                  segments: const [
                    ButtonSegment(value: FinanceTransactionType.income, label: Text('Income', style: TextStyle(fontSize: 12)), icon: Icon(Icons.arrow_downward, color: Colors.green, size: 16)),
                    ButtonSegment(value: FinanceTransactionType.expense, label: Text('Expense', style: TextStyle(fontSize: 12)), icon: Icon(Icons.arrow_upward, color: Colors.orange, size: 16)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (set) {
                    setState(() {
                      _type = set.first;
                      _category = _type == FinanceTransactionType.income ? _incomeCategories.first : _expenseCategories.first;
                    });
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() => _category = val!),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _partyController,
                  decoration: InputDecoration(
                    labelText: _type == FinanceTransactionType.income ? 'Customer / Buyer Name' : 'Supplier / Vendor Name',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculateTotal(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Unit Price (₹)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculateTotal(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _totalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount (₹)',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Method',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: ['Cash', 'Bank Transfer', 'UPI', 'Cheque', 'Credit']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<PaymentStatus>(
                        value: _paymentStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: PaymentStatus.values
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))))
                            .toList(),
                        onChanged: (val) => setState(() => _paymentStatus = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _invoiceController,
                  decoration: const InputDecoration(
                    labelText: 'Invoice Number',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
          onPressed: _submit,
          child: const Text('Save Transaction'),
        ),
      ],
    );
  }
}
