import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/users_list_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🚀 Начало инициализации Firebase...");
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print("✅ Firebase успешно инициализирован!");
  } catch (e) {
    print("❌ Ошибка при инициализации Firebase: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return UsersListScreen();
        } else {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                child: Text("Войти через Google"),
                onPressed: () async {
                  try {
                    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
                    if (googleUser == null) return;

                    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

                    final AuthCredential credential = GoogleAuthProvider.credential(
                      accessToken: googleAuth.accessToken,
                      idToken: googleAuth.idToken,
                    );

                    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

                    var user = userCredential.user;
                    if (user != null) {
                      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                        'email': user.email,
                        'uid': user.uid,
                      }, SetOptions(merge: true));
                    }
                  } catch (e) {
                    print("Ошибка входа через Google: $e");
                  }
                },
              ),
            ),
          );
        }
      },
    );
  }
}