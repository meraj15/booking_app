import 'package:booking_app/models/payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OwnerPayment Model Tests', () {
    test('Calculates balance and payment status correctly', () {
      final payment = OwnerPayment(
        id: 'pay-1',
        ownerName: 'ROYAL PALACE',
        totalAmount: 40000.0,
        amountGiven: 30000.0,
        paymentDate: DateTime(2026, 8, 15),
        paymentMethod: 'UPI',
        accountName: 'SBI Account',
        note: '40 bookings settlement',
      );

      expect(payment.id, 'pay-1');
      expect(payment.ownerName, 'ROYAL PALACE');
      expect(payment.totalAmount, 40000.0);
      expect(payment.amountGiven, 30000.0);
      expect(payment.balance, 10000.0);
      expect(payment.isFullyPaid, false);
      expect(payment.hasPendingBalance, true);
    });

    test('Identifies fully paid settlement when amount given equals total', () {
      final payment = OwnerPayment(
        id: 'pay-2',
        ownerName: 'ROYAL PALACE',
        totalAmount: 40000.0,
        amountGiven: 40000.0,
        paymentDate: DateTime(2026, 8, 15),
        paymentMethod: 'Cash',
        accountName: 'Cash in Hand',
      );

      expect(payment.balance, 0.0);
      expect(payment.isFullyPaid, true);
      expect(payment.hasPendingBalance, false);
    });

    test('Handles toMap and fromMap serialization accurately', () {
      final date = DateTime(2026, 9, 5);
      final payment = OwnerPayment(
        id: 'pay-3',
        ownerName: 'SHARMA RESORTS',
        totalAmount: 50000.0,
        amountGiven: 25000.0,
        paymentDate: date,
        paymentMethod: 'Bank Transfer',
        accountName: 'HDFC Bank',
        note: 'Part payment',
      );

      final map = payment.toMap();
      expect(map['ownerName'], 'SHARMA RESORTS');
      expect(map['totalAmount'], 50000.0);
      expect(map['amountGiven'], 25000.0);
      expect(map['paymentMethod'], 'Bank Transfer');
      expect(map['accountName'], 'HDFC Bank');
      expect(map['note'], 'Part payment');
      expect(map['paymentDate'], isA<Timestamp>());

      final restored = OwnerPayment.fromMap('pay-3', map);
      expect(restored.id, 'pay-3');
      expect(restored.ownerName, 'SHARMA RESORTS');
      expect(restored.totalAmount, 50000.0);
      expect(restored.amountGiven, 25000.0);
      expect(restored.balance, 25000.0);
      expect(restored.paymentMethod, 'Bank Transfer');
      expect(restored.accountName, 'HDFC Bank');
    });

    test('copyWith updates fields while preserving others', () {
      final payment = OwnerPayment(
        id: 'pay-4',
        ownerName: 'STAR LAWNS',
        totalAmount: 30000.0,
        amountGiven: 10000.0,
        paymentDate: DateTime(2026, 9, 1),
        paymentMethod: 'Cash',
        accountName: 'Cash in Hand',
      );

      final updated = payment.copyWith(
        amountGiven: 25000.0,
        paymentMethod: 'UPI',
      );

      expect(updated.id, 'pay-4');
      expect(updated.ownerName, 'STAR LAWNS');
      expect(updated.totalAmount, 30000.0);
      expect(updated.amountGiven, 25000.0);
      expect(updated.balance, 5000.0);
      expect(updated.paymentMethod, 'UPI');
      expect(updated.accountName, 'Cash in Hand');
    });
  });
}
