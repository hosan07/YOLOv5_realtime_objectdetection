class Entry {
  String entryId;
  String date;
  String duration;
  double speed;
  double distance;

  Entry({this.entryId, this.date, this.duration, this.speed, this.distance});

  Map<String, dynamic> toMap() {
    return {
      'entryId': entryId,
      'date': date,
      'duration': duration,
      'speed': speed,
      'distance': distance
    };
  }
  static Entry fromMap(Map<String, dynamic> map) {
    return Entry(
      entryId: map['entryId'],
      date: map['date'],
      duration: map['duration'],
      speed: map['speed'],
      distance: map['distance'],
    );
  }
}
