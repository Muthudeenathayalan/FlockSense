import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/calendar/domain/calendar_event_model.dart';
import 'package:flock_sense/features/calendar/services/calendar_notification_service.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';

class CalendarService {
  final FirebaseFirestore _firestore;

  CalendarService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream real-time calendar events with instant initial yield and offline fallback
  Stream<List<CalendarEventModel>> watchCalendarEvents({
    required String uid,
    String? farmId,
    String? batchId,
  }) async* {
    yield const <CalendarEventModel>[];

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collectionGroup('calendarEvents')
          .where('ownerId', isEqualTo: uid);

      if (farmId != null && farmId.isNotEmpty) {
        query = _firestore
            .collection('users')
            .doc(uid)
            .collection('farms')
            .doc(farmId)
            .collection('calendarEvents');
      }

      await for (final snapshot in query.snapshots()) {
        final seen = <String>{};
        final events = <CalendarEventModel>[];
        for (final doc in snapshot.docs) {
          final e = CalendarEventModel.fromJson(doc.data());
          if (batchId == null || batchId.isEmpty || e.batchId == batchId) {
            if (seen.add(e.id)) {
              events.add(e);
            }
          }
        }

        events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
        yield events;
      }
    } catch (err) {
      debugPrint('[CalendarService] watchCalendarEvents error caught: $err');
      yield const <CalendarEventModel>[];
    }
  }

  /// Add new event to Firestore & schedule notification
  Future<void> addEvent(CalendarEventModel event) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(event.ownerId)
          .collection('farms')
          .doc(event.farmId)
          .collection('calendarEvents')
          .doc(event.id.isNotEmpty ? event.id : null);

      final newEvent = event.copyWith(id: docRef.id);
      await docRef.set(newEvent.toJson());

      // Schedule local notification
      await CalendarNotificationService.scheduleEventNotification(newEvent);
    } catch (e) {
      debugPrint('Error adding calendar event: $e');
    }
  }

  /// Update existing event in Firestore & reschedule notification
  Future<void> updateEvent(CalendarEventModel event) async {
    try {
      final updated = event.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('users')
          .doc(event.ownerId)
          .collection('farms')
          .doc(event.farmId)
          .collection('calendarEvents')
          .doc(event.id)
          .update(updated.toJson());

      await CalendarNotificationService.cancelEventNotification(event.id);
      if (!event.isCompleted) {
        await CalendarNotificationService.scheduleEventNotification(updated);
      }
    } catch (e) {
      debugPrint('Error updating calendar event: $e');
    }
  }

  /// Delete event from Firestore & cancel notification
  Future<void> deleteEvent({
    required String uid,
    required String farmId,
    required String eventId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .doc(farmId)
          .collection('calendarEvents')
          .doc(eventId)
          .delete();

      await CalendarNotificationService.cancelEventNotification(eventId);
    } catch (e) {
      debugPrint('Error deleting calendar event: $e');
    }
  }

  /// Toggle event completion status
  Future<void> markCompleted({
    required String uid,
    required String farmId,
    required String eventId,
    required bool isCompleted,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .doc(farmId)
          .collection('calendarEvents')
          .doc(eventId);

      await docRef.update({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? Timestamp.fromDate(DateTime.now()) : null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (isCompleted) {
        await CalendarNotificationService.cancelEventNotification(eventId);
      }
    } catch (e) {
      debugPrint('Error marking event completed: $e');
    }
  }

  /// Automatically generate reminders based on live farm, batch, and inventory telemetry
  Future<int> generateAutoEventsFromTelemetry({
    required String uid,
    String? farmId,
  }) async {
    int createdCount = 0;
    try {
      // 1. Scan Batches for Harvest & Vaccination Schedule
      final batchesSnap = await _firestore
          .collectionGroup('batches')
          .where('ownerId', isEqualTo: uid)
          .get();

      final batches = batchesSnap.docs
          .map((d) => BatchModel.fromJson(d.data()))
          .toList();

      for (final b in batches) {
        if (b.status.toLowerCase() != 'active') continue;

        final targetFarmId = b.farmId;
        final harvestDate = b.placementDate.add(const Duration(days: 42));

        // Harvest Reminder
        final harvestEventTitle = 'Harvest Reminder — ${b.batchName}';
        final existingHarvestSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('farms')
            .doc(targetFarmId)
            .collection('calendarEvents')
            .where('title', isEqualTo: harvestEventTitle)
            .get();

        if (existingHarvestSnap.docs.isEmpty) {
          final harvestEvent = CalendarEventModel(
            id: '',
            farmId: targetFarmId,
            batchId: b.id,
            ownerId: uid,
            title: harvestEventTitle,
            eventType: 'Harvest Date',
            description:
                'Batch ${b.batchName} reaches target maturity age (42 Days). Prepare for bird sales.',
            eventDate: harvestDate,
            eventTime: '08:00',
            priority: 'high',
            reminderBeforeMinutes: 1440, // 1 day before
            isAutoGenerated: true,
            autoSource: 'Batch Maturity Scanner',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await addEvent(harvestEvent);
          createdCount++;
        }

        // Standard Poultry Vaccination Reminders
        final standardVaccines = [
          {
            'name': 'Lasota / Ranikhet Booster',
            'day': 7,
            'type': 'Vaccination',
          },
          {'name': 'Gumboro IBD Vaccination', 'day': 14, 'type': 'Vaccination'},
          {
            'name': 'Gumboro Booster Vaccination',
            'day': 21,
            'type': 'Vaccination',
          },
        ];

        for (final v in standardVaccines) {
          final vacDay = v['day'] as int;
          final vacName = v['name'] as String;
          final vacDate = b.placementDate.add(Duration(days: vacDay - 1));

          if (vacDate.isAfter(
            DateTime.now().subtract(const Duration(days: 1)),
          )) {
            final vacTitle = '$vacName — ${b.batchName}';
            final existingVacSnap = await _firestore
                .collection('users')
                .doc(uid)
                .collection('farms')
                .doc(targetFarmId)
                .collection('calendarEvents')
                .where('title', isEqualTo: vacTitle)
                .get();

            if (existingVacSnap.docs.isEmpty) {
              final vacEvent = CalendarEventModel(
                id: '',
                farmId: targetFarmId,
                batchId: b.id,
                ownerId: uid,
                title: vacTitle,
                eventType: 'Vaccination',
                description:
                    'Scheduled Day $vacDay vaccination protocol for ${b.batchName}.',
                eventDate: vacDate,
                eventTime: '07:30',
                priority: 'urgent',
                reminderBeforeMinutes: 1440,
                isAutoGenerated: true,
                autoSource: 'Vaccination Protocol Scanner',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await addEvent(vacEvent);
              createdCount++;
            }
          }
        }
      }

      // 2. Scan Inventory for Low Stock Restock Reminders
      final inventorySnap = await _firestore
          .collectionGroup('inventoryItems')
          .where('ownerId', isEqualTo: uid)
          .get();

      final inventoryItems = inventorySnap.docs
          .map((d) => InventoryItemModel.fromJson(d.data()))
          .toList();

      for (final item in inventoryItems) {
        if (item.isLowStock) {
          final restockTitle = 'Restock ${item.itemName} (${item.category})';
          final existingRestockSnap = await _firestore
              .collection('users')
              .doc(uid)
              .collection('farms')
              .doc(item.farmId)
              .collection('calendarEvents')
              .where('title', isEqualTo: restockTitle)
              .get();

          if (existingRestockSnap.docs.isEmpty) {
            final restockEvent = CalendarEventModel(
              id: '',
              farmId: item.farmId,
              ownerId: uid,
              title: restockTitle,
              eventType: 'Inventory Restock',
              description:
                  'Stock quantity (${item.quantityAvailable} ${item.unit}) is below minimum threshold (${item.minStockLevel} ${item.unit}). Contact supplier ${item.supplier}.',
              eventDate: DateTime.now(),
              eventTime: '10:00',
              priority: 'high',
              reminderBeforeMinutes: 60,
              isAutoGenerated: true,
              autoSource: 'Low Stock Inventory Scanner',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await addEvent(restockEvent);
            createdCount++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error generating auto calendar events: $e');
    }
    return createdCount;
  }
}
