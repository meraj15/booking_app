import 'package:booking_app/constant/app_constant_string.dart';
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
    final errorMessage =
        error.contains('User not authenticated')
            ? 'Please sign in to generate PDF'
            : error.contains('timeout')
            ? 'Request timed out. Check your connection.'
            : error.contains('sharing not supported')
            ? 'Sharing unavailable on this device'
            : error.split(':').last.trim();
    debugPrint('Error in $type PDF: $error');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$type PDF failed: $errorMessage')));
  }

  static String buildDateRangeLabel(DateTime start, DateTime end) {
    final startMonth = DateFormat('MMMM').format(start);
    final endMonth = DateFormat('MMMM').format(end);

    if (start.year == end.year) {
      if (start.month == end.month) {
        return '$startMonth ${start.year}';
      } else {
        return '$startMonth - $endMonth ${start.year}';
      }
    } else {
      return '$startMonth ${start.year} - $endMonth ${end.year}';
    }
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
      debugPrint(
        'Fetching bookings for PDF with date range: ${startDate?.toIso8601String()} to ${endDate?.toIso8601String()}',
      );
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
      return bookings.isEmpty ? [] : bookings
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('Booking fetch error: $e');
      final bookings = await _firestoreService.fetchBookingsOnce(
        userEmail,
        startDate: startDate,
        endDate: endDate,
      );
      return bookings.isEmpty ? [] : bookings
        ..sort((a, b) => a.date.compareTo(b.date));
    }
  }

  static Future<List<Expenses>> _fetchExpenses(BuildContext context) async {
    final expensesViewModel = context.read<ExpensesViewModel>();
    final userEmail = expensesViewModel.userEmail;
    final startDate = expensesViewModel.filterStartDate;
    final endDate = expensesViewModel.filterEndDate;

    if (userEmail == null) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('Fetching expenses for PDF directly from Firestore...');
      final expenses =
          await FirestoreService()
              .getExpenses(
                userEmail: userEmail,
                startDate: startDate,
                endDate: endDate,
              )
              .first;

      debugPrint('Fetched ${expenses.length} expenses from Firestore');
      return expenses;
    } catch (e) {
      debugPrint('Expenses fetch error: $e');
      return [];
    }
  }

  static Future<void> generateBookingsPdf(
    BuildContext context, {
    String? selectedOrganizer,
  }) async {
    final bookingViewModel = context.read<BookingViewModel>();
    final allBookings = await _fetchBookings(context);
    final bookings =
        selectedOrganizer == null
            ? allBookings
            : allBookings
                .where((b) => b.organizer == selectedOrganizer)
                .toList();

    if (bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bookings available in the selected date range'),
        ),
      );
      return;
    }

    final startDate = bookingViewModel.filterStartDate ?? DateTime.now();
    final endDate = bookingViewModel.filterEndDate ?? DateTime.now();

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(32)),
          build:
              (context) => [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Bookings Report',
                    style: const pw.TextStyle(fontSize: 24),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Date Range: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Generated Date: ${_dateFormat.format(DateTime.now())}',
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Bookings:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(80),
                    1: const pw.FlexColumnWidth(),
                    2: const pw.FlexColumnWidth(0.5),
                    3: const pw.FixedColumnWidth(110),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Date', style: _headerTextStyle()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Address', style: _headerTextStyle()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Name', style: _headerTextStyle()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Type', style: _headerTextStyle()),
                        ),
                      ],
                    ),
                    ...bookings.map(
                      (booking) => pw.TableRow(
                        decoration:
                            booking.bookingType == "Day&Night"
                                ? const pw.BoxDecoration(
                                  color: PdfColors.blue50,
                                )
                                : booking.bookingType == "Day+HalfNight"
                                ? const pw.BoxDecoration(
                                  color: PdfColors.orange50,
                                )
                                : null,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              _dateFormat.format(booking.date),
                              style: _cellTextStyle(),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              booking.location,
                              style: _cellTextStyle(),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              booking.owner,
                              style: _cellTextStyle(),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              booking
                                  .bookingType, 
                              style: _cellTextStyle(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Total Day Bookings: ${bookings.where((b) => b.bookingType == ConstantsString.allowedBookingTypes[0]).length}',
                  style: _footerTextStyle(),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Total Day&Night Bookings: ${bookings.where((b) => b.bookingType == ConstantsString.allowedBookingTypes[1]).length}',
                  style: _footerTextStyle(),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Total Day+HalfNight Bookings: ${bookings.where((b) => b.bookingType == ConstantsString.allowedBookingTypes[2]).length}',
                  style: _footerTextStyle(),
                ),
              ],
        ),
      );

      final pdfBytes = await pdf.save();

      try {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename:
              '${buildDateRangeLabel(startDate, endDate)} Bookings Report.pdf',
          subject:
              'Bookings Report for ${buildDateRangeLabel(startDate, endDate)}',
        );
      } catch (shareError) {
        debugPrint('Share failed: $shareError');
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          final dir = await getTemporaryDirectory();
          final file = File(
            '${dir.path}/${buildDateRangeLabel(startDate, endDate)} Bookings Report.pdf',
          );
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

    final expensesViewModel = context.read<ExpensesViewModel>();
    final startDate = expensesViewModel.filterStartDate ?? DateTime.now();
    final endDate = expensesViewModel.filterEndDate ?? DateTime.now();

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(32)),
          build:
              (context) => [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Expenses Report',
                    style: const pw.TextStyle(fontSize: 24),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated Date: ${_dateFormat.format(DateTime.now())}',
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(),
                    1: const pw.FixedColumnWidth(80),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Date', style: _headerTextStyle()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Price', style: _headerTextStyle()),
                        ),
                      ],
                    ),
                    ...expenses.map((expense) {
                      final dateText =
                          expense.toDate != null
                              ? '${_dateFormat.format(expense.fromDate)} to ${_dateFormat.format(expense.toDate!)}'
                              : _dateFormat.format(expense.fromDate);
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(dateText, style: _cellTextStyle()),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '${expense.price} Rs',
                              style: _cellTextStyle(),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Total Expenses: ${expenses.length}',
                  style: _footerTextStyle(),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Total Amount: ${expenses.fold<double>(0, (sum, e) => sum + e.price)} Rs',
                  style: _footerTextStyle(),
                ),
              ],
        ),
      );

      final pdfBytes = await pdf.save();

      try {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename:
              '${buildDateRangeLabel(startDate, endDate)} Expenses Report.pdf',
          subject:
              'Expenses Report for ${buildDateRangeLabel(startDate, endDate)}',
        );
      } catch (shareError) {
        debugPrint('Share failed: $shareError');
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          final dir = await getTemporaryDirectory();
          final file = File(
            '${dir.path}/${buildDateRangeLabel(startDate, endDate)} Expenses Report.pdf',
          );
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

  static pw.TextStyle _headerTextStyle() => pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 12,
    color: PdfColors.white,
  );

  static pw.TextStyle _cellTextStyle() => const pw.TextStyle(fontSize: 10);

  static pw.TextStyle _footerTextStyle() =>
      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12);
}
