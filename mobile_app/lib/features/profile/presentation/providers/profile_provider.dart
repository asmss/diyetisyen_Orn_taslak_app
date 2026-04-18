import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../core/models/profile_model.dart';
import '../../../../core/services/firebase/firebase_auth_service.dart';
import '../../../../core/services/firebase/firestore_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    required FirebaseAuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService {
    _authSubscription = _authService.authStateChanges().listen(_handleAuthChange);
    _handleAuthChange(_authService.currentUser);
  }

  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;
  StreamSubscription<dynamic>? _profileSubscription;
  StreamSubscription<dynamic>? _authSubscription;
  ProfileModel? _profile;
  bool _isLoading = true;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;

  void _handleAuthChange(dynamic user) {
    _profileSubscription?.cancel();
    if (user == null) {
      _profile = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    _profileSubscription = _firestoreService.watchUserProfile(user.uid).listen(
      (profile) {
        _profile = profile;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> updateWeight(double newWeight) async {
    final user = _authService.currentUser;
    if (user == null) return;
    await _firestoreService.updateUserWeight(
      userId: user.uid,
      weightKg: newWeight,
    );
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
