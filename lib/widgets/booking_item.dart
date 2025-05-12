import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import 'booking_dialog.dart';

class BookingItem extends StatelessWidget {
  final int index;
  final Booking booking;

  const BookingItem({super.key, required this.index, required this.booking});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => BookingDialog(index: index, booking: booking),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ListTile(
          leading: CircleAvatar(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(booking.date),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(booking.date),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          title: Text(booking.owner),
          subtitle: Row(
            children: [Icon(Icons.location_on,size: 16,), Text(booking.location)],
          ),
          trailing: const Icon(Icons.edit),
        ),
      ),
    );
  }
}
