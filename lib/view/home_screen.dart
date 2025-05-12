import 'package:booking_app/widgets/booking_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/booking_view_model.dart';
import '../widgets/booking_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking App'),
      ),
      body: Consumer<BookingViewModel>(
        builder: (context, viewModel, child) {
          return viewModel.bookings.isEmpty
              ? const Center(child: Text('No bookings yet. Tap to add!'))
              : ListView.builder(
                  itemCount: viewModel.bookings.length,
                  itemBuilder: (context, index) {
                    final booking = viewModel.bookings[index];
                    return BookingItem(index: index, booking: booking);
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const BookingDialog(),
          );
        },
        tooltip: 'Add Booking',
        child: const Icon(Icons.add),
      ),
    );
  }
}
