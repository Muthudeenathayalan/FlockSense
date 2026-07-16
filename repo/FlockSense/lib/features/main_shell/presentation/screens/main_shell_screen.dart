import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/core/providers/connectivity_provider.dart';
import 'package:flock_sense/core/services/sync_service.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_record_form_screen.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
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
  bool _openingRecordFlow = false;

  List<Widget> get _screens => <Widget>[
    const HomeScreen(),
    const FarmListScreen(),
    MoreScreen(onNavigateToTab: _navigateToTab),
    const ProfileScreen(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openingRecordFlow ? null : _openQuickRecordFlow,
        icon: const Icon(Icons.post_add),
        label: const Text('Add Records'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

  void _navigateToTab(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  Future<void> _openQuickRecordFlow() async {
    if (_openingRecordFlow) return;
    setState(() => _openingRecordFlow = true);

    try {
      final farms = await FarmService.getUserFarms();
      final activeFarms = farms
          .where((farm) => farm.status != 'inactive')
          .toList();

      if (!mounted) return;
      if (activeFarms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create a farm before adding records.')),
        );
        return;
      }

      final batchesByFarm = <String, List<BatchModel>>{};
      for (final farm in activeFarms) {
        batchesByFarm[farm.id] = await BatchService.getBatchesForFarm(farm.id);
      }

      final totalBatches = batchesByFarm.values.fold<int>(
        0,
        (count, batches) => count + batches.length,
      );

      if (totalBatches == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Create a batch before adding daily records.'),
          ),
        );
        return;
      }

      final hasMultipleFarms = activeFarms.length > 1;
      final hasMultipleBatches = totalBatches > 1;

      if (!hasMultipleFarms && !hasMultipleBatches) {
        final farm = activeFarms.first;
        final batch = batchesByFarm[farm.id]!.first;
        if (!mounted) return;
        _openDailyRecordWizard(farm, batch);
        return;
      }

      final selection = await showModalBottomSheet<_RecordSelectionResult>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _RecordSelectionSheet(
          farms: activeFarms,
          batchesByFarm: batchesByFarm,
          showFarmSelector: hasMultipleFarms,
          showBatchSelector: true,
        ),
      );

      if (!mounted || selection == null) return;
      _openDailyRecordWizard(selection.farm, selection.batch);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open quick record flow: $e')),
      );
    } finally {
      if (mounted) setState(() => _openingRecordFlow = false);
    }
  }

  void _openDailyRecordWizard(FarmModel farm, BatchModel batch) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyRecordFormScreen(
          farmId: farm.id,
          batchId: batch.id,
          batchName: batch.batchName,
        ),
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

class _RecordSelectionResult {
  const _RecordSelectionResult({required this.farm, required this.batch});

  final FarmModel farm;
  final BatchModel batch;
}

class _RecordSelectionSheet extends StatefulWidget {
  const _RecordSelectionSheet({
    required this.farms,
    required this.batchesByFarm,
    required this.showFarmSelector,
    required this.showBatchSelector,
  });

  final List<FarmModel> farms;
  final Map<String, List<BatchModel>> batchesByFarm;
  final bool showFarmSelector;
  final bool showBatchSelector;

  @override
  State<_RecordSelectionSheet> createState() => _RecordSelectionSheetState();
}

class _RecordSelectionSheetState extends State<_RecordSelectionSheet> {
  late FarmModel _selectedFarm;
  BatchModel? _selectedBatch;

  @override
  void initState() {
    super.initState();
    _selectedFarm = widget.farms.first;
    final initialBatches =
        widget.batchesByFarm[_selectedFarm.id] ?? const <BatchModel>[];
    if (initialBatches.isNotEmpty) {
      _selectedBatch = initialBatches.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final batches =
        widget.batchesByFarm[_selectedFarm.id] ?? const <BatchModel>[];
    if (_selectedBatch != null &&
        !batches.any((b) => b.id == _selectedBatch!.id)) {
      _selectedBatch = batches.isEmpty ? null : batches.first;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Add Records',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Select context and continue to the 2-step daily record wizard.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.showFarmSelector) ...[
              const SizedBox(height: 16),
              Text('Farm', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.farms.map((farm) {
                  return ChoiceChip(
                    label: Text(farm.farmName),
                    selected: _selectedFarm.id == farm.id,
                    onSelected: (_) {
                      setState(() {
                        _selectedFarm = farm;
                        final farmBatches =
                            widget.batchesByFarm[farm.id] ??
                            const <BatchModel>[];
                        _selectedBatch = farmBatches.isEmpty
                            ? null
                            : farmBatches.first;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            if (widget.showBatchSelector) ...[
              const SizedBox(height: 16),
              Text('Batch', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              if (batches.isEmpty)
                const Text('No batches available for selected farm')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: batches.map((batch) {
                    return ChoiceChip(
                      label: Text(batch.batchName),
                      selected: _selectedBatch?.id == batch.id,
                      onSelected: (_) => setState(() => _selectedBatch = batch),
                    );
                  }).toList(),
                ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedBatch == null
                        ? null
                        : () => Navigator.of(context).pop(
                            _RecordSelectionResult(
                              farm: _selectedFarm,
                              batch: _selectedBatch!,
                            ),
                          ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
