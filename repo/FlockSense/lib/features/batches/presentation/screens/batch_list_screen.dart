import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/providers/batch_providers.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';

class BatchListScreen extends ConsumerStatefulWidget {
  const BatchListScreen({
    super.key,
    required this.farmId,
    this.farmName,
    this.shedId,
  });
  final String farmId;
  final String? farmName;
  final String? shedId;

  @override
  ConsumerState<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends ConsumerState<BatchListScreen> {
  String _searchQuery = '';
  String? _selectedStatusFilter; // null = all, 'active', 'completed'
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
          'Are you sure you want to delete "${batch.batchName}" and all associated daily records? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    try {
      await BatchService.deleteBatch(widget.farmId, batch.id);
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

  void _openForm(BuildContext ctx) => Navigator.push(
    ctx,
    MaterialPageRoute(
      builder: (_) => BatchFormScreen(farmId: widget.farmId, shedId: widget.shedId),
    ),
  );

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

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchListProvider(widget.farmId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.farmName != null ? '${widget.farmName} — Batches' : 'Batches',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: batchesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        data: (batches) {
          if (batches.isEmpty) {
            return _EmptyState(onAdd: () => _openForm(context));
          }

          final activeCount = batches.where((b) => b.isActive).length;
          final completedCount = batches.where((b) => !b.isActive).length;

          final filtered = batches.where((b) {
            final matchesQuery = _searchQuery.isEmpty ||
                b.batchName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                b.breedOrFlockType.toLowerCase().contains(_searchQuery.toLowerCase());

            final matchesStatus = _selectedStatusFilter == null ||
                (_selectedStatusFilter == 'active' && b.isActive) ||
                (_selectedStatusFilter == 'completed' && !b.isActive);

            return matchesQuery && matchesStatus;
          }).toList();

          return Column(
            children: [
              // Search & Filter header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search batch name or breed...',
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All (${batches.length})', null),
                          const SizedBox(width: 8),
                          _buildFilterChip('Active ($activeCount)', 'active'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Completed ($completedCount)', 'completed'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filtered List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.filter_list_off_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No batches match "$_searchQuery"'
                                    : 'No ${_selectedStatusFilter ?? ''} batches found',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _BatchCard(
                          batch: filtered[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BatchCommandCenterScreen(
                                farmId: widget.farmId,
                                batchId: filtered[i].id,
                                batchName: filtered[i].batchName,
                              ),
                            ),
                          ),
                          onDelete: () => _deleteBatch(context, filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Batch',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.batch,
    required this.onTap,
    this.onDelete,
  });
  final BatchModel batch;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  int get _age => DateTime.now().difference(batch.placementDate).inDays;
  bool get _isActive => batch.status == 'active';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                gradient: _isActive
                    ? AppColors.primaryGradient
                    : const LinearGradient(
                        colors: [Color(0xFF607D8B), Color(0xFF78909C)],
                      ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.egg_alt_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.batchName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Placed ${batch.placementDate.day}/${batch.placementDate.month}/${batch.placementDate.year}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Pill(
                    _isActive ? 'Day $_age' : 'Completed',
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white,
                  ),
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (val) {
                        if (val == 'delete') onDelete?.call();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.danger,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete Batch',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _Stat(
                    '${batch.currentBirds}',
                    'Live Birds',
                    Icons.pets,
                    AppColors.primary,
                  ),
                  _vDivider(),
                  _Stat(
                    batch.breedOrFlockType,
                    'Breed',
                    Icons.egg_outlined,
                    AppColors.gold,
                  ),
                  _vDivider(),
                  _Stat(
                    '${batch.maleCount}M / ${batch.femaleCount}F',
                    'Split',
                    Icons.people_outline,
                    AppColors.ocean,
                  ),
                  _vDivider(),
                  _Pill(
                    _isActive ? 'Active' : 'Completed',
                    _isActive ? AppColors.emeraldLight : AppColors.surfaceSoft,
                    _isActive ? AppColors.emerald : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 0.5,
    height: 36,
    color: AppColors.border,
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.icon, this.color);
  final String value, label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
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

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.bg, this.fg);
  final String text;
  final Color bg, fg;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No batches yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Place your first batch to begin tracking.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Place Batch'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ],
    ),
  );
}
