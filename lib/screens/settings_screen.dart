import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_messenger/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _imageFile;
  String? _avatarUrl;
  String? _username;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 🔹 Загрузка данных пользователя из Firestore
  Future<void> _loadUserData() async {
    if (currentUser == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>?; // Приводим к типу Map

    if (userData != null) {
      setState(() {
        _username = userData['username'] ?? "Без имени";
        _avatarUrl = userData['photoURL'];
        _nameController.text = _username ?? "";
      });
    }
  }

  // 🔹 Обновление никнейма
  Future<void> _updateUsername() async {
    if (currentUser == null) return;

    String newUsername = _nameController.text.trim();
    if (newUsername.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'username': newUsername});
      setState(() {
        _username = newUsername;
      });
    } catch (e) {
      print("Ошибка обновления имени: $e");
    }
  }

// 🔹 Обновление пароля
  Future<void> _updatePassword() async {
    if (currentUser == null) return;

    String currentPassword = _passwordController.text.trim();
    String newPassword = _newPasswordController.text.trim();

    // Проверяем, что оба поля не пустые
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      setState(() {
        _errorMessage = "Заполните все поля";
      });
      return;
    }

    // Проверяем, что новый пароль отличается от текущего
    if (currentPassword == newPassword) {
      setState(() {
        _errorMessage = "Новый пароль не может быть таким же, как текущий";
      });
      return;
    }

    try {
      // Логируем, что мы пытаемся сделать
      print("Попытка реаутентификации с email: ${currentUser!.email}");

      // Повторная аутентификация пользователя с текущим паролем
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );

      // Реяутентификация пользователя для изменения пароля
      await currentUser!.reauthenticateWithCredential(credential);
      print("Реяутентификация успешна!");

      // Обновляем пароль
      await currentUser!.updatePassword(newPassword);
      print("Пароль успешно обновлен!");

      // Очищаем текстовые поля после успешного изменения пароля
      _passwordController.clear();
      _newPasswordController.clear();

      // Сообщаем об успешном обновлении пароля
      setState(() {
        _errorMessage = "Пароль успешно обновлен";
      });
    } catch (e) {
      print("Ошибка при изменении пароля: ${e.toString()}"); // Логируем ошибку

      setState(() {
        _errorMessage = "Ошибка обновления пароля: ${e.toString()}";
      });
    }
  }

  // 🔹 Обновление аватара
  Future<void> _updateAvatar() async {
    if (currentUser == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
      });

      final ref = FirebaseStorage.instance.ref().child('avatars').child(currentUser!.uid);
      await ref.putFile(_imageFile!, SettableMetadata(contentType: 'image/jpeg'));
      final avatarUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'photoURL': avatarUrl});
      setState(() {
        _avatarUrl = avatarUrl;
      });
    } catch (e) {
      print("Ошибка обновления аватара: $e");
    }
  }

  // 🔹 Выход из аккаунта
  Future<void> _signOut() async {
    if (currentUser == null) return;

    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Настройки")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Отображение аватара с возможностью обновить его
            Center(
              child: GestureDetector(
                onTap: _updateAvatar,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _avatarUrl != null
                      ? NetworkImage(_avatarUrl!)
                      : AssetImage('assets/default_avatar.png') as ImageProvider,
                  child: _imageFile == null ? Icon(Icons.add_a_photo, size: 40, color: Colors.white) : null,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Отображение никнейма
            ListTile(
              title: Text("Никнейм"),
              subtitle: Text(_username ?? "Неизвестно"),
              leading: Icon(Icons.account_circle),
            ),
            Divider(),

            // Обновление никнейма
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Новый никнейм"),
            ),
            ElevatedButton(
              onPressed: _updateUsername,
              child: Text("Обновить никнейм"),
            ),
            Divider(),

            // Поля для изменения пароля
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Текущий пароль"),
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Новый пароль"),
            ),
            ElevatedButton(
              onPressed: _updatePassword,  // Вызов метода для изменения пароля
              child: Text("Изменить пароль"),
            ),

            // Отображение ошибки, если она есть
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),

            Divider(),
            ListTile(
              title: Text("Выйти"),
              leading: Icon(Icons.exit_to_app),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}