import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'Bu platform icin Firebase options henuz tanimlanmadi.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCwuPm6Sn5WRq1FllToalZzi63sFQpm3zs', // Düzenlendi: Fazla 'I' silindi
    appId: '1:778302261559:web:c0b4d47ce1f4acf20532b2',
    messagingSenderId: '778302261559',
    projectId: 'diyetisyen-randevu-demo',
    authDomain: 'diyetisyen-randevu-demo.firebaseapp.com',
    storageBucket: 'diyetisyen-randevu-demo.firebasestorage.app',
    measurementId: 'G-M56J0CM3DJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBICFMViH5cdoFnOjsXaXHZyhGhowUl2Oc',
    appId: '1:778302261559:android:382ea72303701ff90532b2',
    messagingSenderId: '778302261559',
    projectId: 'diyetisyen-randevu-demo',
    storageBucket: 'diyetisyen-randevu-demo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC-EyddTLVFkBcxgR-ivsNq8kjEWnUdadY',
    appId: '1:778302261559:ios:66a743f58a8ff9bd0532b2',
    messagingSenderId: '778302261559',
    projectId: 'diyetisyen-randevu-demo',
    iosBundleId: 'com.diyetsiyen.demo.mobileApp',
    storageBucket: 'diyetisyen-randevu-demo.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC-EyddTLVFkBcxgR-ivsNq8kjEWnUdadY',
    appId: '1:778302261559:ios:66a743f58a8ff9bd0532b2',
    messagingSenderId: '778302261559',
    projectId: 'diyetisyen-randevu-demo',
    iosBundleId: 'com.diyetsiyen.demo.mobileApp',
    storageBucket: 'diyetisyen-randevu-demo.firebasestorage.app',
  );
}