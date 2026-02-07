import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final supabase = Supabase.instance.client;
  int _currentIndex = 0;
  
  // Глобальный ключ для сохранения состояния HomeContentScreen
  final GlobalKey<_HomeContentScreenState> _homeKey = GlobalKey<_HomeContentScreenState>();

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

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
                setState(() {
                  _currentIndex = 2;
                });
              }
            },
            icon: Icon(
              Icons.person,
              color: (user == null) ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeContentScreen(key: _homeKey, userId: user?.id),
          const NoteEditorScreen(),
          const AccountScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Обновляем список при возврате на главную
          if (index == 0) {
            _homeKey.currentState?._refreshNotes();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class HomeContentScreen extends StatefulWidget {
  final String? userId;

  const HomeContentScreen({super.key, this.userId});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  final supabase = Supabase.instance.client;
  
  // Ключ для принудительного обновления StreamBuilder
  int _refreshKey = 0;

  void _refreshNotes() {
    if (mounted) {
      setState(() {
        _refreshKey++;
        print('🔄 Обновление списка заметок (key: $_refreshKey)');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null) {
      return Center(
        child: Text(
          "Please login to see your notes",
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              key: ValueKey(_refreshKey),
              stream: supabase
                  .from('notes')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', widget.userId!)
                  .order('creation_date', ascending: false),
              builder: (context, snapshot) {
                print('📡 StreamBuilder состояние: ${snapshot.connectionState}');
                print('📊 Количество заметок: ${snapshot.data?.length ?? 0}');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: GoogleFonts.nunito(color: Colors.red, fontSize: 16),
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final notes = snapshot.data!;
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return noteCard(
                        () async {
                          print('📝 Открываем заметку: ${note['note_title']}');
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteReaderScreen(note),
                            ),
                          );
                          
                          print('↩️ Вернулись из NoteReader, result: $result');
                          
                          // Если вернулось true (заметка была удалена), обновляем список
                          if (result == true) {
                            print('✅ Заметка была удалена, обновляем список');
                            _refreshNotes();
                          }
                        },
                        note,
                      );
                    },
                  );
                }

                return Center(
                  child: Text(
                    "Sorry, no Notes",
                    style: GoogleFonts.nunito(color: Colors.white, fontSize: 16),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}