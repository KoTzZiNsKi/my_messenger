import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Чаты"),
        actions: [
          IconButton(
            icon: Icon(Icons.create),
            onPressed: () => _createNewChat(context, currentUser),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('members', arrayContains: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("У вас нет чатов"));
          }

          var chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chatData = chats[index].data() as Map<String, dynamic>;
              String chatId = chats[index].id;
              List<dynamic> members = chatData['members'] ?? [];

              // Определяем UID собеседника (кроме текущего пользователя)
              String? otherUserId = members.firstWhere(
                    (uid) => uid != currentUser?.uid,
                orElse: () => null,
              );

              if (otherUserId == null) return SizedBox(); // На случай ошибки

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      title: Text("Неизвестный пользователь"),
                      onTap: () => _openChat(context, chatId, "Неизвестный"),
                    );
                  }

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  String chatName = userData['email'] ?? "Неизвестный";

                  return ListTile(
                    title: Text(chatName),
                    onTap: () => _openChat(context, chatId, chatName),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Открытие экрана чата
  void _openChat(BuildContext context, String chatId, String chatName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chatId, chatName: chatName),
      ),
    );
  }

  // Создание нового чата
  void _createNewChat(BuildContext context, User? currentUser) {
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Создать новый чат"),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: "Введите email для добавления в чат"),
          ),
          actions: [
            TextButton(
              child: Text("Отмена"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Создать"),
              onPressed: () async {
                String email = emailController.text.trim();
                if (email.isNotEmpty) {
                  await _createChat(currentUser, email, context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Логика создания чата
  Future<void> _createChat(User? currentUser, String email, BuildContext context) async {
    var userQuery = await FirebaseFirestore.
    instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (userQuery.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Пользователь не найден")),
      );
      return;
    }

    String contactId = userQuery.docs.first.id;

    // Проверяем, есть ли уже чат
    var existingChat = await FirebaseFirestore.instance
        .collection('chats')
        .where('members', arrayContains: currentUser!.uid)
        .get();

    for (var chat in existingChat.docs) {
      var members = chat['members'] as List<dynamic>;
      if (members.contains(contactId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Чат уже существует")),
        );
        return;
      }
    }

    // Создаем новый чат
    var chatRef = FirebaseFirestore.instance.collection('chats').doc();
    await chatRef.set({
      'members': [currentUser.uid, contactId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Новый чат создан")),
    );
  }
}