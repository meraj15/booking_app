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

  Future<void> updateExpense(String userEmail, int index, Expenses expense) async {
    try {
      final expenses = await getExpenses(userEmail: userEmail).first;
      if (index >= 0 && index < expenses.length) {
        final id = expenses[index].id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('expenses')
            .doc(id)
            .update(expense.toMap());
      } else {
        throw Exception('Invalid index: $index');
      }
    } catch (e) {
      debugPrint('Error updating expense for $userEmail: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String userEmail, int index) async {
    try {
      final expenses = await getExpenses(userEmail: userEmail).first;
      if (index >= 0 && index < expenses.length) {
        final id = expenses[index].id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('expenses')
            .doc(id)
            .delete();
      } else {
        throw Exception('Invalid index: $index');
      }
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

  Future<List<Booking>> fetchBookingsOnce(String userEmail) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('bookings')
          .get();
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

  Future<void> updateBooking(String userEmail, int index, Booking booking) async {
    try {
      final bookings = await getBookings(userEmail).first;
      if (index >= 0 && index < bookings.length) {
        final id = bookings[index].id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('bookings')
            .doc(id)
            .update(booking.toMap());
      } else {
        throw Exception('Invalid index: $index');
      }
    } catch (e) {
      debugPrint('Error updating booking for $userEmail: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(String userEmail, int index) async {
    try {
      final bookings = await getBookings(userEmail).first;
      if (index >= 0 && index < bookings.length) {
        final id = bookings[index].id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('bookings')
            .doc(id)
            .delete();
      } else {
        throw Exception('Invalid index: $index');
      }
    } catch (e) {
      debugPrint('Error deleting booking for $userEmail: $e');
      rethrow;
    }
  }
}