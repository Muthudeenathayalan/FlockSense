import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_list_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_screen.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_active_batches_section.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_identity_header.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_operational_summary.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_specs_card.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_status_control_card.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_records_screen.dart';
import 'package:flock_sense/features/medicine/presentation/screens/medicine_records_screen.dart';
import 'package:flock_sense/features/performance/presentation/screens/batch_performance_screen.dart';
import 'package:flock_sense/features/reports/presentation/screens/reports_dashboard_screen.dart';
import 'package:flock_sense/features/sales/presentation/screens/bird_sales_screen.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/features/sheds/presentation/screens/shed_list_screen.dart';
import 'package:flock_sense/features/sheds/presentation/screens/shed_form_screen.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_sheds_section.dart';

/// Farm Command Center & Management Screen.
/// Aligned with the reference UI (Image 1) featuring:
/// - Green curved gradient SliverAppBar with glow shapes, chips, and 4 header stats
/// - 3 mini stat cards with circular icon backdrops (Total Birds, Capacity, Farm Type)
/// - Quick Actions grid with 8 rounded buttons (Daily Records, View Records, Feed Log, Medicine, Vaccination, Bird Sales, Performance, Reports)
/// - Farm Details structured specifications card
/// - Active Batches list and Farm Status controls
class FarmCommandCenterScreen extends StatefulWidget {
  const FarmCommandCenterScreen({super.key, required this.farm});

  final FarmModel farm;

  @override
  State<FarmCommandCenterScreen> createState() =>
      _FarmCommandCenterScreenState();
}

class _FarmCommandCenterScreenState extends State<FarmCommandCenterScreen> {
  late FarmModel _farm;
  bool _isTogglingStatus = false;

  int _selectedSegment = 0;

  @override
  void initState() {
    super.initState();
    _farm = widget.farm;
  }

  Future<void> _reloadFarm() async {
    try {
      final updated = await FarmService.getFarmById(_farm.id);
      if (updated != null && mounted) {
        setState(() => _farm = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm details refreshed')),
        );
      }
    } catch (_) {}
  }

  Future<void> _deleteFarm() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete Farm',
      message:
          'Are you sure you want to permanently delete "${_farm.farmName}"? All associated data will also be deleted. This cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );

    if (!confirmed || !mounted) return;

