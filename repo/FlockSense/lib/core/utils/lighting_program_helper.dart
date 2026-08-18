/// Broiler photoperiod lighting program advisor.
class LightingProgramHelper {
  /// Returns recommended hours of light per 24-hour cycle based on bird age.
  static int getRecommendedLightHours(int ageDays) {
    if (ageDays <= 3) return 23; // Brooding early orientation
    if (ageDays <= 7) return 20; // Rest introduction
    if (ageDays <= 28) return 18; // Growth & skeletal development
    if (ageDays <= 35) return 19;
    return 20; // Pre-harvest
  }

  /// Returns recommended dark period hours.
  static int getRecommendedDarkHours(int ageDays) {
    return 24 - getRecommendedLightHours(ageDays);
  }
}
