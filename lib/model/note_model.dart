class NoteModel {
  String id;
  String title;
  String body;
  DateTime creationDate;
  int colorId;
  DateTime? reminderDate;

  NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.creationDate,
    this.colorId = 0,
    this.reminderDate,
  });

  Map<String, dynamic> toMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'note_title': title,
      'note_content': body,
      'creation_date': creationDate.toIso8601String(),
      'color_id': colorId,
      'reminder_date': reminderDate?.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      title: map['note_title'],
      body: map['note_content'],
      creationDate: DateTime.parse(map['creation_date']),
      colorId: map['color_id'] ?? 0,
      reminderDate: map['reminder_date'] != null
          ? DateTime.parse(map['reminder_date'])
          : null,
    );
  }
}
