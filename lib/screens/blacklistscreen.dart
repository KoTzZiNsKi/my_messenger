import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Пользователи')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Нет доступных пользователей"));
          }

          var users = snapshot.data!.docs.where((doc) => doc['uid'] != currentUser?.uid).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(user['email']),
                leading: Icon(Icons.person),
                trailing: IconButton(
                  icon: Icon(Icons.block),
                  onPressed: () async {
                    // Добавление пользователя в черный список
                    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('blacklist').doc(user['uid']).set({
                      'blockedUserId': user['uid'],
                    });

                    // Можно добавить уведомление о блокировке
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Пользователь заблокирован')));
                  },
                ),
                onTap: () {
                  // Открытие чата
                  String chatId = "${currentUser.uid}_${user['uid']}";
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chatId: chatId),
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