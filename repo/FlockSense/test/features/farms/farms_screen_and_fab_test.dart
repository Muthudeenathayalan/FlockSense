import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/providers/connectivity_provider.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/main_shell/presentation/screens/main_shell_screen.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_list_screen.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

void main() {
  group('MainShellScreen & FarmListScreen UI Tests', () {
    testWidgets('MainShell FAB displays Add Records on Home and switches to Add Farm on Farms tab', (tester) async {
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
            home: MainShellScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On Home tab (index 0)
      expect(find.widgetWithText(FloatingActionButton, 'Add Records'), findsOneWidget);
      expect(find.byIcon(Icons.post_add), findsOneWidget);

      // Tap on 'Farms' navigation tab
      await tester.tap(find.text('Farms'));
      await tester.pumpAndSettle();

      // On Farms tab (index 1), FAB switches to 'Add Farm'
      expect(find.widgetWithText(FloatingActionButton, 'Add Farm'), findsOneWidget);
      expect(find.widgetWithIcon(FloatingActionButton, Icons.add_rounded), findsOneWidget);
    });

    testWidgets('FarmListScreen renders mild header and facility cards with green header', (tester) async {
      final sampleFarm = FarmModel(
        id: 'farm_test_1',
        userId: 'user_123',
        farmName: 'Farm 1',
        farmType: 'Open',
        flockType: 'Broiler',
        address: 'Sinniampalayam, Sinniampalayam',
        lengthFt: 100,
        widthFt: 30,
        totalSqFt: 3000,
        capacity: 2500,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmListProvider.overrideWith((ref) => Stream.value([sampleFarm])),
            allUserBatchesProvider.overrideWith((ref) => Stream.value([])),
            allUserShedsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: FarmListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify mild light AppBar title & New Farm action
      expect(find.text('Farms & Facilities'), findsOneWidget);
      expect(find.text('New Farm'), findsOneWidget);

      // Verify farm card content
      expect(find.text('Farm 1'), findsOneWidget);
      expect(find.text('Sinniampalayam, Sinniampalayam'), findsOneWidget);
      expect(find.textContaining('100×30 ft • 3000 ft²'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Open'), findsWidgets);
    });
  });
}
