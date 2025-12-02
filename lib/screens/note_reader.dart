import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart"; // Импортируем intl
import "package:postapp/style/app_style.dart";

// ignore: must_be_immutable
class NoteReaderScreen extends StatefulWidget {
  NoteReaderScreen(this.doc, {super.key});
  QueryDocumentSnapshot doc;

  @override
  State<NoteReaderScreen> createState() => _NoteReaderScreenState();
}

class _NoteReaderScreenState extends State<NoteReaderScreen> {
  User? user = FirebaseAuth.instance.currentUser;

  // Функция для "умного" форматирования даты
  String _formatSmartDate(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    
    // Используем текущую дату для сравнения (сегодня 1 декабря 2025 года)
    if (now.year == localDate.year && now.month == localDate.month && now.day == localDate.day) {
      // Если сегодня: отображаем только время
      return DateFormat('HH:mm').format(localDate); 
    } else if (now.year == localDate.year && now.month == localDate.month) {
      // Если этот месяц: отображаем день и месяц
      return DateFormat.MMMd('ru_RU').format(localDate); 
    } else {
      // В остальных случаях: отображаем полную дату
      return DateFormat.yMMMd('ru_RU').format(localDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    int colorId = widget.doc['color_id'];

   
    dynamic dateData = widget.doc["creation_date"];
    DateTime creationDate;

    if (dateData is String) {
      // Если это строка, используем DateFormat для парсинга кастомного формата
      try {
        // Формат, который соответствует вашей строке: "November 30, 2025 15:12:05"
        final format = DateFormat("MMMM d, yyyy HH:mm:ss");
        creationDate = format.parse(dateData);
      } catch (e) {
        print("Error parsing date string: $e");
        creationDate = DateTime.now();
      }
    } else if (dateData is Timestamp) {
      // Если это Timestamp (рекомендуемый формат), конвертируем
      creationDate = dateData.toDate();
    } else {
      // Запасной вариант
      creationDate = DateTime.now(); 
    }
   
    
    // Форматируем дату с помощью нашей новой функции
    String formattedDate = _formatSmartDate(creationDate);

    return Scaffold(
      backgroundColor: AppStyle.cardsColor[colorId],
      appBar: AppBar(
        backgroundColor: AppStyle.cardsColor[colorId],
        elevation:0.0,
      ),
      body:
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.doc["note_title"],
              style: AppStyle.mainTitle,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0,),
            Text(
              formattedDate,
              style: AppStyle.dateTitle,
            ),
            const SizedBox(height: 28.0,),
            Text(
              widget.doc["note_content"],
              style: AppStyle.mainContent,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
       floatingActionButton: FloatingActionButton(
          onPressed: () async {
            FirebaseFirestore.instance.collection(user!.uid).doc(widget.doc.id).delete().then((value){
              print (null);           
              Navigator.pop(context);
       }).catchError((error) => print("failed to delete due $error"));
          },
          child: const Icon(Icons.delete),
    ));
  }
}
