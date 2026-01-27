import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Termal printer xizmati - Xprinter XP-370B uchun
class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  Printer? _selectedPrinter;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Printer? get selectedPrinter => _selectedPrinter;

  /// Mavjud printerlarni olish
  Future<List<Printer>> getAvailablePrinters() async {
    try {
      final printers = await Printing.listPrinters();
      return printers;
    } catch (e) {
      debugPrint('Error listing printers: $e');
      return [];
    }
  }

  /// Printerni tanlash
  Future<void> selectPrinter(Printer printer) async {
    _selectedPrinter = printer;
    _isInitialized = true;
    debugPrint('Printer selected: ${printer.name}');
  }

  /// ========== BARCODE LABEL CHOP ETISH ==========
  /// Mahsulot yorlig'i (40x30mm yoki shunga o'xshash)
  Future<bool> printProductLabel({
    required String productName,
    required String barcode,
    required String price,
    required String size,
    String? color,
    int copies = 1,
  }) async {
    if (_selectedPrinter == null) {
      debugPrint('No printer selected');
      return false;
    }

    try {
      final pdf = pw.Document();

      // Label o'lchami: 50mm x 30mm (kichik yorliq)
      const labelWidth = 50.0 * PdfPageFormat.mm;
      const labelHeight = 30.0 * PdfPageFormat.mm;

      for (int i = 0; i < copies; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: const PdfPageFormat(labelWidth, labelHeight, marginAll: 2 * PdfPageFormat.mm),
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Mahsulot nomi
                  pw.Text(
                    productName,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                  pw.SizedBox(height: 2),
                  // Razmer va rang
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('$size', style: const pw.TextStyle(fontSize: 7)),
                      if (color != null) ...[
                        pw.Text(' | ', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text(color, style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  // Shtrix kod
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.ean13(),
                    data: _padBarcode(barcode),
                    width: 40 * PdfPageFormat.mm,
                    height: 10 * PdfPageFormat.mm,
                    drawText: true,
                    textStyle: const pw.TextStyle(fontSize: 6),
                  ),
                  pw.SizedBox(height: 2),
                  // Narx
                  pw.Text(
                    '$price so\'m',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      final bytes = await pdf.save();
      
      await Printing.directPrintPdf(
        printer: _selectedPrinter!,
        onLayout: (_) => bytes,
      );

      return true;
    } catch (e) {
      debugPrint('Error printing label: $e');
      return false;
    }
  }

  /// ========== KASSA CHEKI CHOP ETISH ==========
  /// 80mm kenglikdagi chek
  Future<bool> printReceipt({
    required String shopName,
    required String orderNumber,
    required List<ReceiptItem> items,
    required int subtotal,
    int discount = 0,
    required int total,
    String? cashierName,
    String? customerPhone,
    String paymentMethod = 'Naqd',
  }) async {
    if (_selectedPrinter == null) {
      debugPrint('No printer selected');
      return false;
    }

    try {
      final pdf = pw.Document();

      // Receipt width: 80mm
      const receiptWidth = 80.0 * PdfPageFormat.mm;
      // Height - dynamic based on content
      final itemCount = items.length;
      final receiptHeight = (150 + (itemCount * 15)).toDouble() * PdfPageFormat.mm / 10;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(receiptWidth, receiptHeight, marginAll: 3 * PdfPageFormat.mm),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Do'kon nomi
                pw.Text(
                  shopName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Tel: +998 XX XXX XX XX',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Divider(thickness: 0.5),
                
                // Buyurtma raqami va sana
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Chek: #$orderNumber', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(
                      DateTime.now().toString().substring(0, 16),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
                if (cashierName != null)
                  pw.Row(
                    children: [
                      pw.Text('Kassir: $cashierName', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5),
                
                // Mahsulotlar jadvali
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      children: [
                        pw.Text('Tovar', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Soni', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Summa', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ],
                    ),
                    // Items
                    ...items.map((item) => pw.TableRow(
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.name, style: const pw.TextStyle(fontSize: 8), maxLines: 1),
                            if (item.size != null || item.color != null)
                              pw.Text(
                                '${item.size ?? ""} ${item.color ?? ""}'.trim(),
                                style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                              ),
                          ],
                        ),
                        pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(
                          '${item.price * item.quantity}',
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ],
                    )),
                  ],
                ),
                
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5),
                
                // Jami
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Jami:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('$subtotal so\'m', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                if (discount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Chegirma:', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('-$discount so\'m', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ITOGO:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('$total so\'m', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5),
                
                // To'lov usuli
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('To\'lov:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(paymentMethod, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                
                pw.SizedBox(height: 8),
                
                // Footer
                pw.Text(
                  'Xaridingiz uchun rahmat!',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'www.ayollar-kiyim.uz',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      
      await Printing.directPrintPdf(
        printer: _selectedPrinter!,
        onLayout: (_) => bytes,
      );

      return true;
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      return false;
    }
  }

  /// Preview ko'rsatish (test uchun)
  Future<void> showPreview(BuildContext context, Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  /// EAN-13 uchun barcode ni 12 raqamga to'ldirish
  String _padBarcode(String barcode) {
    // EAN-13 requires exactly 12 digits (13th is checksum)
    String digits = barcode.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 12) {
      digits = digits.padLeft(12, '0');
    } else if (digits.length > 12) {
      digits = digits.substring(0, 12);
    }
    return digits;
  }
}

/// Chek elementi
class ReceiptItem {
  final String name;
  final int quantity;
  final int price;
  final String? size;
  final String? color;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.size,
    this.color,
  });
}
