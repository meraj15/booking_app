import 'package:booking_app/constants/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For inputFormatters

class BookingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData icon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool showMicButton;
  final bool isListening;
  final VoidCallback? onMicPressed;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType; 
  final List<TextInputFormatter>? inputFormatters; 

  const BookingTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.icon,
    this.validator,
    this.onChanged,
    this.showMicButton = false,
    this.isListening = false,
    this.onMicPressed,
    this.readOnly = false,
    this.onTap,
    this.keyboardType, // New
    this.inputFormatters, // New
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType, 
      inputFormatters: inputFormatters, 
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon),
        suffixIcon: showMicButton
            ? GestureDetector(
                onTap: onMicPressed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.mic,
                    color: isListening ? AppColor.redColor : AppColor.primary,
                    size: isListening ? 24 : 20,
                  ),
                ),
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}