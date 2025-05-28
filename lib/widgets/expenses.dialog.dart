import 'package:booking_app/constants/app_color.dart';
import 'package:booking_app/constants/constants.dart';
import 'package:booking_app/models/expenses.dart';
import 'package:booking_app/view_models/booking_view_model.dart';
import 'package:booking_app/view_models/expenses_view_model.dart';
import 'package:booking_app/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ExpensesDialog extends StatefulWidget {
  final String? id;
  final int? index;
  final Expenses? expenses;

  const ExpensesDialog({super.key, this.id, this.index, this.expenses});

  @override
  _ExpensesDialogState createState() => _ExpensesDialogState();
}

class _ExpensesDialogState extends State<ExpensesDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fromDateController;
  late TextEditingController _toDateController;
  late TextEditingController _priceController;
  DateTime? _fromDate;
  DateTime? _toDate;

  static final _firstDate = DateTime(2025);
  static final _lastDate = DateTime(2026);
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _fromDate = widget.expenses?.fromDate ?? DateTime.now();
    _toDate = widget.expenses?.toDate;

    _fromDateController = TextEditingController(
      text: _fromDate != null ? _dateFormat.format(_fromDate!) : '',
    );
    _toDateController = TextEditingController(
      text: _toDate != null ? _dateFormat.format(_toDate!) : '',
    );
    _priceController = TextEditingController(
      text: widget.expenses?.price.toString() ?? '',
    );
    debugPrint(
      'ExpensesDialog initialized with fromDate: ${_fromDateController.text}, '
      'toDate: ${_toDateController.text}, price: ${_priceController.text}',
    );
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: _firstDate,
      lastDate: _lastDate,
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        _fromDateController.text = _dateFormat.format(picked);
      });
      debugPrint('Selected from date: ${picked.toString()}');
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? (_fromDate ?? DateTime.now()),
      firstDate: _fromDate ?? _firstDate,
      lastDate: _lastDate,
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
        _toDateController.text = _dateFormat.format(picked);
      });
      debugPrint('Selected to date: ${picked.toString()}');
    }
  }

  void _clearToDate() {
    setState(() {
      _toDate = null;
      _toDateController.clear();
    });
    debugPrint('Cleared to date');
  }

  Future<void> _addExpenses(BuildContext context) async {
    final bookingViewModel = context.read<BookingViewModel>();
    if (bookingViewModel.user?.email == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add an expense')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final price = double.parse(_priceController.text.trim());
      final viewModel = context.read<ExpensesViewModel>();
      final newExpenses = Expenses(
        id: widget.id ?? '',
        price: price,
        fromDate: _fromDate!,
        toDate: _toDate,
      );

      try {
        if (widget.index != null) {
          await viewModel.updateExpenses(widget.index!, newExpenses);
          debugPrint('Expense updated for ${bookingViewModel.user!.email}: ${newExpenses.toMap()}');
        } else {
          await viewModel.addExpense(newExpenses);
          debugPrint('Expense added for ${bookingViewModel.user!.email}: ${newExpenses.toMap()}');
        }
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error saving expense: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save expense: $e')),
        );
      }
    } else {
      debugPrint('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingViewModel = context.watch<BookingViewModel>();

    if (bookingViewModel.user?.email == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to add an expense')),
        );
      });
      return const SizedBox.shrink();
    }

    return AlertDialog(
      title: Text(
        widget.index != null ? 'Update Expense' : 'Add Expense',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookingTextField(
                controller: _fromDateController,
                labelText: 'From Date',
                hintText: 'Select from date',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _selectFromDate(context),
                validator: (value) =>
                    _fromDate == null ? 'Please select a from date' : null,
              ),
              const SizedBox(height: 18.0),
              Row(
                children: [
                  Expanded(
                    child: BookingTextField(
                      controller: _toDateController,
                      labelText: 'To Date (Optional)',
                      hintText: 'Select to date',
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: () => _selectToDate(context),
                      validator: (value) {
                        if (_toDate != null && _fromDate != null) {
                          if (_toDate!.isBefore(_fromDate!)) {
                            return 'To date must be after from date';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  if (_toDateController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearToDate,
                      tooltip: 'Clear To Date',
                    ),
                ],
              ),
              const SizedBox(height: 18.0),
              BookingTextField(
                controller: _priceController,
                labelText: 'Price',
                hintText: 'Enter price in rupees',
                icon: Icons.money,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value.trim()) == null ||
                      double.parse(value.trim()) <= 0) {
                    return 'Please enter a valid positive price';
                  }
                  return null;
                },
                onChanged: (value) => _priceController.text = value,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            debugPrint('Cancel button pressed');
            Navigator.pop(context);
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        ElevatedButton(
          onPressed: () => _addExpenses(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: AppColor.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(widget.index == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}