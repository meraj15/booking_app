import 'package:booking_app/constant/app_color.dart';
import 'package:booking_app/view_models/booking_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
      final viewModel = context.watch<BookingViewModel>();

    return  Drawer(
        child: Column(
          children: [
            Container(
              height: 200, 
              width: double.infinity,
              color: AppColor.primary,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColor.secondary,
                    child: Text(
                      viewModel.user?.displayName?.isNotEmpty == true
                          ? viewModel.user!.displayName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppColor.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.user?.displayName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    viewModel.user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColor.redColor),
              title: const Text('Logout'),
              onTap: () async {
                debugPrint('Logging out user: ${viewModel.user?.email}');
                try {
                  await viewModel.signOut();
                  Navigator.pop(context); // Close the drawer
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              },
            ),
          ],
        ),
      )
;
  }
}