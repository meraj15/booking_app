import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'view/home_screen.dart';
import 'view_models/booking_view_model.dart';

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => BookingViewModel(),
//       child: MaterialApp(
//         theme: ThemeData(
//           useMaterial3: false,
//         ),
//         home: const HomeScreen(),
//       ),
//     );
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = BookingViewModel();
        viewModel.loadBookings(); 
        return viewModel;
      },
      child: MaterialApp(
        title: 'Booking App',
        theme: ThemeData(
          useMaterial3: false
        ),
        home: const HomeScreen(),
      ),
    );
  }
}