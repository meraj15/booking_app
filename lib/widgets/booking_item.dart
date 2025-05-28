import 'package:booking_app/constants/app_color.dart';
import 'package:booking_app/view_models/booking_view_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import 'booking_dialog.dart';

class BookingItem extends StatelessWidget {
  final int index;
  final Booking booking;

  const BookingItem({super.key, required this.index, required this.booking});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        context.read<BookingViewModel>().googleLogin();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ListTile(
          leading: CircleAvatar(
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
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
            children: [
              const Icon(Icons.location_on, size: 16),
              Text(booking.location),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final viewModel = context.read<BookingViewModel>();
              if (value == 'edit') {
                showDialog(
                  context: context,
                  builder: (_) => BookingDialog(index: index, booking: booking),
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
                  viewModel.deleteBooking(index);
                }
              } else if (value == 'duplicate') {
                showDialog(
                  context: context,
                  builder:
                      (_) => BookingDialog(booking: booking, isDuplicate: true),
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color:  AppColor.primary),
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
                        Icon(Icons.control_point_duplicate, color:  AppColor.primary),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                ],
          ),
        
        
        ),
      ),
    );
  }
}
