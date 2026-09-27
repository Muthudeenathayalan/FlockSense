import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('OnboardingScreen renders initial 5-pillar screen properly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify first pillar is shown
    expect(find.text('DAILY TELEMETRY & CLIMATE'), findsOneWidget);
    expect(find.text('30-Second Smart Logging'), findsOneWidget);
    expect(find.text('Next Pillar'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('OnboardingScreen advances through pillars on tap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap next to advance to Growth Benchmarks
    await tester.tap(find.text('Next Pillar'));
    await tester.pumpAndSettle();

    expect(find.text('GROWTH BENCHMARKS & 42-DAY PLAN'), findsOneWidget);
    expect(find.text('Industry Standard Curves'), findsOneWidget);

    // Tap next to advance to Inventory
    await tester.tap(find.text('Next Pillar'));
    await tester.pumpAndSettle();

    expect(find.text('CONNECTED INVENTORY & SILOS'), findsOneWidget);
    expect(find.text('Automated Supply Deductions'), findsOneWidget);

    // Tap next to advance to Finance
    await tester.tap(find.text('Next Pillar'));
    await tester.pumpAndSettle();

    expect(find.text('FARM FINANCIALS & PROFITABILITY'), findsOneWidget);
    expect(find.text('Live Profit & Cost Tracking'), findsOneWidget);

    // Tap next to advance to AI & Offline
    await tester.tap(find.text('Next Pillar'));
    await tester.pumpAndSettle();

    expect(find.text('AI CONSULTANT & OFFLINE POWER'), findsOneWidget);
    expect(find.text('24/7 AI Advisor & 100% Offline'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('OnboardingScreen replay mode has close button and back button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(isReplay: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });
}
