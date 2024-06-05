class Event {
  final String title;
  final String date;
  final String type;
  bool isDone;

  Event({
    required this.title,
    required this.date,
    required this.type,
    this.isDone = false,
  });
}
