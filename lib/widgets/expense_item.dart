import 'package:booking_app/constant/app_color.dart';
import 'package:booking_app/models/expenses.dart';
import 'package:booking_app/view_models/expenses_view_model.dart';
import 'package:booking_app/widgets/expenses.dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExpenseItem extends StatelessWidget {
  final int index; 
  final Expenses expense;
  final String dateText;

  const ExpenseItem({
    super.key,
    required this.index,
    required this.expense,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(child: Text("${index + 1}")),
        title: Text('${expense.price} Rupees'),
        subtitle: Text(dateText),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            final viewModel = context.read<ExpensesViewModel>();
            if (value == 'edit') {
              showDialog(
                context: context,
                builder: (_) => ExpensesDialog(expense: expense),
              );
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Expense'),
                  content: const Text(
                    'Are you sure you want to delete this expense?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: AppColor.redColor),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await viewModel.deleteExpenses(expense.id);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete expense: $e')),
                  );
                }
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColor.primary),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColor.redColor),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}