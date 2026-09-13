import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
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
          'My Facilities',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'New Farm',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.farmSetup),
            ),
          ),
        ],
      ),
      body: farmsAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load farms',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please check connection and tap retry.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(farmListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (farms) {
          if (farms.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        size: 64,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Farms Created Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Register your first poultry farm or shed complex to begin managing flocks, telemetry, and inventory.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_business_rounded),
                      label: const Text(
                        'Create First Farm',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.farmSetup),
                    ),
                  ],
                ),
              ),
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

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
            children: [
              // Mild Overview Summary Card
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.agriculture_rounded,
                            color: Color(0xFF16A34A),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Facilities Overview',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${farms.length} Total',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MildBannerStat(
                            label: 'Capacity',
                            value: totalCapacity > 0
                                ? '${(totalCapacity / 1000).toStringAsFixed(1)}k'
                                : '${farms.fold<int>(0, (sum, f) => sum + (f.totalSqFt > 0 ? (f.totalSqFt / 1.2).round() : 0))}',
                            unit: 'birds',
                            icon: Icons.groups_rounded,
                            iconColor: const Color(0xFF16A34A),
                          ),
                        ),
                        Container(
                          height: 32,
                          width: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                        Expanded(
                          child: _MildBannerStat(
                            label: 'Flocks',
                            value: '$activeBatchesCount',
                            unit: 'active',
                            icon: Icons.pets_rounded,
                            iconColor: const Color(0xFF2563EB),
                          ),
                        ),
                        Container(
                          height: 32,
                          width: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                        Expanded(
                          child: _MildBannerStat(
                            label: 'Sheds',
                            value: '${allSheds.length}',
                            unit: 'total',
                            icon: Icons.warehouse_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
              const SizedBox(height: 14),

              // List of Farm Cards
              if (filteredFarms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No matching facilities found',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredFarms.map((farm) {
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
                      borderRadius: BorderRadius.circular(20),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          // Top card header with lush green gradient
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDashboardActive
                                    ? const [
                                        Color(0xFF15803D),
                                        Color(0xFF166534),
                                      ]
                                    : const [
                                        Color(0xFF16A34A),
                                        Color(0xFF15803D),
                                      ],
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    farm.farmName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (farm.farmType.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.22),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      farm.farmType,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (farm.isActive
                                            ? const Color(0xFF22C55E)
                                            : Colors.amber.shade700)
                                        .withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    farm.isActive ? 'Active' : 'Inactive',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (isDashboardActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      '★ ACTIVE',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // White card body
                          Material(
                            color: Colors.white,
                            child: InkWell(
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
                                    // Location row
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _locationFor(farm),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF334155),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Dimensions & Capacity row
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.straighten_rounded,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            farm.lengthFt > 0 &&
                                                    farm.widthFt > 0
                                                ? '${farm.lengthFt.toStringAsFixed(0)}×${farm.widthFt.toStringAsFixed(0)} ft • ${farm.totalSqFt.toStringAsFixed(0)} ft²'
                                                : (farm.totalSqFt > 0
                                                    ? '${farm.totalSqFt.toStringAsFixed(0)} ft²'
                                                    : 'Standard facility layout'),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Tags & Actions row
                                    Row(
                                      children: [
                                        if (farm.farmType.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              farm.farmType,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF15803D),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2FE),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            farm.flockType.isNotEmpty
                                                ? farm.flockType
                                                : 'Broiler',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0369A1),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            '$farmActiveBatches Flocks • $farmSheds Sheds',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (!isDashboardActive)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.radio_button_unchecked_rounded,
                                              size: 20,
                                              color: Color(0xFF16A34A),
                                            ),
                                            tooltip: 'Set as Dashboard Farm',
                                            onPressed: () =>
                                                _setActiveFarm(farm),
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
                                                child: Text(
                                                  'Set as Active Farm',
                                                ),
                                              ),
                                            const PopupMenuItem(
                                              value: 'command',
                                              child: Text('Command Center'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'batches',
                                              child: Text('View Batches'),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text(
                                                'Delete Farm',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Color(0xFF94A3B8),
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
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

class _MildBannerStat extends StatelessWidget {
  const _MildBannerStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$label ($unit)',
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
