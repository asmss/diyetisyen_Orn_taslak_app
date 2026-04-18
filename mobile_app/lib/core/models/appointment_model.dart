import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { pending, upcoming, completed, cancelled }

class AppointmentModel {
  AppointmentModel({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.durationMinutes,
    required this.notes,
    required this.status,
  });

  final String id;
  final String title;
  final DateTime dateTime;
  final int durationMinutes;
  final String notes;
  final AppointmentStatus status;

  DateTime get endTime => dateTime.add(Duration(minutes: durationMinutes));

  // DÜZELTİLDİ: Çift id parametresi kaldırıldı
  factory AppointmentModel.fromMap(Map<String, dynamic> map, {required String id}) {
    final timestamp = map['dateTime'];
    final dateTime = timestamp is Timestamp
        ? timestamp.toDate()
        : DateTime.tryParse(timestamp.toString()) ?? DateTime.now();

    return AppointmentModel(
      id: id,
      title: map['title'] as String? ?? 'Randevu Talebi',
      dateTime: dateTime,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 40,
      notes: map['notes'] as String? ?? '',
      status: AppointmentStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => AppointmentStatus.pending,
      ),
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
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'notes': notes,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}