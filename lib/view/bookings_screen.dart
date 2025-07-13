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
  static final _lastDate = DateTime(2026);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
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
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.filterStartDate ?? DateTime.now(),
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
    DateTime initialDate = viewModel.filterEndDate ?? DateTime.now();
    if (viewModel.filterStartDate != null &&
        initialDate.isBefore(viewModel.filterStartDate!)) {
      initialDate = viewModel.filterStartDate!;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: viewModel.filterStartDate ?? _firstDate,
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
    final theme = Theme.of(context);
    final viewModel = context.watch<BookingViewModel>();

    if (viewModel.user == null) {
      return const AuthScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(ConstantsString.appBarName),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,

        actions: [
          IconButton(
            icon: const Icon(Icons.money),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BookingExpensesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _handleGeneratePdf(context),
          ),
        ],
      ),
      drawer:AppDrawer(),
      body: Stack(
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: StreamBuilder<List<Booking>>(
  stream: viewModel.bookings,
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      debugPrint('Bookings stream error: ${snapshot.error}');
    }
    final allBookings = snapshot.data ?? [];
final filteredBookings = _selectedOwnerFilter == null
    ? allBookings
    : allBookings.where((b) =>
        b.organizer != null &&
        b.organizer!.trim().toLowerCase() ==
            _selectedOwnerFilter!.trim().toLowerCase()
      ).toList();

return Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      "Total Booking: ${filteredBookings.length}",
      style: const TextStyle(fontSize: 16),
    ),
        DropdownButton<String>(
          value: _selectedOwnerFilter,
          hint: const Text("Select Owner"),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text("All"),
            ),
            ...viewModel.organizers
                .where((o) => o != "Other")
                .map((organizer) => DropdownMenuItem<String>(
                      value: organizer,
                      child: Text(organizer),
                    ))
                .toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedOwnerFilter = value;
            });
          },
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
final bookings = _selectedOwnerFilter == null
    ? allBookings
    : allBookings.where((b) => b.organizer?.trim().toLowerCase() == _selectedOwnerFilter?.trim().toLowerCase()
).toList();

                    return bookings.isEmpty
                        ? const Center(
                          child: Text(ConstantsString.bookingNotFound),
                        )
                        : ListView.builder(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (_) => const BookingDialog());
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
