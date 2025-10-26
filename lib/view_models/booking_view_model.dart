import 'package:booking_app/models/booking.dart';
import 'package:booking_app/services/firestore_service.dart';
import 'package:booking_app/view_models/expenses_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

import 'package:provider/provider.dart';

class BookingViewModel extends ChangeNotifier {
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool isSharedPdf = true;
  bool isCheckingAuth = true; // ✅ Check auth state while initializing
  StreamSubscription? _bookingSubscription;
  final _bookingsStreamController = StreamController<List<Booking>>.broadcast();
  List<String> _organizers = ['Ramzaan', 'Irfan', 'Other'];

  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  Stream<List<Booking>> get bookings => _bookingsStreamController.stream;
  List<String> get organizers => _organizers;
  GoogleSignInAccount? get user => _user;

  final FirestoreService _firestoreService = FirestoreService();
  GoogleSignInAccount? _user;

  final GoogleSignIn googleSignIn = GoogleSignIn();

  BookingViewModel() {
    _filterStartDate = DateTime(2025, 1, 1);
    _filterEndDate = DateTime(2025, 12, 31);
  }

  Future<void> init(BuildContext context) async {
    await checkInitialSignIn(context);
  }

  /// ✅ Check if user was already signed in
  Future<void> checkInitialSignIn(BuildContext context) async {
    try {
      final isSignedIn = await googleSignIn.isSignedIn();
      if (isSignedIn) {
        _user = await googleSignIn.signInSilently();
        if (_user != null) {
          // ✅ Sync with ExpensesViewModel so expenses know who is signed in
          // Use try-catch to handle case where ExpensesViewModel might not be available
          try {
            final expensesViewModel = Provider.of<ExpensesViewModel>(
              context,
              listen: false,
            );
            expensesViewModel.setUserEmail(_user!.email);
          } catch (e) {
            debugPrint('ExpensesViewModel not available yet: $e');
          }

          _fetchBookings();
          _fetchOrganizers();
        }
      }
    } catch (e) {
      debugPrint('Error restoring sign-in: $e');
    } finally {
      isCheckingAuth = false;
      notifyListeners();
    }
  }

  /// ✅ Google login
  Future<void> googleLogin(BuildContext context) async {
    try {
      _user = await googleSignIn.signIn();
      if (_user != null) {
        // ✅ Sync with ExpensesViewModel so expenses know who is signed in
        try {
          final expensesViewModel = Provider.of<ExpensesViewModel>(
            context,
            listen: false,
          );
          expensesViewModel.setUserEmail(_user!.email);
        } catch (e) {
          debugPrint('ExpensesViewModel not available: $e');
        }

        _fetchBookings();
        _fetchOrganizers();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// ✅ Sign out
  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      _user = null;
      _bookingsStreamController.add([]);
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// ✅ Fetch unique organizers dynamically from Firestore
  void _fetchOrganizers() async {
    if (_user?.email == null) return;
    try {
      final bookings = await _firestoreService.fetchBookingsOnce(_user!.email);
      final customOrganizers =
          bookings
              .map((b) => b.organizer)
              .where(
                (o) =>
                    o != null && o.isNotEmpty && o != 'Ramzaan' && o != 'Irfan',
              )
              .cast<String>()
              .toSet()
              .toList();
      _organizers = ['Ramzaan', 'Irfan', ...customOrganizers, 'Other'];
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching organizers: $e');
    }
  }

  /// ✅ Subscribe to Firestore bookings
  void _fetchBookings() {
    if (_user?.email == null) {
      _bookingsStreamController.add([]);
      return;
    }
    _bookingSubscription?.cancel();
    _bookingSubscription = _firestoreService
        .getBookings(_user!.email)
        .map(
          (bookings) =>
              bookings
                  .where(
                    (b) =>
                        (b.date.isAtSameMomentAs(
                              _filterStartDate ?? DateTime(2000),
                            ) ||
                            b.date.isAfter(
                              _filterStartDate ?? DateTime(2000),
                            )) &&
                        (b.date.isBefore(
                          (_filterEndDate ?? DateTime(2100)).add(
                            const Duration(days: 1),
                          ),
                        )),
                  )
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date)),
        )
        .listen(
          _bookingsStreamController.add,
          onError: (e) {
            debugPrint('Error fetching bookings: $e');
            _bookingsStreamController.addError(e);
          },
        );
  }

  /// ✅ Add booking
  Future<void> addBooking(Booking booking) async {
    if (_user?.email == null) throw Exception('User not authenticated');
    try {
      final userBooking = Booking(
        id: booking.id,
        date: booking.date,
        location: booking.location,
        owner: booking.owner,
        bookingType: booking.bookingType,
        organizer: booking.organizer,
      );
      await _firestoreService.addBooking(_user!.email, userBooking);
      _fetchOrganizers();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding booking: $e');
      rethrow;
    }
  }

  /// ✅ Update booking
  Future<void> updateBooking(String bookingId, Booking booking) async {
    if (_user?.email == null) throw Exception('User not authenticated');
    try {
      await _firestoreService.updateBooking(_user!.email, bookingId, booking);
      _fetchOrganizers();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating booking: $e');
      rethrow;
    }
  }

  /// ✅ Delete booking
  Future<void> deleteBooking(String bookingId) async {
    if (_user?.email == null) throw Exception('User not authenticated');
    try {
      await _firestoreService.deleteBooking(_user!.email, bookingId);
      _fetchOrganizers();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting booking: $e');
      rethrow;
    }
  }

  /// ✅ Apply date/month filter
  void filterBookings({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? month,
  }) {
    if (month != null) {
      _filterStartDate = DateTime(month.year, month.month, 1);
      _filterEndDate = DateTime(month.year, month.month + 1, 0);
    } else {
      _filterStartDate = startDate ?? _filterStartDate;
      _filterEndDate = endDate ?? _filterEndDate;
    }
    _fetchBookings();
    notifyListeners();
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel();
    _bookingsStreamController.close();
    super.dispose();
  }
}
