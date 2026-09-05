import 'package:booking_app/constant/app_color.dart';
import 'package:booking_app/models/payment.dart';
import 'package:booking_app/view_models/payment_view_model.dart';
import 'package:booking_app/widgets/payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PaymentItem extends StatelessWidget {
  final OwnerPayment payment;

  const PaymentItem({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.isFullyPaid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: PaymentDialog(payment: payment),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Badge
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColor.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(payment.paymentDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(payment.paymentDate),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Owner Name + Status Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              payment.ownerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColor.greyDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? AppColor.success.withOpacity(0.12)
                                  : AppColor.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isPaid
                                    ? AppColor.success.withOpacity(0.3)
                                    : AppColor.accent.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isPaid
                                  ? 'CLEARED'
                                  : 'BAL: ₹${payment.balance.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPaid
                                    ? AppColor.success
                                    : AppColor.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Amounts Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _amountSnippet(
                              'Total',
                              '₹${payment.totalAmount.toStringAsFixed(0)}',
                              Colors.grey.shade700,
                            ),
                            Container(
                              height: 16,
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                            _amountSnippet(
                              'Given',
                              '₹${payment.amountGiven.toStringAsFixed(0)}',
                              AppColor.success,
                            ),
                            Container(
                              height: 16,
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                            _amountSnippet(
                              'Balance',
                              '₹${payment.balance.toStringAsFixed(0)}',
                              isPaid ? AppColor.success : AppColor.accent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Method & Account Row
                      Row(
                        children: [
                          Icon(
                            Icons.payment,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            payment.paymentMethod,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.account_balance,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              payment.accountName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Note
                      if (payment.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          payment.note,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Popup Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: PaymentDialog(payment: payment),
                        ),
                      );
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: const Text(
                            'Delete Payment',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            'Are you sure you want to delete payment record for ${payment.ownerName}?',
                            style: const TextStyle(fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.error,
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        try {
                          await context
                              .read<PaymentViewModel>()
                              .deletePayment(payment.id);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e')),
                            );
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              color: AppColor.primary, size: 16),
                          SizedBox(width: 10),
                          Text('Edit', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: AppColor.error, size: 16),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountSnippet(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
