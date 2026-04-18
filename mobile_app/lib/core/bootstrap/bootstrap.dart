import 'package:firebase_core/firebase_core.dart';

import '../services/firebase/firebase_options.dart';

class AppBootstrapper {
  const AppBootstrapper._();

  static Future<void> ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
