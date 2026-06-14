import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/models/flock.dart';
import 'package:flock_sense/screens/flock_detail_screen.dart';
import 'package:flock_sense/screens/new_flock_screen.dart';
import 'package:flock_sense/services/firestore_service.dart';

class FlocksScreen extends StatelessWidget {
  const FlocksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Flocks')),
        body: const Center(child: Text('Please sign in to view your flocks.')),
      );
    }

    final service = FirestoreService(uid: uid);

    return Scaffold(
      appBar: AppBar(title: const Text('My Flocks')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('My Flocks', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Track your active flocks, create new batches, and inspect details.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Flock>>(
                  stream: service.watchFlocks(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Failed to load flocks: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final flocks = snapshot.data ?? [];
                    if (flocks.isEmpty) {
                      return const Center(
                        child: Text(
                          'No flock batches yet. Use the + button to add a new flock.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: flocks.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final flock = flocks[index];
                        return ListTile(
                          title: Text(flock.name),
                          subtitle: Text('${flock.birdType} · ${flock.openingCount} birds'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FlockDetailScreen(flock: flock),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewFlockScreen()));
        },
      ),
    );
  }
}
