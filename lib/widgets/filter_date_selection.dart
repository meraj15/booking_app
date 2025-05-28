import 'package:booking_app/widgets/text_field.dart';
import 'package:flutter/material.dart';

class FilterSection extends StatelessWidget {
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;

  const FilterSection({
    super.key,
    required this.startDateController,
    required this.endDateController,
    required this.onStartDateTap,
    required this.onEndDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: BookingTextField(
                  controller: startDateController,
                  labelText: 'Start Date',
                  hintText: 'Select start date',
                  icon: Icons.calendar_today,
                  readOnly: true,
                  onTap: onStartDateTap,
                  
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: BookingTextField(
                  controller: endDateController,
                  labelText: 'End Date',
                  hintText: 'Select end date',
                  icon: Icons.calendar_today,
                  readOnly: true,
                  onTap: onEndDateTap,
                  
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}