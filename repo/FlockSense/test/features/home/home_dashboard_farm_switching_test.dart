import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

void main() {
  group('Dashboard Farm Switching & Scoped Data Tests', () {
    test('SelectedDashboardFarmNotifier initializes null and updates selected farmId', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedDashboardFarmIdProvider), isNull);

      container.read(selectedDashboardFarmIdProvider.notifier).selectFarm('farm_alpha');
      expect(container.read(selectedDashboardFarmIdProvider), equals('farm_alpha'));

      container.read(selectedDashboardFarmIdProvider.notifier).selectFarm('farm_beta');
      expect(container.read(selectedDashboardFarmIdProvider), equals('farm_beta'));

      container.read(selectedDashboardFarmIdProvider.notifier).selectFarm(null);
      expect(container.read(selectedDashboardFarmIdProvider), isNull);
    });
  });
}
