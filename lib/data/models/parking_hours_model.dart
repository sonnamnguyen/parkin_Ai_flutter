class ParkingHours {
  final String monday;
  final String tuesday;
  final String wednesday;
  final String thursday;
  final String friday;
  final String saturday;
  final String sunday;

  ParkingHours({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory ParkingHours.fromJson(Map<String, dynamic> json) => ParkingHours(
    monday: json['monday'] as String,
    tuesday: json['tuesday'] as String,
    wednesday: json['wednesday'] as String,
    thursday: json['thursday'] as String,
    friday: json['friday'] as String,
    saturday: json['saturday'] as String,
    sunday: json['sunday'] as String,
  );

  Map<String, dynamic> toJson() => {
    'monday': monday,
    'tuesday': tuesday,
    'wednesday': wednesday,
    'thursday': thursday,
    'friday': friday,
    'saturday': saturday,
    'sunday': sunday,
  };

  String getTodayHours() {
    final today = DateTime.now().weekday;
    switch (today) {
      case 1: return monday;
      case 2: return tuesday;
      case 3: return wednesday;
      case 4: return thursday;
      case 5: return friday;
      case 6: return saturday;
      case 7: return sunday;
      default: return monday;
    }
  }
}