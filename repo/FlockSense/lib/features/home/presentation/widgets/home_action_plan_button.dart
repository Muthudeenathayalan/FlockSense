import 'package:flutter/material.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/flock_plan/data/flock_plan_service.dart';
import 'package:flock_sense/features/flock_plan/domain/daily_plan_model.dart';
import 'package:flock_sense/features/flock_plan/presentation/screens/flock_plan_screen.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';

/// Simple, neat compact pill button for Today's Action Plan on the Home Dashboard.
/// Auto-sizes to content rather than stretching full-width horizontally.
class HomeActionPlanButton extends StatefulWidget {
  const HomeActionPlanButton({
    super.key,
    required this.batch,
    required this.farmId,
    required this.farmName,
  });

  final BatchModel batch;
  final String farmId;
  final String farmName;

  @override
  State<HomeActionPlanButton> createState() => _HomeActionPlanButtonState();
}

class _HomeActionPlanButtonState extends State<HomeActionPlanButton> {
  DailyFlockPlan? _plan;

  @override
  void initState() {
    super.initState();
    final age = FlockPlanService.getFlockAge(widget.batch);
    _plan = FlockPlanService.getStandardPlanForDay(batch: widget.batch, day: age);
    _fetchLivePlan();
  }

  @override
  void didUpdateWidget(covariant HomeActionPlanButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.batch.id != widget.batch.id ||
        oldWidget.batch.currentBirds != widget.batch.currentBirds) {
      _fetchLivePlan();
    }
  }

  Future<void> _fetchLivePlan() async {
    try {
      final plan = await FlockPlanService.getTodayPlan(
        farmId: widget.farmId,
        batch: widget.batch,
      );
      if (mounted) {
        setState(() => _plan = plan);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final age = FlockPlanService.getFlockAge(widget.batch);
    final plan = _plan;
    final completedCount = plan?.tasks.where((t) => t.isCompleted).length ?? 0;
    final totalCount = plan?.tasks.length ?? 0;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlockPlanScreen(
                  batch: widget.batch,
                  farmId: widget.farmId,
                ),
              ),
            ).then((_) => _fetchLivePlan());
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD1FAE5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: HomeTokens.primaryDark.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4.5),
                  decoration: BoxDecoration(
                    color: HomeTokens.greenTint,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: HomeTokens.primary,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Today's Action Plan",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: HomeTokens.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: HomeTokens.greenTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    totalCount > 0 ? 'Day $age • $completedCount/$totalCount' : 'Day $age',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: HomeTokens.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'View Plan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: HomeTokens.primary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 9,
                  color: HomeTokens.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