    try {
      await FarmService.deleteFarm(_farm.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm deleted successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting farm: $e')));
      }
    }
  }

  Future<void> _toggleFarmStatus(bool value) async {
    setState(() => _isTogglingStatus = true);
    try {
      await FarmService.setFarmStatus(farmId: _farm.id, isActive: value);
      setState(() {
        _farm = _farm.copyWith(status: value ? 'active' : 'inactive');
        _isTogglingStatus = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Farm marked as ${value ? 'Active' : 'Inactive'}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status update failed: $e')));
      }
    }
  }

  void _openBatchFeature(
    List<BatchModel> batches,
    List<ShedModel> sheds,
    Widget Function(BatchModel batch) screenBuilder, {
    required String featureName,
  }) {
    final activeBatches =
        batches.where((b) => b.status.toLowerCase() == 'active').toList();
    final targetBatch = activeBatches.isNotEmpty
        ? activeBatches.first
        : (batches.isNotEmpty ? batches.first : null);

    if (targetBatch != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screenBuilder(targetBatch)),
      );
    } else if (sheds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add a shed first before creating a batch to access $featureName.'),
          action: SnackBarAction(
            label: 'Add Shed',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShedFormScreen(
                    farmId: _farm.id,
                    farm: _farm,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add a batch first to access $featureName.'),
          action: SnackBarAction(
            label: 'Add Batch',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchFormScreen(farmId: _farm.id),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Widget _buildSegmentedControl(int shedsCount, int batchesCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSegmentItem(
            index: 0,
            label: 'Infrastructure',
            badgeText: '$shedsCount Sheds • $batchesCount Batches',
            icon: Icons.grid_view_rounded,
          ),
          _buildSegmentItem(
            index: 1,
            label: 'Operations',
            icon: Icons.bolt_rounded,
          ),
          _buildSegmentItem(
            index: 2,
            label: 'Farm Specs',
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required int index,
    required String label,
    String? badgeText,
    required IconData icon,
  }) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedSegment != index) {
            HapticFeedback.selectionClick();
            setState(() => _selectedSegment = index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF104422) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF104422).withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              if (badgeText != null) ...[
                const SizedBox(height: 2),
                Text(
                  badgeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.85)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BatchModel>>(
      stream: BatchService.watchBatches(_farm.id),
      builder: (context, snapshot) {
        final batches = snapshot.data ?? [];
        final activeBatches = batches
            .where((b) => b.status.toLowerCase() == 'active')
            .toList();
        final totalLiveBirds = activeBatches.fold<int>(
          0,
          (sum, b) => sum + b.currentBirds,
        );

        return StreamBuilder<List<ShedModel>>(
          stream: ShedService.watchSheds(_farm.id),
          builder: (context, shedSnapshot) {
            final sheds = shedSnapshot.data ?? [];
            final shedsCount = sheds.isNotEmpty
                ? sheds.length
                : (_farm.capacity != null && _farm.capacity! > 0
                    ? 1
                    : (_farm.totalSqFt > 0 ? 1 : 1));

            return Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // 1. Header (Emerald gradient, glow shapes, status chips, 4 header stats)
                  FarmIdentityHeader(
                    farm: _farm,
                    liveBirds: totalLiveBirds,
                    activeBatchesCount: activeBatches.length,
                    shedsCount: shedsCount,
                    onFarmUpdated: (updated) => setState(() => _farm = updated),
                    onDeleteFarm: _deleteFarm,
                    onRefresh: _reloadFarm,
                    onShedsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShedListScreen(farm: _farm),
                      ),
                    ),
                  ),

                  // 2. Body Sections
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 3 Mini Stat Cards (Total Birds, Capacity, Farm Type)
                          FarmOperationalSummary(farm: _farm, batches: batches),

                          const SizedBox(height: 16),

                          // Segmented Navigation Pill
                          _buildSegmentedControl(sheds.length, activeBatches.length),

                          const SizedBox(height: 16),

                          // Segmented Views with Smooth Animated Transition
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.03),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey<int>(_selectedSegment),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_selectedSegment == 0) ...[
                                    // Sheds Section
                                    FarmShedsSection(
                                      farm: _farm,
                                      sheds: sheds,
                                      batches: batches,
                                    ),
                                    const SizedBox(height: 20),
                                    // Active Batches Section Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        AppDesign.sectionTitle('Active Batches'),
                                        if (activeBatches.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFBBF7D0)),
                                            ),
                                            child: Text(
                                              '${activeBatches.length} Active',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF166534),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    FarmActiveBatchesSection(
                                      farm: _farm,
                                      sheds: sheds,
                                      batches: batches,
                                    ),
                                  ] else if (_selectedSegment == 1) ...[
                                    // Quick Actions Section Header
                                    AppDesign.sectionTitle('Quick Actions'),
                                    const SizedBox(height: 8),
                                    // Quick Actions 4x2 Grid
                                    _buildQuickActionsGrid(batches, sheds),
                                    const SizedBox(height: 20),
                                    // Farm Status Control
                                    FarmStatusControlCard(
                                      farm: _farm,
                                      isToggling: _isTogglingStatus,
                                      onToggle: _toggleFarmStatus,
                                    ),
                                  ] else ...[
                                    // Farm Details Section Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: AppDesign.sectionTitle('Farm Details & Specs'),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ShedListScreen(farm: _farm),
                                            ),
                                          ),
                                          icon: const Icon(Icons.domain_rounded, size: 16),
                                          label: Text(
                                            sheds.isNotEmpty
                                                ? 'Sheds (${sheds.length})'
                                                : 'Manage Sheds',
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Farm Details Card
                                    FarmSpecsCard(farm: _farm),
                                    const SizedBox(height: 20),
                                    // Farm Status Control
                                    FarmStatusControlCard(
                                      farm: _farm,
                                      isToggling: _isTogglingStatus,
                                      onToggle: _toggleFarmStatus,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              floatingActionButton: sheds.isEmpty
                  ? FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShedFormScreen(
                              farmId: _farm.id,
                              farm: _farm,
                            ),
                          ),
                        );
                      },
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      icon: const Icon(Icons.add_business_rounded, size: 20),
                      label: const Text(
                        'Add Shed',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    )
                  : FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BatchFormScreen(farmId: _farm.id),
                          ),
                        );
                      },
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Add Batch',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
        );
      },
    );
      },
    );
  }

  Widget _buildQuickActionsGrid(
    List<BatchModel> batches,
    List<ShedModel> sheds,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 0.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        // 1. Daily Records (Green)
        AppDesign.actionButton(
          icon: Icons.assignment_outlined,
          label: 'Daily Records',
          gradient: AppDesign.actionGreen,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DailyRecordsDashboardScreen(initialFarmId: _farm.id),
              ),
            );
          },
        ),

        // 2. View Records (Teal)
        AppDesign.actionButton(
          icon: Icons.list_alt_outlined,
          label: 'View Records',
          gradient: AppDesign.actionTeal,
          onTap: () {
            if (batches.isNotEmpty) {
              final first = batches.first;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyRecordsScreen(
                    farmId: _farm.id,
                    batchId: first.id,
                    batchName: first.batchName,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchListScreen(
                    farmId: _farm.id,
                    farmName: _farm.farmName,
                  ),
                ),
              );
            }
          },
        ),

        // 3. Feed Log (Gold)
        AppDesign.actionButton(
          icon: Icons.inventory_outlined,
          label: 'Feed Log',
          gradient: AppDesign.actionGold,
          onTap: () {
            _openBatchFeature(
              batches,
              sheds,
              (batch) => FeedRecordsScreen(
                farmId: _farm.id,
                batchId: batch.id,
                batchName: batch.batchName,
              ),
              featureName: 'Feed Log',
            );
          },
        ),

        // 4. Medicine (Red)
        AppDesign.actionButton(
          icon: Icons.medication_outlined,
          label: 'Medicine',
          gradient: AppDesign.actionRed,
          onTap: () {
            _openBatchFeature(
              batches,
              sheds,
              (batch) => MedicineRecordsScreen(
                farmId: _farm.id,
                batchId: batch.id,
                batchName: batch.batchName,
              ),
              featureName: 'Medicine',
            );
          },
        ),

        // 5. Vaccination (Purple)
        AppDesign.actionButton(
          icon: Icons.vaccines_rounded,
          label: 'Vaccination',
          gradient: AppDesign.actionPurple,
          onTap: () {
            _openBatchFeature(
              batches,
              sheds,
              (batch) => VaccineRecordsScreen(
                farmId: _farm.id,
                batchId: batch.id,
                batchName: batch.batchName,
              ),
              featureName: 'Vaccination',
            );
          },
        ),

        // 6. Bird Sales (Blue)
        AppDesign.actionButton(
          icon: Icons.scale_rounded,
          label: 'Bird Sales',
          gradient: AppDesign.actionBlue,
          onTap: () {
            _openBatchFeature(
              batches,
              sheds,
              (batch) => BirdSalesScreen(
                farmId: _farm.id,
                batchId: batch.id,
                batchName: batch.batchName,
              ),
              featureName: 'Bird Sales',
            );
          },
        ),

        // 7. Performance (Dark Teal)
        AppDesign.actionButton(
          icon: Icons.bar_chart_rounded,
          label: 'Performance',
          gradient: AppDesign.actionDarkTeal,
          onTap: () {
            _openBatchFeature(
              batches,
              sheds,
              (batch) => BatchPerformanceScreen(
                farmId: _farm.id,
                batchId: batch.id,
                batchName: batch.batchName,
                batch: batch,
              ),
              featureName: 'Performance',
            );
          },
        ),

        // 8. Reports (Dark Red)
        AppDesign.actionButton(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Reports',
          gradient: AppDesign.actionDarkRed,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ReportsDashboardScreen(initialFarmId: _farm.id),
              ),
            );
          },
        ),
      ],
    );
  }
}

