import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;  // Библиотека для AES

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  ChatScreen({required this.chatId, required this.chatName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final _random = Random();

  // 🔐 Генерация ключа (можно заменить на PBKDF2, если хочешь)
  final String secretKey = "my_super_secret_key_32";  // Длина 32 байта для AES-256

  // Функция шифрования AES
  String encryptMessage(String plainText) {
    final key = encrypt.Key.fromUtf8(secretKey);
    final iv = encrypt.IV.fromLength(16); // Вектор инициализации (рандомный)

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return "${base64Encode(iv.bytes)}:${encrypted.base64}";  // Сохраняем IV вместе с текстом
  }

  // Функция расшифровки
  String decryptMessage(String encryptedText) {
    try {
      final key = encrypt.Key.fromUtf8(secretKey);
      final parts = encryptedText.split(":");
      if (parts.length != 2) return "Ошибка расшифровки";

      final iv = encrypt.IV.fromBase64(parts[0]);  // Извлекаем IV
      final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      print("❌ Ошибка расшифровки: $e");
      return "Ошибка декодирования";
    }
  }

  // Отправка сообщения (с шифрованием)
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String encryptedText = encryptMessage(_messageController.text.trim());

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add({
      'text': encryptedText,
      'senderId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("📩 Отправлено (зашифровано): $encryptedText");
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.chatName)),
    body: Column(
    children: [
    // Отображение сообщений
    Expanded(
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
    .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return Center(child: Text("Нет сообщений"));
    }

    var messages = snapshot.data!.docs;

    return ListView.builder(
    reverse: true,
    itemCount: messages.length,
    itemBuilder: (context, index) {
    var message = messages[index].data() as Map<String, dynamic>?;

    if (message == null || !message.containsKey('text')) {
    return SizedBox.shrink();
    }

    String encryptedText = message['text'] ?? "";
    String decryptedText = decryptMessage(encryptedText);
    bool isMe = message['senderId'] == currentUser?.uid;

    return Align(
    alignment: isMe ? Alignment.
    centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          decryptedText,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
    },
    );
    },
    ),
    ),

      // Поле для отправки сообщений
      Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: "Сообщение...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send, color: Colors.blue),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    ],
    ),
    );
  }
}