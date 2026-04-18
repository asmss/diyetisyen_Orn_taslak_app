import 'package:flutter/material.dart';

import '../../../../core/models/profile_model.dart';
import '../../../../core/services/firebase/firebase_auth_service.dart';
import '../../../../core/services/firebase/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required FirebaseAuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService {
    _authService.authStateChanges().listen((user) {
      _isAuthenticated = user != null;
      notifyListeners();
    });
  }

  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;

  bool _isAuthenticated = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      _errorMessage = null;
      await _authService.signIn(email: email, password: password);
    } catch (error) {
      _errorMessage = 'Giris yapilamadi: $error';
      notifyListeners();
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      _errorMessage = null;
      if (fullName.trim().isEmpty) {
        throw Exception('Ad soyad bos olamaz.');
      }
      final credential = await _authService.register(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Kullanici olusturulamadi.');
      }
      await _firestoreService.createOrUpdateUserProfile(
        ProfileModel(
          id: user.uid,
          fullName: fullName,
          email: email,
          heightCm: 170,
          weightKg: 65,
          goal: 'Dengeli beslenme',
          age: 25,
        ),
      );
    } catch (error) {
      _errorMessage = 'Kayit olunamadi: $error';
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _errorMessage = null;
    await _authService.signOut();
    notifyListeners();
  }
}
