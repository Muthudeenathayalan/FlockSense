import 'package:flutter/material.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/flock_plan/data/flock_plan_service.dart';
import 'package:flock_sense/features/flock_plan/domain/daily_plan_model.dart';
import 'package:flock_sense/features/flock_plan/presentation/screens/flock_plan_screen.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';

/// Compact, elegant button for Today's Action Plan on the Home Dashboard.
/// Replaces the massive embedded 450px card to keep the home screen compact and neat,
/// while providing immediate 1-tap navigation to the full FlockPlanScreen.
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

    return Material(
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
        borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
            border: Border.all(color: const Color(0xFFD1FAE5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: HomeTokens.primaryDark.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: HomeTokens.greenTint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: HomeTokens.primaryDark,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Today's Action Plan",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: HomeTokens.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: HomeTokens.primaryDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Day $age',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalCount > 0
                          ? '$completedCount/$totalCount Tasks Done • Target: ${plan?.targetWeightGrams ?? 0}g'
                          : '${widget.batch.breedOrFlockType.isNotEmpty ? widget.batch.breedOrFlockType : "Commercial Broiler"} • Standard Protocol',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: HomeTokens.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: HomeTokens.greenTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Plan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: HomeTokens.primaryDark,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 9,
                      color: HomeTokens.primaryDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
