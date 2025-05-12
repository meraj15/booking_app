import 'package:flutter/material.dart';

class AppConstants {
  static const double spacing = 15.0;
}

class AppStyles {
  static const TextStyle dialogTitleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  static const TextStyle cancelButtonStyle = TextStyle(
    color: Colors.grey,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white,
  );

  static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );
}