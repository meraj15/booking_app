import 'package:booking_app/constant/app_color.dart';
import 'package:booking_app/models/expenses.dart';
import 'package:booking_app/view_models/expenses_view_model.dart';
import 'package:booking_app/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ExpensesDialog extends StatefulWidget {
  final Expenses? expense;
  final DateTime? initialDate;

  const ExpensesDialog({super.key, this.expense, this.initialDate});

  @override
  // ignore: library_private_types_in_public_api
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
  static final _lastDate = DateTime(2026, 12, 31);
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // Use initialDate if provided (from booking), otherwise use expense date or today
    _fromDate =
        widget.initialDate ?? widget.expense?.fromDate ?? DateTime.now();
    _toDate = widget.expense?.toDate;

    _fromDateController = TextEditingController(
      text: _fromDate != null ? _dateFormat.format(_fromDate!) : '',
    );
    _toDateController = TextEditingController(
      text: _toDate != null ? _dateFormat.format(_toDate!) : '',
    );
    _priceController = TextEditingController(
      text: widget.expense?.price.toInt().toString() ?? '',
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
    // Use current date as initial date, clamped within valid range
    DateTime initialDate = DateTime.now();
    if (initialDate.isBefore(_firstDate)) {
      initialDate = _firstDate;
    } else if (initialDate.isAfter(_lastDate)) {
      initialDate = _lastDate;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
    // Use current date as initial date, clamped within valid range
    DateTime initialDate = DateTime.now();
    final firstDateForToPicker = _fromDate ?? _firstDate;

    if (initialDate.isBefore(firstDateForToPicker)) {
      initialDate = firstDateForToPicker;
    } else if (initialDate.isAfter(_lastDate)) {
      initialDate = _lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDateForToPicker,
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
            SnackBar(
              content: Text('Speech recognition error: ${error.errorMsg}'),
            ),
          );
        },
      );
      if (available) {
        setState(() => _isListening = true);
        FocusScope.of(context).unfocus();
        _speech.listen(
          onResult: (result) {
            final cleanedText = result.recognizedWords.replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );
            setState(() {
              _priceController.text = cleanedText.isNotEmpty ? cleanedText : '';
            });
            debugPrint(
              'Recognized: ${result.recognizedWords}, Cleaned: $cleanedText',
            );
            if (cleanedText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please say a valid integer number'),
                ),
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
        price: price.toDouble(),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save expense: $e')));
      }
    } else {
      debugPrint('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          // Header with gradient
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColor.accentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColor.accent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.expense != null ? 'Update Expense' : 'New Expense',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColor.info.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppColor.info,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Date Range',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.greyDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          BookingTextField(
                            controller: _fromDateController,
                            labelText: 'From Date',
                            hintText: 'Select from date',
                            icon: Icons.event,
                            readOnly: true,
                            onTap: () => _selectFromDate(context),
                            validator:
                                (value) =>
                                    _fromDate == null
                                        ? 'Please select a from date'
                                        : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: BookingTextField(
                                  controller: _toDateController,
                                  labelText: 'To Date (Optional)',
                                  hintText: 'Select to date',
                                  icon: Icons.event_available,
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
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(
                                    color: AppColor.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: AppColor.error,
                                      size: 16,
                                    ),
                                    onPressed: _clearToDate,
                                    tooltip: 'Clear To Date',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Price Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColor.success.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.currency_rupee,
                                color: AppColor.success,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.greyDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: BookingTextField(
                                  controller: _priceController,
                                  labelText: 'Price',
                                  hintText: 'Enter price in rupees',
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
                                    if (int.tryParse(cleanedValue) == null ||
                                        int.parse(cleanedValue) <= 0) {
                                      return 'Please enter a valid positive integer';
                                    }
                                    return null;
                                  },
                                  onChanged:
                                      (value) => _priceController.text = value,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  gradient:
                                      _isListening
                                          ? const LinearGradient(
                                            colors: [
                                              AppColor.error,
                                              Color(0xFFFF8E8E),
                                            ],
                                          )
                                          : LinearGradient(
                                            colors: [
                                              AppColor.primary,
                                              AppColor.primaryLight,
                                            ],
                                          ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isListening
                                              ? AppColor.error
                                              : AppColor.primary)
                                          .withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    _isListening ? Icons.mic : Icons.mic_none,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () => _toggleListening(context),
                                  tooltip:
                                      _isListening
                                          ? 'Stop Listening'
                                          : 'Voice Input',
                                ),
                              ),
                            ],
                          ),
                          if (_isListening)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColor.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColor.error,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Listening... Speak the amount',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          // Footer with actions
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.grey.shade50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    debugPrint('Cancel button pressed');
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
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
                  child: ElevatedButton(
                    onPressed: () => _saveExpense(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.expense == null
                              ? Icons.add_circle_outline
                              : Icons.check_circle_outline,
                          color: AppColor.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.expense == null ? 'Add Expense' : 'Update',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColor.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
