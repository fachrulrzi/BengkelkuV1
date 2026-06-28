import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../customer/models/order_model.dart';
import '../../customer/models/booking_model.dart';

class FinancePdfHelper {
  static Future<void> exportFinanceReport({
    required BuildContext context,
    required String bengkelName,
    required String bengkelAddress,
    required List<OrderModel> completedOrders,
    required List<BookingModel> completedBookings,
    required double overallRevenue,
    required double totalProductRevenue,
    required double totalServiceRevenue,
  }) async {
    try {
      debugPrint('[PDFExport] Generating PDF document for $bengkelName...');
      final pdf = pw.Document();
      final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
      final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());

      // Prepare table data
      final List<List<String>> tableData = [
        ['Tanggal', 'Jenis', 'Item / Layanan', 'Pelanggan', 'Jumlah', 'Status']
      ];

      // Combine transactions
      final List<Map<String, dynamic>> allTx = [];
      for (var o in completedOrders) {
        final itemsText = o.items.map((i) => i.sparepart?.name ?? 'Item').join(', ');
        allTx.add({
          'date': o.createdAt,
          'type': 'Sparepart',
          'title': itemsText.isNotEmpty ? itemsText : 'Pembelian Sparepart',
          'customer': o.recipientName ?? 'Pelanggan',
          'amount': o.totalPrice,
          'status': o.status,
        });
      }

      for (var b in completedBookings) {
        allTx.add({
          'date': b.bookingDate,
          'type': 'Servis',
          'title': b.serviceCategory,
          'customer': b.customerName ?? 'Pelanggan',
          'amount': (b.totalPrice ?? 0).toDouble(),
          'status': b.status,
        });
      }

      // Sort by date desc
      allTx.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      for (var tx in allTx) {
        final txDate = DateFormat('dd MMM yyyy, HH:mm').format(tx['date'] as DateTime);
        tableData.add([
          txDate,
          tx['type'] as String,
          tx['title'] as String,
          tx['customer'] as String,
          currencyFormat.format(tx['amount']),
          tx['status'] as String,
        ]);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        bengkelName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        bengkelAddress,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'LAPORAN KEUANGAN BENGKEL',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Tanggal Cetak: $dateStr',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Financial Summary Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blueGrey800,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'TOTAL PENDAPATAN',
                            style: const pw.TextStyle(color: PdfColors.grey200, fontSize: 8),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            currencyFormat.format(overallRevenue),
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PENDAPATAN SERVIS',
                            style: const pw.TextStyle(color: PdfColors.grey800, fontSize: 8),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            currencyFormat.format(totalServiceRevenue),
                            style: pw.TextStyle(
                              color: PdfColors.blueGrey800,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PENDAPATAN SPAREPART',
                            style: const pw.TextStyle(color: PdfColors.grey800, fontSize: 8),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            currencyFormat.format(totalProductRevenue),
                            style: pw.TextStyle(
                              color: PdfColors.blueGrey800,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Section Title
              pw.Text(
                'Rincian Transaksi Keuangan',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 10),

              // Table details
              pw.TableHelper.fromTextArray(
                headers: tableData[0],
                data: tableData.sublist(1),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              ),
            ];
          },
        ),
      );

      debugPrint('[PDFExport] Triggering Printing.layoutPdf...');
      final printResult = await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Keuangan_${bengkelName.replaceAll(' ', '_')}.pdf',
      );
      debugPrint('[PDFExport] Printing layout dialog displayed. Result: $printResult');
    } catch (e, stack) {
      debugPrint('[PDFExport] ERROR generating/exporting PDF: $e');
      debugPrint('[PDFExport] Stacktrace: $stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
