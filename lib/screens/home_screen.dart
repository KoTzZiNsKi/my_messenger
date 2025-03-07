import 'package:flutter/material.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Чаты")),
      body: ListView(
        children: [
          ListTile(
            title: Text("Чат 1"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(chatId: "chat1", userId: "testUser"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}