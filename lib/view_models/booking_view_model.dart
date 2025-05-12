import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';
import 'dart:convert';

class BookingViewModel extends ChangeNotifier {
  List<Booking> _bookings = [];
   final double _spacing = 15.0;
  double get spacing => _spacing;
  List<Booking> get bookings => _bookings;

  

  Future<void> loadBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? bookingsJson = prefs.getString('bookings');
    if (bookingsJson != null) {
      final List<dynamic> decoded = jsonDecode(bookingsJson);
      _bookings = decoded.map((item) => Booking.fromJson(item)).toList();
      debugPrint('Loaded ${_bookings.length} bookings from SharedPreferences');
      notifyListeners();
    }
  }

  Future<void> addBooking(Booking booking) async {
    _bookings.add(booking);
    debugPrint('Added booking: ${booking.toJson()}');
    await _saveBookings();
    notifyListeners();
  }

  Future<void> updateBooking(int index, Booking booking) async {
    _bookings[index] = booking;
    debugPrint('Updated booking at index $index: ${booking.toJson()}');
    await _saveBookings();
    notifyListeners();
  }

  Future<void> _saveBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> serializableBookings =
        _bookings.map((booking) => booking.toJson()).toList();
    await prefs.setString('bookings', jsonEncode(serializableBookings));
    debugPrint('Saved ${_bookings.length} bookings to SharedPreferences');
  }
}