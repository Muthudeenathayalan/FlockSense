import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/app_loading_indicator.dart';
import 'package:flock_sense/core/widgets/hen_icon.dart';
import 'package:flock_sense/features/batches/presentation/screens/all_batches_screen.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_command_center_screen.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_setup_screen.dart';
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
      final text = _searchController.text.trim().toLowerCase();
      if (_searchQuery != text) {
        setState(() {
          _searchQuery = text;
        });
      }
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
          'Permanently delete "${farm.farmName}" and all associated batches, daily records, and sheds? This cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
    );
    if (!ok) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await FarmService.deleteFarm(farm.id);
      if (!mounted || messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${farm.farmName} removed successfully'),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted || messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
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
              Expanded(
                child: Text(
                  '${farm.farmName} is now the active facility',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF104422),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set active farm: $e'),
          behavior: SnackBarBehavior.floating,
        ),
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
    return 'Location not set';
  }

  @override
  Widget build(BuildContext context) {
    try {
      // 1. Resilient data access: Fallback to dashboard cache so UI renders instantly
      final farmsAsync = ref.watch(farmListProvider);
      final dashboardData = ref.watch(homeDashboardDataProvider).value;
      final allBatches = ref.watch(allUserBatchesProvider).value ?? const [];
      final allSheds = ref.watch(allUserShedsProvider).value ?? const [];

      final List<FarmModel> rawFarms = farmsAsync.value ??
          dashboardData?.farms ??
          const <FarmModel>[];

      final bool isInitialLoading = farmsAsync.isLoading && rawFarms.isEmpty;
      final activeFarmId = dashboardData?.activeFarm?.id ??
          (rawFarms.isNotEmpty ? rawFarms.first.id : null);

      // Compute metrics
      final totalActiveBatches = allBatches.where((b) => b.isActive).length;
      final totalShedsCount = allSheds.length;
      final activeFarmsCount = rawFarms.where((f) => f.isActive).length;

      // Filter farms
      final filteredFarms = rawFarms.where((f) {
        if (_searchQuery.isNotEmpty) {
          final matchName = f.farmName.toLowerCase().contains(_searchQuery);
          final matchLoc = _locationFor(f).toLowerCase().contains(_searchQuery);
          final matchType = f.farmType.toLowerCase().contains(_searchQuery);
          final matchFlock = f.flockType.toLowerCase().contains(_searchQuery);
          if (!matchName && !matchLoc && !matchType && !matchFlock) {
            return false;
          }
        }

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
        if (_selectedFilter == 'EC') {
          return f.farmType.toLowerCase().contains('ec');
        }
        if (_selectedFilter == 'Open') {
          return f.farmType.toLowerCase().contains('open');
        }
        return true;
      }).toList();

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Farms & Facilities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  height: 34,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF104422),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'New Farm',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.farmSetup),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: const Color(0xFF104422),
          onRefresh: () async {
            ref.invalidate(farmListProvider);
            ref.invalidate(allUserBatchesProvider);
            ref.invalidate(allUserShedsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Quick Operations Metric Banner (Hero Stat Strip)
              _buildOverviewStats(
                totalFarms: rawFarms.length,
                activeFarms: activeFarmsCount,
                totalBatches: totalActiveBatches,
                totalSheds: totalShedsCount,
              ),
              const SizedBox(height: 16),

              // Modern Search Input
              _buildSearchBar(),
              const SizedBox(height: 12),

              // Filter Chips Bar
              _buildFilterChips(),
              const SizedBox(height: 16),

              // Content Section
              if (isInitialLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: AppLoadingIndicator(message: 'Loading facilities...'),
                )
              else if (rawFarms.isEmpty)
                _buildEmptyState(context)
              else if (filteredFarms.isEmpty)
                _buildNoSearchResults()
              else
                ...filteredFarms.map((farm) {
                  final isDashboardActive = farm.id == activeFarmId;
                  final farmBatches =
                      allBatches.where((b) => b.farmId == farm.id).toList();
                  final farmActiveBatches =
                      farmBatches.where((b) => b.isActive).length;
                  final farmSheds =
                      allSheds.where((s) => s.farmId == farm.id).length;

                  return _buildFarmCard(
                    context: context,
                    farm: farm,
                    isDashboardActive: isDashboardActive,
                    activeBatchesCount: farmActiveBatches,
                    shedsCount: farmSheds,
                  );
                }),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      return Scaffold(
        appBar: AppBar(title: const Text('Farm Screen Error')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText('Exception in FarmListScreen: $e\n\nStack:\n$stack'),
        ),
      );
    }
  }

  // --- Macro Operations Overview Banner ---
  Widget _buildOverviewStats({
    required int totalFarms,
    required int activeFarms,
    required int totalBatches,
    required int totalSheds,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _statItem(
            label: 'Facilities',
            value: '$activeFarms / $totalFarms',
            icon: Icons.business_rounded,
            iconColor: const Color(0xFF104422),
            iconBg: const Color(0xFFDCFCE7),
          ),
          _divider(),
          _statItem(
            label: 'Active Flocks',
            value: '$totalBatches',
            icon: Icons.layers_rounded,
            iconColor: const Color(0xFF0284C7),
            iconBg: const Color(0xFFF0F7FF),
          ),
          _divider(),
          _statItem(
            label: 'Total Sheds',
            value: '$totalSheds',
            icon: Icons.warehouse_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFFFBEB),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 34,
      color: const Color(0xFFF1F5F9),
    );
  }

  // --- Modern Search Bar ---
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search facility, district, or type...',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: Color(0xFF104422),
              size: 22,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // --- Filter Chips Bar ---
  Widget _buildFilterChips() {
    const filterOptions = [
      'All',
      'Active',
      'Inactive',
      'Broiler',
      'Layer',
      'EC',
      'Open',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filterOptions.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF104422),
              showCheckmark: false,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF104422)
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 1.4 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Farm Card Redesign ---
  Widget _buildFarmCard({
    required BuildContext context,
    required FarmModel farm,
    required bool isDashboardActive,
    required int activeBatchesCount,
    required int shedsCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDashboardActive
              ? const Color(0xFF104422)
              : const Color(0xFFE2E8F0),
          width: isDashboardActive ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDashboardActive
                ? const Color(0x18104422)
                : const Color(0x0A0F172A),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FarmCommandCenterScreen(farm: farm),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Identity Row: Hen Avatar + Names + Active Badge + Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Squircle Hen Avatar
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isDashboardActive
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDashboardActive
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: HenIcon(
                        size: 26,
                        color: isDashboardActive
                            ? const Color(0xFF104422)
                            : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Farm Name & Location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  farm.farmName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDashboardActive) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFBBF7D0),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 11,
                                        color: Color(0xFF15803D),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  _locationFor(farm),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
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

                    // Actions Menu
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (val) {
                        if (val == 'active') {
                          _setActiveFarm(farm);
                        } else if (val == 'command') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FarmCommandCenterScreen(farm: farm),
                            ),
                          );
                        } else if (val == 'batches') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AllBatchesScreen(),
                            ),
                          );
                        } else if (val == 'edit') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FarmSetupScreen(initialFarm: farm),
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
                                Icon(Icons.star_rounded,
                                    size: 18, color: Color(0xFF16A34A)),
                                SizedBox(width: 8),
                                Text('Set as Active Facility'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'command',
                          child: Row(
                            children: [
                              Icon(Icons.dashboard_customize_rounded,
                                  size: 18, color: Color(0xFF0F172A)),
                              SizedBox(width: 8),
                              Text('Command Center'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'batches',
                          child: Row(
                            children: [
                              Icon(Icons.layers_rounded,
                                  size: 18, color: Color(0xFF0F172A)),
                              SizedBox(width: 8),
                              Text('View Batches'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 18, color: Color(0xFF0F172A)),
                              SizedBox(width: 8),
                              Text('Edit Facility'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete Farm',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Operational KPI 3-Column Grid
                Row(
                  children: [
                    // Active Batches Tile
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.layers_rounded,
                                    size: 13, color: Color(0xFF0284C7)),
                                SizedBox(width: 4),
                                Text(
                                  'Flocks',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$activeBatchesCount Active',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0C4A6E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sheds Tile
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warehouse_rounded,
                                    size: 13, color: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text(
                                  'Sheds',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$shedsCount Configured',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF14532D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Capacity / Area Tile
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.aspect_ratio_rounded,
                                    size: 13, color: Color(0xFFD97706)),
                                SizedBox(width: 4),
                                Text(
                                  'Capacity',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              farm.capacity != null && farm.capacity! > 0
                                  ? '${farm.capacity} birds'
                                  : (farm.totalSqFt > 0
                                      ? '${farm.totalSqFt.toInt()} ft²'
                                      : 'Not set'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF78350F),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tags & Specs Ribbon (Type, Dimensions)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (farm.farmType.isNotEmpty || farm.flockType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              farm.farmType.toLowerCase().contains('ec')
                                  ? Icons.bolt_rounded
                                  : Icons.wb_sunny_outlined,
                              size: 12,
                              color: const Color(0xFF475569),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              farm.farmType.isNotEmpty
                                  ? farm.farmType
                                  : farm.flockType,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (farm.lengthFt > 0 && farm.widthFt > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '${farm.lengthFt.toInt()}×${farm.widthFt.toInt()} ft • ${farm.totalSqFt.toInt()} ft²',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    if (farm.farmerName != null &&
                        farm.farmerName!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              farm.farmerName!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Card Bottom Action Bar
                Row(
                  children: [
                    // Set as active button if not active
                    if (!isDashboardActive) ...[
                      InkWell(
                        onTap: () => _setActiveFarm(farm),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_border_rounded,
                                size: 15,
                                color: Color(0xFF16A34A),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Make Active',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Command Center Primary Action Button
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF104422),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FarmCommandCenterScreen(farm: farm),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.dashboard_customize_rounded, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Command Center',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, size: 16),
                          ],
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
  }

  // --- Empty Search Results ---
  Widget _buildNoSearchResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No facilities match your search',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try clearing filters or searching another keyword',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _selectedFilter = 'All');
              },
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Full Empty State (No Farms Created) ---
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const HenIcon(
                size: 56,
                color: Color(0xFF104422),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Farms Registered Yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register your first poultry farm to manage sheds, flocks, telemetry, and automated record-keeping.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF104422),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Register First Farm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.farmSetup),
            ),
          ],
        ),
      ),
    );
  }
}
