import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../core/models/appointment_model.dart';
import '../../../../core/models/profile_model.dart';
import '../../../../core/services/firebase/firebase_auth_service.dart';
import '../../../../core/services/firebase/firestore_service.dart';

class AppointmentProvider extends ChangeNotifier {
  AppointmentProvider({
    required FirebaseAuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService {
    _authSubscription = _authService.authStateChanges().listen(_handleAuthChange);
    _handleAuthChange(_authService.currentUser);
  }

  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;
  final List<AppointmentModel> _appointments = [];
  StreamSubscription<dynamic>? _appointmentsSubscription;
  StreamSubscription<dynamic>? _authSubscription;
  bool _isLoading = true;

  // DÜZELTME: İptal edilen (cancelled) randevular artık bu listede GÖZÜKMEYECEK
  List<AppointmentModel> get allAppointments => _appointments
      .where((item) => item.status != AppointmentStatus.cancelled)
      .toList();

  bool get isLoading => _isLoading;

  List<AppointmentModel> get upcomingAppointments => _appointments
      .where((item) => item.status == AppointmentStatus.upcoming)
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  void _handleAuthChange(dynamic user) {
    _appointmentsSubscription?.cancel();
    _appointments.clear();
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    _appointmentsSubscription = _firestoreService.watchAppointments(user.uid).listen(
      (items) {
        _appointments
          ..clear()
          ..addAll(items);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> deleteAppointment(String appointmentId) async {
    if (appointmentId.isEmpty) {
      debugPrint('KRİTİK HATA: Silinmek istenen randevunun IDsi boş!');
      return false; 
    }

    try {
      await _firestoreService.appointments.doc(appointmentId).delete();
      return true; 
    } catch (e) {
      debugPrint('Randevu silinirken hata: $e');
      return false; 
    }
  }

  Future<void> createAppointment({
    required DateTime date,
    required ProfileModel profile,
  }) async {
    await _firestoreService.createAppointment(
      AppointmentModel(
        id: '',
        title: 'Randevu Talebi',
        dateTime: date,
        durationMinutes: 40,
        notes: 'Mobil uygulama üzerinden talep oluşturuldu.',
        status: AppointmentStatus.pending,
      ),
      profile,
    );
  }

  Future<void> refreshData() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}