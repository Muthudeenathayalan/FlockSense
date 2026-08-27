import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/calendar/domain/calendar_event_model.dart';
import 'package:flock_sense/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

class CalendarEventFormScreen extends ConsumerStatefulWidget {
  const CalendarEventFormScreen({super.key, this.existingEvent});

  final CalendarEventModel? existingEvent;

  @override
  ConsumerState<CalendarEventFormScreen> createState() =>
      _CalendarEventFormScreenState();
}

class _CalendarEventFormScreenState
    extends ConsumerState<CalendarEventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  String _eventType = 'Vaccination';
  String? _selectedBatchId;
  DateTime _eventDate = DateTime.now();
  TimeOfDay _eventTime = const TimeOfDay(hour: 9, minute: 0);
  String _repeat = 'none';
  String _priority = 'medium';
  int _reminderBeforeMinutes = 30;
  bool _isSaving = false;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  final List<String> _eventTypes = [
    'Vaccination',
    'Medicine',
    'Feed Delivery',
    'Water Check',
    'Cleaning Schedule',
    'Bird Weighing',
    'Batch Placement',
    'Harvest Date',
    'Inventory Restock',
    'Custom Reminder',
  ];

  final Map<int, String> _reminderOptions = {
    15: '15 minutes before',
    30: '30 minutes before',
    60: '1 hour before',
    360: '6 hours before',
    1440: '1 day before (24h)',
    4320: '3 days before',
    10080: '7 days before',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existingEvent;

    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');

    if (e != null) {
      _eventType = e.eventType;
      _selectedBatchId = e.batchId;
      _eventDate = e.eventDate;
      _repeat = e.repeat;
      _priority = e.priority;
      _reminderBeforeMinutes = e.reminderBeforeMinutes;

      final parts = e.eventTime.split(':');
      if (parts.length == 2) {
        _eventTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingEvent != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Event & Reminder' : 'Add Event & Reminder'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Type Dropdown
              const Text(
                'Event Type *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _eventType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _eventTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _eventType = val);
                },
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title *',
                  hintText: 'e.g. Lasota Vaccination, Feed Restock',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please enter event title'
                    : null,
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Details or instructions...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              // Date & Time Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _eventDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setState(() => _eventDate = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Event Date *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        child: Text(_dateFormat.format(_eventDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _eventTime,
                        );
                        if (picked != null) setState(() => _eventTime = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Event Time *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        child: Text(_eventTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Reminder Before & Priority
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _reminderBeforeMinutes,
                      decoration: InputDecoration(
                        labelText: 'Remind Before *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _reminderOptions.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.value,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _reminderBeforeMinutes = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: InputDecoration(
                        labelText: 'Priority *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Text('Urgent'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _priority = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Repeat Option
              DropdownButtonFormField<String>(
                value: _repeat,
                decoration: InputDecoration(
                  labelText: 'Repeat Event *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'none',
                    child: Text('Does not repeat'),
                  ),
                  DropdownMenuItem(value: 'daily', child: Text('Every day')),
                  DropdownMenuItem(value: 'weekly', child: Text('Every week')),
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text('Every month'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _repeat = val);
                },
              ),
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes / Remarks',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveEvent,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isEdit
                              ? 'Update Event & Reminder'
                              : 'Save Event & Schedule Reminder',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authStateProvider).value;
      final activeFarmId = ref.read(activeFarmIdProvider).value;

      if (user == null || activeFarmId == null) {
        throw Exception('User or farm session not found.');
      }

      final service = ref.read(calendarServiceProvider);

      final timeStr =
          '${_eventTime.hour.toString().padLeft(2, '0')}:${_eventTime.minute.toString().padLeft(2, '0')}';

      final event = CalendarEventModel(
        id: widget.existingEvent?.id ?? '',
        farmId: activeFarmId,
        batchId: _selectedBatchId,
        ownerId: user.uid,
        title: _titleController.text.trim(),
        eventType: _eventType,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        eventDate: _eventDate,
        eventTime: timeStr,
        repeat: _repeat,
        priority: _priority,
        reminderBeforeMinutes: _reminderBeforeMinutes,
        isCompleted: widget.existingEvent?.isCompleted ?? false,
        completedAt: widget.existingEvent?.completedAt,
        isAutoGenerated: widget.existingEvent?.isAutoGenerated ?? false,
        autoSource: widget.existingEvent?.autoSource,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: widget.existingEvent?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingEvent == null) {
        await service.addEvent(event);
      } else {
        await service.updateEvent(event);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingEvent == null
                  ? 'Event saved and smart reminder scheduled!'
                  : 'Event updated successfully!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving event: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
