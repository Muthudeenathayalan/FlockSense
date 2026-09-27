import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/ai/presentation/screens/ai_screen.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/medicine/presentation/screens/medicine_records_screen.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  static const _diseases = [
    _DiseaseGuide(
      name: 'Newcastle Disease (ND)',
      pathogen: 'Paramyxovirus',
      symptoms: 'Gasping, coughing, neck twisting, green diarrhoea, sudden mortality.',
      prevention: 'Strict ND vaccination (Day 5-7 B1/LaSota, Booster Day 21). Maintain biosecurity.',
      action: 'Isolate affected shed immediately, provide supportive electrolytes, notify vet.',
      color: Color(0xFFEF4444),
    ),
    _DiseaseGuide(
      name: 'Infectious Bursal Disease (Gumboro)',
      pathogen: 'Avibirnavirus',
      symptoms: 'Ruffled feathers, depression, white watery diarrhoea, severe vent pecking.',
      prevention: 'IBD Intermediate Plus vaccine at Day 12-14. Avoid immunosuppression.',
      action: 'Reduce protein in feed, provide vitamin C and electrolytes in clean drinking water.',
      color: Color(0xFFF59E0B),
    ),
    _DiseaseGuide(
      name: 'Coccidiosis',
      pathogen: 'Eimeria Protozoa',
      symptoms: 'Bloody or orange droppings, pale combs, huddling, sharp drop in feed conversion.',
      prevention: 'Keep litter dry (<25% moisture). Administer anti-coccidial feed additives.',
      action: 'Treat with Amprolium, Toltrazuril, or Sulphonamides in water for 3-5 days.',
      color: Color(0xFFD97706),
    ),
    _DiseaseGuide(
      name: 'Chronic Respiratory Disease (CRD)',
      pathogen: 'Mycoplasma gallisepticum',
      symptoms: 'Nasal discharge, tracheal rales, facial swelling, eye foaming, reduced growth.',
      prevention: 'Optimize ventilation to minimize shed ammonia (<20 ppm). Strict density limits.',
      action: 'Administer Tylosin, Enrofloxacin, or Doxycycline prescribed by your veterinarian.',
      color: Color(0xFF2563EB),
    ),
    _DiseaseGuide(
      name: 'Heat Stress Syndrome',
      pathogen: 'Environmental',
      symptoms: 'Panting, wings spread away from body, extreme lethargy, high water intake.',
      prevention: 'Run cooling pads, misting nozzles, and high-velocity circulation fans.',
      action: 'Provide sodium bicarbonate & vitamin C in cool water during peak daytime heat.',
      color: Color(0xFFEA580C),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(allUserBatchesProvider).value ?? <BatchModel>[];
    final activeBatches = batches.where((b) => b.isActive).toList();
    final firstBatch = activeBatches.isNotEmpty ? activeBatches.first : batches.firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Flock Health & Biosecurity'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Proactive Flock Wellness',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Log treatments, inspect common symptoms, and consult AI biosecurity protocols.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            AppDesign.sectionTitle('Health Actions'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickHealthButton(
                    icon: Icons.vaccines_outlined,
                    label: 'Vaccinations',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => firstBatch != null
                            ? VaccineRecordsScreen(
                                farmId: firstBatch.farmId,
                                batchId: firstBatch.id,
                                batchName: firstBatch.batchName,
                              )
                            : const VaccineRecordsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickHealthButton(
                    icon: Icons.medication_outlined,
                    label: 'Medicine Log',
                    color: const Color(0xFF2563EB),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicineRecordsScreen(
                          farmId: firstBatch?.farmId,
                          batchId: firstBatch?.id,
                          batchName: firstBatch?.batchName,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickHealthButton(
                    icon: Icons.psychology_outlined,
                    label: 'AI Diagnostic',
                    color: const Color(0xFF6366F1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Daily Health Observations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Daily Symptom Check',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Record mortality, culls, and shed observations.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyRecordsDashboardScreen(),
                      ),
                    ),
                    child: const Text('Log Today'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Diagnostic Reference Guide
            AppDesign.sectionTitle('Poultry Disease & Symptom Guide'),
            const SizedBox(height: 12),
            ..._diseases.map((d) => _buildDiseaseCard(context, d)),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseCard(BuildContext context, _DiseaseGuide d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: d.color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning_amber_rounded, color: d.color, size: 20),
        ),
        title: Text(
          d.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'Pathogen: ${d.pathogen}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildInfoRow('Symptoms', d.symptoms),
                const SizedBox(height: 8),
                _buildInfoRow('Prevention', d.prevention),
                const SizedBox(height: 8),
                _buildInfoRow('Recommended Action', d.action),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
      ],
    );
  }
}

class _DiseaseGuide {
  final String name;
  final String pathogen;
  final String symptoms;
  final String prevention;
  final String action;
  final Color color;

  const _DiseaseGuide({
    required this.name,
    required this.pathogen,
    required this.symptoms,
    required this.prevention,
    required this.action,
    required this.color,
  });
}

class _QuickHealthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickHealthButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
