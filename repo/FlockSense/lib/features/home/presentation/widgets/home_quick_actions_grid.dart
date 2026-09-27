import 'package:flutter/material.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import 'package:flock_sense/features/reports/presentation/screens/reports_dashboard_screen.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_section_header.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';

/// 4-Tile Quick Operations launcher for fast, one-tap data logging.
class HomeQuickActionsGrid extends StatelessWidget {
  const HomeQuickActionsGrid({
    super.key,
    required this.activeBatches,
  });

  final List<BatchModel> activeBatches;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'Quick Operations',
          subtitle: 'One-tap operational logging and reports',
        ),
        const SizedBox(height: HomeTokens.gapHeaderToBody),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.edit_note_rounded,
                label: 'Daily Log',
                color: HomeTokens.primary,
                bg: HomeTokens.greenTint,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DailyRecordsDashboardScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: HomeTokens.gapTight),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.grass_rounded,
                label: 'Feed Stock',
                color: HomeTokens.sky,
                bg: HomeTokens.blueTint,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InventoryDashboardScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: HomeTokens.gapTight),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.vaccines_rounded,
                label: 'Vaccine',
                color: HomeTokens.amber,
                bg: HomeTokens.amberTint,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => activeBatches.isNotEmpty
                        ? VaccineRecordsScreen(
                            farmId: activeBatches.first.farmId,
                            batchId: activeBatches.first.id,
                            batchName: activeBatches.first.batchName,
                          )
                        : const VaccineRecordsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: HomeTokens.gapTight),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Reports',
                color: HomeTokens.indigo,
                bg: HomeTokens.indigoTint,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportsDashboardScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: HomeTokens.surface,
            borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
            border: Border.all(color: HomeTokens.border, width: 1),
            boxShadow: HomeTokens.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: HomeTokens.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
