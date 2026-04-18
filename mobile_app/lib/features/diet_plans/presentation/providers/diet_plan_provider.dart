import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../core/models/diet_plan_model.dart';
import '../../../../core/services/firebase/firebase_auth_service.dart';
import '../../../../core/services/firebase/firestore_service.dart';

class DietPlanProvider extends ChangeNotifier {
  DietPlanProvider({
    required FirebaseAuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService {
    _authSubscription = _authService.authStateChanges().listen(_handleAuthChange);
    _handleAuthChange(_authService.currentUser);
  }

  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;
  final List<DietPlanModel> _plans = [];
  StreamSubscription<dynamic>? _dietPlansSubscription;
  StreamSubscription<dynamic>? _authSubscription;
  bool _isLoading = true;

  List<DietPlanModel> get plans => List.unmodifiable(_plans);
  bool get isLoading => _isLoading;

  DietPlanModel? get activePlan => _plans.isEmpty ? null : _plans.first;

  void _handleAuthChange(dynamic user) {
    _dietPlansSubscription?.cancel();
    _plans.clear();
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    _dietPlansSubscription = _firestoreService.watchDietPlans(user.uid).listen(
      (items) {
        _plans
          ..clear()
          ..addAll(items);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _dietPlansSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
