import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Отправка сообщения
  Future<void> sendMessage(String receiverId, String text) async {
    try {
      final senderId = _auth.currentUser!.uid;

      await _firestore.collection('messages').add({
        'text': text,
        'senderId': senderId,
        'receiverId': receiverId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Ошибка отправки сообщения: $e");
    }
  }

  // Удаление сообщения
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      print("Ошибка удаления сообщения: $e");
    }
  }

  // Изменение сообщения
  Future<void> updateMessage(String messageId, String newText) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'text': newText,
      });
    } catch (e) {
      print("Ошибка изменения сообщения: $e");
    }
  }
}