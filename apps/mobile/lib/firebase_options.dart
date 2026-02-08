import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDiODUUQaVpfZusDQWZohUOeeby9Lo_6JQ',
    appId: '1:689830026078:android:ceb8a20ef7f17d9182cdcf',
    messagingSenderId: '689830026078',
    projectId: 'tmovie-2ead2',
    storageBucket: 'tmovie-2ead2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyALHhaupPjQrXSkL5PwS6kXmvh9dTiPmiM',
    appId: '1:689830026078:ios:30a687e7f3d3b3d582cdcf',
    messagingSenderId: '689830026078',
    projectId: 'tmovie-2ead2',
    storageBucket: 'tmovie-2ead2.firebasestorage.app',
    iosBundleId: 'com.thientech.mobile',
  );
}
