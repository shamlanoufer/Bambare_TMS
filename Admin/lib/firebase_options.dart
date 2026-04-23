// Generated from Firebase config in this repo (google-services.json,
// GoogleService-Info.plist, firebase.json). Re-run FlutterFire CLI if you rotate keys.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD5J4NlweaXWhL8hjLf0nBlQnfWE9eBTCo',
    appId: '1:36981082575:web:0a50d5e4a3673db085eaba',
    messagingSenderId: '36981082575',
    projectId: 'bambare-14a12',
    authDomain: 'bambare-14a12.firebaseapp.com',
    storageBucket: 'bambare-14a12.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD5J4NlweaXWhL8hjLf0nBlQnfWE9eBTCo',
    appId: '1:36981082575:android:34866783532274d485eaba',
    messagingSenderId: '36981082575',
    projectId: 'bambare-14a12',
    storageBucket: 'bambare-14a12.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBArVLDDguFoxggueVfPRcC4bmpsSVI_fk',
    appId: '1:36981082575:ios:f770f363d3e5c32e85eaba',
    messagingSenderId: '36981082575',
    projectId: 'bambare-14a12',
    storageBucket: 'bambare-14a12.firebasestorage.app',
    iosBundleId: 'com.example.userTws',
  );
}
