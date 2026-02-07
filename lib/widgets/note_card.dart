import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:postapp/style/app_style.dart';

// Функция для "умного" форматирования даты
String _formatSmartDate(DateTime date) {
  final now = DateTime.now();
  final localDate = date.toLocal();

  if (now.year == localDate.year &&
      now.month == localDate.month &&
      now.day == localDate.day) {
    return DateFormat('HH:mm').format(localDate);
  } else if (now.year == localDate.year && now.month == localDate.month) {
    return DateFormat.MMMd('ru_RU').format(localDate);
  } else {
    return DateFormat.yMMMd('ru_RU').format(localDate);
  }
}

// noteCard для Supabase
Widget noteCard(Function()? onTap, Map<String, dynamic> doc) {
  // Дата создания
  DateTime creationDate;
  final dateData = doc['creation_date'];

  if (dateData is String) {
    try {
      creationDate = DateTime.parse(dateData);
    } catch (e) {
      debugPrint("Error parsing creation_date: $e");
      creationDate = DateTime.now();
    }
  } else if (dateData is DateTime) {
    creationDate = dateData;
  } else {
    creationDate = DateTime.now();
  }

  final formattedDate = _formatSmartDate(creationDate);

  // Дата напоминания
  DateTime? reminderDate;
  if (doc.containsKey('reminder_date') && doc['reminder_date'] != null) {
    try {
      reminderDate = DateTime.parse(doc['reminder_date']);
    } catch (e) {
      debugPrint("Error parsing reminder_date: $e");
    }
  }

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
            doc['note_title'] ?? '',
            style: AppStyle.mainTitle,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4.0),
          Text(
            formattedDate,
            style: AppStyle.dateTitle,
          ),
          if (reminderDate != null) ...[
            const SizedBox(height: 4.0),
            Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  size: 14,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4.0),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(reminderDate),
                  style: AppStyle.dateTitle.copyWith(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8.0),
          Text(
            doc['note_content'] ?? '',
            style: AppStyle.mainContent,
            overflow: TextOverflow.ellipsis,
            maxLines: 4,
          ),
        ],
      ),
    ),
  );
}
