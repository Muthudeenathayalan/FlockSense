import 'package:cloud_firestore/cloud_firestore.dart';

enum RecordType {
  feed,
  water,
  mortality,
  weight,
  medicine,
  vaccination,
  environment,
  dg,
}

class DailyRecordModel {
  const DailyRecordModel({
    required this.id,
    required this.farmId,
    required this.batchId,
    required this.recordDate,
    required this.batchAgeDay,
    required this.openingBirds,
    required this.mortalityCount,
    required this.cullCount,
    required this.adjustmentCount,
    required this.closingBirds,
    required this.feedConsumedKg,
    required this.waterConsumedLiters,
    required this.avgWeightGrams,
    required this.medicineGiven,
    this.medicineName,
    required this.vaccineGiven,
    this.vaccineName,
    this.symptoms,
    this.notes,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    // Detailed sub-record fields for 8 specialized types
    this.feedType,
    this.feedCost,
    this.feedSupplier,
    this.waterSource,
    this.waterQuality,
    this.mortalityCause,
    this.mortalityDisease,
    this.mortalityRemarks,
    this.sampleBirds,
    this.medicineDose,
    this.medicineQuantity,
    this.medicineCost,
    this.medicineReason,
    this.vaccineDose,
    this.vaccineCompletedBy,
    this.vaccineNextDueDate,
    this.temperature,
    this.humidity,
    this.weather,
    this.dgLevelLiters,
    this.dgAddedLiters,
    this.dgRunningHours,
    this.dgName,
  });

  final String id;
  final String farmId;
  final String batchId;
  final DateTime recordDate;
  final int batchAgeDay;
  final int openingBirds;
  final int mortalityCount;
  final int cullCount;
  final int adjustmentCount;
  final int closingBirds;
  final double feedConsumedKg;
  final double waterConsumedLiters;
  final double avgWeightGrams;
  final bool medicineGiven;
  final String? medicineName;
  final bool vaccineGiven;
  final String? vaccineName;
  final String? symptoms;
  final String? notes;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 1. Feed Record
  final String? feedType;
  final double? feedCost;
  final String? feedSupplier;

  // 2. Water Record
  final String? waterSource;
  final String? waterQuality;

  // 3. Mortality Record
  final String? mortalityCause;
  final String? mortalityDisease;
  final String? mortalityRemarks;

  // 4. Weight Record
  final int? sampleBirds;

  // 5. Medicine Record
  final String? medicineDose;
  final double? medicineQuantity;
  final double? medicineCost;
  final String? medicineReason;

  // 6. Vaccination Record
  final String? vaccineDose;
  final String? vaccineCompletedBy;
  final DateTime? vaccineNextDueDate;

  // 7. Environment Record
  final double? temperature;
  final double? humidity;
  final String? weather;

  // 8. Diesel Generator (DG) Record
  final double? dgLevelLiters;
  final double? dgAddedLiters;
  final double? dgRunningHours;
  final String? dgName;

  factory DailyRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? _parseDateString(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? _parseDateString(v);
      }
      return null;
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    int? parseOptionalInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    double? parseOptionalDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final recordDate = parseDate(
      json['recordDate'] ?? json['recordDateString'] ?? json['date'],
    );
    final openingBirds = parseInt(json['openingBirds']);
    final rawMortality = parseInt(json['mortalityCount']);
    final mortalityCount = rawMortality < 0 ? 0 : rawMortality;
    final rawCull = parseInt(json['cullCount']);
    final cullCount = rawCull < 0 ? 0 : rawCull;
    final adjustmentCount = parseInt(json['adjustmentCount']);
    final calcClosing =
        openingBirds - mortalityCount - cullCount + adjustmentCount;
    final closingBirds = parseInt(json['closingBirds']) != 0
        ? parseInt(json['closingBirds'])
        : (calcClosing < 0 ? 0 : calcClosing);

