import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/providers/connectivity_provider.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_providers.dart';
import 'package:flock_sense/features/auth/data/user_state_service.dart';
import 'package:flock_sense/features/auth/presentation/screens/auth_wrapper.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/home/presentation/screens/home_screen.dart';
import 'package:flock_sense/features/notifications/domain/notification_providers.dart';

void main() {
  testWidgets('Test HomeScreen and MainShellScreen for brand new user with no farms', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          userStateStreamProvider.overrideWith((ref) => Stream.value(UserState.farmSetup)),
          farmListProvider.overrideWith((ref) => Stream.value([])),
          allUserBatchesProvider.overrideWith((ref) => Stream.value([])),
          allUserShedsProvider.overrideWith((ref) => Stream.value([])),
          recentDailyRecordsProvider.overrideWith((ref) => Stream.value([])),
          todayMortalityProvider.overrideWith((ref) => Stream.value(0)),
          latestDgRecordProvider.overrideWith((ref) => Stream.value(null)),
          activeFarmIdProvider.overrideWith((ref) => Stream.value(null)),
          notificationStatsProvider.overrideWithValue(
            const NotificationStatsResult(
              unreadCount: 0,
              todayAlertsCount: 0,
              criticalAlertsCount: 0,
              completedRemindersCount: 0,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HomeScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Command Center'), findsOneWidget);
  });

  testWidgets('Test AuthWrapper loading state renders branded splash without crash', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStateStreamProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const MaterialApp(
          home: AuthWrapper(),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('FlockSense'), findsOneWidget);
  });
}

