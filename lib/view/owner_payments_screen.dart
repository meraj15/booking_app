import 'package:booking_app/constant/app_color.dart';
import 'package:booking_app/constant/app_constant_string.dart';
import 'package:booking_app/models/payment.dart';
import 'package:booking_app/view_models/booking_view_model.dart';
import 'package:booking_app/view_models/payment_view_model.dart';
import 'package:booking_app/widgets/filter_date_selection.dart';
import 'package:booking_app/widgets/payment_dialog.dart';
import 'package:booking_app/widgets/payment_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OwnerPaymentsScreen extends StatefulWidget {
  const OwnerPaymentsScreen({super.key});

  @override
  State<OwnerPaymentsScreen> createState() => _OwnerPaymentsScreenState();
}

class _OwnerPaymentsScreenState extends State<OwnerPaymentsScreen> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat(ConstantsString.dateFormat);

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedOwner;

  static final _firstDate = DateTime(2024);
  static final _lastDate = DateTime(2030, 12, 31);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);

    _startDateController.text = _dateFormat.format(_startDate!);
    _endDateController.text = _dateFormat.format(_endDate!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingViewModel = context.read<BookingViewModel>();
      final paymentViewModel = context.read<PaymentViewModel>();
      paymentViewModel.setUserEmail(bookingViewModel.user?.email);
      paymentViewModel.setFilterDates(_startDate, _endDate);
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
      context.read<PaymentViewModel>().setFilterDates(_startDate, _endDate);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? _firstDate,
      lastDate: _lastDate,
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateController.text = _dateFormat.format(picked);
      });
      context.read<PaymentViewModel>().setFilterDates(_startDate, _endDate);
    }
  }

  void _openPaymentDialog([OwnerPayment? payment]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PaymentDialog(
          payment: payment,
          initialOwnerName: _selectedOwner,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentViewModel = context.watch<PaymentViewModel>();
    final bookingViewModel = context.watch<BookingViewModel>();

    // Build list of all unique owners from payments and bookings for the filter dropdown
    final Set<String> uniqueOwners = {};
    for (final p in paymentViewModel.cachedPayments) {
      if (p.ownerName.trim().isNotEmpty) uniqueOwners.add(p.ownerName.trim());
    }
    for (final o in bookingViewModel.organizers) {
      if (o != 'Other' && o.trim().isNotEmpty) uniqueOwners.add(o.trim());
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColor.primaryGradient,
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
                    Icons.payments_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Owner Settlements',
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
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                tooltip: 'Add Settlement Payment',
                onPressed: () => _openPaymentDialog(),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: AppColor.background,
        child: Column(
          children: [
            // Date Filter Section
            FilterSection(
              startDateController: _startDateController,
              endDateController: _endDateController,
              onStartDateTap: () => _selectStartDate(context),
              onEndDateTap: () => _selectEndDate(context),
            ),

            // Top Financial Summary Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColor.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Owner Filter Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Settlements Summary',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButton<String?>(
                          value: _selectedOwner,
                          dropdownColor: AppColor.primaryDark,
                          underline: const SizedBox(),
                          icon: const Icon(
                            Icons.filter_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          hint: const Text(
                            'All Owners',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Owners'),
                            ),
                            ...uniqueOwners.map((owner) {
                              return DropdownMenuItem<String?>(
                                value: owner,
                                child: Text(owner),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedOwner = val);
                            paymentViewModel.setOwnerFilter(val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Three-stat column row: Total Billed, Total Given, Balance
                  Row(
                    children: [
                      Expanded(
                        child: _summaryBox(
                          'Total Billed',
                          '₹${paymentViewModel.totalBilledAmount.toStringAsFixed(0)}',
                          Colors.white,
                          Icons.receipt,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white24,
                      ),
                      Expanded(
                        child: _summaryBox(
                          'Amount Given',
                          '₹${paymentViewModel.totalGivenAmount.toStringAsFixed(0)}',
                          const Color(0xFF81C784), // Light vibrant green
                          Icons.arrow_downward,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white24,
                      ),
                      Expanded(
                        child: _summaryBox(
                          'Balance',
                          '₹${paymentViewModel.totalBalanceAmount.toStringAsFixed(0)}',
                          const Color(0xFFFFB74D), // Light vibrant amber/orange
                          Icons.pending,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Payments List
            Expanded(
              child: StreamBuilder<List<OwnerPayment>>(
                stream: paymentViewModel.payments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      paymentViewModel.cachedPayments.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColor.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final payments = snapshot.data ?? [];

                  if (payments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No settlement payments recorded',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the + button below to add an owner payment',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 80),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      return PaymentItem(payment: payments[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColor.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColor.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _openPaymentDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: 'Add Owner Payment',
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _summaryBox(
    String label,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
