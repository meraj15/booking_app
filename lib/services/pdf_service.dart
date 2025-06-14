import 'package:booking_app/constants/constants.dart';
import 'package:booking_app/models/booking.dart';
import 'package:booking_app/models/expenses.dart';
import 'package:booking_app/services/firestore_service.dart';
import 'package:booking_app/view_models/booking_view_model.dart';
import 'package:booking_app/view_models/expenses_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';

import 'package:provider/provider.dart';

class PdfService {
  static final _dateFormat = DateFormat(ConstantsString.dateFormat);
  static final _firestoreService = FirestoreService();

  static void _handleError(BuildContext context, String error, String type) {
    final errorMessage = error.contains('User not authenticated')
        ? 'Please sign in to generate PDF'
        : error.contains('timeout')
            ? 'Request timed out. Check your connection.'
            : error.contains('sharing not supported')
                ? 'Sharing unavailable on this device'
                : error.split(':').last.trim();
    debugPrint('Error in $type PDF: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type PDF failed: $errorMessage')),
    );
  }

  static Future<List<Booking>> _fetchBookings(BuildContext context) async {
    final bookingViewModel = context.read<BookingViewModel>();
    final userEmail = bookingViewModel.user?.email;
    final startDate = bookingViewModel.filterStartDate;
    final endDate = bookingViewModel.filterEndDate;
    if (userEmail == null) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('Fetching bookings for PDF with date range: ${startDate?.toIso8601String()} to ${endDate?.toIso8601String()}');
      // Bookings from stream are already filtered by BookingViewModel
      final bookings = await bookingViewModel.bookings.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () async {
          debugPrint('Stream timed out, using fetchBookingsOnce');
          return await _firestoreService.fetchBookingsOnce(
            userEmail,
            startDate: startDate,
            endDate: endDate,
          );
        },
      );
      // Ensure sorting by date ascending
      return bookings.isEmpty ? [] : bookings..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('Booking fetch error: $e');
      final bookings = await _firestoreService.fetchBookingsOnce(
        userEmail,
        startDate: startDate,
        endDate: endDate,
      );
      // Ensure sorting by date ascending
      return bookings.isEmpty ? [] : bookings..sort((a, b) => a.date.compareTo(b.date));
    }
  }

  static Future<List<Expenses>> _fetchExpenses(BuildContext context) async {
    final bookingViewModel = context.read<BookingViewModel>();
    final userEmail = bookingViewModel.user?.email;
    if (userEmail == null) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('Fetching expenses for PDF...');
      final expenses = await context.read<ExpensesViewModel>().expenses.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () async {
          debugPrint('Stream timed out, using fetchExpensesOnce');
          return await _firestoreService.getExpenses(userEmail: userEmail).first;
        },
      );
      return expenses.isEmpty ? [] : expenses;
    } catch (e) {
      debugPrint('Expenses fetch error: $e');
      final expenses = await _firestoreService.getExpenses(userEmail: userEmail).first;
      return expenses.isEmpty ? [] : expenses;
    }
  }

  static Future<void> generateBookingsPdf(BuildContext context) async {
    final bookingViewModel = context.read<BookingViewModel>();
    final bookings = await _fetchBookings(context);

    if (bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bookings available in the selected date range')),
      );
      return;
    }

    try {
      final pdf = pw.Document();
      final startDate = bookingViewModel.filterStartDate ?? DateTime.now();
      final endDate = bookingViewModel.filterEndDate ?? DateTime.now();

      pdf.addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(32)),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Bookings Report', style: const pw.TextStyle(fontSize: 24)),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date Range: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}'),
                    pw.SizedBox(height: 4),
                    pw.Text('Generated Date: ${_dateFormat.format(DateTime.now())}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox( height: 20),
            pw.Text('Bookings:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey),
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FlexColumnWidth(),
                2: const pw.FlexColumnWidth(0.5),
                3: const pw.FixedColumnWidth(90),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.black),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Date',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Address',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Name',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Day/Night',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                ...bookings.map(
                  (booking) => pw.TableRow(
                    decoration: booking.dayNight ? const pw.BoxDecoration(color: PdfColors.blue50) : null,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_dateFormat.format(booking.date), style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(booking.location, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(booking.owner, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(booking.dayNight ? 'Yes' : 'No', style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Total Bookings: ${bookings.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Total Day&Night Bookings: ${bookings.where((booking) => booking.dayNight).length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      debugPrint('Attempting to share bookings PDF...');

      try {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'bookings_report.pdf',
          subject: 'Bookings Report for ${_dateFormat.format(startDate)} to ${_dateFormat.format(endDate)}',
        );
      } catch (shareError) {
        debugPrint('Share failed: $shareError');
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/bookings_report.pdf');
          await file.writeAsBytes(pdfBytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF saved locally at ${file.path}')),
          );
        } else {
          throw Exception('PDF sharing not supported: $shareError');
        }
      }
    } catch (e) {
      _handleError(context, e.toString(), 'Bookings');
    }
  }

  static Future<void> generateExpensesPdf(BuildContext context) async {
    final expenses = await _fetchExpenses(context);

    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses available to generate PDF')),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(32)),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Expenses Report', style: const pw.TextStyle(fontSize: 24)),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Generated Date: ${_dateFormat.format(DateTime.now())}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Expenses:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey),
              columnWidths: {
                0: const pw.FlexColumnWidth(),
                1: const pw.FixedColumnWidth(80),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.black),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Date',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Price',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                ...expenses.map(
                  (expense) {
                    final dateText = expense.toDate != null
                        ? '${_dateFormat.format(expense.fromDate)} to ${_dateFormat.format(expense.toDate!)}'
                        : _dateFormat.format(expense.fromDate);
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(dateText, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${expense.price} Rs', style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Total Expenses: ${expenses.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Total Amount: ${expenses.fold<double>(0, (sum, expense) => sum + expense.price)} Rs',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      debugPrint('Attempting to share expenses PDF...');

      try {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'expenses_report.pdf',
          subject: 'Expenses Report generated on ${_dateFormat.format(DateTime.now())}',
        );
      } catch (shareError) {
        debugPrint('Share failed: $shareError');
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/expenses_report.pdf');
          await file.writeAsBytes(pdfBytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF saved locally at ${file.path}')),
          );
        } else {
          throw Exception('PDF sharing not supported: $shareError');
        }
      }
    } catch (e) {
      _handleError(context, e.toString(), 'Expenses');
    }
  }
}