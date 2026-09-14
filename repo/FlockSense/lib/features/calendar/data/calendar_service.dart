import 'dart:async';
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
  }) {
    if (farmId != null && farmId.isNotEmpty) {
      return _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .doc(farmId)
          .collection('calendarEvents')
          .snapshots()
          .map((snapshot) {
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
            return events;
          });
    }

    // When farmId is null, dynamically stream and merge across all user farms
    late StreamController<List<CalendarEventModel>> controller;
    StreamSubscription? farmsSub;
    final farmEventSubs = <String, StreamSubscription>{};
    final farmEvents = <String, List<CalendarEventModel>>{};

    void emit() {
      final merged = <CalendarEventModel>[];
      final seenIds = <String>{};
      for (final list in farmEvents.values) {
        for (final item in list) {
          if (batchId == null || batchId.isEmpty || item.batchId == batchId) {
            if (seenIds.add(item.id)) {
              merged.add(item);
            }
          }
        }
      }
      merged.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      if (!controller.isClosed) {
        controller.add(merged);
      }
    }

    controller = StreamController<List<CalendarEventModel>>.broadcast(
      onListen: () {
        farmsSub = _firestore
            .collection('users')
            .doc(uid)
            .collection('farms')
            .snapshots()
            .listen(
          (farmSnapshot) {
            final currentFarmIds = farmSnapshot.docs.map((d) => d.id).toSet();
            final removedFarmIds = farmEventSubs.keys
                .where((id) => !currentFarmIds.contains(id))
                .toList();
            for (final id in removedFarmIds) {
              farmEventSubs[id]?.cancel();
              farmEventSubs.remove(id);
              farmEvents.remove(id);
            }

            if (currentFarmIds.isEmpty) {
              farmEvents.clear();
              emit();
              return;
            }

            for (final fId in currentFarmIds) {
              if (!farmEventSubs.containsKey(fId)) {
                farmEventSubs[fId] = _firestore
                    .collection('users')
                    .doc(uid)
                    .collection('farms')
                    .doc(fId)
                    .collection('calendarEvents')
                    .snapshots()
                    .listen(
                  (snap) {
                    farmEvents[fId] = snap.docs.map((doc) {
                      return CalendarEventModel.fromJson(doc.data());
                    }).toList();
                    emit();
                  },
                  onError: (e) {
                    debugPrint('[CalendarService] Error on farm $fId: $e');
                  },
                );
              }
            }
            emit();
          },
          onError: (e) {
            debugPrint('[CalendarService] Error watching farms: $e');
          },
        );
      },
      onCancel: () {
        farmsSub?.cancel();
        for (final sub in farmEventSubs.values) {
          sub.cancel();
        }
        farmEventSubs.clear();
        farmEvents.clear();
      },
    );

    return controller.stream;
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

  /// Toggle event completion
  Future<void> toggleEventCompletion(CalendarEventModel event) async {
    final updated = event.copyWith(
      isCompleted: !event.isCompleted,
      completedAt: !event.isCompleted ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    await updateEvent(updated);
  }

  /// Automatically generate reminders based on live farm, batch, and inventory telemetry
  Future<int> generateAutoEventsFromTelemetry({
    required String uid,
    String? farmId,
  }) async {
    int createdCount = 0;
    try {
      final farmsSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .get();

      for (final farmDoc in farmsSnap.docs) {
        final targetFarmId = farmDoc.id;
        if (farmId != null && farmId.isNotEmpty && farmId != targetFarmId) {
          continue;
        }

        // 1. Scan Batches for Harvest & Vaccination Schedule
        final batchesSnap = await farmDoc.reference.collection('batches').get();
        final batches = batchesSnap.docs
            .map(
              (d) => BatchModel.fromJson({
                'id': d.id,
                'farmId': targetFarmId,
                ...d.data(),
              }),
            )
            .toList();

        for (final b in batches) {
          if (b.status.toLowerCase() != 'active') continue;

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
            {
              'name': 'Gumboro IBD Vaccination',
              'day': 14,
              'type': 'Vaccination',
            },
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
        final inventorySnap =
            await farmDoc.reference.collection('inventoryItems').get();
        final inventoryItems = inventorySnap.docs
            .map(
              (d) => InventoryItemModel.fromJson({
                'id': d.id,
                'farmId': targetFarmId,
                ...d.data(),
              }),
            )
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
      }
    } catch (e) {
      debugPrint('Error generating auto calendar events: $e');
    }
    return createdCount;
  }
}
