import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:my_messenger/screens/register_screen.dart';
import 'settings_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // 🔹 Метод для входа через никнейм
  void _signInWithUsername() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Введите никнейм и пароль";
      });
      return;
    }

    User? user = await _authService.loginWithUsername(username, password);
    if (user == null) {
      setState(() {
        _errorMessage = "Неверный никнейм или пароль";
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SettingsScreen()),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 🔹 Метод для входа через Google
  void _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await _authService.signInWithGoogle();
    if (user == null) {
      setState(() {
        _errorMessage = "Ошибка входа через Google";
      });
    } else {
      // Если пользователь вошел через Google, проверим, есть ли у него привязанный пароль
      List<UserInfo> providerData = user.providerData;
      bool hasPassword = providerData.any((info) => info.providerId == "password");

      if (!hasPassword) {
        _showSetPasswordDialog(user); // Показываем диалог для установки пароля
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SettingsScreen()),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 🔹 Диалоговое окно для установки пароля
  void _showSetPasswordDialog(User user) {
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();
    String? errorText;

    showDialog(
        context: context,
        builder: (context) {
      return StatefulBuilder(
          builder: (context, setState) {
        return AlertDialog(
            title: Text("Установите пароль"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Новый пароль"),
                ),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Подтвердите пароль"),
                ),
                if (errorText != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(errorText!, style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            actions: [
            TextButton(
            onPressed: () => Navigator.pop(context),
    child: Text("Отмена"),
    ),
    TextButton(
    onPressed: () async {
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    // 🔹 Проверяем, что пароль не пустой
    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() => errorText = "Заполните все поля");
      return;
    }

    // 🔹 Проверяем минимальную длину пароля
    if (password.length < 6) {
      setState(() => errorText = "Пароль должен быть не менее 6 символов");
      return;
    }

    // 🔹 Проверяем совпадение паролей
    if (password != confirmPassword) {
      setState(() => errorText = "Пароли не совпадают");
      return;
    }

    try {
      // 🔹 Повторная аутентификация через Google
      final googleProvider = GoogleAuthProvider();
      final reauthResult = await user.reauthenticateWithProvider(googleProvider);

      print("✅ Повторная аутентификация успешна!");

      // 🔹 Теперь обновляем пароль
      await user.updatePassword(password);

      print("✅ Пароль успешно установлен!");

      // 🔹 Закрываем диалог и просим пользователя войти заново
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Пароль установлен! Войдите снова.")),
      );
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("❌ Ошибка установки пароля: $e");
      setState(() => errorText = "Ошибка: ${e.toString()}");
    }
    },
      child: Text("Сохранить"),
    ),
            ],
        );
          },
      );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Вход")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Никнейм"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Пароль"),
            ),
            SizedBox(height: 10),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _signInWithUsername,
              child: Text("Войти"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: Text("Войти через Google"),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text("Нет аккаунта? Зарегистрироваться"),
            ),
          ],
        ),
      ),
    );
  }
}