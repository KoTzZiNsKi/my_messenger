import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Метод для входа с помощью Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      // Добавляем пользователя в коллекцию users, если его там нет
      var userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      var userDoc = await userRef.get();

      if (!userDoc.exists) {
        await userRef.set({
          'email': user.email,
          'name': user.displayName,
          'uid': user.uid,
        });
      }

      return user;
    } catch (e) {
      print("Ошибка входа через Google: $e");
      return null;
    }
  }

  // Метод для выхода из системы
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}