class ObsModel {
  final String user_id;
  final String? title;
  final DateTime create_at;
  final String? date;
  final String? horain;

  ObsModel(
      {required this.user_id,
      this.title,
      required this.create_at,
      this.date,
      this.horain});

  factory ObsModel.fromJson(Map<dynamic, dynamic> data) {
    return ObsModel(
        user_id: data['user_id'],
        title: data['title'],
        create_at: DateTime.parse(data['created_at']),
        date: data['date'],
        horain: data['horain']);
  }
}
