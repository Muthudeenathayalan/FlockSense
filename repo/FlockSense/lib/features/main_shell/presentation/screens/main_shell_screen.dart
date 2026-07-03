import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/providers/connectivity_provider.dart';
import 'package:flock_sense/core/services/sync_service.dart';
import 'package:flock_sense/features/home/presentation/screens/home_screen.dart';
import 'package:flock_sense/features/more/presentation/screens/more_screen.dart';
import 'package:flock_sense/features/profile/presentation/screens/profile_screen.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_list_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    FarmListScreen(),
    MoreScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Trigger sync the moment connectivity is restored.
    ref.listen(connectivityProvider, (prev, next) {
      final wasOnline =
          prev?.maybeWhen(data: (v) => v, orElse: () => true) ?? true;
      final nowOnline = next.maybeWhen(data: (v) => v, orElse: () => true);
      if (!wasOnline && nowOnline) {
        _syncOnReconnect();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        elevation: 16,
        height: 72,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            selectedIcon: Icon(Icons.agriculture),
            label: 'Farms',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'More',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _syncOnReconnect() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await SyncService().syncPendingOperations();
    debugPrint('[MainShell] Sync triggered on reconnect');
  }
}
