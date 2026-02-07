import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postapp/screens/home_screen.dart';
import 'package:postapp/style/app_style.dart';
import 'package:postapp/services/notification_service.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  int color_id = Random().nextInt(AppStyle.cardsColor.length);
  final supabase = Supabase.instance.client;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _mainController = TextEditingController();
  final String date = DateFormat.yMMMMd().add_Hms().format(DateTime.now()).toString();
  DateTime? _reminderDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.cardsColor[color_id],
      appBar: AppBar(
        backgroundColor: AppStyle.cardsColor[color_id],
        elevation: 0.0,
        title: const Text("Add new Note"),
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
              const SizedBox(height: 8.0),
              Text(date, style: AppStyle.dateTitle),
              const SizedBox(height: 8.0),
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
              const SizedBox(height: 16.0),
              // Напоминание
              Row(
                children: [
                  const Icon(Icons.notifications, size: 20),
                  const SizedBox(width: 8.0),
                  Text(
                    _reminderDate == null
                        ? "Напоминание не установлено"
                        : "Напоминание: ${DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(_reminderDate!)}",
                    style: AppStyle.dateTitle,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('ru', 'RU'),
                      );
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _reminderDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _reminderDate == null ? "Установить напоминание" : "Изменить напоминание",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  if (_reminderDate != null) ...[
                    const SizedBox(width: 8.0),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _reminderDate = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      tooltip: "Удалить напоминание",
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_titleController.text.isEmpty || _mainController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Title and content is required!'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final user = supabase.auth.currentUser;
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User not logged in!'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          try {
            // Сохраняем в Supabase
            await supabase.from('notes').insert({
              'user_id': user.id,
              'note_title': _titleController.text,
              'note_content': _mainController.text,
              'creation_date': date,
              'color_id': color_id,
              'reminder_date': _reminderDate?.toIso8601String(),
            });

            // Планирование уведомления
            if (_reminderDate != null && _reminderDate!.isAfter(DateTime.now())) {
              final notificationId = _titleController.text.hashCode.abs();
              await NotificationService().scheduleNotification(
                id: notificationId,
                title: _titleController.text,
                body: _mainController.text,
                scheduledDate: _reminderDate!,
              );
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );

          } catch (e) {
            // Ошибка при запросе Supabase
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка при сохранении заметки: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
