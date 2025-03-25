import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class UsersListScreen extends StatelessWidget {
  Future<bool> _isBlocked(String userId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('blacklist')
        .doc(userId)
        .get();

    return snapshot.exists;
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Выберите собеседника')),
      body: Column(
          children: [
      // Кнопка для заметок
      ListTile(
      title: Text('Заметки', style: TextStyle(fontWeight: FontWeight.bold)),
      leading: Icon(Icons.note),
      onTap: () async {
        print("🔍 Проверяем заметки в Firestore...");

        var snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc('notes_user')
            .get();

        if (snapshot.exists) {
          var notesUser = snapshot.data();
          if (notesUser != null) {
            print("✅ Найдены заметки: ${notesUser['email']}");

            String notesChatId = "notes_${currentUser!.uid}";
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatScreen(chatId: notesChatId, chatName: "Заметки")),
            );
          } else {
            print("⚠️ Документ 'notes_user' пуст.");
          }
        } else {
          print("❌ Документ 'notes_user' не найден.");
        }
      },
    ),
    Divider(),

    // Список пользователей
    Expanded(
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('users').snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return Center(child: Text("Нет доступных пользователей"));
    }

    var users = snapshot.data!.docs
        .where((doc) => doc['uid'] != currentUser?.uid)
        .toList();

    return ListView.builder(
    itemCount: users.length,
    itemBuilder: (context, index) {
    var user = users[index].data() as Map<String, dynamic>;

    return FutureBuilder<bool>(
    future: _isBlocked(user['uid']),
    builder: (context, blockSnapshot) {
    if (blockSnapshot.connectionState == ConnectionState.waiting) {
    return ListTile(
    title: Text(user['email']),
    leading: Icon(Icons.person),
    subtitle: Text("Загружается..."),
    );
    }

    bool isBlocked = blockSnapshot.data ?? false;

    return ListTile(
    title: Text(user['email']),
    leading: Icon(Icons.person),
    subtitle: isBlocked ? Text("Заблокирован", style: TextStyle(color: Colors.red)) : null,
    onTap: isBlocked
    ? null
        : () {
    String chatId = "${currentUser!.uid}_${user['uid']}";
    Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        chatId: chatId,
        chatName: user['email'],
      ),
    ),
    );
    },
    );
    },
    );
    },
    );
    },
    ),
    ),
          ],
      ),
    );
  }
}