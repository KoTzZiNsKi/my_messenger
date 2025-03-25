import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Чаты")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Нет доступных чатов"));
          }

          var users = snapshot.data!.docs.where((doc) {
            var userData = doc.data() as Map<String, dynamic>;
            List<dynamic> blacklist = userData['blacklist'] ?? [];
            return doc.id != currentUser?.uid && !blacklist.contains(currentUser?.uid);
          }).toList();

          if (users.isEmpty) {
            return Center(child: Text("Нет доступных пользователей"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(user['email'] ?? "Без имени"),
                subtitle: Text("Нажмите, чтобы начать чат"),
                onTap: () {
                  String chatId = "${currentUser!.uid}_${user['uid']}";
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chatId: chatId, userId: user['uid']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}