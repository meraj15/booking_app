import 'dart:async';
import 'package:flutter/material.dart';
import 'package:booking_app/models/payment.dart';
import 'package:booking_app/services/firestore_service.dart';

class PaymentViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final _paymentsStreamController =
      StreamController<List<OwnerPayment>>.broadcast();

  Stream<List<OwnerPayment>> get payments => _paymentsStreamController.stream;

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _selectedOwner;
  StreamSubscription? _paymentSubscription;
  String? _userEmail;
  List<OwnerPayment> _cachedPayments = [];

  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String? get selectedOwner => _selectedOwner;
  String? get userEmail => _userEmail;
  List<OwnerPayment> get cachedPayments => _cachedPayments;

  double get totalBilledAmount =>
      _filteredList.fold(0.0, (sum, p) => sum + p.totalAmount);

  double get totalGivenAmount =>
      _filteredList.fold(0.0, (sum, p) => sum + p.amountGiven);

  double get totalBalanceAmount =>
      _filteredList.fold(0.0, (sum, p) => sum + p.balance);

  List<OwnerPayment> get _filteredList {
    if (_selectedOwner == null || _selectedOwner!.trim().isEmpty) {
      return _cachedPayments;
    }
    return _cachedPayments
        .where(
          (p) =>
              p.ownerName.trim().toLowerCase() ==
              _selectedOwner!.trim().toLowerCase(),
        )
        .toList();
  }

  PaymentViewModel() {
    final now = DateTime.now();
    _filterStartDate = DateTime(now.year, now.month, 1);
    _filterEndDate = DateTime(now.year, now.month + 1, 0);
  }

  void setUserEmail(String? email) {
    if (_userEmail != email) {
      _userEmail = email;
      _paymentSubscription?.cancel();

      if (_userEmail != null) {
        _fetchPayments();
      } else {
        _cachedPayments = [];
        _paymentsStreamController.add([]);
      }
      notifyListeners();
    }
  }

  void setFilterDates(DateTime? startDate, DateTime? endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    _paymentSubscription?.cancel();
    _fetchPayments();
    notifyListeners();
  }

  void setOwnerFilter(String? owner) {
    _selectedOwner = owner;
    _emitFilteredPayments();
    notifyListeners();
  }

  void _fetchPayments() {
    if (_userEmail == null) {
      _cachedPayments = [];
      _paymentsStreamController.add([]);
      return;
    }

    _paymentSubscription?.cancel();
    _paymentSubscription = _firestoreService
        .getPayments(
          userEmail: _userEmail!,
          startDate: _filterStartDate,
          endDate: _filterEndDate,
        )
        .listen(
          (list) {
            _cachedPayments = list;
            _emitFilteredPayments();
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error fetching owner payments: $e');
            _paymentsStreamController.addError(e);
          },
        );
  }

  void _emitFilteredPayments() {
    _paymentsStreamController.add(_filteredList);
  }

  Future<void> addPayment(OwnerPayment payment) async {
    if (_userEmail == null) throw Exception('User not authenticated');
    try {
      await _firestoreService.addPayment(_userEmail!, payment);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding owner payment: $e');
      rethrow;
    }
  }

  Future<void> updatePayment(String id, OwnerPayment payment) async {
    if (_userEmail == null) throw Exception('User not authenticated');
    try {
      await _firestoreService.updatePayment(_userEmail!, id, payment);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating owner payment: $e');
      rethrow;
    }
  }

  Future<void> deletePayment(String id) async {
    if (_userEmail == null) throw Exception('User not authenticated');
    try {
      await _firestoreService.deletePayment(_userEmail!, id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting owner payment: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    _paymentsStreamController.close();
    super.dispose();
  }
}
