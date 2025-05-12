import 'package:flutter/foundation.dart';

class Booking {
  final DateTime date;
  final String location;
  final String owner;

  Booking({
    required this.date,
    required this.location,
    required this.owner,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String,
      owner: json['owner'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'location': location,
      'owner': owner,
    };
  }
}