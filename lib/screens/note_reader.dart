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

  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  DateTime? _reminderDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.noteData['note_title'] as String? ?? '');
    _contentController =
        TextEditingController(text: widget.noteData['note_content'] as String? ?? '');

    // Парсим reminder_date если есть
    if (widget.noteData.containsKey('reminder_date') &&
        widget.noteData['reminder_date'] != null) {
      try {
        _reminderDate =
            DateTime.parse(widget.noteData['reminder_date'] as String);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

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

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заголовок и содержимое не могут быть пустыми'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final String noteId = widget.noteData['id'] as String;

    try {
      final updatedData = {
        'note_title': _titleController.text.trim(),
        'note_content': _contentController.text.trim(),
        'reminder_date': _reminderDate?.toUtc().toIso8601String(),
      };

      await supabase
          .from('notes')
          .update(updatedData)
          .eq('id', noteId)
          .eq('user_id', user.id);

      // Обновляем локальные данные виджета
      widget.noteData['note_title'] = _titleController.text.trim();
      widget.noteData['note_content'] = _contentController.text.trim();
      widget.noteData['reminder_date'] = _reminderDate?.toUtc().toIso8601String();

      // Обновляем уведомление
      await NotificationService().cancelNotification(noteId.hashCode);
      if (_reminderDate != null && _reminderDate!.isAfter(DateTime.now())) {
        await NotificationService().scheduleNotification(
          id: noteId.hashCode,
          title: _titleController.text.trim(),
          body: _contentController.text.trim(),
          scheduledDate: _reminderDate!,
        );
      }

      if (!mounted) return;

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заметка сохранена!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      // Сообщаем HomeScreen, что нужно обновить список
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteNote(String noteId) async {
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
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await NotificationService().cancelNotification(noteId.hashCode);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
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
            content: Text(
                'Заметка не найдена или не принадлежит текущему пользователю'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заметка удалена!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

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

  Future<void> _pickReminderDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderDate != null
          ? TimeOfDay.fromDateTime(_reminderDate!)
          : TimeOfDay.now(),
    );
    if (pickedTime == null) return;

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

  @override
  Widget build(BuildContext context) {
    final data = widget.noteData;
    final int colorId = (data['color_id'] ?? 0) as int;
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

    return Scaffold(
      backgroundColor: AppStyle.cardsColor[colorId],
      appBar: AppBar(
        backgroundColor: AppStyle.cardsColor[colorId],
        elevation: 0.0,
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Редактировать заметку',
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Удалить заметку',
              onPressed: () => deleteNote(noteId),
            ),
          ] else ...[
            // В режиме редактирования — кнопки отмены и сохранения
            TextButton.icon(
              onPressed: () {
                // Откатываем изменения
                _titleController.text =
                    widget.noteData['note_title'] as String? ?? '';
                _contentController.text =
                    widget.noteData['note_content'] as String? ?? '';
                final rawReminder = widget.noteData['reminder_date'];
                _reminderDate = rawReminder != null
                    ? DateTime.tryParse(rawReminder as String)
                    : null;
                setState(() => _isEditing = false);
              },
              icon: const Icon(Icons.close),
              label: const Text('Отмена'),
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            _isEditing
                ? TextField(
                    controller: _titleController,
                    style: AppStyle.mainTitle,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Заголовок',
                      hintStyle: AppStyle.mainTitle
                          .copyWith(color: Colors.black38),
                    ),
                  )
                : Text(data['note_title'] as String, style: AppStyle.mainTitle),

            const SizedBox(height: 4),
            Text(formattedDate, style: AppStyle.dateTitle),

            // Напоминание
            const SizedBox(height: 8),
            if (_isEditing) ...[
              // Редактирование напоминания
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickReminderDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _reminderDate == null
                          ? 'Установить напоминание'
                          : 'Изменить напоминание',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  if (_reminderDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _reminderDate = null),
                      icon: const Icon(Icons.close),
                      tooltip: 'Удалить напоминание',
                    ),
                  ],
                ],
              ),
              if (_reminderDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    DateFormat('dd.MM.yyyy HH:mm', 'ru_RU')
                        .format(_reminderDate!),
                    style:
                        AppStyle.dateTitle.copyWith(color: Colors.orange.shade700),
                  ),
                ),
            ] else if (_reminderDate != null) ...[
              // Просмотр напоминания
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
                            'Напоминание',
                            style: AppStyle.dateTitle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm', 'ru_RU')
                                .format(_reminderDate!),
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

            // Содержимое
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _contentController,
                      style: AppStyle.mainContent,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Содержимое заметки',
                        hintStyle: AppStyle.mainContent
                            .copyWith(color: Colors.black38),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        data['note_content'] as String,
                        style: AppStyle.mainContent,
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: _isSaving ? null : _saveNote,
              backgroundColor: Colors.green,
              tooltip: 'Сохранить',
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
            )
          : FloatingActionButton(
              onPressed: () => deleteNote(noteId),
              backgroundColor: Colors.red,
              tooltip: 'Удалить',
              child: const Icon(Icons.delete),
            ),
    );
  }
}