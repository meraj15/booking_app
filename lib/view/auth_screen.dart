
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/booking_view_model.dart';
import 'bookings_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookingViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await viewModel.googleLogin();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BookingsScreen()),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}