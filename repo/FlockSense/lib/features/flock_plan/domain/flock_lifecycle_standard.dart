/// Universal commercial broiler lifecycle standards (Days 1 to 45)
/// based on Cobb 500 and Ross 308 management guidelines.
class FlockDayStandard {
  final int day;
  final String phase; // Brooding, Starter, Grower, Finisher, Pre-Harvest
  final double targetWeightGrams;
  final double dailyFeedPerBirdGrams;
  final double cumulativeFeedPerBirdGrams;
  final double dailyWaterPerBirdMl;
  final String feedType; // Pre-Starter Crumbles, Starter Pellets, Grower Pellets, Finisher Pellets
  final double targetTempCelsius;
  final int lightingHours;
  final String? vaccineName;
  final String? vaccineRoute;
  final String? medicineProtocol;
  final List<String> managementTasks;
  final List<String> biosecurityChecklist;

  const FlockDayStandard({
    required this.day,
    required this.phase,
    required this.targetWeightGrams,
    required this.dailyFeedPerBirdGrams,
    required this.cumulativeFeedPerBirdGrams,
    required this.dailyWaterPerBirdMl,
    required this.feedType,
    required this.targetTempCelsius,
    required this.lightingHours,
    this.vaccineName,
    this.vaccineRoute,
    this.medicineProtocol,
    required this.managementTasks,
    required this.biosecurityChecklist,
  });

  /// Benchmark cumulative Feed Conversion Ratio (FCR) for this age day.
  double get standardFcr => targetWeightGrams > 0
      ? (cumulativeFeedPerBirdGrams / targetWeightGrams)
      : 1.55;
}

class FlockLifecycleStandard {
  FlockLifecycleStandard._();

  /// Retrieve the standard guideline for any day (1 to 45).
  /// If day exceeds 45, falls back to Day 42 harvest standard.
  static FlockDayStandard getForDay(int day) {
    final effectiveDay = day.clamp(1, 45);
    return _dayStandards[effectiveDay] ?? _fallbackDay(effectiveDay);
  }

  /// Calculates total recommended feed in kilograms for the flock today.
  static double calculateDailyFeedKg(int day, int birdCount) {
    if (birdCount <= 0) return 0.0;
    final std = getForDay(day);
    return (std.dailyFeedPerBirdGrams * birdCount) / 1000.0;
  }

  /// Calculates total recommended water in liters for the flock today.
  static double calculateDailyWaterLiters(int day, int birdCount) {
    if (birdCount <= 0) return 0.0;
    final std = getForDay(day);
    return (std.dailyWaterPerBirdMl * birdCount) / 1000.0;
  }

  static FlockDayStandard _fallbackDay(int day) {
    return FlockDayStandard(
      day: day,
      phase: 'Harvest & Marketing',
      targetWeightGrams: 2800,
      dailyFeedPerBirdGrams: 220,
      cumulativeFeedPerBirdGrams: 5000,
      dailyWaterPerBirdMl: 440,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 20.0,
      lightingHours: 23,
      managementTasks: [
        'Enforce strict antibiotic withdrawal period (0 residues)',
        'Raise feed lines 4-6 hours prior to bird catching',
        'Maintain clean sanitized water until bird catching begins',
      ],
      biosecurityChecklist: [
        'Sanitize bird catching crates and transport vehicle wheels',
      ],
    );
  }

