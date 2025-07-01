import 'package:booking_app/constant/app_constant_string.dart';
import 'package:booking_app/models/expenses.dart';
import 'package:booking_app/services/pdf_service.dart';
import 'package:booking_app/view_models/booking_view_model.dart';
import 'package:booking_app/view_models/expenses_view_model.dart';
import 'package:booking_app/widgets/expense_item.dart';
import 'package:booking_app/widgets/expenses.dialog.dart';
import 'package:booking_app/widgets/filter_date_selection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'auth_screen.dart';

class BookingExpensesScreen extends StatefulWidget {
  const BookingExpensesScreen({super.key});

  @override
  State<BookingExpensesScreen> createState() => _BookingExpensesScreenState();
}

class _BookingExpensesScreenState extends State<BookingExpensesScreen> {
  bool _isLoading = false;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  DateTime? _startDate;
  DateTime? _endDate;
  static final _firstDate = DateTime(2025);
  static final _lastDate = DateTime(2026);
  final DateFormat _dateFormat = DateFormat(ConstantsString.dateFormat);

  @override
  void initState() {
    super.initState();
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);

    _startDateController.text = _dateFormat.format(_startDate!);
    _endDateController.text = _dateFormat.format(_endDate!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingViewModel = context.read<BookingViewModel>();
      context.read<ExpensesViewModel>().setUserEmail(bookingViewModel.user?.email);
      context.read<ExpensesViewModel>().setFilterDates(_startDate, _endDate);
    });
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _firstDate,
      lastDate: _lastDate,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = _dateFormat.format(picked);
      });
      context.read<ExpensesViewModel>().setFilterDates(_startDate, _endDate);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? _firstDate,
      lastDate: _lastDate,
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateController.text = _dateFormat.format(picked);
      });
      context.read<ExpensesViewModel>().setFilterDates(_startDate, _endDate);
    }
  }

  Future<void> _showExpensesDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const ExpensesDialog(),
    );
  }

  Future<void> _handleGenerateExpensesPdf(BuildContext context) async {
    final viewModel = context.read<BookingViewModel>();
    if (!viewModel.isSharedPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF sharing is disabled')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await PdfService.generateExpensesPdf(context).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('PDF generation timed out'),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: ${e.toString().split(':').last.trim()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingViewModel = context.watch<BookingViewModel>();
 final expenseViewModel = context.watch<ExpensesViewModel>();
    if (bookingViewModel.user == null) {
      return const AuthScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses Entry'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _handleGenerateExpensesPdf(context),
            tooltip: 'Generate PDF',
          ),
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   onPressed: () async {
          //     try {
          //       await bookingViewModel.signOut();
          //       Navigator.pushReplacement(
          //         context,
          //         MaterialPageRoute(builder: (_) => const AuthScreen()),
          //       );
          //     } catch (e) {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         SnackBar(content: Text('Error signing out: $e')),
          //       );
          //     }
          //   },
          // ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterSection(
            startDateController: _startDateController,
            endDateController: _endDateController,
            onStartDateTap: () => _selectStartDate(context),
            onEndDateTap: () => _selectEndDate(context),
          ),
         Padding(
  padding: const EdgeInsets.all(8.0),
  child: StreamBuilder<List<Expenses>>(
    stream: expenseViewModel.expenses,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        debugPrint('Expense stream error: ${snapshot.error}');
      }
      final expenses = snapshot.data ?? [];

      // Calculate the total amount
      final totalAmount = expenses.fold<double>(
        0.0,
        (previousValue, element) => previousValue + (element.price),
      );

      return Text(
        "Total Amount: \$${totalAmount.toStringAsFixed(2)}",
        style: const TextStyle(fontSize: 16),
      );
    },
  ),
),

          Expanded(
            child: Stack(
              children: [
                Consumer<ExpensesViewModel>(
                  builder: (context, viewModel, _) {
                    return StreamBuilder<List<Expenses>>(
                      stream: viewModel.expenses,
                      builder: (context, expenseSnapshot) {
                        if (expenseSnapshot.hasError) {
                          debugPrint('Expenses stream error: ${expenseSnapshot.error}');
                          return const Center(child: Text('Error fetching Expenses'));
                        }
                        if (expenseSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final expensesList = expenseSnapshot.data ?? [];
                        if (expensesList.isEmpty) {
                          return const Center(child: Text('No Expenses added yet'));
                        }
                        return ListView.builder(
                          itemCount: expensesList.length,
                          itemBuilder: (context, index) {
                            final expense = expensesList[index];
                            final dateFormat = DateFormat('dd MMM');
                            final dateText = expense.toDate != null
                                ? '${dateFormat.format(expense.fromDate)} to ${dateFormat.format(expense.toDate!)}'
                                : dateFormat.format(expense.fromDate);
                            return ExpenseItem(
                              index: index,
                              expense: expense,
                              dateText: dateText,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExpensesDialog(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}