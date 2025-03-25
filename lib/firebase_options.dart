import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "YOUR_WEB_API_KEY",
        authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_PROJECT_ID.appspot.com",
        messagingSenderId: "YOUR_SENDER_ID",
        appId: "YOUR_WEB_APP_ID",
      );
    } else if (Platform.isAndroid) {
      return const FirebaseOptions(
        apiKey: "YOUR_ANDROID_API_KEY",
        appId: "YOUR_ANDROID_APP_ID",
        messagingSenderId: "YOUR_ANDROID_SENDER_ID",
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_PROJECT_ID.appspot.com",
      );
    } else if (Platform.isIOS) {
      return const FirebaseOptions(
        apiKey: "YOUR_IOS_API_KEY",
        appId: "YOUR_IOS_APP_ID",
        messagingSenderId: "YOUR_IOS_SENDER_ID",
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_PROJECT_ID.appspot.com",
        iosClientId: "YOUR_IOS_CLIENT_ID",
        iosBundleId: "YOUR_IOS_BUNDLE_ID",
      );
    } else {
      throw UnsupportedError("This platform is not supported");
    }
  }
}