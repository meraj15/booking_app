import 'package:booking_app/constant/app_color.dart';
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
      context.read<ExpensesViewModel>().setUserEmail(
        bookingViewModel.user?.email,
      );
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
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: const ExpensesDialog(),
          ),
    );
  }

  Future<void> _handleGenerateExpensesPdf(BuildContext context) async {
    final viewModel = context.read<BookingViewModel>();
    if (!viewModel.isSharedPdf) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF sharing is disabled')));
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
        SnackBar(
          content: Text(
            'Failed to generate PDF: ${e.toString().split(':').last.trim()}',
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingViewModel = context.watch<BookingViewModel>();
    final expenseViewModel = context.watch<ExpensesViewModel>();
    if (bookingViewModel.user == null) {
      return const AuthScreen();
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColor.accentGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Expenses Entry',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  onPressed: () => _handleGenerateExpensesPdf(context),
                  tooltip: 'Generate PDF',
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: AppColor.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterSection(
              startDateController: _startDateController,
              endDateController: _endDateController,
              onStartDateTap: () => _selectStartDate(context),
              onEndDateTap: () => _selectEndDate(context),
            ),
            // Stats Card
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColor.accentGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.accent.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: StreamBuilder<List<Expenses>>(
                stream: expenseViewModel.expenses,
                builder: (context, snapshot) {
                  final expenses = snapshot.data ?? [];
                  final totalAmount = expenses.fold<double>(
                    0.0,
                    (previousValue, element) => previousValue + element.price,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white70,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            "Total Expenses",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.currency_rupee,
                            color: Colors.white,
                            size: 18,
                          ),
                          Text(
                            totalAmount.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          "${expenses.length} entries recorded",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
                            debugPrint(
                              'Expenses stream error: ${expenseSnapshot.error}',
                            );
                            return const Center(
                              child: Text('Error fetching Expenses'),
                            );
                          }
                          if (expenseSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColor.accent,
                              ),
                            );
                          }
                          final expensesList = expenseSnapshot.data ?? [];
                          if (expensesList.isEmpty) {
                            return const Center(
                              child: Text(
                                'No Expenses added yet',
                                style: TextStyle(color: AppColor.grey),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: expensesList.length,
                            itemBuilder: (context, index) {
                              final expense = expensesList[index];
                              final dateFormat = DateFormat('dd MMM');
                              final dateText =
                                  expense.toDate != null
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
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColor.accentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColor.accent.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showExpensesDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
