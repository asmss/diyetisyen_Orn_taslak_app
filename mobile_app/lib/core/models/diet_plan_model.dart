import 'package:cloud_firestore/cloud_firestore.dart';

class MealEntry {
  MealEntry({
    required this.timeLabel,
    required this.title,
    required this.description,
  });

  final String timeLabel;
  final String title;
  final String description;

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      timeLabel: map['timeLabel'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timeLabel': timeLabel,
      'title': title,
      'description': description,
    };
  }
}

class DietPlanModel {
  DietPlanModel({
    required this.id,
    required this.title,
    required this.dietitianName,
    required this.startDate,
    required this.endDate,
    required this.waterTargetLiters,
    required this.notes,
    required this.meals,
  });

  final String id;
  final String title;
  final String dietitianName;
  final DateTime startDate;
  final DateTime endDate;
  final double waterTargetLiters;
  final String notes;
  final List<MealEntry> meals;

  factory DietPlanModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final startTimestamp = map['startDate'];
    final endTimestamp = map['endDate'];

    return DietPlanModel(
      id: id,
      title: map['title'] as String? ?? 'Diyet Plani',
      dietitianName: map['dietitianName'] as String? ?? 'Diyetisyen',
      startDate: startTimestamp is Timestamp
          ? startTimestamp.toDate()
          : DateTime.now(),
      endDate: endTimestamp is Timestamp
          ? endTimestamp.toDate()
          : DateTime.now().add(const Duration(days: 7)),
      waterTargetLiters: (map['waterTargetLiters'] as num?)?.toDouble() ?? 2,
      notes: map['notes'] as String? ?? '',
      meals: ((map['meals'] as List<dynamic>?) ?? [])
          .map((item) => MealEntry.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap({
    required String userId,
    required String userName,
  }) {
    return {
      'userId': userId,
      'userName': userName,
      'title': title,
      'dietitianName': dietitianName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'waterTargetLiters': waterTargetLiters,
      'notes': notes,
      'meals': meals.map((meal) => meal.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
