import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/lighting_program_helper.dart';

void main() {
  group('LightingProgramHelper Tests', () {
    test('provides correct light and dark hours across lifecycle', () {
      expect(LightingProgramHelper.getRecommendedLightHours(1), 23);
      expect(LightingProgramHelper.getRecommendedDarkHours(1), 1);

      expect(LightingProgramHelper.getRecommendedLightHours(14), 18);
      expect(LightingProgramHelper.getRecommendedDarkHours(14), 6);

      expect(LightingProgramHelper.getRecommendedLightHours(40), 20);
      expect(LightingProgramHelper.getRecommendedDarkHours(40), 4);
    });
  });
}
