import 'package:cloud_firestore/cloud_firestore.dart';

class Expenses {
  final String id;
  final double price;
  final DateTime fromDate;
  final DateTime? toDate;
  

  Expenses({
    required this.id,
    required this.price,
    required this.fromDate,
    this.toDate,
  });

  Map<String, dynamic> toMap() => {
        'price': price,
        'fromDate': Timestamp.fromDate(fromDate),
        'toDate': toDate != null ? Timestamp.fromDate(toDate!) : null,
      };

  factory Expenses.fromMap(String id, Map<String, dynamic> data) => Expenses(
        id: id,
        price: data['price']?.toDouble() ?? 0.0,
        fromDate: (data['fromDate'] as Timestamp).toDate(),
        toDate: data['toDate'] != null ? (data['toDate'] as Timestamp).toDate() : null,
      );
}