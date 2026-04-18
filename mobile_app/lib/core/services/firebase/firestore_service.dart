import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/appointment_model.dart';
import '../../models/diet_plan_model.dart';
import '../../models/profile_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get appointments =>
      _firestore.collection('appointments');

  CollectionReference<Map<String, dynamic>> get dietPlans =>
      _firestore.collection('dietPlans');

  Stream<ProfileModel?> watchUserProfile(String userId) {
    return users.doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return ProfileModel.fromMap(snapshot.id, data);
    });
  }

  Future<void> createOrUpdateUserProfile(ProfileModel profile) {
    return users.doc(profile.id).set(profile.toMap(), SetOptions(merge: true));
  }

  // SADECE KİLO GÜNCELLEME (Eski yöntem)
  Future<void> updateUserWeight({
    required String userId,
    required double weightKg,
  }) {
    return users.doc(userId).set({
      'weightKg': weightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // YENİ: HEM KİLO GÜNCELLE HEM GEÇMİŞE YAZ
  Future<void> logDailyWeight({
    required String userId,
    required double weightKg,
  }) async {
    // ÇÖZÜM BURADA: FieldValue.serverTimestamp() yerine Timestamp.now() kullanıyoruz.
    final logEntry = {
      'date': Timestamp.now(), 
      'weight': weightKg,
    };

    return users.doc(userId).set({
      'weightKg': weightKg, 
      'updatedAt': FieldValue.serverTimestamp(), // Bu tekil bir alan olduğu için burada sorun yok
      'weightHistory': FieldValue.arrayUnion([logEntry]), 
    }, SetOptions(merge: true));
  }

  Stream<List<AppointmentModel>> watchAppointments(String userId) {
    return appointments
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppointmentModel.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<void> createAppointment(AppointmentModel appointment, ProfileModel profile) {
    return appointments.add(
      appointment.toMap(userId: profile.id, userName: profile.fullName),
    );
  }

  Stream<List<DietPlanModel>> watchDietPlans(String userId) {
    return dietPlans
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DietPlanModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}