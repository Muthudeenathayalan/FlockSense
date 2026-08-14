import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/temperature_humidity_index.dart';

void main() {
  group('TemperatureHumidityIndex Tests', () {
    test('computes THI correctly for normal shed conditions', () {
      final thi = TemperatureHumidityIndex.calculateThi(
        temperatureC: 24.0,
        relativeHumidityPercent: 60.0,
      );
      expect(thi, 21.9);
      expect(TemperatureHumidityIndex.evaluateHeatStress(thi), 'Comfort');
    });

    test('flags heat stress alert and emergency correctly', () {
      final dangerThi = TemperatureHumidityIndex.calculateThi(
        temperatureC: 32.0,
        relativeHumidityPercent: 75.0,
      );
      expect(dangerThi, greaterThanOrEqualTo(28.9));
      expect(TemperatureHumidityIndex.evaluateHeatStress(31.5), 'Emergency');
    });
  });
}
