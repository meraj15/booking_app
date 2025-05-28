import 'package:booking_app/constants/app_color.dart';
import 'package:booking_app/constants/constants.dart';
import 'package:booking_app/widgets/booking_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/booking.dart';
import '../view_models/booking_view_model.dart';
import 'text_field.dart';

class BookingDialog extends StatefulWidget {
  final String? id;
  final int? index;
  final Booking? booking;
  final bool isDuplicate;

  const BookingDialog({
    super.key,
    this.id,
    this.index,
    this.booking,
    this.isDuplicate = false,
  });

  @override
  _BookingDialogState createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _locationController;
  late final TextEditingController _ownerController;
  late final TextEditingController _dateController;
  late final TextEditingController _customOrganizerController;
  DateTime? _selectedDate;
  bool _isDayNight = false;
  String? _selectedOrganizer;

  final SpeechToText _speech = SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListeningForLocation = false;
  bool _isListeningForOwner = false;

  static final _firstDate = DateTime(2025);
  static final _lastDate = DateTime(2026);

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.booking?.location.toUpperCase() ?? '');
    _ownerController = TextEditingController(text: widget.booking?.owner.toUpperCase() ?? '');
    _selectedDate = widget.booking?.date ?? (widget.isDuplicate ? DateTime.now() : DateTime.now());
    _dateController = TextEditingController(
      text: DateFormat(ConstantsString.dateFormat).format(_selectedDate!),
    );
    _customOrganizerController = TextEditingController();
    _isDayNight = widget.booking?.dayNight ?? false;
    _selectedOrganizer = widget.booking?.organizer != null &&
            context.read<BookingViewModel>().organizers.contains(widget.booking!.organizer)
        ? widget.booking!.organizer
        : 'Ramzaan';
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isSpeechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListeningForLocation = false;
              _isListeningForOwner = false;
            });
          }
        },
        onError: (error) {
          setState(() {
            _isSpeechAvailable = false;
            _isListeningForLocation = false;
            _isListeningForOwner = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mic error: ${error.errorMsg}')));
        },
      );
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing speech: $e');
      setState(() => _isSpeechAvailable = false);
    }
  }

  void _startListening(TextEditingController controller, String field) {
    if (!_isSpeechAvailable) {
      _initSpeech();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mic not available')));
      return;
    }
    setState(() {
      if (field == 'location') {
        _isListeningForLocation = true;
        _isListeningForOwner = false;
      } else {
        _isListeningForOwner = true;
        _isListeningForLocation = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listening...')));
    _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          setState(() => controller.text = result.recognizedWords.toUpperCase());
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      localeId: 'en_US',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListeningForLocation = false;
      _isListeningForOwner = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stopped')));
  }

  @override
  void dispose() {
    _locationController.dispose();
    _ownerController.dispose();
    _dateController.dispose();
    _customOrganizerController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: _firstDate,
      lastDate: _lastDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =DateFormat(ConstantsString.dateFormat).format(picked);
      });
    }
  }

  Future<void> _addBooking(BuildContext context) async {
    final viewModel = context.read<BookingViewModel>();
    if (_formKey.currentState!.validate()) {
      String? finalOrganizer = _selectedOrganizer;
      if (_selectedOrganizer == 'Other') {
        finalOrganizer = _customOrganizerController.text.trim().toUpperCase();
        if (finalOrganizer.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('enter custom organizer')),
          );
          return;
        }
      }

      final newBooking = Booking(
        id: widget.id ?? '',
        date: _selectedDate!,
        location: _locationController.text.trim().toUpperCase(),
        owner: _ownerController.text.trim().toUpperCase(),
        // userEmail: viewModel.user!.email,
        dayNight: _isDayNight,
        organizer: finalOrganizer,
      );

      try {
        if (widget.index != null && !widget.isDuplicate) {
          await viewModel.updateBooking(widget.index!, newBooking);
        } else {
          await viewModel.addBooking(newBooking);
        }
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error saving booking: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save booking: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<BookingViewModel>();
    if (viewModel.user?.email == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to add a booking')));
      return const SizedBox.shrink();
    }

    return AlertDialog(
      title: Text(
        widget.isDuplicate
            ? 'Duplicate Booking'
            : widget.index == null
                ? 'Enter Booking Details'
                : 'Edit Booking Details',
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
                controller: _dateController,
                labelText: 'Date',
                hintText: 'Select booking date',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) => _selectedDate == null ? 'Please select a date' : null,
              ),
              const SizedBox(height: 18.0),
              BookingTextField(
                controller: _locationController,
                labelText: 'Location',
                hintText: 'Booking location',
                icon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  final trimmedValue = value.trim();
                  if (trimmedValue.replaceAll(' ', '').length < 3) {
                    return 'Location must be at least 3 characters long';
                  }
                  return null;
                },
                onChanged: (value) => _locationController.text = value.toUpperCase(),
                showMicButton: _isSpeechAvailable,
                isListening: _isListeningForLocation,
                onMicPressed: () =>
                    _isListeningForLocation ? _stopListening() : _startListening(_locationController, 'location'),
              ),
              const SizedBox(height: 18.0),
              BookingTextField(
                controller: _ownerController,
                labelText: 'Owner Name',
                hintText: "Owner's name",
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an owner name';
                  }
                  final trimmedValue = value.trim();
                  if (trimmedValue.replaceAll(' ', '').length < 3) {
                    return 'Owner name must be at least 3 characters long';
                  }
                  return null;
                },
                onChanged: (value) => _ownerController.text = value.toUpperCase(),
                showMicButton: _isSpeechAvailable,
                isListening: _isListeningForOwner,
                onMicPressed: () =>
                    _isListeningForOwner ? _stopListening() : _startListening(_ownerController, 'owner'),
              ),
              const SizedBox(height: 18.0),
              Text(
                'Booking Type',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              BookingTypeSelector(
                isDayNight: _isDayNight,
                onChanged: (value) => setState(() => _isDayNight = value),
              ),
              const SizedBox(height: 18.0),
              Text(
                'Organizer',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _selectedOrganizer,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: viewModel.organizers.map((String organizer) {
                  return DropdownMenuItem<String>(
                    value: organizer,
                    child: Text(organizer),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedOrganizer = newValue;
                    if (_selectedOrganizer != 'Other') {
                      _customOrganizerController.clear();
                    }
                  });
                },
                validator: (value) => value == null ? 'Please select an organizer' : null,
              ),
              if (_selectedOrganizer == 'Other') ...[
                const SizedBox(height: 18.0),
                BookingTextField(
                  controller: _customOrganizerController,
                  labelText: 'Custom Organizer',
                  hintText: 'Enter organizer name',
                  icon: Icons.person,
                  onChanged: (value) => _customOrganizerController.text = value.toUpperCase(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a custom organizer';
                    }
                    final trimmedValue = value.trim();
                    if (trimmedValue.replaceAll(' ', '').length < 3) {
                      return 'Organizer name must be at least 3 characters long';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ),
        ElevatedButton(
          onPressed: () => _addBooking(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: AppColor.whiteColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          child: Text(widget.isDuplicate ? 'Add' : widget.index == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}