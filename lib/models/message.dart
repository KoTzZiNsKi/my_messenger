class Message {
  final String senderId;
  final String senderEmail;
  final String text;
  final DateTime timestamp;

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.text,
    required this.timestamp,
  });

  // Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Создание объекта из Firestore
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      text: map['text'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}