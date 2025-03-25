import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    createNotesChat();  // Создаем чат с заметками, если его еще нет
  }

  // Создание чата с заметками
  Future<void> createNotesChat() async {
    String userId = currentUser!.uid;

    // Проверим, существует ли чат
    var chatDoc = await FirebaseFirestore.instance.collection('chats').doc('notes_chat_$userId').get();

    if (!chatDoc.exists) {
      await FirebaseFirestore.instance.collection('chats').doc('notes_chat_$userId').set({
        'name': 'Заметки',
        'userIds': [userId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Добавляем первое сообщение
      await FirebaseFirestore.instance.collection('chats').doc('notes_chat_$userId').collection('messages').add({
        'text': 'Добро пожаловать в ваши заметки!',
        'senderId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Отправка заметки
  void _sendNote() async {
    String noteText = _messageController.text.trim();
    if (noteText.isEmpty) return;

    String userId = currentUser!.uid;
    String chatId = 'notes_chat_$userId';  // Чат для заметок текущего пользователя

    // Добавляем заметку в коллекцию сообщений чата
    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({
      'text': noteText,
      'senderId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Заметки')),
      body: Column(
          children: [
      Expanded(
      child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
          .doc('notes_chat_${currentUser!.uid}')
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Нет заметок"));
        }

        var messages = snapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var message = messages[index].data() as Map<String, dynamic>;

            return Container(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message['text'] ?? "",
                style: TextStyle(color: Colors.black),
              ),
            );
          },
        );
      },
    ),
    ),
    Padding(
    padding: EdgeInsets.all(8.0),
    child: Row(
    children: [
    Expanded(
    child: TextField(
    controller: _messageController,
    decoration: InputDecoration(
    labelText: "Заметка...",
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    ),
    ),
      SizedBox(width: 8),
      IconButton(
        icon: Icon(Icons.send, color: Colors.blue),
        onPressed: _sendNote,
      ),
    ],
    ),
    ),
          ],
      ),
    );
  }
}