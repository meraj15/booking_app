import 'package:booking_app/constant/app_color.dart';
import 'package:booking_app/view_models/booking_view_model.dart';
import 'package:booking_app/widgets/expenses.dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import 'booking_dialog.dart';

class BookingItem extends StatelessWidget {
  final Booking booking;

  const BookingItem({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('dd').format(booking.date),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('MMM').format(booking.date),
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        title: Text(booking.owner),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, size: 16),
            Expanded(
              child: Text(
                booking.location,
                // overflow: TextOverflow.ellipsis,
                // maxLines: 1,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            final viewModel = context.read<BookingViewModel>();
            if (value == 'edit') {
              showDialog(
                context: context,
                builder:
                    (_) =>
                        BookingDialog(bookingId: booking.id, booking: booking),
              );
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Delete Booking'),
                      content: const Text(
                        'Are you sure you want to delete this booking?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: AppColor.redColor),
                          ),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                try {
                  await viewModel.deleteBooking(booking.id);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete booking: $e')),
                  );
                }
              }
            } else if (value == 'duplicate') {
              showDialog(
                context: context,
                builder:
                    (_) => BookingDialog(booking: booking, isDuplicate: true),
              );
            } else if (value == 'add_expense') {
              showDialog(
                context: context,
                builder: (context) =>  ExpensesDialog(),
              );
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppColor.primary),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColor.redColor),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(
                        Icons.control_point_duplicate,
                        color: AppColor.primary,
                      ),
                      SizedBox(width: 8),
                      Text('Duplicate'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'add_expense',
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, color: AppColor.primary),
                      SizedBox(width: 8),
                      Text('Add Expense'),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }
}
