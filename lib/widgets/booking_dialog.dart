import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../view_models/booking_view_model.dart';
import 'booking_text_field.dart';

class BookingDialog extends StatefulWidget {
  final int? index;
  final Booking? booking;

  const BookingDialog({super.key, this.index, this.booking});

  @override
  _BookingDialogState createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  late final TextEditingController _locationController;
  late final TextEditingController _ownerController;
  late final TextEditingController _dateController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _locationController =
        TextEditingController(text: widget.booking?.location ?? '');
    _ownerController = TextEditingController(text: widget.booking?.owner ?? '');
    _dateController = TextEditingController(
      text: widget.booking?.date != null
          ? DateFormat('dd/MM/yyyy').format(widget.booking!.date)
          : '',
    );
    _selectedDate = widget.booking?.date;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _ownerController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    if (_selectedDate == null) {
      return 'Please select a date';
    }
    if (_locationController.text.trim().isEmpty) {
      return 'Please enter a location';
    }
    if (_ownerController.text.trim().isEmpty) {
      return 'Please enter an owner name';
    }
    return null;
  }

  void _saveBooking(BuildContext context) {
    final errorMessage = _validateInputs();
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    final newBooking = Booking(
      date: _selectedDate!,
      location: _locationController.text.trim(),
      owner: _ownerController.text.trim(),
    );
    final viewModel = context.read<BookingViewModel>();
    if (widget.index != null) {
      viewModel.updateBooking(widget.index!, newBooking);
    } else {
      viewModel.addBooking(newBooking);
    }
    Navigator.of(context).pop();
  }

  Future<void> _selectDate(BuildContext context) async {
    debugPrint('Opening DatePicker');
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      debugPrint('Selected date: ${picked.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerRead = context.read<BookingViewModel>();
    return AlertDialog(
      title: Text(
        widget.index == null ? 'Enter Booking Details' : 'Edit Booking Details',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BookingTextField(
              controller: _dateController,
              labelText: 'Date',
              hintText: 'Select booking date',
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            SizedBox(height: providerRead.spacing),
            BookingTextField(
              controller: _locationController,
              labelText: 'Location',
              hintText: 'Enter booking location',
              icon: Icons.location_on,
            ),
            SizedBox(height: providerRead.spacing),
            BookingTextField(
              controller: _ownerController,
              labelText: 'Owner Name',
              hintText: "Enter owner's name",
              icon: Icons.person,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(
                color: Colors.grey,
              )),
        ),
        ElevatedButton(
          onPressed: () => _saveBooking(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            widget.index == null ? 'Add' : 'Update',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
