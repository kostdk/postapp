import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:postapp/screens/home_screen.dart';
import 'package:postapp/style/app_style.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  int color_id = Random().nextInt(AppStyle.cardsColor.length);
  User? user = FirebaseAuth.instance.currentUser;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _mainController = TextEditingController();
  final String date = DateFormat.yMMMMd().add_Hms().format(DateTime.now()).toString();
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppStyle.cardsColor[color_id],
        appBar: AppBar(
          backgroundColor: AppStyle.cardsColor[color_id],
          elevation: 0.0,
          title: const Text(
            "Add new Note",
          ),
        
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Note title",
                  ),
                  style: AppStyle.mainTitle,
                ),
                const SizedBox(
                  height: 8.0,
                ),
                Text(
                  date,
                  style: AppStyle.dateTitle,
                ),
                const SizedBox(
                  height: 8.0,
                ),
                TextField(
                  controller: _mainController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Note content",
                  ),
                  style: AppStyle.mainContent,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
         
          onPressed: () async {
            
            if (_titleController.text.isEmpty || _mainController.text.isEmpty) {
            // Показываем предупреждение если поле заголовка пустое
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Title and content is required!'),
                backgroundColor: Colors.red,
              ),
            );
            return; // Прекращаем выполнение метода onPressed
          }

          // Сохранение заметки в Firestore
          FirebaseFirestore.instance.collection(user!.uid).add({
            "note_title": _titleController.text,
            "creation_date": date,
            "note_content": _mainController.text,
            "color_id": color_id,
          }).then((value) {
            Navigator.pushReplacement(context,MaterialPageRoute(builder:(contex) => const HomeScreen()),);
          });
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}