import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/models/flock.dart';
import 'package:flock_sense/models/daily_record.dart';
import 'package:flock_sense/services/firestore_service.dart';
import 'package:flock_sense/screens/daily_entry_screen.dart';

class FlockDetailScreen extends StatelessWidget {
  final Flock flock;

  const FlockDetailScreen({required this.flock, super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(flock.name)),
        body: const Center(child: Text('Please sign in to view flock details.')),
      );
    }

    final service = FirestoreService(uid: uid);

    return Scaffold(
      appBar: AppBar(title: Text(flock.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Batch: ${flock.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _InfoChip(label: 'Type', value: flock.birdType),
                  _InfoChip(label: 'Breed', value: flock.breed.isEmpty ? 'Unknown' : flock.breed),
                  _InfoChip(label: 'Count', value: '${flock.openingCount} birds'),
                  _InfoChip(label: 'Placement', value: flock.placementDate.toLocal().toString().split(' ').first),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Daily Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<List<DailyRecord>>(
                        stream: service.watchDailyRecords(flock.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Failed to load records: ${snapshot.error}'));
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final records = snapshot.data ?? [];
                          if (records.isEmpty) {
                            return const Center(child: Text('No daily records yet. Add one to start tracking.'));
                          }
                          return ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final record = records[index];
                              return ListTile(
                                title: Text(record.date),
                                subtitle: Text('Closing: ${record.closingCount} • Feed: ${record.feedConsumedKg.toStringAsFixed(1)} kg'),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DailyEntryScreen(flock: flock),
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.teal.shade50,
    );
  }
}
