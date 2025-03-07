import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String phoneNumber = "";
  String verificationId = "";
  bool codeSent = false;
  TextEditingController smsController = TextEditingController();
  final AuthService _authService = AuthService();

  // Метод для верификации номера телефона
  void verifyPhone() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Ошибка: ${e.message}");
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          codeSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  // Метод для входа через телефон
  void signInWithPhone() async {
    String smsCode = smsController.text.trim();
    await _authService.signInWithPhone(verificationId, smsCode);
  }

  // Метод для входа через Google
  void signInWithGoogle() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      print("Вход выполнен: ${user.displayName}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Вход")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Кнопка для входа через Google
            ElevatedButton(
              onPressed: signInWithGoogle,
              child: Text("Войти через Google"),
            ),
            SizedBox(height: 20),
            // Форма для ввода номера телефона и кода
            if (!codeSent)
              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: "Номер телефона"),
                onChanged: (value) {
                  phoneNumber = value;
                },
              ),
            if (!codeSent)
              ElevatedButton(
                onPressed: verifyPhone,
                child: Text("Отправить код"),
              ),
            if (codeSent)
              TextField(
                controller: smsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Код из SMS"),
              ),
            if (codeSent)
              ElevatedButton(
                onPressed: signInWithPhone,
                child: Text("Войти через телефон"),
              ),
          ],
        ),
      ),
    );
  }
}
