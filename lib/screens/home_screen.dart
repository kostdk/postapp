import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:postapp/screens/account_screen.dart';
import 'package:postapp/screens/login_screen.dart';
import 'package:postapp/screens/note_editor.dart';
import 'package:postapp/screens/note_reader.dart';
import 'package:postapp/style/app_style.dart';
import 'package:postapp/widgets/note_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  int _currentIndex = 0;

  // Определяем список виджетов для страниц, на которые будем переключаться
  final List<Widget> _pages = [
    const HomeContentScreen(), // Основной контент домашней страницы
    const NoteEditorScreen(),
    const AccountScreen(),     // Страница аккаунта
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.mainColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0.0,
        centerTitle: true,
        title: const Text("PostApp"),
        backgroundColor: AppStyle.bgColor,
        actions: [
          IconButton(
            onPressed: () {
              if (user == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AccountScreen()),
                );
              }
            },
            icon: Icon(
              Icons.person,
              color: (user == null) ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),

      body: _pages[_currentIndex], // Показываем текущую выбранную страницу

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),

    //   floatingActionButton: _currentIndex == 0
    //       ? FloatingActionButton.extended(
    //           onPressed: () {
    //             Navigator.push(
    //                 context,
    //                 MaterialPageRoute(
    //                     builder: (context) => const NoteEditorScreen()));
    //           },
    //           label: const Text("Add Note"),
    //           icon: const Icon(Icons.add),
    //         )
    //       : null, // Отображаем кнопку только на главной странице
    // );
  );}
}

class HomeContentScreen extends StatelessWidget {
  const HomeContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Your recent Notes",
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(user!.uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasData) {
                  return GridView(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2),
                    children: snapshot.data!.docs
                        .map((note) => noteCard(() {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NoteReaderScreen(note),
                                  ));
                            }, note))
                        .toList(),
                  );
                }
                return Text(
                  "Sorry, no Notes",
                  style: GoogleFonts.nunito(color: Colors.white),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
