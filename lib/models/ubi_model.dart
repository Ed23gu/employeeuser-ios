class UbiModel {
  final double latitude;
  final double longitude;

  UbiModel({required this.latitude, required this.longitude});

  factory UbiModel.fromJson(Map<dynamic, dynamic> data) {
    return UbiModel(latitude: data['latitude'], longitude: data['longitude']);
  }
}
