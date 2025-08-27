// import 'package:flutter/material.dart';

// class BookingTypeSelector extends StatelessWidget {
//   final bool isDayNight;
//   final ValueChanged<bool> onChanged;

//   const BookingTypeSelector({
//     super.key,
//     required this.isDayNight,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: [
//         Radio<bool>(
//           value: false,
//           groupValue: isDayNight,
//           onChanged: (value) => onChanged(value!),
//         ),
//         const Text('Only Day'),
//         const SizedBox(width: 2),
//         Radio<bool>(
//           value: true,
//           groupValue: isDayNight,
//           onChanged: (value) => onChanged(value!),
//         ),
//         const Text('Day&Night'),
//       ],
//     );
//   }
// }