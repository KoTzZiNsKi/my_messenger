import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Контакты"),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () => _addContactDialog(context, currentUser),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> contacts = userData['contacts'] ?? [];
          List<dynamic> blacklist = userData['blacklist'] ?? [];

          if (contacts.isEmpty) {
            return Center(child: Text("У вас пока нет контактов"));
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              String contactId = contacts[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(contactId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return SizedBox.shrink();
                  }

                  var contactData = userSnapshot.data!.data() as Map<String, dynamic>;
                  String contactEmail = contactData['email'] ?? "Неизвестный пользователь";

                  // Проверка, не в черном ли списке контакт
                  if (blacklist != null && blacklist.contains(contactId)) {
                    return SizedBox.shrink();
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(contactEmail),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeContact(currentUser, contactId),
                    ),
                    onTap: () {
                      String chatId = "${currentUser!.uid}_$contactId";
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(chatId: chatId, chatName: contactEmail),
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
    );
  }

  // Диалоговое окно для добавления контакта
  void _addContactDialog(BuildContext context, User? currentUser) {
    TextEditingController emailController = TextEditingController();

    showDialog(
        context: context,
        builder: (context) {
      return AlertDialog(
          title: Text("Добавить контакт"),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: "Введите email"),
          ),
          actions: [
      TextButton(
      child: Text("Отмена"),
    onPressed: () => Navigator.pop(context),
    ),
    TextButton(
    child: Text("Добавить"),
    onPressed: () async {
    String email = emailController.text.trim();
    if (email.isNotEmpty) {
    await _addContact(currentUser, email);
    Navigator.pop(context);
    }
    },
    ),
          ],
      );
        },
    );
  }

  // Логика добавления контакта
  Future<void> _addContact(User? currentUser, String email) async {
    var userQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
    if (userQuery.docs.isEmpty) {
      print("❌ Пользователь не найден");
      return;
    }

    String contactId = userQuery.docs.first.id;
    await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).update({
      'contacts': FieldValue.arrayUnion([contactId])
    });

    print("✅ Контакт добавлен");
  }

  // Логика удаления контакта
  Future<void> _removeContact(User? currentUser, String contactId) async {
    await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).update({
      'contacts': FieldValue.arrayRemove([contactId])
    });

    print("❌ Контакт удалён");
  }
}