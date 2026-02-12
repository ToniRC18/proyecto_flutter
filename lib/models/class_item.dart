class ClassItem {
  final String id;
  final String title;
  final String day;
  final String startTime;
  final String endTime;
  final int colorIndex;
  final String? note;

  ClassItem({
    required this.id,
    required this.title,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.colorIndex,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'colorIndex': colorIndex,
      'note': note,
    };
  }

  factory ClassItem.fromJson(Map<String, dynamic> json) {
    return ClassItem(
      id: json['id'],
      title: json['title'],
      day: json['day'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      colorIndex: json['colorIndex'],
      note: json['note'],
    );
  }
}
