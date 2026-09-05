import 'package:booking_app/constant/app_color.dart';
import 'package:booking_app/constant/app_constant_string.dart';
import 'package:booking_app/models/payment.dart';
import 'package:booking_app/view_models/booking_view_model.dart';
import 'package:booking_app/view_models/payment_view_model.dart';
import 'package:booking_app/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PaymentDialog extends StatefulWidget {
  final OwnerPayment? payment;
  final String? initialOwnerName;

  const PaymentDialog({
    super.key,
    this.payment,
    this.initialOwnerName,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ownerController;
  late final TextEditingController _totalAmountController;
  late final TextEditingController _amountGivenController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _noteController;
  late final TextEditingController _dateController;

  DateTime _selectedDate = DateTime.now();
  String _selectedMethod = 'UPI / GPay / PhonePe';
  bool _isSaving = false;

  static const List<String> _paymentMethods = [
    'UPI / GPay / PhonePe',
    'Cash',
    'Bank Transfer',
    'Cheque',
    'Other',
  ];

  static const List<String> _accountSuggestions = [
    'Cash in Hand',
    'SBI Account',
    'HDFC Bank',
    'Google Pay',
    'PhonePe',
    'Paytm',
  ];

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    _ownerController = TextEditingController(
      text: payment?.ownerName ?? widget.initialOwnerName ?? '',
    );
    _totalAmountController = TextEditingController(
      text: payment != null && payment.totalAmount > 0
          ? (payment.totalAmount % 1 == 0
              ? payment.totalAmount.toInt().toString()
              : payment.totalAmount.toString())
          : '',
    );
    _amountGivenController = TextEditingController(
      text: payment != null && payment.amountGiven > 0
          ? (payment.amountGiven % 1 == 0
              ? payment.amountGiven.toInt().toString()
              : payment.amountGiven.toString())
          : '',
    );
    _accountNameController = TextEditingController(
      text: payment?.accountName ?? 'Cash in Hand',
    );
    _noteController = TextEditingController(
      text: payment?.note ?? '',
    );
    _selectedDate = payment?.paymentDate ?? DateTime.now();
    _dateController = TextEditingController(
      text: DateFormat(ConstantsString.dateFormat).format(_selectedDate),
    );
    _selectedMethod = payment?.paymentMethod ?? 'UPI / GPay / PhonePe';
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _totalAmountController.dispose();
    _amountGivenController.dispose();
    _accountNameController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  double get _totalAmount =>
      double.tryParse(_totalAmountController.text.trim()) ?? 0.0;

  double get _amountGiven =>
      double.tryParse(_amountGivenController.text.trim()) ?? 0.0;

  double get _currentBalance =>
      (_totalAmount - _amountGiven).clamp(0.0, double.infinity);

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            DateFormat(ConstantsString.dateFormat).format(picked);
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final ownerName = _ownerController.text.trim().toUpperCase();
    final accountName = _accountNameController.text.trim();
    final note = _noteController.text.trim();

    setState(() => _isSaving = true);
    try {
      final paymentViewModel = context.read<PaymentViewModel>();
      final newPayment = OwnerPayment(
        id: widget.payment?.id ?? '',
        ownerName: ownerName,
        totalAmount: _totalAmount,
        amountGiven: _amountGiven,
        paymentDate: _selectedDate,
        paymentMethod: _selectedMethod,
        accountName: accountName.isNotEmpty ? accountName : 'Cash in Hand',
        note: note,
        createdAt: widget.payment?.createdAt ?? DateTime.now(),
      );

      if (widget.payment != null) {
        await paymentViewModel.updatePayment(widget.payment!.id, newPayment);
      } else {
        await paymentViewModel.addPayment(newPayment);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.payment != null
                  ? 'Payment updated successfully'
                  : 'Payment recorded successfully',
            ),
            backgroundColor: AppColor.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save payment: $e'),
            backgroundColor: AppColor.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get unique owner suggestions from bookings & cached payments
    final bookingViewModel = context.watch<BookingViewModel>();
    final paymentViewModel = context.watch<PaymentViewModel>();
    final Set<String> existingOwners = {};
    for (final p in paymentViewModel.cachedPayments) {
      if (p.ownerName.isNotEmpty) existingOwners.add(p.ownerName);
    }
    for (final b in bookingViewModel.organizers) {
      if (b != 'Other') existingOwners.add(b);
    }

    final isPaidFull = _totalAmount > 0 && _amountGiven >= _totalAmount;

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
                colors: AppColor.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColor.primary.withOpacity(0.3),
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
                    Icons.payments_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.payment == null
                            ? 'Record Owner Payment'
                            : 'Edit Owner Payment',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Track amount given, balance & accounts',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Form Content
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Owner Name with Autocomplete
                    RawAutocomplete<String>(
                      textEditingController: _ownerController,
                      focusNode: FocusNode(),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return existingOwners;
                        }
                        return existingOwners.where((String option) {
                          return option
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                maxWidth: 300,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Owner Name *',
                            hintText: 'Enter or select venue owner',
                            prefixIcon: const Icon(
                              Icons.person,
                              size: 18,
                              color: AppColor.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter owner name';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Financial Section (Total Due & Amount Given)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _totalAmountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Total Amount (₹) *',
                              hintText: 'e.g. 40000',
                              prefixIcon: const Icon(
                                Icons.currency_rupee,
                                size: 16,
                                color: AppColor.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final num = double.tryParse(value);
                              if (num == null || num <= 0) {
                                return 'Enter valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _amountGivenController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColor.success,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Amount Given (₹) *',
                              hintText: 'e.g. 30000',
                              prefixIcon: const Icon(
                                Icons.arrow_downward,
                                size: 16,
                                color: AppColor.success,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final num = double.tryParse(value);
                              if (num == null || num < 0) {
                                return 'Enter valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Live Calculated Balance Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isPaidFull
                            ? AppColor.success.withOpacity(0.1)
                            : AppColor.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPaidFull
                              ? AppColor.success.withOpacity(0.3)
                              : AppColor.accent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPaidFull
                                    ? Icons.check_circle
                                    : Icons.pending_actions,
                                size: 18,
                                color: isPaidFull
                                    ? AppColor.success
                                    : AppColor.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPaidFull
                                    ? 'Fully Paid / Cleared'
                                    : 'Remaining Balance:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isPaidFull
                                      ? AppColor.success
                                      : AppColor.greyDark,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹${_currentBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPaidFull
                                  ? AppColor.success
                                  : AppColor.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date Amount Given
                    BookingTextField(
                      controller: _dateController,
                      labelText: 'Date Amount Given *',
                      hintText: 'Select payment date',
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: () => _pickDate(context),
                    ),
                    const SizedBox(height: 12),

                    // Payment Method ("Via How")
                    const Text(
                      'Payment Method (Via How):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.greyDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _paymentMethods.map((method) {
                          final isSelected = _selectedMethod == method;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                method,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColor.greyDark,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColor.primary,
                              backgroundColor: Colors.grey.shade100,
                              onSelected: (_) {
                                setState(() => _selectedMethod = method);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Account Name ("Which Account")
                    TextFormField(
                      controller: _accountNameController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Account Name (Which Account) *',
                        hintText: 'e.g. SBI, HDFC, Cash in Hand, GPay',
                        prefixIcon: const Icon(
                          Icons.account_balance,
                          size: 18,
                          color: AppColor.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter account name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    // Account quick chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _accountSuggestions.map((acc) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(
                                acc,
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor: Colors.grey.shade100,
                              onPressed: () {
                                setState(() {
                                  _accountNameController.text = acc;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Note / Remarks
                    BookingTextField(
                      controller: _noteController,
                      labelText: 'Note / Remarks (optional)',
                      hintText: 'e.g. Settlement for 40 bookings in July-Aug',
                      icon: Icons.notes,
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.grey.shade50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColor.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePayment,
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
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.payment == null
                                    ? Icons.save_alt
                                    : Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.payment == null
                                    ? 'Save Payment'
                                    : 'Update Payment',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
