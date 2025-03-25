import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/chats_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notes_screen.dart'; // Экран заметок
import 'firebase_options.dart';

/// Главная точка входа в приложение
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🚀 Начало инициализации Firebase...");
  try {
    // Инициализация Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print("✅ Firebase успешно инициализирован!");
  } catch (e) {
    print("❌ Ошибка при инициализации Firebase: $e");
  }

  // Запуск приложения
  runApp(MyApp());
}

/// Основной виджет приложения
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      supportedLocales: [
        Locale('en', 'US'), // Поддержка английского
        Locale('ru', 'RU'), // Поддержка русского
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: Locale('ru', 'RU'), // Устанавливаем локаль по умолчанию (русский)
      home: AuthWrapper(), // Определяем, какую страницу показывать (логин или домашнюю)
    );
  }
}

/// Определяет, показывать экран авторизации или домашний экран
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Отслеживает изменения состояния пользователя
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator())); // Показываем индикатор загрузки
        }

        if (snapshot.hasData) {
          return HomeScreen(); // Если пользователь авторизован, показываем домашний экран
        } else {
          return LoginScreen(); // Если нет — экран входа
        }
      },
    );
  }
}

/// Главный экран с навигацией между вкладками
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // Индекс текущей вкладки
  late PageController _pageController; // Контроллер для анимации переключения страниц

  final List<Widget> _screens = [
    ChatsScreen(),
    ContactsScreen(),
    SettingsScreen(),
    NotesScreen(),  // Экран заметок
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  /// Переключение страниц по тапу в BottomNavigationBar
  void _onItemTapped(int index) {
    _pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  /// Обновление индекса при перелистывании
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
            items: [
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Чаты"),
    BottomNavigationBarItem(icon: Icon(Icons.contacts), label: "Контакты"),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Настройки"),
              BottomNavigationBarItem(icon: Icon(Icons.note), label: "Заметки"),  // Вкладка для заметок
            ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
        ),
    );
  }
}

/// Экран входа через Google
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: Text("Войти через Google"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () async {
            try {
              print("🟡 Начало авторизации через Google...");

              // Открываем окно входа Google
              final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
              if (googleUser == null) {
                print("❌ Вход отменен пользователем");
                return;
              }

              // Получаем аутентификационные данные Google
              final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
              final AuthCredential credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );

              // Авторизуем пользователя в Firebase
              final UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
              var user = userCredential.user;

              if (user != null) {
                print("✅ Пользователь вошел: ${user.email}");

                // Добавляем или обновляем пользователя в Firestore
                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                  'email': user.email,
                  'uid': user.uid,
                  'blacklist': [],
                }, SetOptions(merge: true));
              }
            } catch (e) {
              print("❌ Ошибка входа через Google: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Ошибка входа: $e")),
              );
            }
          },
        ),
      ),
    );
  }
}