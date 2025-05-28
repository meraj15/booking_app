import 'package:booking_app/constants/app_color.dart';
import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

 

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2025),
              lastDate: DateTime(2026),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Text(
            selectedDate == null
                ? 'Select Booking Date'
                : 'Selected: ${selectedDate!.toLocal().toString().split(' ')[0]}',
            style: TextStyle(
    color: AppColor.primary,
    fontSize: 16,
  ),
          ),
        ),
      ],
    );
  }
}