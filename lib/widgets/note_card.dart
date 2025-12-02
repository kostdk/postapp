import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart"; 
import "package:postapp/style/app_style.dart";

// Функция для "умного" форматирования даты
String _formatSmartDate(DateTime date) {
  final now = DateTime.now();
  final localDate = date.toLocal();
  
  if (now.year == localDate.year && now.month == localDate.month && now.day == localDate.day) {
    return DateFormat('HH:mm').format(localDate); 
  } else if (now.year == localDate.year && now.month == localDate.month) {
    return DateFormat.MMMd('ru_RU').format(localDate); 
  } else {
    return DateFormat.yMMMd('ru_RU').format(localDate);
  }
}


Widget noteCard(Function()? onTap, QueryDocumentSnapshot doc){
  

  dynamic dateData = doc["creation_date"];
  DateTime creationDate;

  if (dateData is String) {
    try {
      final format = DateFormat("MMMM d, yyyy HH:mm:ss");
      creationDate = format.parse(dateData);
    } catch (e) {
 
      debugPrint("Error parsing date string in noteCard: $e"); 
      creationDate = DateTime.now();
    }
  } else if (dateData is Timestamp) {
    creationDate = dateData.toDate();
  } else {
    creationDate = DateTime.now(); 
  }
  
  String formattedDate = _formatSmartDate(creationDate);
 


  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppStyle.cardsColor[doc['color_id']],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column( 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [ 
          
          
          Text(
            doc["note_title"], 
            style: AppStyle.mainTitle,
            overflow: TextOverflow.ellipsis,
          ), 
          
          const SizedBox(height: 4.0,),
          Text(
            formattedDate,
            style: AppStyle.dateTitle,
          ),
          const SizedBox(height: 8.0,),
          Text(
            doc["note_content"],
            style: AppStyle.mainContent,
            overflow: TextOverflow.ellipsis,
            maxLines: 4,
          )
        ], 
      ),
    ),
  );
}
