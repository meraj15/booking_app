import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/expenses.dart';
import '../models/booking.dart';

class FirestoreService {
  Future<void> addExpense(String userEmail, Expenses expense) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('expenses')
          .add(expense.toMap());
    } catch (e) {
      debugPrint('Error adding expense for $userEmail: $e');
      rethrow;
    }
  }

  Stream<List<Expenses>> getExpenses({
    required String userEmail,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final defaultStart = DateTime(now.year, now.month, 1);
    final defaultEnd = DateTime(now.year, now.month + 1, 0);

    final start = startDate ?? defaultStart;
    final end = endDate ?? defaultEnd;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('expenses')
        .where('fromDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fromDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return Expenses.fromMap(doc.id, doc.data());
              } catch (e) {
                debugPrint('Error parsing expense ${doc.id} for $userEmail: $e');
                return null;
              }
            })
            .where((expense) => expense != null)
            .cast<Expenses>()
            .toList());
  }

 Future<void> updateExpense(String userEmail, String id, Expenses expense) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('expenses')
        .doc(id)
        .update(expense.toMap());
  } catch (e) {
    debugPrint('Error updating expense for $userEmail: $e');
    rethrow;
  }
}

Future<void> deleteExpense(String userEmail, String id) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('expenses')
        .doc(id)
        .delete();
  } catch (e) {
    debugPrint('Error deleting expense for $userEmail: $e');
    rethrow;
  }
}

  Future<void> addBooking(String userEmail, Booking booking) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('bookings')
          .add(booking.toMap());
    } catch (e) {
      debugPrint('Error adding booking for $userEmail: $e');
      rethrow;
    }
  }

  Stream<List<Booking>> getBookings(String userEmail) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('bookings')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return Booking.fromMap(doc.id, doc.data());
              } catch (e) {
                debugPrint('Error parsing booking ${doc.id} for $userEmail: $e');
                return null;
              }
            })
            .where((booking) => booking != null)
            .cast<Booking>()
            .toList());
  }

Future<List<Booking>> fetchBookingsOnce(String userEmail, {DateTime? startDate, DateTime? endDate}) async {
  try {
    var query = FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('bookings')
        .orderBy('date', descending: false);

    // Apply date range filters if provided
  if (startDate != null) {
  final adjustedStartDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
  query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(adjustedStartDate));
}
if (endDate != null) {
  final adjustedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
  query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(adjustedEndDate));
}

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) {
          try {
            return Booking.fromMap(doc.id, doc.data());
          } catch (e) {
            debugPrint('Error parsing booking ${doc.id} for $userEmail: $e');
            return null;
          }
        })
        .where((booking) => booking != null)
        .cast<Booking>()
        .toList();
  } catch (e) {
    debugPrint('Error fetching bookings for $userEmail: $e');
    rethrow;
  }
}

 Future<void> updateBooking(String userEmail, String bookingId, Booking booking) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('bookings')
          .doc(bookingId)
          .update(booking.toMap());
    } catch (e) {
      debugPrint('Error updating booking $bookingId for $userEmail: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(String userEmail, String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('bookings')
          .doc(bookingId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting booking $bookingId for $userEmail: $e');
      rethrow;
    }
  }
}