import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/app_empty_state.dart';
import 'package:flock_sense/core/widgets/app_loading_indicator.dart';
import 'package:flock_sense/features/batches/presentation/screens/all_batches_screen.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_command_center_screen.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

class FarmListScreen extends ConsumerStatefulWidget {
  const FarmListScreen({super.key});

  @override
  ConsumerState<FarmListScreen> createState() => _FarmListScreenState();
}

class _FarmListScreenState extends ConsumerState<FarmListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteFarm(BuildContext context, FarmModel farm) async {
    final ok = await AppDialog.confirm(
      context: context,
      title: 'Delete farm?',
      message:
          'Permanently delete ${farm.farmName} and all associated batches, daily records, and sheds? This cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
    );
    if (!ok) return;

    try {
      await FarmService.deleteFarm(farm.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${farm.farmName} removed successfully'),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _setActiveFarm(FarmModel farm) async {
    try {
      await switchDashboardFarm(ref, farm.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Active dashboard facility: ${farm.farmName}'),
            ],
          ),
          backgroundColor: const Color(0xFF15803D),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set active farm: $e')),
      );
    }
  }

  String _locationFor(FarmModel farm) {
    final parts = <String>[];
    if (farm.areaName?.trim().isNotEmpty ?? false) {
      parts.add(farm.areaName!.trim());
    }
    if (farm.district?.trim().isNotEmpty ?? false) {
      parts.add(farm.district!.trim());
    }
    if (parts.isNotEmpty) return parts.join(', ');
    if (farm.address.trim().isNotEmpty) return farm.address.trim();
    return 'Location not added';
  }

  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(farmListProvider);
    final allBatches = ref.watch(allUserBatchesProvider).value ?? [];
    final allSheds = ref.watch(allUserShedsProvider).value ?? [];
    final dashboardData = ref.watch(homeDashboardDataProvider).value;
    final activeFarmId = dashboardData?.activeFarm?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Facilities & Sheds',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            tooltip: 'Add Facility',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.farmSetup),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Facility',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.farmSetup),
      ),
      body: farmsAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (err, _) => AppEmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Unable to load farms',
          message: 'Please check your connection and try again.',
          buttonLabel: 'Retry',
          onButtonPressed: () => ref.invalidate(farmListProvider),
        ),
        data: (farms) {
          if (farms.isEmpty) {
            return AppEmptyState(
              icon: Icons.holiday_village_outlined,
              title: 'No registered facilities yet',
              message:
                  'Create your first poultry farm or shed complex to begin managing flocks, telemetry, and inventory.',
              buttonLabel: 'Create Facility',
              onButtonPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.farmSetup),
            );
          }

          // Calculate Aggregates
          final totalCapacity = farms.fold<int>(
            0,
            (sum, f) =>
                sum +
                (f.capacity ??
                    (f.totalSqFt > 0 ? (f.totalSqFt / 1.2).round() : 0)),
          );
          final activeBatchesCount =
              allBatches.where((b) => b.isActive).length;

          // Filter farms
          final filteredFarms = farms.where((f) {
            // Search query
            if (_searchQuery.isNotEmpty) {
              final matchName = f.farmName.toLowerCase().contains(_searchQuery);
              final matchLoc = _locationFor(f).toLowerCase().contains(_searchQuery);
              final matchType = f.farmType.toLowerCase().contains(_searchQuery);
              if (!matchName && !matchLoc && !matchType) return false;
            }

            // Category filter
            if (_selectedFilter == 'All') return true;
            if (_selectedFilter == 'Active') return f.isActive;
            if (_selectedFilter == 'Inactive') return !f.isActive;
            if (_selectedFilter == 'Broiler') {
              return f.farmType.toLowerCase().contains('broiler') ||
                  f.flockType.toLowerCase().contains('broiler');
            }
            if (_selectedFilter == 'Layer') {
              return f.farmType.toLowerCase().contains('layer') ||
                  f.flockType.toLowerCase().contains('layer');
            }
            if (_selectedFilter == 'Breeder') {
              return f.farmType.toLowerCase().contains('breeder') ||
                  f.flockType.toLowerCase().contains('breeder');
            }
            return true;
          }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Executive Summary Banner
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF132E23),
                        Color(0xFF166534),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF166534).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: Color(0xFF4ADE80),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Facility Overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${farms.length} Total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _BannerMetric(
                              label: 'Total Capacity',
                              value: totalCapacity > 0
                                  ? '${(totalCapacity / 1000).toStringAsFixed(1)}k birds'
                                  : '${farms.fold<int>(0, (sum, f) => sum + (f.lengthFt * f.widthFt ~/ 1.2))} cap',
                              icon: Icons.groups_rounded,
                            ),
                          ),
                          Container(
                            height: 36,
                            width: 1,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          Expanded(
                            child: _BannerMetric(
                              label: 'Active Flocks',
                              value: '$activeBatchesCount batches',
                              icon: Icons.pets_rounded,
                            ),
                          ),
                          Container(
                            height: 36,
                            width: 1,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          Expanded(
                            child: _BannerMetric(
                              label: 'Total Sheds',
                              value: '${allSheds.length} sheds',
                              icon: Icons.warehouse_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Search & Filter Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by farm name, location, type...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('All'),
                            _filterChip('Active'),
                            _filterChip('Inactive'),
                            _filterChip('Broiler'),
                            _filterChip('Layer'),
                            _filterChip('Breeder'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Farms List
              if (filteredFarms.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No matching facilities found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try changing your search term or filter category.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final farm = filteredFarms[index];
                        final isDashboardActive = farm.id == activeFarmId;
                        final farmBatches = allBatches
                            .where((b) => b.farmId == farm.id)
                            .toList();
                        final farmActiveBatches =
                            farmBatches.where((b) => b.isActive).length;
                        final farmSheds =
                            allSheds.where((s) => s.farmId == farm.id).length;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDashboardActive
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFE2E8F0),
                              width: isDashboardActive ? 1.8 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDashboardActive
                                    ? const Color(0xFF16A34A).withOpacity(0.08)
                                    : Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FarmCommandCenterScreen(farm: farm),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header row: Farm Name, Badges & Menu
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isDashboardActive
                                                ? const Color(0xFFDCFCE7)
                                                : const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.warehouse_rounded,
                                            size: 18,
                                            color: isDashboardActive
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      farm.farmName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            Color(0xFF0F172A),
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isDashboardActive) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF16A34A,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          20,
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'ACTIVE',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _locationFor(farm),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert_rounded,
                                            size: 18,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          onSelected: (val) {
                                            if (val == 'active') {
                                              _setActiveFarm(farm);
                                            } else if (val == 'command') {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      FarmCommandCenterScreen(
                                                    farm: farm,
                                                  ),
                                                ),
                                              );
                                            } else if (val == 'batches') {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const AllBatchesScreen(),
                                                ),
                                              );
                                            } else if (val == 'delete') {
                                              _deleteFarm(context, farm);
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            if (!isDashboardActive)
                                              const PopupMenuItem(
                                                value: 'active',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.radio_button_checked,
                                                      size: 16,
                                                      color: Color(0xFF16A34A),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Set as Dashboard Farm'),
                                                  ],
                                                ),
                                              ),
                                            const PopupMenuItem(
                                              value: 'command',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.tune_rounded,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Command Center'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'batches',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.pets_rounded,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('View Batches'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete_outline_rounded,
                                                    size: 16,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Delete Facility',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Metric Pills Row (4 KPIs)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _CardMetricPill(
                                            title: 'Capacity',
                                            value: (farm.capacity != null &&
                                                    farm.capacity! > 0)
                                                ? '${farm.capacity}'
                                                : '${(farm.totalSqFt / 1.2).toStringAsFixed(0)}',
                                            unit: 'birds',
                                            color: const Color(0xFF16A34A),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _CardMetricPill(
                                            title: 'Batches',
                                            value: '$farmActiveBatches',
                                            unit: 'active',
                                            color: const Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _CardMetricPill(
                                            title: 'Sheds',
                                            value: '$farmSheds',
                                            unit: 'total',
                                            color: const Color(0xFF6366F1),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _CardMetricPill(
                                            title: 'Area',
                                            value:
                                                farm.totalSqFt.toStringAsFixed(0),
                                            unit: 'sq ft',
                                            color: const Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Action Bar
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${farm.farmType} • ${farm.flockType.isNotEmpty ? farm.flockType : "Broiler"}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (!isDashboardActive)
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              foregroundColor:
                                                  const Color(0xFF16A34A),
                                            ),
                                            onPressed: () =>
                                                _setActiveFarm(farm),
                                            icon: const Icon(
                                              Icons.check_circle_outline_rounded,
                                              size: 15,
                                            ),
                                            label: const Text(
                                              'Set Active',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF0F172A),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    FarmCommandCenterScreen(
                                                  farm: farm,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.tune_rounded,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            'Command Center',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filteredFarms.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedFilter = label),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF16A34A),
        showCheckmark: false,
        side: BorderSide(
          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }
}

class _BannerMetric extends StatelessWidget {
  const _BannerMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4ADE80)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CardMetricPill extends StatelessWidget {
  const _CardMetricPill({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String title;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
