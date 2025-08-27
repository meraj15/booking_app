import 'dart:async';
import 'package:flutter/material.dart';
import 'package:booking_app/models/expenses.dart';
import 'package:booking_app/services/firestore_service.dart';

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
  String? get userEmail => _userEmail;

  /// ✅ Called after Google Sign-In success
  void setUserEmail(String? email) {
    debugPrint("🔑 Setting user email in ExpensesViewModel: $email");
    if (_userEmail != email) {
      _userEmail = email;

      // cancel old subscription
      _expenseSubscription?.cancel();

      if (_userEmail != null) {
        _fetchExpenses();
      } else {
        _expensesStreamController.add([]);
      }
      notifyListeners();
    }
  }

  /// Set filters for expenses list
  void setFilterDates(DateTime? startDate, DateTime? endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    _expenseSubscription?.cancel();
    _fetchExpenses();
    notifyListeners();
  }

  void _fetchExpenses() {
    if (_userEmail == null) {
      debugPrint("⚠️ Tried fetching expenses but userEmail is null");
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
      debugPrint('❌ Error fetching expenses: $e');
      _expensesStreamController.addError(e);
    });
  }

  Future<void> addExpense(Expenses expense) async {
    if (_userEmail == null) {
      debugPrint("❌ addExpense failed: User not authenticated");
      throw Exception('User not authenticated');
    }
    try {
      await _firestoreService.addExpense(_userEmail!, expense);
      debugPrint("✅ Expense added successfully for $_userEmail");
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error adding expense: $e');
      rethrow;
    }
  }

  Future<void> updateExpenses(String id, Expenses expense) async {
    if (_userEmail == null) {
      debugPrint("❌ updateExpenses failed: User not authenticated");
      throw Exception('User not authenticated');
    }
    try {
      await _firestoreService.updateExpense(_userEmail!, id, expense);
      debugPrint("✅ Expense updated for $_userEmail (id: $id)");
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpenses(String id) async {
    if (_userEmail == null) {
      debugPrint("❌ deleteExpenses failed: User not authenticated");
      throw Exception('User not authenticated');
    }
    try {
      await _firestoreService.deleteExpense(_userEmail!, id);
      debugPrint("✅ Expense deleted for $_userEmail (id: $id)");
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error deleting expense: $e');
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
