import 'package:booking_app/view/auth_screen.dart';
import 'package:booking_app/view_models/expenses_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'view/bookings_screen.dart';
import 'view_models/booking_view_model.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingViewModel()),
        ChangeNotifierProvider(create: (_) => ExpensesViewModel()),
      ],
      child: MaterialApp(
        title: 'Booking App',
        home: Builder(
          builder: (context) {
            // Initialize BookingViewModel after providers are available
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final bookingViewModel = Provider.of<BookingViewModel>(
                context,
                listen: false,
              );
              if (bookingViewModel.isCheckingAuth) {
                bookingViewModel.checkInitialSignIn(context);
              }
            });

            return Consumer<BookingViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.isCheckingAuth) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return viewModel.user != null
                    ? const BookingsScreen()
                    : const AuthScreen();
              },
            );
          },
        ),
      ),
    );
  }
}
