import 'package:booking_app/constant/app_color.dart';
import 'package:booking_app/constant/app_constant_string.dart';
import 'package:booking_app/models/booking.dart';
import 'package:booking_app/services/pdf_service.dart';
import 'package:booking_app/view/auth_screen.dart';
import 'package:booking_app/view/expenses_screen.dart';
import 'package:booking_app/widgets/booking_item.dart';
import 'package:booking_app/widgets/drawer.dart';
import 'package:booking_app/widgets/filter_date_selection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../view_models/booking_view_model.dart';
import '../widgets/booking_dialog.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedOwnerFilter = 'Ramzaan';

  static final _firstDate = DateTime(2025);
  static final _lastDate = DateTime(2026, 12, 31);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    Future.microtask(() {
      Provider.of<BookingViewModel>(
        context,
        listen: false,
      ).checkInitialSignIn(context);
    });
    _startDateController.text = DateFormat(
      ConstantsString.dateFormat,
    ).format(startOfMonth);
    _endDateController.text = DateFormat(
      ConstantsString.dateFormat,
    ).format(now);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BookingViewModel>().filterBookings(month: now);
      }
    });
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final viewModel = context.read<BookingViewModel>();
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
      _startDateController.text = DateFormat(
        ConstantsString.dateFormat,
      ).format(picked);
      viewModel.filterBookings(startDate: picked);
      if (viewModel.filterEndDate != null &&
          picked.isAfter(viewModel.filterEndDate!)) {
        final newEndDate = picked;
        _endDateController.text = DateFormat(
          ConstantsString.dateFormat,
        ).format(newEndDate);
        viewModel.filterBookings(endDate: newEndDate);
      }
      _formKey.currentState?.validate();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final viewModel = context.read<BookingViewModel>();
    // Use current date as initial date, clamped within valid range
    DateTime initialDate = DateTime.now();
    final firstDateForEndPicker = viewModel.filterStartDate ?? _firstDate;

    if (initialDate.isBefore(firstDateForEndPicker)) {
      initialDate = firstDateForEndPicker;
    } else if (initialDate.isAfter(_lastDate)) {
      initialDate = _lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDateForEndPicker,
      lastDate: _lastDate,
    );
    if (picked != null) {
      _endDateController.text = DateFormat(
        ConstantsString.dateFormat,
      ).format(picked);
      viewModel.filterBookings(endDate: picked);
      _formKey.currentState?.validate();
    }
  }

  Future<void> _handleGeneratePdf(BuildContext context) async {
    final viewModel = context.read<BookingViewModel>();
    if (!viewModel.isSharedPdf) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF sharing is disabled')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await PdfService.generateBookingsPdf(
        context,
        selectedOrganizer: _selectedOwnerFilter,
      ).timeout(
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
    final viewModel = context.watch<BookingViewModel>();

    if (viewModel.user == null) {
      return const AuthScreen();
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
                    Icons.event_note,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  ConstantsString.appBarName,
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
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  icon: const Icon(Icons.account_balance_wallet, size: 20),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BookingExpensesScreen(),
                      ),
                    );
                  },
                  tooltip: 'Expenses',
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 6, left: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  onPressed: () => _handleGeneratePdf(context),
                  tooltip: 'Generate PDF',
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: AppDrawer(),
      body: Container(
        color: AppColor.background,
        child: Stack(
          children: [
            Column(
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
                  child: StreamBuilder<List<Booking>>(
                    stream: viewModel.bookings,
                    builder: (context, snapshot) {
                      final allBookings = snapshot.data ?? [];
                      final filteredBookings =
                          _selectedOwnerFilter == null
                              ? allBookings
                              : allBookings
                                  .where(
                                    (b) =>
                                        b.organizer != null &&
                                        b.organizer!.trim().toLowerCase() ==
                                            _selectedOwnerFilter!
                                                .trim()
                                                .toLowerCase(),
                                  )
                                  .toList();

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.event_note,
                                          color: Colors.white70,
                                          size: 14,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          "Total Bookings",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "${filteredBookings.length}",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedOwnerFilter,
                                  hint: const Text(
                                    "Filter",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  dropdownColor: AppColor.primaryDark,
                                  underline: const SizedBox(),
                                  icon: const Icon(
                                    Icons.filter_list,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text("All Organizers"),
                                    ),
                                    ...viewModel.organizers
                                        .where((o) => o != "Other")
                                        .map(
                                          (organizer) =>
                                              DropdownMenuItem<String>(
                                                value: organizer,
                                                child: Text(organizer),
                                              ),
                                        )
                                        .toList(),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedOwnerFilter = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Booking>>(
                    stream: viewModel.bookings,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColor.primary,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        debugPrint('Bookings stream error: ${snapshot.error}');
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final allBookings = snapshot.data ?? [];
                      final bookings =
                          _selectedOwnerFilter == null
                              ? allBookings
                              : allBookings
                                  .where(
                                    (b) =>
                                        b.organizer?.trim().toLowerCase() ==
                                        _selectedOwnerFilter
                                            ?.trim()
                                            .toLowerCase(),
                                  )
                                  .toList();

                      return bookings.isEmpty
                          ? const Center(
                            child: Text(
                              ConstantsString.bookingNotFound,
                              style: TextStyle(color: AppColor.grey),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
                              return BookingItem(booking: booking);
                            },
                          );
                    },
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
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
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder:
                  (_) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: const BookingDialog(),
                  ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
