import 'package:booking_app/constant/app_color.dart';
import 'package:booking_app/constant/app_constant_string.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/booking.dart';
import '../view_models/booking_view_model.dart';
import 'text_field.dart';

class BookingDialog extends StatefulWidget {
  final String? bookingId;
  final Booking? booking;
  final bool isDuplicate;

  const BookingDialog({
    super.key,
    this.bookingId,
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
  late final TextEditingController _descriptionController;
  DateTime? _selectedDate;
  String _selectedBookingType = ConstantsString.defaultBookingType;
  String? _selectedOrganizer;

  final SpeechToText _speech = SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListeningForLocation = false;
  bool _isListeningForOwner = false;

  static final _firstDate = DateTime(2025);
  static final _lastDate = DateTime(2026, 12, 31);

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(
      text: widget.booking?.location.toUpperCase() ?? '',
    );
    _ownerController = TextEditingController(
      text: widget.booking?.owner.toUpperCase() ?? '',
    );
    _selectedDate =
        widget.booking?.date ??
        (widget.isDuplicate ? DateTime.now() : DateTime.now());
    _dateController = TextEditingController(
      text: DateFormat(ConstantsString.dateFormat).format(_selectedDate!),
    );
    _customOrganizerController = TextEditingController();
    _descriptionController = TextEditingController(
      text: widget.booking?.description ?? "",
    );
    _selectedBookingType =
        widget.booking?.bookingType ?? ConstantsString.defaultBookingType; // ✅
    _selectedOrganizer =
        widget.booking?.organizer != null &&
                context.read<BookingViewModel>().organizers.contains(
                  widget.booking!.organizer,
                )
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
            _isListeningForLocation = false;
            _isListeningForOwner = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mic error: ${error.errorMsg}')),
          );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mic not available')));
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Listening...')));
    _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          setState(
            () => controller.text = result.recognizedWords.toUpperCase(),
          );
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Stopped')));
  }

  @override
  void dispose() {
    _locationController.dispose();
    _ownerController.dispose();
    _dateController.dispose();
    _customOrganizerController.dispose();
    _descriptionController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
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
        _selectedDate = picked;
        _dateController.text = DateFormat(
          ConstantsString.dateFormat,
        ).format(picked);
      });
    }
  }

  Future<void> _saveBooking(BuildContext context) async {
    final viewModel = context.read<BookingViewModel>();
    if (_formKey.currentState!.validate()) {
      String? finalOrganizer = _selectedOrganizer;
      if (_selectedOrganizer == 'Other') {
        finalOrganizer = _customOrganizerController.text.trim().toUpperCase();
        if (finalOrganizer.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter custom organizer')),
          );
          return;
        }
      }

      final newBooking = Booking(
        id: widget.bookingId ?? '', // Use empty ID for new bookings
        date: _selectedDate!,
        location: _locationController.text.trim().toUpperCase(),
        owner: _ownerController.text.trim().toUpperCase(),
        bookingType: _selectedBookingType,
        organizer: finalOrganizer,
        description: _descriptionController.text.trim(),
      );

      try {
        if (widget.bookingId != null && !widget.isDuplicate) {
          await viewModel.updateBooking(widget.bookingId!, newBooking);
        } else {
          await viewModel.addBooking(newBooking);
        }
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error saving booking: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save booking: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookingViewModel>();
    if (viewModel.user?.email == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add a booking')),
      );
      return const SizedBox.shrink();
    }

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
                    Icons.event_note,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.isDuplicate
                        ? 'Duplicate Booking'
                        : widget.bookingId == null
                        ? 'New Booking'
                        : 'Edit Booking',
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
                    // Date & Location Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColor.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.event_available,
                                color: AppColor.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Booking Details',
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
                            controller: _dateController,
                            labelText: 'Date',
                            hintText: 'Select booking date',
                            icon: Icons.calendar_today,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            validator:
                                (value) =>
                                    _selectedDate == null
                                        ? 'Please select a date'
                                        : null,
                          ),
                          const SizedBox(height: 10),
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
                            onChanged:
                                (value) =>
                                    _locationController.text =
                                        value.toUpperCase(),
                            showMicButton: _isSpeechAvailable,
                            isListening: _isListeningForLocation,
                            onMicPressed:
                                () =>
                                    _isListeningForLocation
                                        ? _stopListening()
                                        : _startListening(
                                          _locationController,
                                          'location',
                                        ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Owner Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.info.withOpacity(0.05),
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
                                Icons.person_outline,
                                color: AppColor.info,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Owner Information',
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
                            onChanged:
                                (value) =>
                                    _ownerController.text = value.toUpperCase(),
                            showMicButton: _isSpeechAvailable,
                            isListening: _isListeningForOwner,
                            onMicPressed:
                                () =>
                                    _isListeningForOwner
                                        ? _stopListening()
                                        : _startListening(
                                          _ownerController,
                                          'owner',
                                        ),
                          ),
                          const SizedBox(height: 10),
                          BookingTextField(
                            controller: _descriptionController,
                            labelText: 'Description (optional)',
                            hintText: 'Enter description...',
                            icon: Icons.notes,
                            validator: (value) => null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Booking Type Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.success.withOpacity(0.05),
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
                                Icons.category,
                                color: AppColor.success,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Booking Type',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.greyDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedBookingType,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items:
                                ConstantsString.allowedBookingTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedBookingType = value);
                              }
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Please select booking type'
                                        : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Organizer Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.accent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColor.accent.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.groups,
                                color: AppColor.accent,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Organizer',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.greyDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedOrganizer,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items:
                                viewModel.organizers.map((String organizer) {
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
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Please select an organizer'
                                        : null,
                          ),
                          if (_selectedOrganizer == 'Other') ...[
                            const SizedBox(height: 12),
                            BookingTextField(
                              controller: _customOrganizerController,
                              labelText: 'Custom Organizer',
                              hintText: 'Enter organizer name',
                              icon: Icons.person_add,
                              onChanged:
                                  (value) =>
                                      _customOrganizerController.text =
                                          value.toUpperCase(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a custom organizer';
                                }
                                final trimmedValue = value.trim();
                                if (trimmedValue.replaceAll(' ', '').length <
                                    3) {
                                  return 'Organizer name must be at least 3 characters long';
                                }
                                return null;
                              },
                            ),
                          ],
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
                  onPressed: () => Navigator.pop(context),
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
                    onPressed: () => _saveBooking(context),
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
                          widget.isDuplicate
                              ? Icons.content_copy
                              : widget.bookingId == null
                              ? Icons.add_circle_outline
                              : Icons.check_circle_outline,
                          color: AppColor.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isDuplicate
                              ? 'Duplicate'
                              : widget.bookingId == null
                              ? 'Add Booking'
                              : 'Update',
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
