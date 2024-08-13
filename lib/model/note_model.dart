class NoteModel {
  //int? id; // Необязательно, так как Firestore генерирует id автоматически
  String title;
  String body;
  DateTime creationDate;

  NoteModel({required this.title, required this.body, required this.creationDate});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'creation_date': creationDate.toString(),
    };
  }

  static NoteModel fromMap(Map<String, dynamic> map) {
    return NoteModel(
      title: map['title'],
      body: map['body'],
      creationDate: DateTime.parse(map['creation_date']),
    );
  }
}