import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_list_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_active_batches_section.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_identity_header.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_operational_summary.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_specs_card.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_status_control_card.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_records_screen.dart';
import 'package:flock_sense/features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import 'package:flock_sense/features/medicine/presentation/screens/medicine_records_screen.dart';
import 'package:flock_sense/features/reports/presentation/screens/reports_dashboard_screen.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';

const Color _kPrimary = Color(0xFF16A34A);
const Color _kBackground = Color(0xFFF8FAFC);
const Color _kTextSecondary = Color(0xFF64748B);

/// Dedicated Farm Command Center & Management Screen.
/// Composes modular sub-widgets for identity, summary, actions, batches, and specs.
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

  @override
  void initState() {
    super.initState();
    _farm = widget.farm;
  }

  Future<void> _deleteFarm() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete Farm',
      message:
          'Are you sure you want to permanently delete "${_farm.farmName}"? All associated data will also be deleted. This cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          FarmIdentityHeader(
            farm: _farm,
            onFarmUpdated: (updated) => setState(() => _farm = updated),
            onDeleteFarm: _deleteFarm,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // 1. Operational Summary Strip (3 Cards)
                  FarmOperationalSummary(farm: _farm),

                  const SizedBox(height: 20),

                  // 2. Quick Actions Grid (8 Actions in 2 Rows)
                  _buildQuickActionsGrid(_farm),

                  const SizedBox(height: 24),

                  // 3. Active Batches Section
                  FarmActiveBatchesSection(farm: _farm),

                  const SizedBox(height: 24),

                  // 4. Farm Specifications Card
                  FarmSpecsCard(farm: _farm),

                  const SizedBox(height: 20),

                  // 5. Farm Status Control Toggle Card
                  FarmStatusControlCard(
                    farm: _farm,
                    isToggling: _isTogglingStatus,
                    onToggle: _toggleFarmStatus,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BatchFormScreen(farmId: _farm.id),
            ),
          );
        },
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Add Batch',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(FarmModel farm) {
    return Container(
      decoration: AppDesign.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kTextSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 1: Daily Log, Add Batch, All Batches, Feed Log
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppDesign.actionButton(
                icon: Icons.edit_calendar_rounded,
                label: 'Daily Log',
                gradient: AppDesign.actionGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DailyRecordsDashboardScreen(initialFarmId: farm.id),
                    ),
                  );
                },
              ),
              AppDesign.actionButton(
                icon: Icons.add_circle_outline_rounded,
                label: 'Add Batch',
                gradient: AppDesign.actionTeal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BatchFormScreen(farmId: farm.id),
                    ),
                  );
                },
              ),
              AppDesign.actionButton(
                icon: Icons.layers_rounded,
                label: 'All Batches',
                gradient: AppDesign.actionDarkTeal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BatchListScreen(
                        farmId: farm.id,
                        farmName: farm.farmName,
                      ),
                    ),
                  );
                },
              ),
              AppDesign.actionButton(
                icon: Icons.restaurant_rounded,
                label: 'Feed Log',
                gradient: AppDesign.actionGold,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedRecordsScreen(
                        farmId: farm.id,
                        batchId: '',
                        batchName: 'Farm Feed',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Medicine, Vaccines, Inventory, Reports
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppDesign.actionButton(
                icon: Icons.medication_liquid_rounded,
                label: 'Medicine',
                gradient: AppDesign.actionDarkTeal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicineRecordsScreen(
                        farmId: farm.id,
                        batchId: '',
                        batchName: 'Farm Medicine',
                      ),
                    ),
                  );
                },
              ),
              AppDesign.actionButton(
                icon: Icons.vaccines_rounded,
                label: 'Vaccines',
                gradient: AppDesign.actionTeal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VaccineRecordsScreen(
                        farmId: farm.id,
                        batchId: '',
                        batchName: 'Farm Vaccines',
                      ),
                    ),
                  );
                },
              ),
              AppDesign.actionButton(
                icon: Icons.inventory_2_rounded,
                label: 'Inventory',
                gradient: AppDesign.actionGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventoryDashboardScreen(),
                    ),
                  );
                },
              ),
              AppDesign.actionButton(
                icon: Icons.bar_chart_rounded,
                label: 'Reports',
                gradient: AppDesign.actionDarkRed,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportsDashboardScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
