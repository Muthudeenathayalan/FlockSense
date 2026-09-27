import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/providers/connectivity_provider.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/home/presentation/screens/home_screen.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_stat_card.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_telemetry_button.dart';
import 'package:flock_sense/features/home/presentation/widgets/telemetry_health_bottom_sheet.dart';

void main() {
  group('Home Dashboard Alignment & Telemetry Button Tests', () {
    testWidgets('HomeStatCard renders with locked geometry and auto-scales large numbers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeStatCard(
              icon: Icons.groups_rounded,
              iconBg: Color(0xFFDCFCE7),
              iconColor: Color(0xFF16A34A),
              value: '1,250,000',
              unit: 'birds',
              valueColor: Color(0xFF15803D),
              label: 'Live Population\n(Across All Sheds)',
              badgeText: 'Active Census',
              badgeColor: Color(0xFF16A34A),
              badgeBg: Color(0xFFDCFCE7),
              cardBg: Color(0xFFF0FDF4),
              borderColor: Color(0xFFBBF7D0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1,250,000'), findsOneWidget);
      expect(find.text('birds'), findsOneWidget);
      expect(find.text('Active Census'), findsOneWidget);
      expect(find.text('Live Population\n(Across All Sheds)'), findsOneWidget);
    });

    testWidgets('HomeTelemetryButton displays live status and opens TelemetryHealthBottomSheet on tap', (tester) async {
      final sampleData = HomeDashboardData(
        farms: [
          FarmModel(
            id: 'farm_1',
            userId: 'user_1',
            farmName: 'Sunrise Broiler Farm',
            farmType: 'EC',
            flockType: 'Broiler',
            address: 'Coimbatore, Tamil Nadu',
            lengthFt: 100,
            widthFt: 30,
            totalSqFt: 3000,
            capacity: 2500,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        ],
        activeFarm: FarmModel(
          id: 'farm_1',
          userId: 'user_1',
          farmName: 'Sunrise Broiler Farm',
          farmType: 'EC',
          flockType: 'Broiler',
          address: 'Coimbatore, Tamil Nadu',
          lengthFt: 100,
          widthFt: 30,
          totalSqFt: 3000,
          capacity: 2500,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        activeBatchCount: 2,
        liveBirds: 24500,
        todayMortality: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTelemetryButton(
              todayMortality: 0,
              activeBatchesCount: 2,
              data: sampleData,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check button contents
      expect(find.text('Live Telemetry'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('0 Losses • Optimal'), findsOneWidget);

      // Tap on the button to open bottom sheet
      await tester.tap(find.text('Live Telemetry'));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears
      expect(find.byType(TelemetryHealthBottomSheet), findsOneWidget);
      expect(find.text('Live Shed Telemetry'), findsOneWidget);
      expect(find.text('Sunrise Broiler Farm • Firebase Real-Time Stream'), findsOneWidget);
      expect(find.text('24,500 birds'), findsOneWidget);

      // Dismiss the bottom sheet
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.byType(TelemetryHealthBottomSheet), findsNothing);
    });

    testWidgets('HomeScreen renders cleanly with spatial tokens and aligned sub-widgets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith((ref) => Stream.value(true)),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            farmListProvider.overrideWith((ref) => Stream.value([])),
            allUserBatchesProvider.overrideWith((ref) => Stream.value([])),
            allUserShedsProvider.overrideWith((ref) => Stream.value([])),
            recentDailyRecordsProvider.overrideWith((ref) => Stream.value([])),
            todayMortalityProvider.overrideWith((ref) => Stream.value(0)),
            latestDgRecordProvider.overrideWith((ref) => Stream.value(null)),
            activeFarmIdProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Command Header
      expect(find.text('Command Center'), findsOneWidget);

      // Farm Switcher & Telemetry Button
      expect(find.text('CURRENT FACILITY'), findsOneWidget);
      expect(find.text('Live Telemetry'), findsOneWidget);

      // 4 KPIs
      expect(find.text('Active Batches'), findsWidgets);
      expect(find.text('Live Population'), findsOneWidget);
      expect(find.text("Today's Mortality"), findsOneWidget);
      expect(find.text('Est. FCR'), findsOneWidget);

      // Operations Grid
      expect(find.text('Daily Log'), findsOneWidget);
      expect(find.text('Feed Stock'), findsOneWidget);
      expect(find.text('Vaccine'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
    });
  });
}
