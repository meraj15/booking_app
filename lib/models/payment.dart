import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerPayment {
  final String id;
  final String ownerName;
  final double totalAmount;
  final double amountGiven;
  final DateTime paymentDate;
  final String paymentMethod;
  final String accountName;
  final String note;
  final DateTime createdAt;

  OwnerPayment({
    required this.id,
    required this.ownerName,
    required this.totalAmount,
    required this.amountGiven,
    required this.paymentDate,
    required this.paymentMethod,
    required this.accountName,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get balance =>
      (totalAmount - amountGiven).clamp(0.0, double.infinity);

  bool get isFullyPaid => totalAmount > 0 && amountGiven >= totalAmount;

  bool get hasPendingBalance => balance > 0;

  Map<String, dynamic> toMap() {
    return {
      'ownerName': ownerName,
      'totalAmount': totalAmount,
      'amountGiven': amountGiven,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentMethod': paymentMethod,
      'accountName': accountName,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory OwnerPayment.fromMap(String id, Map<String, dynamic> data) {
    final paymentDateVal = data['paymentDate'];
    DateTime parsedPaymentDate;
    if (paymentDateVal is Timestamp) {
      parsedPaymentDate = paymentDateVal.toDate();
    } else if (paymentDateVal is DateTime) {
      parsedPaymentDate = paymentDateVal;
    } else {
      parsedPaymentDate = DateTime.now();
    }

    final createdAtVal = data['createdAt'];
    DateTime parsedCreatedAt;
    if (createdAtVal is Timestamp) {
      parsedCreatedAt = createdAtVal.toDate();
    } else if (createdAtVal is DateTime) {
      parsedCreatedAt = createdAtVal;
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return OwnerPayment(
      id: id,
      ownerName: data['ownerName'] ?? 'Unknown Owner',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      amountGiven: (data['amountGiven'] as num?)?.toDouble() ?? 0.0,
      paymentDate: parsedPaymentDate,
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      accountName: data['accountName'] ?? 'Cash in Hand',
      note: data['note'] ?? '',
      createdAt: parsedCreatedAt,
    );
  }

  OwnerPayment copyWith({
    String? id,
    String? ownerName,
    double? totalAmount,
    double? amountGiven,
    DateTime? paymentDate,
    String? paymentMethod,
    String? accountName,
    String? note,
    DateTime? createdAt,
  }) {
    return OwnerPayment(
      id: id ?? this.id,
      ownerName: ownerName ?? this.ownerName,
      totalAmount: totalAmount ?? this.totalAmount,
      amountGiven: amountGiven ?? this.amountGiven,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      accountName: accountName ?? this.accountName,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