  static final Map<int, FlockDayStandard> _dayStandards = {
    // ────────────── WEEK 1: BROODING PHASE (DAYS 1 - 7) ──────────────
    1: FlockDayStandard(
      day: 1,
      phase: 'Brooding Phase',
      targetWeightGrams: 56,
      dailyFeedPerBirdGrams: 15,
      cumulativeFeedPerBirdGrams: 15,
      dailyWaterPerBirdMl: 30,
      feedType: 'Pre-Starter Crumbles',
      targetTempCelsius: 33.5,
      lightingHours: 23,
      vaccineName: "Marek's + ND B1 (Hatchery)",
      vaccineRoute: 'Subcutaneous / Spray at Hatchery',
      medicineProtocol: 'Anti-stress: Electrolytes + 5% Glucose + Vitamin C in water',
      managementTasks: [
        'Check brooding paper feed spread (cover at least 50% of brooding circle)',
        'Conduct 8-hour crop fill test: at least 80% of chicks must have soft, full crops',
        'Check chick behavior: evenly spread without huddling under brooder or against walls',
      ],
      biosecurityChecklist: [
        'Fresh disinfectant footbath at shed entrance',
        'Sanitize all boots and handwash before entering brooding ring',
      ],
    ),
    2: FlockDayStandard(
      day: 2,
      phase: 'Brooding Phase',
      targetWeightGrams: 70,
      dailyFeedPerBirdGrams: 18,
      cumulativeFeedPerBirdGrams: 33,
      dailyWaterPerBirdMl: 36,
      feedType: 'Pre-Starter Crumbles',
      targetTempCelsius: 33.0,
      lightingHours: 23,
      medicineProtocol: 'Continue electrolyte + probiotic hydration booster',
      managementTasks: [
        'Conduct 24-hour crop fill test: target 95%+ chicks with full, soft crops',
        'Replenish paper feed 4-5 times in small quantities to stimulate active feeding',
        'Verify water line pressure: gentle droplet visible at bottom of every nipple pin',
      ],
      biosecurityChecklist: [
        'Inspect shed curtain seals for cold drafts',
        'Ensure no wild bird or rodent access points',
      ],
    ),
    3: FlockDayStandard(
      day: 3,
      phase: 'Brooding Phase',
      targetWeightGrams: 87,
      dailyFeedPerBirdGrams: 22,
      cumulativeFeedPerBirdGrams: 55,
      dailyWaterPerBirdMl: 44,
      feedType: 'Pre-Starter Crumbles',
      targetTempCelsius: 32.5,
      lightingHours: 23,
      medicineProtocol: 'Electrolytes morning, plain sanitized water afternoon',
      managementTasks: [
        'Expand brooding area by 20% to prevent crowding as chicks grow',
        'Begin gradually removing paper sheets while activating automated pan feeders',
        'Check vent minimum run time to expel CO2 and humidity without draft',
      ],
      biosecurityChecklist: [
        'Check and record morning and evening shed temperature & humidity',
      ],
    ),
    4: FlockDayStandard(
      day: 4,
      phase: 'Brooding Phase',
      targetWeightGrams: 106,
      dailyFeedPerBirdGrams: 26,
      cumulativeFeedPerBirdGrams: 81,
      dailyWaterPerBirdMl: 52,
      feedType: 'Pre-Starter Crumbles',
      targetTempCelsius: 32.0,
      lightingHours: 22,
      medicineProtocol: 'Preventive gut acidifier or organic acid in drinking water',
      managementTasks: [
        'Remove remaining paper feed sheets; transition 100% to pan feeders',
        'Introduce 1-hour dark period during night to establish circadian rhythm',
        'Check chick vent area: ensure no pasty vents (sign of chilling or dehydration)',
      ],
      biosecurityChecklist: [
        'Clean and disinfect manual mini-drinkers if still in use',
      ],
    ),
    5: FlockDayStandard(
      day: 5,
      phase: 'Brooding Phase',
      targetWeightGrams: 128,
      dailyFeedPerBirdGrams: 30,
      cumulativeFeedPerBirdGrams: 111,
      dailyWaterPerBirdMl: 60,
      feedType: 'Pre-Starter Crumbles',
      targetTempCelsius: 31.5,
      lightingHours: 21,
      managementTasks: [
        'Adjust nipple drinker height: chicks should drink with neck at 45-degree angle',
        'Inspect litter under drinkers: ensure completely dry friable shavings',
        'Sample weigh 20 chicks to track average daily gain curve',
      ],
      biosecurityChecklist: [
        'Replenish shed entrance disinfectant footbath solution',
      ],
    ),
    6: FlockDayStandard(
      day: 6,
      phase: 'Brooding Phase',
      targetWeightGrams: 152,
      dailyFeedPerBirdGrams: 34,
      cumulativeFeedPerBirdGrams: 145,
      dailyWaterPerBirdMl: 68,
      feedType: 'Pre-Starter Crumbles',
      targetTempCelsius: 31.0,
      lightingHours: 20,
      medicineProtocol: 'Preparation for Day 7 vaccine: clean water, no chlorine 4h prior',
      managementTasks: [
        'Expand brooding circle to 50% of shed floor area',
        'Check inventory: ensure Newcastle (ND LaSota) vaccine vials and ice packs are ready',
        'Flush water lines with plain water to clear any disinfectant residue before vaccine',
      ],
      biosecurityChecklist: [
        'Store vaccine vials in temperature-monitored cooler (2°C - 8°C)',
      ],
    ),
    7: FlockDayStandard(
      day: 7,
      phase: 'Brooding Phase',
      targetWeightGrams: 185,
      dailyFeedPerBirdGrams: 38,
      cumulativeFeedPerBirdGrams: 183,
      dailyWaterPerBirdMl: 76,
      feedType: 'Pre-Starter Crumbles',
      targetTempCelsius: 30.0,
      lightingHours: 20,
      vaccineName: 'Newcastle Disease (ND LaSota / B1)',
      vaccineRoute: 'Ocular / Drinking water with skim milk stabilizer',
      medicineProtocol: 'Post-vaccine stress relief: B-Complex + Vitamin C in evening water',
      managementTasks: [
        'CRITICAL MILESTONE: 7-Day Body Weight Check (Target: 4-5x hatch weight, ~185g)',
        'Administer Newcastle LaSota vaccine protocol in morning cool hours',
        'Withdraw water 1.5 - 2 hours prior so birds drink vaccine water within 2 hours',
      ],
      biosecurityChecklist: [
        'Safely incinerate or disinfect used vaccine vials and packaging',
      ],
    ),

    // ────────────── WEEK 2: STARTER & EXPANSION PHASE (DAYS 8 - 14) ──────────────
    8: FlockDayStandard(
      day: 8,
      phase: 'Starter Phase',
      targetWeightGrams: 220,
      dailyFeedPerBirdGrams: 43,
      cumulativeFeedPerBirdGrams: 226,
      dailyWaterPerBirdMl: 86,
      feedType: 'Pre-Starter Crumbles',
      targetTempCelsius: 29.5,
      lightingHours: 19,
      medicineProtocol: 'B-Complex vitamins in drinking water',
      managementTasks: [
        'Raise nipple drinker height: chicks must reach up with feet flat on the litter',
        'Expand brooding pen to 75% of shed area',
        'Inspect litter around feeder pans and rake any compacted spots',
      ],
      biosecurityChecklist: [
        'Check mortality disposal pit/incinerator operation',
      ],
    ),
    9: FlockDayStandard(
      day: 9,
      phase: 'Starter Phase',
      targetWeightGrams: 255,
      dailyFeedPerBirdGrams: 48,
      cumulativeFeedPerBirdGrams: 274,
      dailyWaterPerBirdMl: 96,
      feedType: 'Pre-Starter Crumbles',
      targetTempCelsius: 29.0,
      lightingHours: 19,
      managementTasks: [
        'Calibrate pan feeder feed depth: set to minimum depth that prevents spillage',
        'Inspect air quality: zero ammonia smell at bird level (<10 ppm)',
        'Ensure automatic feeder lines run 3-4 cycles daily to stimulate feeding activity',
      ],
      biosecurityChecklist: [
        'Inspect shed curtain winch cables and safety locks',
      ],
    ),
    10: FlockDayStandard(
      day: 10,
      phase: 'Starter Phase',
      targetWeightGrams: 290,
      dailyFeedPerBirdGrams: 53,
      cumulativeFeedPerBirdGrams: 327,
      dailyWaterPerBirdMl: 106,
      feedType: 'Pre-Starter Crumbles',
      targetTempCelsius: 28.5,
      lightingHours: 18,
      medicineProtocol: 'Liver tonic + Vitamin E/Selenium supplement',
      managementTasks: [
        'Prepare for feed transition: order Starter Pellets for Day 11-12',
        'Release birds to 100% of shed floor (full shed expansion)',
        'Check water flow rate: minimum 30-40 ml/min per nipple drinker',
      ],
      biosecurityChecklist: [
        'Inspect water storage tank and verify chlorination level (2-3 ppm)',
      ],
    ),
    11: FlockDayStandard(
      day: 11,
      phase: 'Starter Phase',
      targetWeightGrams: 335,
      dailyFeedPerBirdGrams: 58,
      cumulativeFeedPerBirdGrams: 385,
      dailyWaterPerBirdMl: 116,
      feedType: 'Transition: 50% Pre-Starter / 50% Starter Pellets',
      targetTempCelsius: 28.0,
      lightingHours: 18,
      managementTasks: [
        'FEED TRANSITION: Blend 50% Pre-Starter with 50% Starter Pellets to prevent gut shock',
        'Observe bird feeding behavior during transition',
        'Adjust feeder pan lip height to bird back level',
      ],
      biosecurityChecklist: [
        'Inspect feed storage silo / room for rodent signs and moisture leaks',
      ],
    ),
    12: FlockDayStandard(
      day: 12,
      phase: 'Starter Phase',
      targetWeightGrams: 387,
      dailyFeedPerBirdGrams: 64,
      cumulativeFeedPerBirdGrams: 449,
      dailyWaterPerBirdMl: 128,
      feedType: 'Starter Pellets (100%)',
      targetTempCelsius: 27.5,
      lightingHours: 18,
      medicineProtocol: 'Gut probiotics in drinking water',
      managementTasks: [
        'Complete feed transition to 100% Starter Pellets',
        'Rake wet litter around drinker zones and top-dress with dry wood shavings',
        'Sample weigh 30 birds to verify growth rate meets Cobb/Ross standard (~385g)',
      ],
      biosecurityChecklist: [
        'Change footbath disinfectant solution with fresh mixture',
      ],
    ),
    13: FlockDayStandard(
      day: 13,
      phase: 'Starter Phase',
      targetWeightGrams: 443,
      dailyFeedPerBirdGrams: 70,
      cumulativeFeedPerBirdGrams: 519,
      dailyWaterPerBirdMl: 140,
      feedType: 'Starter Pellets',
      targetTempCelsius: 27.0,
      lightingHours: 18,
      medicineProtocol: 'Pre-vaccine preparation: Plain non-chlorinated water in afternoon',
      managementTasks: [
        'Prepare for Day 14 Gumboro (IBD) vaccine: inspect vaccine cold-chain storage',
        'Ensure vaccine skim milk stabilizer is available to protect live viral titer',
        'Inspect all tunnel ventilation fans and cooling pads operation',
      ],
      biosecurityChecklist: [
        'Ensure no unauthorized visitors enter farm compound',
      ],
    ),
    14: FlockDayStandard(
      day: 14,
      phase: 'Starter Phase',
      targetWeightGrams: 500,
      dailyFeedPerBirdGrams: 76,
      cumulativeFeedPerBirdGrams: 595,
      dailyWaterPerBirdMl: 152,
      feedType: 'Starter Pellets',
      targetTempCelsius: 26.5,
      lightingHours: 18,
      vaccineName: 'Infectious Bursal Disease (Gumboro IBD Intermediate)',
      vaccineRoute: 'Drinking water with skim milk stabilizer',
      medicineProtocol: 'Post-vaccine stress relief: Vitamin C + Betaine in evening water',
      managementTasks: [
        'CRITICAL MILESTONE: Day 14 Gumboro (IBD) Vaccination in early morning',
        'Deprive water 1.5 - 2 hrs; ensure all birds drink vaccine water within 1.5 hrs',
        'Conduct Week 2 body weight sampling (Target: ~500g)',
      ],
      biosecurityChecklist: [
        'Dispose of empty vaccine vials in disinfectant solution',
      ],
    ),

    // ────────────── WEEK 3: RAPID GROWTH PHASE (DAYS 15 - 21) ──────────────
    15: FlockDayStandard(
      day: 15,
      phase: 'Grower Phase',
      targetWeightGrams: 559,
      dailyFeedPerBirdGrams: 83,
      cumulativeFeedPerBirdGrams: 678,
      dailyWaterPerBirdMl: 166,
      feedType: 'Starter Pellets',
      targetTempCelsius: 26.0,
      lightingHours: 18,
      medicineProtocol: 'Coccidiosis preventive check; monitor droppings for blood or mucus',
      managementTasks: [
        'Inspect bird droppings: normal brown/grey with white uric acid cap',
        'Rake litter under all drinking lines to prevent caking and ammonia buildup',
        'Raise drinker lines: birds should stretch their necks up at 45 degrees',
      ],
      biosecurityChecklist: [
        'Check shed perimeter for wild bird nesting and weed overgrowth',
      ],
    ),
    16: FlockDayStandard(
      day: 16,
      phase: 'Grower Phase',
      targetWeightGrams: 618,
      dailyFeedPerBirdGrams: 90,
      cumulativeFeedPerBirdGrams: 768,
      dailyWaterPerBirdMl: 180,
      feedType: 'Starter Pellets',
      targetTempCelsius: 25.5,
      lightingHours: 18,
      managementTasks: [
        'Increase minimum ventilation air exchange rate to match growing biomass',
        'Check water meter: ensure daily water intake is roughly 1.8x to 2.0x feed weight',
        'Remove any cull or weak birds promptly to maintain flock uniformity',
      ],
      biosecurityChecklist: [
        'Verify mortality logging in FlockSense daily record',
      ],
    ),
    17: FlockDayStandard(
      day: 17,
      phase: 'Grower Phase',
      targetWeightGrams: 677,
      dailyFeedPerBirdGrams: 97,
      cumulativeFeedPerBirdGrams: 865,
      dailyWaterPerBirdMl: 194,
      feedType: 'Starter Pellets',
      targetTempCelsius: 25.0,
      lightingHours: 18,
      medicineProtocol: 'B-Complex + Choline chloride in drinking water',
      managementTasks: [
        'Check feeder pan distribution: ensure all birds have immediate access when lines run',
        'Inspect litter moisture: target 20-25% moisture (crumble in hand without sticking)',
        'Check nipple drinker pressure: increase regulator pressure to meet growing demand',
      ],
      biosecurityChecklist: [
        'Scrub and sanitize shed entrance boot-dip trays',
      ],
    ),
    18: FlockDayStandard(
      day: 18,
      phase: 'Grower Phase',
      targetWeightGrams: 736,
      dailyFeedPerBirdGrams: 104,
      cumulativeFeedPerBirdGrams: 969,
      dailyWaterPerBirdMl: 208,
      feedType: 'Starter Pellets',
      targetTempCelsius: 24.5,
      lightingHours: 18,
      managementTasks: [
        'Check fan belt tensions and louvers on all extraction fans',
        'Walk through the flock slowly twice daily to stimulate bird movement and feeding',
        'Observe bird respiration: zero panting or open-mouth breathing',
      ],
      biosecurityChecklist: [
        'Maintain clean apron around exterior shed walls',
      ],
    ),
    19: FlockDayStandard(
      day: 19,
      phase: 'Grower Phase',
      targetWeightGrams: 795,
      dailyFeedPerBirdGrams: 111,
      cumulativeFeedPerBirdGrams: 1080,
      dailyWaterPerBirdMl: 222,
      feedType: 'Starter Pellets',
      targetTempCelsius: 24.0,
      lightingHours: 18,
      medicineProtocol: 'Electrolytes during peak afternoon heat hours',
      managementTasks: [
        'Prepare for Day 21 Newcastle booster: check vaccine inventory in refrigerator',
        'Inspect evaporative cooling pads: ensure uniform wetting across entire pad face',
        'Verify target body weight tracking: target ~800g',
      ],
      biosecurityChecklist: [
        'Check Diesel Generator fuel level and test automatic changeover',
      ],
    ),
    20: FlockDayStandard(
      day: 20,
      phase: 'Grower Phase',
      targetWeightGrams: 854,
      dailyFeedPerBirdGrams: 118,
      cumulativeFeedPerBirdGrams: 1198,
      dailyWaterPerBirdMl: 236,
      feedType: 'Starter Pellets',
      targetTempCelsius: 24.0,
      lightingHours: 18,
      medicineProtocol: 'Plain non-chlorinated water in afternoon to clear lines for vaccine',
      managementTasks: [
        'Flush water lines with clean non-chlorinated water before tomorrow vaccine',
        'Weigh sample of 50 birds to calculate batch uniformity and coefficient of variation',
        'Inspect drinker lines for any pin leaks or drips',
      ],
      biosecurityChecklist: [
        'Ensure vaccine cooler and ice packs are ready for morning administration',
      ],
    ),
    21: FlockDayStandard(
      day: 21,
      phase: 'Grower Phase',
      targetWeightGrams: 913,
      dailyFeedPerBirdGrams: 125,
      cumulativeFeedPerBirdGrams: 1323,
      dailyWaterPerBirdMl: 250,
      feedType: 'Starter Pellets',
      targetTempCelsius: 23.5,
      lightingHours: 18,
      vaccineName: 'Newcastle Disease Booster (ND LaSota)',
      vaccineRoute: 'Drinking water with milk stabilizer',
      medicineProtocol: 'Vitamin C + anti-stress electrolytes in evening water',
      managementTasks: [
        'CRITICAL MILESTONE: Day 21 Newcastle (ND) Booster Vaccine in morning',
        'Calculate Week 3 cumulative FCR (Target: ~1.30 - 1.35)',
        'Prepare feed order for Grower Pellets transition on Day 24-25',
      ],
      biosecurityChecklist: [
        'Safely burn or sanitize empty vaccine vials',
      ],
    ),

    // ────────────── WEEK 4: GROWER PHASE (DAYS 22 - 28) ──────────────
    22: FlockDayStandard(
      day: 22,
      phase: 'Grower Phase',
      targetWeightGrams: 993,
      dailyFeedPerBirdGrams: 132,
      cumulativeFeedPerBirdGrams: 1455,
      dailyWaterPerBirdMl: 264,
      feedType: 'Starter Pellets',
      targetTempCelsius: 23.0,
      lightingHours: 18,
      medicineProtocol: 'Calcium + Phosphorus + Vitamin D3 for bone strength',
      managementTasks: [
        'Check bird leg strength and mobility during daily shed walk',
        'Raise feeder lines to match bird back level to eliminate feed spillage',
        'Ensure drinker lines are high enough that birds reach upward without bending legs',
      ],
      biosecurityChecklist: [
        'Clean and disinfect cooling pad water sump tank',
      ],
    ),
    23: FlockDayStandard(
      day: 23,
      phase: 'Grower Phase',
      targetWeightGrams: 1073,
      dailyFeedPerBirdGrams: 139,
      cumulativeFeedPerBirdGrams: 1594,
      dailyWaterPerBirdMl: 278,
      feedType: 'Starter Pellets',
      targetTempCelsius: 23.0,
      lightingHours: 18,
      managementTasks: [
        'Prepare for Grower feed transition: 50% Starter / 50% Grower tomorrow',
        'Check cooling pad air velocity: target 2.0 - 2.5 m/s in tunnel ventilated shed',
        'Inspect litter quality throughout shed: remove any wet caked clumps',
      ],
      biosecurityChecklist: [
        'Check bait stations around shed perimeter for rodent activity',
      ],
    ),
    24: FlockDayStandard(
      day: 24,
      phase: 'Grower Phase',
      targetWeightGrams: 1153,
      dailyFeedPerBirdGrams: 146,
      cumulativeFeedPerBirdGrams: 1740,
      dailyWaterPerBirdMl: 292,
      feedType: 'Transition: 50% Starter / 50% Grower Pellets',
      targetTempCelsius: 22.5,
      lightingHours: 18,
      managementTasks: [
        'FEED TRANSITION: Blend 50% Starter with 50% Grower Pellets',
        'Monitor feed bin clean-out: avoid old feed sticking to bin hopper walls',
        'Check water consumption meter: sudden drop signals line blockage or illness',
      ],
      biosecurityChecklist: [
        'Ensure fresh footbath disinfectant solution is mixed',
      ],
    ),
    25: FlockDayStandard(
      day: 25,
      phase: 'Grower Phase',
      targetWeightGrams: 1233,
      dailyFeedPerBirdGrams: 153,
      cumulativeFeedPerBirdGrams: 1893,
      dailyWaterPerBirdMl: 306,
      feedType: 'Grower Pellets (100%)',
      targetTempCelsius: 22.5,
      lightingHours: 18,
      medicineProtocol: 'Liver tonic in morning water to assist fat metabolism',
      managementTasks: [
        'Transition completely to 100% Grower Pellets',
        'Weigh sample of 50 birds: target average weight ~1,230g',
        'Adjust minimum ventilation timers to keep relative humidity between 55-65%',
      ],
      biosecurityChecklist: [
        'Inspect external electrical panels and fan motor temperatures',
      ],
    ),
    26: FlockDayStandard(
      day: 26,
      phase: 'Grower Phase',
      targetWeightGrams: 1313,
      dailyFeedPerBirdGrams: 160,
      cumulativeFeedPerBirdGrams: 2053,
      dailyWaterPerBirdMl: 320,
      feedType: 'Grower Pellets',
      targetTempCelsius: 22.0,
      lightingHours: 18,
      managementTasks: [
        'Inspect bird feathering and breast muscle development',
        'Rake and aerate litter in walking alleys and near drinker lines',
        'Check water line end-flush: open drain valves for 2 mins to flush sediments',
      ],
      biosecurityChecklist: [
        'Log daily mortality and cull counts accurately in FlockSense',
      ],
    ),
    27: FlockDayStandard(
      day: 27,
      phase: 'Grower Phase',
      targetWeightGrams: 1394,
      dailyFeedPerBirdGrams: 167,
      cumulativeFeedPerBirdGrams: 2220,
      dailyWaterPerBirdMl: 334,
      feedType: 'Grower Pellets',
      targetTempCelsius: 22.0,
      lightingHours: 18,
      managementTasks: [
        'Check feeder pan depth: adjust to position 2 to prevent billing out of feed',
        'Verify bird stocking density: ensure adequate floor space (1.2 sq ft / bird)',
        'Check static pressure in tunnel shed: target 0.10 - 0.15 inches of water',
      ],
      biosecurityChecklist: [
        'Ensure shed lighting bulbs are clean and dust-free for uniform intensity',
      ],
    ),
    28: FlockDayStandard(
      day: 28,
      phase: 'Grower Phase',
      targetWeightGrams: 1475,
      dailyFeedPerBirdGrams: 173,
      cumulativeFeedPerBirdGrams: 2393,
      dailyWaterPerBirdMl: 346,
      feedType: 'Grower Pellets',
      targetTempCelsius: 21.5,
      lightingHours: 18,
      vaccineName: 'Optional: Gumboro Booster (only in high-challenge zones)',
      vaccineRoute: 'Drinking water',
      medicineProtocol: 'Multi-vitamin + electrolyte booster',
      managementTasks: [
        'CRITICAL MILESTONE: End of 4th Week Weighing (Target: ~1,475g)',
        'Calculate Cumulative FCR (Target: 1.45 - 1.50)',
        'Assess bird uniformity: target CV < 9% across the flock',
      ],
      biosecurityChecklist: [
        'Inspect farm perimeter fencing and gates',
      ],
    ),

    // ────────────── WEEK 5: FINISHER & WEIGHT DEPOSITION (DAYS 29 - 35) ──────────────
    29: FlockDayStandard(
      day: 29,
      phase: 'Finisher Phase',
      targetWeightGrams: 1566,
      dailyFeedPerBirdGrams: 180,
      cumulativeFeedPerBirdGrams: 2573,
      dailyWaterPerBirdMl: 360,
      feedType: 'Grower Pellets',
      targetTempCelsius: 21.5,
      lightingHours: 19,
      managementTasks: [
        'Prepare for Finisher feed transition: order Finisher Pellets from feed mill',
        'Check water flow rate: adult birds require minimum 60-80 ml/min per nipple',
        'Inspect litter: ensure litter is friable and warm without wet crusting',
      ],
      biosecurityChecklist: [
        'Disinfect service room and entrance doorways',
      ],
    ),
    30: FlockDayStandard(
      day: 30,
      phase: 'Finisher Phase',
      targetWeightGrams: 1658,
      dailyFeedPerBirdGrams: 186,
      cumulativeFeedPerBirdGrams: 2759,
      dailyWaterPerBirdMl: 372,
      feedType: 'Transition: 50% Grower / 50% Finisher Pellets',
      targetTempCelsius: 21.0,
      lightingHours: 19,
      managementTasks: [
        'FEED TRANSITION: Blend 50% Grower with 50% Finisher Pellets',
        'Observe bird feeding speed and appetite after transition',
        'Walk shed 3 times daily to ensure all birds get up to drink and feed',
      ],
      biosecurityChecklist: [
        'Clean all fan safety grilles of accumulated dust and feathers',
      ],
    ),
    31: FlockDayStandard(
      day: 31,
      phase: 'Finisher Phase',
      targetWeightGrams: 1749,
      dailyFeedPerBirdGrams: 192,
      cumulativeFeedPerBirdGrams: 2951,
      dailyWaterPerBirdMl: 384,
      feedType: 'Finisher Pellets (100%)',
      targetTempCelsius: 21.0,
      lightingHours: 19,
      medicineProtocol: 'Gut acidifier in water; zero antibiotics',
      managementTasks: [
        'Transition completely to 100% Finisher Pellets',
        'Raise drinker lines again: birds have grown; nipples must be at crown height',
        'Check tunnel cooling pads: ensure pads are clean and free of algae buildup',
      ],
      biosecurityChecklist: [
        'Inspect and log daily water meter reading morning and night',
      ],
    ),
    32: FlockDayStandard(
      day: 32,
      phase: 'Finisher Phase',
      targetWeightGrams: 1840,
      dailyFeedPerBirdGrams: 198,
      cumulativeFeedPerBirdGrams: 3149,
      dailyWaterPerBirdMl: 396,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 21.0,
      lightingHours: 20,
      managementTasks: [
        'Sample weigh 50 birds: target average weight ~1,840g',
        'Check heat stress prevention: ensure tunnel airspeed >2.5 m/s during peak afternoon',
        'Verify all automatic feeder pans are filling evenly down the entire length of house',
      ],
      biosecurityChecklist: [
        'Maintain zero feed spillage on outside aprons to prevent attracting wild birds',
      ],
    ),
    33: FlockDayStandard(
      day: 33,
      phase: 'Finisher Phase',
      targetWeightGrams: 1931,
      dailyFeedPerBirdGrams: 203,
      cumulativeFeedPerBirdGrams: 3352,
      dailyWaterPerBirdMl: 406,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 20.5,
      lightingHours: 20,
      managementTasks: [
        'Review market weight expectations with poultry integrator / bird buyers',
        'Rake litter near sidewalls to maintain floor dryness',
        'Check drinker line regulators: confirm stable water pressure throughout line',
      ],
      biosecurityChecklist: [
        'Refresh boot bath disinfectant solution',
      ],
    ),
    34: FlockDayStandard(
      day: 34,
      phase: 'Finisher Phase',
      targetWeightGrams: 2023,
      dailyFeedPerBirdGrams: 208,
      cumulativeFeedPerBirdGrams: 3560,
      dailyWaterPerBirdMl: 416,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 20.5,
      lightingHours: 20,
      medicineProtocol: 'Preparation for strict withdrawal: Stop all medicated additives',
      managementTasks: [
        'COMMENCE MANDATORY WITHDRAWAL: Zero antibiotics or chemical additives in feed/water',
        'Check water sanitization: maintain 2-3 ppm free chlorine with ORP > 650 mV',
        'Inspect flock walking gait: identify and cull any severely lame birds',
      ],
      biosecurityChecklist: [
        'Verify complete cessation of all medicinal products',
      ],
    ),
    35: FlockDayStandard(
      day: 35,
      phase: 'Finisher Phase',
      targetWeightGrams: 2115,
      dailyFeedPerBirdGrams: 213,
      cumulativeFeedPerBirdGrams: 3773,
      dailyWaterPerBirdMl: 426,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 20.0,
      lightingHours: 21,
      medicineProtocol: 'STRICT WITHDRAWAL: Pure clean sanitized water only',
      managementTasks: [
        'CRITICAL MILESTONE: Day 35 Body Weight & FCR Audit (Target: ~2,115g, FCR: ~1.55)',
        'Sample weigh 100 birds for accurate pre-sale weight grading',
        'Plan harvest logistics: schedule bird catching dates and vehicle access',
      ],
      biosecurityChecklist: [
        'Audit feed bin: verify zero medicated feed remains in hoppers',
      ],
    ),

    // ────────────── WEEK 6: PRE-HARVEST & MARKETING (DAYS 36 - 42+) ──────────────
    36: FlockDayStandard(
      day: 36,
      phase: 'Pre-Harvest Phase',
      targetWeightGrams: 2206,
      dailyFeedPerBirdGrams: 217,
      cumulativeFeedPerBirdGrams: 3990,
      dailyWaterPerBirdMl: 434,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 20.0,
      lightingHours: 21,
      medicineProtocol: 'STRICT WITHDRAWAL: Pure clean drinking water only',
      managementTasks: [
        'Confirm bird catching schedule and processing plant delivery timing',
        'Ensure shed lighting dimmers are functioning (dim lights required during catching)',
        'Keep tunnel ventilation running at full capacity to remove heat produced by heavy birds',
      ],
      biosecurityChecklist: [
        'Clear farm driveway and parking apron for large transport trucks',
      ],
    ),
    37: FlockDayStandard(
      day: 37,
      phase: 'Pre-Harvest Phase',
      targetWeightGrams: 2296,
      dailyFeedPerBirdGrams: 220,
      cumulativeFeedPerBirdGrams: 4210,
      dailyWaterPerBirdMl: 440,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 20.0,
      lightingHours: 22,
      medicineProtocol: 'STRICT WITHDRAWAL: Clean water only',
      managementTasks: [
        'Inspect shed interior for any sharp protruding wire or obstacles that could cause scratches',
        'Monitor daily mortality closely: heavy birds are vulnerable to heart stress during heat',
        'Keep water temperature cool: flush lines if water in pipes exceeds 25°C',
      ],
      biosecurityChecklist: [
        'Inspect transport truck disinfectant spray area',
      ],
    ),
    38: FlockDayStandard(
      day: 38,
      phase: 'Pre-Harvest Phase',
      targetWeightGrams: 2387,
      dailyFeedPerBirdGrams: 222,
      cumulativeFeedPerBirdGrams: 4432,
      dailyWaterPerBirdMl: 444,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 20.0,
      lightingHours: 22,
      medicineProtocol: 'STRICT WITHDRAWAL: Clean water only',
      managementTasks: [
        'Sample weigh birds: target ~2,380g average body weight',
        'Calculate projected flock tonnage and sales revenue in FlockSense',
        'Ensure all bird catching team members are briefed on humane, bruise-free handling',
      ],
      biosecurityChecklist: [
        'Sanitize weighing scales and hanging hooks before use',
      ],
    ),
    39: FlockDayStandard(
      day: 39,
      phase: 'Pre-Harvest Phase',
      targetWeightGrams: 2477,
      dailyFeedPerBirdGrams: 224,
      cumulativeFeedPerBirdGrams: 4656,
      dailyWaterPerBirdMl: 448,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 20.0,
      lightingHours: 22,
      medicineProtocol: 'STRICT WITHDRAWAL: Clean water only',
      managementTasks: [
        'Check weather forecast for harvest days: prepare cooling fans for daytime catch',
        'Ensure backup diesel generator has full fuel tank for night catching lights',
        'Maintain constant water availability up to the moment bird catching starts',
      ],
      biosecurityChecklist: [
        'Verify strict zero-medication compliance in flock log',
      ],
    ),
    40: FlockDayStandard(
      day: 40,
      phase: 'Harvest & Marketing',
      targetWeightGrams: 2568,
      dailyFeedPerBirdGrams: 225,
      cumulativeFeedPerBirdGrams: 4881,
      dailyWaterPerBirdMl: 450,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 20.0,
      lightingHours: 23,
      medicineProtocol: 'STRICT WITHDRAWAL: Clean water only',
      managementTasks: [
        'Verify bird catch plan (time of arrival, number of crates, crew size)',
        'Inspect bird catching crates: reject any broken crates with sharp plastic edges',
        'Check flock uniform weight: target ~2,550g',
      ],
      biosecurityChecklist: [
        'Ensure vehicle disinfection wheel dip is fresh and active',
      ],
    ),
    41: FlockDayStandard(
      day: 41,
      phase: 'Harvest & Marketing',
      targetWeightGrams: 2659,
      dailyFeedPerBirdGrams: 225,
      cumulativeFeedPerBirdGrams: 5106,
      dailyWaterPerBirdMl: 450,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 20.0,
      lightingHours: 23,
      medicineProtocol: 'STRICT WITHDRAWAL: Clean water only',
      managementTasks: [
        'FEED WITHDRAWAL PROTOCOL: Raise feed lines 4 to 6 hours before scheduled catching',
        'Keep drinker lines fully charged and accessible until catching team enters shed',
        'Dim house lights to blue / low red intensity during catching to keep birds calm',
      ],
      biosecurityChecklist: [
        'Weigh transport trucks empty (tare weight) and fully loaded (gross weight)',
      ],
    ),
    42: FlockDayStandard(
      day: 42,
      phase: 'Harvest & Marketing',
      targetWeightGrams: 2750,
      dailyFeedPerBirdGrams: 225,
      cumulativeFeedPerBirdGrams: 5331,
      dailyWaterPerBirdMl: 450,
      feedType: 'Finisher Pellets',
      targetTempCelsius: 20.0,
      lightingHours: 23,
      medicineProtocol: 'STRICT WITHDRAWAL: Clean water only',
      managementTasks: [
        'CRITICAL MILESTONE: Final Batch Harvest & Bird Delivery',
        'Record final sales slips: total birds caught, total gross kg, average weight in FlockSense',
        'Initiate post-harvest shed clean-out, litter removal, and sanitation protocol',
        'Generate 15-Page Complete Batch Completion Report PDF in FlockSense',
      ],
      biosecurityChecklist: [
        'Remove all manure/litter off-farm; begin high-pressure shed wash-down',
      ],
    ),
  };
}
