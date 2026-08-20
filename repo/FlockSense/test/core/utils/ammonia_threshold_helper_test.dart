import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/ammonia_threshold_helper.dart';

void main() {
  group('AmmoniaThresholdHelper Tests', () {
    test('evaluates ppm thresholds accurately', () {
      expect(AmmoniaThresholdHelper.evaluateAmmoniaPpm(8.0), 'Optimal');
      expect(AmmoniaThresholdHelper.evaluateAmmoniaPpm(15.0), 'Acceptable');
      expect(AmmoniaThresholdHelper.evaluateAmmoniaPpm(22.0), contains('Warning'));
      expect(AmmoniaThresholdHelper.evaluateAmmoniaPpm(35.0), contains('Critical'));
    });

    test('advises appropriate ventilation interventions', () {
      expect(AmmoniaThresholdHelper.getVentilationAdvisory(8.0), contains('minimum ventilation'));
      expect(AmmoniaThresholdHelper.getVentilationAdvisory(30.0), contains('Emergency purge'));
    });
  });
}