    return DailyRecordModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? '',
      recordDate: recordDate,
      batchAgeDay: parseInt(json['batchAgeDay']),
      openingBirds: openingBirds,
      mortalityCount: mortalityCount,
      cullCount: cullCount,
      adjustmentCount: adjustmentCount,
      closingBirds: closingBirds,
      feedConsumedKg: parseDouble(json['feedConsumedKg']),
      waterConsumedLiters: parseDouble(json['waterConsumedLiters']),
      avgWeightGrams: parseDouble(json['avgWeightGrams']),
      medicineGiven: json['medicineGiven'] as bool? ?? false,
      medicineName: json['medicineName'] as String?,
      vaccineGiven: json['vaccineGiven'] as bool? ?? false,
      vaccineName: json['vaccineName'] as String?,
      symptoms: json['symptoms'] as String?,
      notes: json['notes'] as String?,
      ownerId: json['ownerId'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      // Sub-fields
      feedType: json['feedType'] as String?,
      feedCost: parseOptionalDouble(json['feedCost']),
      feedSupplier: json['feedSupplier'] as String?,
      waterSource: json['waterSource'] as String?,
      waterQuality: json['waterQuality'] as String?,
      mortalityCause: json['mortalityCause'] as String?,
      mortalityDisease: json['mortalityDisease'] as String?,
      mortalityRemarks: json['mortalityRemarks'] as String?,
      sampleBirds: parseOptionalInt(json['sampleBirds']),
      medicineDose: json['medicineDose'] as String?,
      medicineQuantity: parseOptionalDouble(json['medicineQuantity']),
      medicineCost: parseOptionalDouble(json['medicineCost']),
      medicineReason: json['medicineReason'] as String?,
      vaccineDose: json['vaccineDose'] as String?,
      vaccineCompletedBy: json['vaccineCompletedBy'] as String?,
      vaccineNextDueDate: parseOptionalDate(json['vaccineNextDueDate']),
      temperature: parseOptionalDouble(json['temperature']),
      humidity: parseOptionalDouble(json['humidity']),
      weather: json['weather'] as String?,
      dgLevelLiters: parseOptionalDouble(json['dgLevelLiters']),
      dgAddedLiters: parseOptionalDouble(json['dgAddedLiters']),
      dgRunningHours: parseOptionalDouble(json['dgRunningHours']),
      dgName: json['dgName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmId': farmId,
    'batchId': batchId,
    'recordDate': _formatRecordDate(recordDate),
    'batchAgeDay': batchAgeDay,
    'openingBirds': openingBirds,
    'mortalityCount': mortalityCount,
    'cullCount': cullCount,
    'adjustmentCount': adjustmentCount,
    'closingBirds': closingBirds,
    'feedConsumedKg': feedConsumedKg,
    'waterConsumedLiters': waterConsumedLiters,
    'avgWeightGrams': avgWeightGrams,
    'medicineGiven': medicineGiven,
    'medicineName': medicineName,
    'vaccineGiven': vaccineGiven,
    'vaccineName': vaccineName,
    'symptoms': symptoms,
    'notes': notes,
    'ownerId': ownerId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    // Sub-fields
    if (feedType != null) 'feedType': feedType,
    if (feedCost != null) 'feedCost': feedCost,
    if (feedSupplier != null) 'feedSupplier': feedSupplier,
    if (waterSource != null) 'waterSource': waterSource,
    if (waterQuality != null) 'waterQuality': waterQuality,
    if (mortalityCause != null) 'mortalityCause': mortalityCause,
    if (mortalityDisease != null) 'mortalityDisease': mortalityDisease,
    if (mortalityRemarks != null) 'mortalityRemarks': mortalityRemarks,
    if (sampleBirds != null) 'sampleBirds': sampleBirds,
    if (medicineDose != null) 'medicineDose': medicineDose,
    if (medicineQuantity != null) 'medicineQuantity': medicineQuantity,
    if (medicineCost != null) 'medicineCost': medicineCost,
    if (medicineReason != null) 'medicineReason': medicineReason,
    if (vaccineDose != null) 'vaccineDose': vaccineDose,
    if (vaccineCompletedBy != null) 'vaccineCompletedBy': vaccineCompletedBy,
    if (vaccineNextDueDate != null)
      'vaccineNextDueDate': vaccineNextDueDate!.toIso8601String(),
    if (temperature != null) 'temperature': temperature,
    if (humidity != null) 'humidity': humidity,
    if (weather != null) 'weather': weather,
    if (dgLevelLiters != null) 'dgLevelLiters': dgLevelLiters,
    if (dgAddedLiters != null) 'dgAddedLiters': dgAddedLiters,
    if (dgRunningHours != null) 'dgRunningHours': dgRunningHours,
    if (dgName != null) 'dgName': dgName,
  };

  DailyRecordModel copyWith({
    String? id,
    String? farmId,
    String? batchId,
    DateTime? recordDate,
    int? batchAgeDay,
    int? openingBirds,
    int? mortalityCount,
    int? cullCount,
    int? adjustmentCount,
    int? closingBirds,
    double? feedConsumedKg,
    double? waterConsumedLiters,
    double? avgWeightGrams,
    bool? medicineGiven,
    String? medicineName,
    bool? vaccineGiven,
    String? vaccineName,
    String? symptoms,
    String? notes,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? feedType,
    double? feedCost,
    String? feedSupplier,
    String? waterSource,
    String? waterQuality,
    String? mortalityCause,
    String? mortalityDisease,
    String? mortalityRemarks,
    int? sampleBirds,
    String? medicineDose,
    double? medicineQuantity,
    double? medicineCost,
    String? medicineReason,
    String? vaccineDose,
    String? vaccineCompletedBy,
    DateTime? vaccineNextDueDate,
    double? temperature,
    double? humidity,
    String? weather,
    double? dgLevelLiters,
    double? dgAddedLiters,
    double? dgRunningHours,
    String? dgName,
  }) {
    return DailyRecordModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      batchId: batchId ?? this.batchId,
      recordDate: recordDate ?? this.recordDate,
      batchAgeDay: batchAgeDay ?? this.batchAgeDay,
      openingBirds: openingBirds ?? this.openingBirds,
      mortalityCount: mortalityCount ?? this.mortalityCount,
      cullCount: cullCount ?? this.cullCount,
      adjustmentCount: adjustmentCount ?? this.adjustmentCount,
      closingBirds: closingBirds ?? this.closingBirds,
      feedConsumedKg: feedConsumedKg ?? this.feedConsumedKg,
      waterConsumedLiters: waterConsumedLiters ?? this.waterConsumedLiters,
      avgWeightGrams: avgWeightGrams ?? this.avgWeightGrams,
      medicineGiven: medicineGiven ?? this.medicineGiven,
      medicineName: medicineName ?? this.medicineName,
      vaccineGiven: vaccineGiven ?? this.vaccineGiven,
      vaccineName: vaccineName ?? this.vaccineName,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      feedType: feedType ?? this.feedType,
      feedCost: feedCost ?? this.feedCost,
      feedSupplier: feedSupplier ?? this.feedSupplier,
      waterSource: waterSource ?? this.waterSource,
      waterQuality: waterQuality ?? this.waterQuality,
      mortalityCause: mortalityCause ?? this.mortalityCause,
      mortalityDisease: mortalityDisease ?? this.mortalityDisease,
      mortalityRemarks: mortalityRemarks ?? this.mortalityRemarks,
      sampleBirds: sampleBirds ?? this.sampleBirds,
      medicineDose: medicineDose ?? this.medicineDose,
      medicineQuantity: medicineQuantity ?? this.medicineQuantity,
      medicineCost: medicineCost ?? this.medicineCost,
      medicineReason: medicineReason ?? this.medicineReason,
      vaccineDose: vaccineDose ?? this.vaccineDose,
      vaccineCompletedBy: vaccineCompletedBy ?? this.vaccineCompletedBy,
      vaccineNextDueDate: vaccineNextDueDate ?? this.vaccineNextDueDate,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      weather: weather ?? this.weather,
      dgLevelLiters: dgLevelLiters ?? this.dgLevelLiters,
      dgAddedLiters: dgAddedLiters ?? this.dgAddedLiters,
      dgRunningHours: dgRunningHours ?? this.dgRunningHours,
      dgName: dgName ?? this.dgName,
    );
  }

  static String _formatRecordDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Validates mortality input against live birds.
  static bool isValidMortality(int mortality, int liveBirds) {
    if (mortality < 0) return false;
    if (liveBirds > 0 && mortality > liveBirds) return false;
    return true;
  }

  /// Validates feed consumption (must be >= 0).
  static bool isValidFeedIntake(double feedKg) => feedKg >= 0;

  /// Validates water consumption (must be >= 0).
  static bool isValidWaterIntake(double waterLiters) => waterLiters >= 0;

  /// Validates temperature within plausible environmental poultry range (°C).
  static bool isValidTemperature(double tempC) => tempC >= 0 && tempC <= 60;

  /// Validates relative humidity percentage (0% to 100%).
  static bool isValidHumidity(double humidity) =>
      humidity >= 0 && humidity <= 100;

  static DateTime? _parseDateString(String value) {
    try {
      final parts = value.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
