import 'package:booking_app/models/booking.dart';
import 'package:booking_app/services/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

class BookingViewModel extends ChangeNotifier {
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool isSharedPdf = true;
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

BookingViewModel() {
  _filterStartDate = DateTime(2025, 1, 1);
  _filterEndDate = DateTime(2025, 12, 31);
  googleSignIn.isSignedIn().then((isSignedIn) async {
    if (isSignedIn) {
      try {
        _user = await googleSignIn.signInSilently();
        if (_user != null) {
          _fetchBookings();
          _fetchOrganizers();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error restoring sign-in: $e');
      }
    }
    _fetchBookings(); 
  });
}

  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<void> googleLogin() async {
    try {
      _user = await googleSignIn.signIn();
      if (_user != null) {
        _fetchBookings();
        _fetchOrganizers();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      throw e;
    }
  }

  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      _user = null;
      _bookingsStreamController.add([]);
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw e;
    }
  }

  void _fetchOrganizers() async {
    if (_user?.email == null) return;
    try {
      final bookings = await _firestoreService.fetchBookingsOnce(_user!.email);
      final customOrganizers = bookings
          .map((b) => b.organizer)
          .where((o) => o != null && o.isNotEmpty && o != 'Ramzaan' && o != 'Irfan') // Exclude defaults
          .cast<String>()
          .toSet()
          .toList();
      _organizers = ['Ramzaan', 'Irfan', ...customOrganizers, 'Other'];
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching organizers: $e');
    }
  }

  void _fetchBookings() {
  if (_user?.email == null) {
    _bookingsStreamController.add([]);
    return;
  }
  _bookingSubscription?.cancel();
  _bookingSubscription = _firestoreService
      .getBookings(_user!.email)
      .map((bookings) => bookings
          .where((b) =>
              (b.date.isAtSameMomentAs(_filterStartDate ?? DateTime(2000)) ||
                  b.date.isAfter(_filterStartDate ?? DateTime(2000))) &&
              (b.date.isBefore((_filterEndDate ?? DateTime(2100)).add(Duration(days: 1)))))
          .toList()
            ..sort((a, b) => a.date.compareTo(b.date)))
      .listen(_bookingsStreamController.add, onError: (e) {
        debugPrint('Error fetching bookings: $e');
        _bookingsStreamController.addError(e);
      });
}

  Future<void> addBooking(Booking booking) async {
    if (_user?.email == null) throw Exception('User not authenticated');
    try {
      final userBooking = Booking(
        id: booking.id,
        date: booking.date,
        location: booking.location,
        owner: booking.owner,
        // userEmail: _user!.email,
        dayNight: booking.dayNight,
        organizer: booking.organizer,
      );
      await _firestoreService.addBooking(_user!.email, userBooking);
      _fetchOrganizers();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding booking: $e');
      throw e;
    }
  }

  Future<void> updateBooking(String bookingId, Booking booking) async {
    if (_user?.email == null) throw Exception('User not authenticated');
    try {
      await _firestoreService.updateBooking(_user!.email, bookingId, booking);
      _fetchOrganizers();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating booking: $e');
      throw e;
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    if (_user?.email == null) throw Exception('User not authenticated');
    try {
      await _firestoreService.deleteBooking(_user!.email, bookingId);
      _fetchOrganizers();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting booking: $e');
      throw e;
    }
  }

  void filterBookings({DateTime? startDate, DateTime? endDate, DateTime? month}) {
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