import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_command_center_screen.dart';

class FarmListScreen extends ConsumerWidget {
  const FarmListScreen({super.key});

  // FIX — SET ACTIVE: was calling Navigator.pop(context, farmId) which
  // returned to whatever screen was below in the stack — often a blank/black
  // page when FarmListScreen lives inside IndexedStack (main shell). Now we
  // just show a success snackbar and stay on the same screen. The
  // farmListProvider stream is live, so if any UI depends on the active farm
  // it will rebuild automatically.
  Future<void> _setActive(BuildContext ctx, FarmModel farm) async {
    try {
      await FarmService.setActiveFarm(farm.id);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('"${farm.farmName}" is now your active farm'),
          ]),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (ctx.mounted) _snackErr(ctx, 'Could not set active farm: $e');
    }
  }

  // FIX — CASCADE DELETE: shows a strong confirmation dialog, then calls
  // the updated FarmService.deleteFarm which batch-deletes sheds first and
  // uses a WriteBatch (not a transaction) so deletion is instant in the UI
  // even on a slow connection.
  Future<void> _delete(BuildContext ctx, FarmModel farm) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete farm?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('You are about to permanently delete:', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          _bullet('Farm: ${farm.farmName}'),
          _bullet('All sheds inside this farm'),
          _bullet('All data associated with it'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('This action cannot be undone.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13))),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );

    if (ok != true || !ctx.mounted) return;

    // Show a loading indicator while deleting.
    final snack = ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
      content: Row(children: [
        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        SizedBox(width: 12),
        Text('Deleting farm and all its data…'),
      ]),
      duration: Duration(seconds: 30),
    ));

    try {
      await FarmService.deleteFarm(farm.id);
      snack.close();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('"${farm.farmName}" deleted successfully'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      snack.close();
      if (ctx.mounted) _snackErr(ctx, 'Delete failed: $e');
    }
  }

  void _snackErr(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ]),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(farmListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Farms'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.farmSetup),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Farm'),
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: farmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: '$e'),
        data: (farms) {
          if (farms.isEmpty) return _EmptyState(onAdd: () => Navigator.pushNamed(context, AppRoutes.farmSetup));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: farms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _PremiumFarmCard(
              farm: farms[i],
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => FarmCommandCenterScreen(farm: farms[i]))),
              onSetActive: () => _setActive(context, farms[i]),
              onEdit: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit farm feature coming soon'))),
              onDelete: () => _delete(context, farms[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.farmSetup),
        icon: const Icon(Icons.add),
        label: const Text('Add Farm', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}

// ── Premium Farm Card ───────────────────────────────────────────────────────

class _PremiumFarmCard extends StatelessWidget {
  const _PremiumFarmCard({
    required this.farm,
    required this.onTap,
    required this.onSetActive,
    required this.onEdit,
    required this.onDelete,
  });

  final FarmModel farm;
  final VoidCallback onTap, onSetActive, onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final location = farm.location?.isNotEmpty ?? false ? farm.location! : farm.address;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border, width: 0.8),
            boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Gradient header ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.agriculture, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(farm.farmName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800,
                                fontSize: 17, letterSpacing: -0.2),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(farm.farmType, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                      ]),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.9)),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (v) {
                        if (v == 'active') onSetActive();
                        if (v == 'edit') onEdit();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        _menuItem('active', Icons.check_circle_outline, 'Set as active', Colors.teal),
                        _menuItem('edit', Icons.edit_outlined, 'Edit farm', AppColors.primary),
                        _menuItem('delete', Icons.delete_outline, 'Delete farm', Colors.red),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location row — FARM location, not user's GPS location
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Expanded(child: Text(location,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),



                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 14),

                    // Stats row
                    Row(children: [
                      _statChip(Icons.eco_outlined, farm.flockType, Colors.teal),
                      const Spacer(),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.circle, size: 8, color: Colors.green.shade600),
                          const SizedBox(width: 5),
                          Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
                        ]),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  PopupMenuItem<String> _menuItem(String v, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: v,
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(28)),
            child: const Icon(Icons.agriculture, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 28),
          const Text('No farms yet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          const Text('Create your first farm to start tracking your flock — sheds, batches, daily records and more.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Create your first farm')),
        ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Error: $message', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
    ));
  }
}
