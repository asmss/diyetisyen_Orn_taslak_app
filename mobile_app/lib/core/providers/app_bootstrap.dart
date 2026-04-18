import 'package:provider/provider.dart';

import '../services/firebase/firebase_auth_service.dart';
import '../services/firebase/firestore_service.dart';
import '../../features/appointments/presentation/providers/appointment_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/diet_plans/presentation/providers/diet_plan_provider.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

typedef AppSessionProvider = AuthProvider;

class AppBootstrap {
  const AppBootstrap._();

  static final providers = [
    Provider<FirebaseAuthService>(create: (_) => FirebaseAuthService()),
    Provider<FirestoreService>(create: (_) => FirestoreService()),
    ChangeNotifierProvider<AuthProvider>(
      create: (context) => AuthProvider(
        authService: context.read<FirebaseAuthService>(),
        firestoreService: context.read<FirestoreService>(),
      ),
    ),
    ChangeNotifierProvider<ProfileProvider>(
      create: (context) => ProfileProvider(
        authService: context.read<FirebaseAuthService>(),
        firestoreService: context.read<FirestoreService>(),
      ),
    ),
    ChangeNotifierProvider<AppointmentProvider>(
      create: (context) => AppointmentProvider(
        authService: context.read<FirebaseAuthService>(),
        firestoreService: context.read<FirestoreService>(),
      ),
    ),
    ChangeNotifierProvider<DietPlanProvider>(
      create: (context) => DietPlanProvider(
        authService: context.read<FirebaseAuthService>(),
        firestoreService: context.read<FirestoreService>(),
      ),
    ),
  ];
}
