import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Booking {
  final String id;
  final DateTime date;
  final String location;
  final String owner;
  final bool dayNight;
  final String? organizer;
  // final String userEmail; // New field for user email

  Booking({
    required this.id,
    required this.date,
    required this.location,
    required this.owner,
    // required this.userEmail,
    this.dayNight = false,
    this.organizer,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'location': location,
      'owner': owner,
      // 'userEmail': userEmail, // Store userEmail
      'dayNight': dayNight,
      'organizer': organizer,
    };
  }

  factory Booking.fromMap(String id, Map<String, dynamic> data) {
    final dateValue = data['date'];
    DateTime parsedDate;
    if (dateValue is Timestamp) {
      parsedDate = dateValue.toDate();
    } else {
      parsedDate = DateTime.now();
      debugPrint('Warning: Invalid or missing date in Firestore data: $data');
    }

    return Booking(
      id: id,
      date: parsedDate,
      location: data['location'] ?? 'Unknown',
      owner: data['owner'] ?? 'Unknown',
      // userEmail: data['userEmail'] ?? 'Unknown', // Fetch userEmail
      dayNight: data['dayNight'] ?? false,
      organizer: data['organizer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'location': location,
      'owner': owner,
      // 'userEmail': userEmail,
      'dayNight': dayNight,
      'organizer': organizer,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      owner: json['owner'],
      // userEmail: json['userEmail'],
      dayNight: json['dayNight'] ?? false,
      organizer: json['organizer'],
    );
  }
}