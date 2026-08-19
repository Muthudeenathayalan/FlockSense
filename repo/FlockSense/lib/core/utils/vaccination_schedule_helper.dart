/// Standard broiler vaccination milestones and recommended administration methods.
class VaccinationScheduleHelper {
  static const List<Map<String, dynamic>> defaultProtocol = [
    {'day': 0, 'vaccine': "Marek's Disease (HVT)", 'method': 'Subcutaneous at Hatchery'},
    {'day': 5, 'vaccine': 'Newcastle Disease + IB (B1/Clone 30)', 'method': 'Eye Drop or Coarse Spray'},
    {'day': 12, 'vaccine': 'Infectious Bursal Disease (Gumboro - Intermediate)', 'method': 'Drinking Water'},
    {'day': 18, 'vaccine': 'Infectious Bursal Disease (Booster)', 'method': 'Drinking Water'},
    {'day': 24, 'vaccine': 'Newcastle Disease (LaSota Booster)', 'method': 'Drinking Water'},
  ];

  /// Returns scheduled calendar dates for all protocol vaccinations given placement date.
  static List<Map<String, dynamic>> generateSchedule(DateTime placementDate) {
    return defaultProtocol.map((milestone) {
      final day = milestone['day'] as int;
      final targetDate = placementDate.add(Duration(days: day));
      return {
        'targetDate': targetDate,
        'day': day,
        'vaccine': milestone['vaccine'],
        'method': milestone['method'],
      };
    }).toList();
  }
}
