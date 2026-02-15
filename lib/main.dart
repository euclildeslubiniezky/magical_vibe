import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'magical_vibe_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize App Check
  try {
    await FirebaseAppCheck.instance.activate(
      // Web Provider with reCAPTCHA v3
      webProvider: ReCaptchaV3Provider('6Lch8GssAAAAAEu18BPi0tVW_iXtKA3_3Lu23Dm_'),
      // Default providers for Android/iOS
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest,
    );
  } catch (e) {
    debugPrint('Firebase App Check activation failed: $e');
  }

  // Authentication Logic
  if (kIsWeb) {
    // On Web, persistence is managed by browser. 
    // If not signed in, we can stay anonymous or try silent Google.
    // Since UI change is prohibited, we default to Anonymous for now to ensure app works.
    // Google Sign-In capability is added to Repository for future UI.
    if (FirebaseAuth.instance.currentUser == null) {
       await FirebaseAuth.instance.signInAnonymously();
    }
  } else {
    // Mobile: Anonymous Default
     if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  runApp(const MagicalVibeApp());
}