import 'package:booking_app/models/expenses.dart';
import 'package:booking_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ExpensesViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final _expensesStreamController = StreamController<List<Expenses>>.broadcast();
  Stream<List<Expenses>> get expenses => _expensesStreamController.stream;

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  StreamSubscription? _expenseSubscription;
  String? _userEmail;

  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;

  void setUserEmail(String? email) {
    if (_userEmail != email) {
      _userEmail = email;
      _expenseSubscription?.cancel();
      if (_userEmail != null) {
        _fetchExpenses();
      } else {
        _expensesStreamController.add([]);
      }
      notifyListeners();
    }
  }

  void setFilterDates(DateTime? startDate, DateTime? endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    _expenseSubscription?.cancel();
    _fetchExpenses();
    notifyListeners();
  }

  void _fetchExpenses() {
    if (_userEmail == null) {
      _expensesStreamController.add([]);
      return;
    }
    _expenseSubscription = _firestoreService
        .getExpenses(
          userEmail: _userEmail!,
          startDate: _filterStartDate,
          endDate: _filterEndDate,
        )
        .listen(_expensesStreamController.add, onError: (e) {
          debugPrint('Error fetching expenses: $e');
          _expensesStreamController.addError(e);
        });
  }

  Future<void> addExpense(Expenses expenses) async {
    if (_userEmail == null) throw Exception('User not authenticated');
    try {
      await _firestoreService.addExpense(_userEmail!, expenses);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding expense: $e');
      throw e;
    }
  }

  Future<void> updateExpenses(String id, Expenses expense) async {
  if (_userEmail == null) throw Exception('User not authenticated');
  try {
    await _firestoreService.updateExpense(_userEmail!, id, expense);
    notifyListeners();
  } catch (e) {
    debugPrint('Error updating expense: $e');
    rethrow;
  }
}

Future<void> deleteExpenses(String id) async {
  if (_userEmail == null) throw Exception('User not authenticated');
  try {
    await _firestoreService.deleteExpense(_userEmail!, id);
    notifyListeners();
  } catch (e) {
    debugPrint('Error deleting expense: $e');
    rethrow;
  }
}

  @override
  void dispose() {
    _expenseSubscription?.cancel();
    _expensesStreamController.close();
    super.dispose();
  }
}