import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/app_empty_state.dart';
import 'package:flock_sense/core/widgets/app_loading_indicator.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_setup_screen.dart';

/// Flocks & Batches screen displaying all batches across farms,
/// showing each batch clearly along with its associated farm name.
class AllBatchesScreen extends ConsumerStatefulWidget {
  const AllBatchesScreen({super.key});

  @override
  ConsumerState<AllBatchesScreen> createState() => _AllBatchesScreenState();
}

class _AllBatchesScreenState extends ConsumerState<AllBatchesScreen> {
  String _searchQuery = '';
  String? _selectedStatusFilter; // null = all, 'active', 'completed'
  String? _selectedFarmId; // null = all farms
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteBatch(BuildContext context, BatchModel batch) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete Batch',
      message:
          'Are you sure you want to permanently delete "${batch.batchName}" and all associated records? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    try {
      await BatchService.deleteBatch(batch.farmId, batch.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch "${batch.batchName}" deleted'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete batch: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _onAddBatch(List<FarmModel> farms) {
    if (farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please create a farm first before adding a batch.'),
          action: SnackBarAction(
            label: 'Create Farm',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FarmSetupScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    if (farms.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BatchFormScreen(farmId: farms.first.id),
        ),
      );
      return;
    }

    // Multiple farms: prompt user to pick farm
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Farm for New Batch',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: farms.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final f = farms[i];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.agriculture_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          f.farmName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          f.areaName?.isNotEmpty == true
                              ? f.areaName!
                              : (f.address.isNotEmpty ? f.address : 'Farm'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BatchFormScreen(farmId: f.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(allUserBatchesProvider);
    final farmsAsync = ref.watch(farmListProvider);

    final farms = farmsAsync.valueOrNull ?? [];
    final farmMap = {for (final f in farms) f.id: f.farmName};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Flocks & Batches',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(allUserBatchesProvider);
              ref.invalidate(farmListProvider);
            },
          ),
        ],
      ),
      body: batchesAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (err, _) => AppEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Unable to load batches',
          message: err.toString(),
          buttonLabel: 'Retry',
          onButtonPressed: () => ref.invalidate(allUserBatchesProvider),
        ),
        data: (allBatches) {
          // Filter by search query
          var filtered = allBatches.where((b) {
            final fName = farmMap[b.farmId] ?? '';
            final matchesQuery = _searchQuery.isEmpty ||
                b.batchName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                b.breedOrFlockType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                fName.toLowerCase().contains(_searchQuery.toLowerCase());

            final matchesStatus = _selectedStatusFilter == null ||
                (_selectedStatusFilter == 'active' && b.isActive) ||
                (_selectedStatusFilter == 'completed' && !b.isActive);

            final matchesFarm = _selectedFarmId == null || b.farmId == _selectedFarmId;

            return matchesQuery && matchesStatus && matchesFarm;
          }).toList();

          return Column(
            children: [
              // Search and Filter Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    // Search box
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search batch or farm name...',
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                    const SizedBox(height: 10),

                    // Filter chips row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', null),
                          const SizedBox(width: 8),
                          _buildFilterChip('Active', 'active'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Closed', 'completed'),
                          if (farms.length > 1) ...[
                            const SizedBox(width: 12),
                            Container(width: 1, height: 20, color: AppColors.border),
                            const SizedBox(width: 12),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedFarmId,
                                hint: const Text(
                                  'All Farms',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                icon: const Icon(Icons.arrow_drop_down, size: 18),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('All Farms'),
                                  ),
                                  ...farms.map(
                                    (f) => DropdownMenuItem<String?>(
                                      value: f.id,
                                      child: Text(f.farmName),
                                    ),
                                  ),
                                ],
                                onChanged: (val) => setState(() => _selectedFarmId = val),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // List of Batches
              Expanded(
                child: filtered.isEmpty
                    ? AppEmptyState(
                        icon: Icons.pets_outlined,
                        title: allBatches.isEmpty ? 'No batches yet' : 'No matching batches',
                        message: allBatches.isEmpty
                            ? 'Place your first flock or batch to begin tracking daily records.'
                            : 'Try adjusting your search or filters.',
                        buttonLabel: allBatches.isEmpty ? 'Place Batch' : null,
                        onButtonPressed: allBatches.isEmpty ? () => _onAddBatch(farms) : null,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final batch = filtered[i];
                          final farmName = farmMap[batch.farmId] ?? 'Farm';
                          return _AllBatchesCard(
                            batch: batch,
                            farmName: farmName,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BatchCommandCenterScreen(
                                    farmId: batch.farmId,
                                    batchId: batch.id,
                                    batchName: batch.batchName,
                                  ),
                                ),
                              );
                            },
                            onDelete: () => _deleteBatch(context, batch),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddBatch(farms),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Place Batch',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? statusValue) {
    final isSelected = _selectedStatusFilter == statusValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatusFilter = statusValue),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _AllBatchesCard extends StatelessWidget {
  const _AllBatchesCard({
    required this.batch,
    required this.farmName,
    required this.onTap,
    required this.onDelete,
  });

  final BatchModel batch;
  final String farmName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  int get _age => DateTime.now().difference(batch.placementDate).inDays;
  bool get _isActive => batch.status.toLowerCase() == 'active';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Card Header with Gradient
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                gradient: _isActive
                    ? AppDesign.actionGreen
                    : const LinearGradient(
                        colors: [Color(0xFF64748B), Color(0xFF475569)],
                      ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Batch Name & Farm Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.batchName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // Prominently displays the farm name!
                        Row(
                          children: [
                            const Icon(
                              Icons.agriculture_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                farmName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Age chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Day $_age',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Popup menu for delete
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    onSelected: (val) {
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Delete Batch',
                              style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card Body Metrics
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  _buildMetric(
                    'Live Birds',
                    '${batch.currentBirds > 0 ? batch.currentBirds : batch.totalBirds}',
                    Icons.pets_outlined,
                    AppColors.primary,
                  ),
                  _buildDivider(),
                  _buildMetric(
                    'Placed',
                    '${batch.totalBirds}',
                    Icons.inventory_2_outlined,
                    AppColors.gold,
                  ),
                  _buildDivider(),
                  _buildMetric(
                    'Breed',
                    batch.breedOrFlockType.isNotEmpty ? batch.breedOrFlockType : 'Broiler',
                    Icons.egg_outlined,
                    AppColors.ocean,
                  ),
                  _buildDivider(),
                  _buildStatusBadge(_isActive),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 0.5,
      height: 32,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? AppColors.emeraldLight : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isActive ? 'Active' : 'Closed',
        style: TextStyle(
          color: isActive ? AppColors.emerald : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
