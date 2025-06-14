import 'package:booking_app/constants/app_color.dart';
import 'package:booking_app/models/expenses.dart';
import 'package:booking_app/view_models/booking_view_model.dart';
import 'package:booking_app/view_models/expenses_view_model.dart';
import 'package:booking_app/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For inputFormatters
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ExpensesDialog extends StatefulWidget {
  final Expenses? expense;

  const ExpensesDialog({super.key, this.expense});

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
  late stt.SpeechToText _speech;
  bool _isListening = false;

  static final _firstDate = DateTime(2025);
  static final _lastDate = DateTime(2026);
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _fromDate = widget.expense?.fromDate ?? DateTime.now();
    _toDate = widget.expense?.toDate;

    _fromDateController = TextEditingController(
      text: _fromDate != null ? _dateFormat.format(_fromDate!) : '',
    );
    _toDateController = TextEditingController(
      text: _toDate != null ? _dateFormat.format(_toDate!) : '',
    );
    _priceController = TextEditingController(
      text: widget.expense?.price.toInt().toString() ?? '', // Convert to int
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

  Future<void> _toggleListening(BuildContext context) async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech recognition error: ${error.errorMsg}')),
          );
        },
      );
      if (available) {
        setState(() => _isListening = true);
        FocusScope.of(context).unfocus();
        _speech.listen(
          onResult: (result) {
            final cleanedText = result.recognizedWords.replaceAll(RegExp(r'[^0-9]'), '');
            setState(() {
              _priceController.text = cleanedText.isNotEmpty ? cleanedText : '';
            });
            debugPrint('Recognized: ${result.recognizedWords}, Cleaned: $cleanedText');
            if (cleanedText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please say a valid integer number')),
              );
            }
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _saveExpense(BuildContext context) async {
   

    if (_formKey.currentState!.validate()) {
      final priceText = _priceController.text.trim();
      final price = int.tryParse(priceText) ?? 0;
      final viewModel = context.read<ExpensesViewModel>();
      final newExpense = Expenses(
        id: widget.expense?.id ?? '',
        price: price.toDouble(), // Store as int
        fromDate: _fromDate!,
        toDate: _toDate,
      );

      try {
        if (widget.expense != null) {
          await viewModel.updateExpenses(newExpense.id, newExpense);
          
        } else {
          await viewModel.addExpense(newExpense);
         
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

   

    return AlertDialog(
      title: Text(
        widget.expense != null ? 'Update Expense' : 'Add Expense',
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
                validator: (value) => _fromDate == null ? 'Please select a from date' : null,
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
              Row(
                children: [
                  Expanded(
                    child: BookingTextField(
                      controller: _priceController,
                      labelText: 'Price',
                      hintText: 'Enter price in rupees (integer only)',
                      icon: Icons.money,
                      readOnly: _isListening,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, 
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a price';
                        }
                        final cleanedValue = value.trim();
                        if (int.tryParse(cleanedValue) == null || int.parse(cleanedValue) <= 0) {
                          return 'Please enter a valid positive integer';
                        }
                        return null;
                      },
                      onChanged: (value) => _priceController.text = value,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? AppColor.redColor : AppColor.primary,
                    ),
                    onPressed: () => _toggleListening(context),
                    tooltip: _isListening ? 'Stop Listening' : 'Start Listening',
                  ),
                ],
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
          onPressed: () => _saveExpense(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: AppColor.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(widget.expense == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}