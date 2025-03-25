import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();  // Создаем экземпляр GoogleSignIn

  // 🔹 Вход через Google
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

      if (user != null) {
        var userRef = _firestore.collection('users').doc(user.uid);
        var userDoc = await userRef.get();

        if (!userDoc.exists) {
          await userRef.set({
            'email': user.email,
            'username': user.displayName ?? 'Пользователь',
            'uid': user.uid,
          });
        }
      }

      return user;
    } catch (e) {
      print("❌ Ошибка входа через Google: $e");
      return null;
    }
  }

  // 🔹 Регистрация с никнеймом
  Future<User?> registerWithEmail(String email, String password, String username) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'username': username,
          'uid': user.uid,
        });
      }

      return user;
    } catch (e) {
      print("❌ Ошибка регистрации: $e");
      return null;
    }
  }

  // 🔹 Вход по никнейму
  Future<User?> loginWithUsername(String username, String password) async {
    try {
      // 1. Запрос для поиска пользователя по username
      var userQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)  // Фильтрация по username
          .limit(1)  // Ограничиваем результат до 1 документа
          .get();

      // 2. Если пользователь с таким username не найден
      if (userQuery.docs.isEmpty) {
        print("❌ Пользователь с таким никнеймом не найден");
        return null;
      }

      // 3. Извлекаем email пользователя из найденного документа
      String email = userQuery.docs.first.get('email');
      String uid = userQuery.docs.first.id;  // Получаем UID

      // 4. Пытаемся войти через email и пароль
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 5. Возвращаем пользователя, если он успешно вошел
      User? user = userCredential.user;

      if (user != null && user.uid == uid) {
        return user; // Успешный вход
      } else {
        print("❌ Неверный пароль");
        return null;
      }
    } catch (e) {
      print("❌ Ошибка входа: $e");
      return null;
    }
  }

  // 🔹 Изменение пароля
  Future<void> changePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("❌ Ошибка: Пользователь не найден");
        return;
      }

      await user.updatePassword(newPassword);
      print("✅ Пароль успешно изменен!");
    } catch (e) {
      print("❌ Ошибка при смене пароля: $e");
    }
  }

  // 🔹 Изменение никнейма
  Future<void> changeUsername(String newUsername) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("❌ Ошибка: Пользователь не найден");
        return;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'username': newUsername,
      });
      print("✅ Никнейм успешно изменен!");
    } catch (e) {
      print("❌ Ошибка при смене никнейма: $e");
    }
  }

  // 🔹 Выход из системы
  Future<void> signOut() async {
    await _googleSignIn.signOut();  // Выход из Google
    await _auth.signOut();          // Выход из Firebase
  }
}