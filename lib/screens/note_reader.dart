import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postapp/style/app_style.dart';
import 'package:postapp/services/notification_service.dart';

// ignore: must_be_immutable
class NoteReaderScreen extends StatefulWidget {
  NoteReaderScreen(this.noteData, {super.key});
  Map<String, dynamic> noteData;

  @override
  State<NoteReaderScreen> createState() => _NoteReaderScreenState();
}

class _NoteReaderScreenState extends State<NoteReaderScreen> {
  final supabase = Supabase.instance.client;

  String _formatSmartDate(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();

    if (now.year == localDate.year &&
        now.month == localDate.month &&
        now.day == localDate.day) {
      return DateFormat('HH:mm').format(localDate);
    }
    if (now.year == localDate.year) {
      return DateFormat('d MMM', 'ru_RU').format(localDate);
    }
    return DateFormat('d MMM y', 'ru_RU').format(localDate);
  }

  Future<void> deleteNote(String noteId) async {
    // Показываем диалог подтверждения
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: const Text('Вы уверены, что хотите удалить эту заметку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    // Если пользователь отменил, выходим
    if (confirm != true) return;

    // Отменяем уведомление (если id уведомления завязан на noteId.hashCode)
    await NotificationService().cancelNotification(noteId.hashCode);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Удаляем заметку и возвращаем удалённые строки
      final res = await supabase
          .from('notes')
          .delete()
          .eq('id', noteId)
          .eq('user_id', user.id)
          .select();

      if (!mounted) return;

      if (res.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Заметка не найдена или не принадлежит текущему пользователю'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Показываем сообщение об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заметка удалена!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      // ВАЖНО: Возвращаем true чтобы HomeScreen обновил список
      Navigator.pop(context, true);
      
    } catch (e) {
      print("Failed to delete note: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении заметки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.noteData;
    final int colorId = (data['color_id'] ?? 0) as int;

    // id как uuid-строка
    final String noteId = data['id'] as String;

    DateTime creationDate;
    final dateData = data['creation_date'];

    if (dateData is String) {
      try {
        creationDate = DateTime.parse(dateData);
      } catch (e) {
        creationDate = DateTime.now();
      }
    } else if (dateData is DateTime) {
      creationDate = dateData;
    } else {
      creationDate = DateTime.now();
    }

    final String formattedDate = _formatSmartDate(creationDate);

    DateTime? reminderDate;
    if (data.containsKey('reminder_date') && data['reminder_date'] != null) {
      try {
        // В Supabase timestamp with time zone → String → DateTime.parse
        reminderDate = DateTime.parse(data['reminder_date'] as String);
      } catch (e) {
        print("Error parsing reminder date: $e");
      }
    }

    return Scaffold(
      backgroundColor: AppStyle.cardsColor[colorId],
      appBar: AppBar(
        backgroundColor: AppStyle.cardsColor[colorId],
        elevation: 0.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Удалить заметку',
            onPressed: () => deleteNote(noteId),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['note_title'] as String, style: AppStyle.mainTitle),
            const SizedBox(height: 4),
            Text(formattedDate, style: AppStyle.dateTitle),
            if (reminderDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active,
                        color: Colors.orange.shade700),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Напоминание",
                            style: AppStyle.dateTitle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm', 'ru_RU')
                                .format(reminderDate),
                            style: AppStyle.dateTitle.copyWith(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  data['note_content'] as String,
                  style: AppStyle.mainContent,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => deleteNote(noteId),
        backgroundColor: Colors.red,
        child: const Icon(Icons.delete),
      ),
    );
  }
}