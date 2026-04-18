import 'package:cloud_firestore/cloud_firestore.dart';

class WeightLog {
  WeightLog({required this.date, required this.weight});

  final DateTime date;
  final double weight;

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    final timestamp = map['date'];
    return WeightLog(
      date: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'weight': weight,
    };
  }
}

class ProfileModel {
  ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.age,
    this.weightHistory = const [], // Yeni eklendi
  });

  final String id;
  final String fullName;
  final String email;
  final int heightCm;
  final double weightKg;
  final String goal;
  final int age;
  final List<WeightLog> weightHistory; // Yeni eklendi

  double get bodyMassIndex {
    final heightMeter = heightCm / 100;
    return weightKg / (heightMeter * heightMeter);
  }

  factory ProfileModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ProfileModel(
      id: id,
      fullName: map['fullName'] as String? ?? 'Demo Kullanici',
      email: map['email'] as String? ?? '',
      heightCm: (map['heightCm'] as num?)?.toInt() ?? 170,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 65,
      goal: map['goal'] as String? ?? 'Dengeli beslenme',
      age: (map['age'] as num?)?.toInt() ?? 25,
      weightHistory: ((map['weightHistory'] as List<dynamic>?) ?? [])
          .map((item) => WeightLog.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'goal': goal,
      'age': age,
      'updatedAt': FieldValue.serverTimestamp(),
      // weightHistory genelde ayrı fonksiyonla güncellenecek ama burda da bulunabilir
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? email,
    int? heightCm,
    double? weightKg,
    String? goal,
    int? age,
    List<WeightLog>? weightHistory,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goal: goal ?? this.goal,
      age: age ?? this.age,
      weightHistory: weightHistory ?? this.weightHistory,
    );
  }
}