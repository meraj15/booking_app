import 'package:booking_app/constant/app_constant_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Booking {
  final String id;
  final DateTime date;
  final String location;
  final String owner;
  final String bookingType;
  final String? organizer;
  final String description;

  Booking({
    required this.id,
    required this.date,
    required this.location,
    required this.owner,
    required this.bookingType,
    this.organizer,
    this.description = '',
  }) : assert(
         ConstantsString.allowedBookingTypes.contains(bookingType),
         'Invalid bookingType: $bookingType',
       );

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'location': location,
      'owner': owner,
      'bookingType': bookingType,
      'organizer': organizer,
      'description': description,
    };
  }

  factory Booking.fromMap(String id, Map<String, dynamic> data) {
    final dateValue = data['date'];
    DateTime parsedDate;

    if (dateValue is Timestamp) {
      parsedDate = dateValue.toDate();
    } else if (dateValue is DateTime) {
      parsedDate = dateValue;
    } else {
      parsedDate = DateTime.now();
      debugPrint(
        '⚠️ Warning: Invalid or missing date in Firestore data: $data',
      );
    }

    return Booking(
      id: id,
      date: parsedDate,
      location: data['location'] ?? 'Unknown',
      owner: data['owner'] ?? 'Unknown',
      bookingType: data['bookingType'] ?? ConstantsString.defaultBookingType,
      organizer: data['organizer'],
      description: data['description'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'location': location,
      'owner': owner,
      'bookingType': bookingType,
      'organizer': organizer,
      'description': description,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      location: json['location'] ?? 'Unknown',
      owner: json['owner'] ?? 'Unknown',
      bookingType: json['bookingType'] ?? ConstantsString.defaultBookingType,
      organizer: json['organizer'],
      description: json['description'] ?? "",
    );
  }
}
