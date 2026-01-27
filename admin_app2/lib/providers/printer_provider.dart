import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/printer_service.dart';

/// Printer sozlamalari va holati uchun provider
class PrinterProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PrinterService _printerService = PrinterService();

  List<Printer> _availablePrinters = [];
  Printer? _selectedPrinter;
  bool _isLoading = false;
  bool _autoPrintReceipt = true;
  bool _autoPrintLabel = false;

  List<Printer> get availablePrinters => _availablePrinters;
  Printer? get selectedPrinter => _selectedPrinter;
  bool get isLoading => _isLoading;
  bool get isConfigured => _selectedPrinter != null;
  bool get autoPrintReceipt => _autoPrintReceipt;
  bool get autoPrintLabel => _autoPrintLabel;
  PrinterService get service => _printerService;

  /// Mavjud printerlarni skanerlash
  Future<void> scanPrinters() async {
    _isLoading = true;
    notifyListeners();

    try {
      _availablePrinters = await _printerService.getAvailablePrinters();
      debugPrint('Found ${_availablePrinters.length} printers');
    } catch (e) {
      debugPrint('Error scanning printers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Printerni tanlash
  Future<void> selectPrinter(Printer printer) async {
    _selectedPrinter = printer;
    await _printerService.selectPrinter(printer);
    await _saveSettings();
    notifyListeners();
  }

  /// Sozlamalarni yuklash
  Future<void> loadSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('printer').get();
      
      if (doc.exists) {
        final data = doc.data()!;
        _autoPrintReceipt = data['autoPrintReceipt'] ?? true;
        _autoPrintLabel = data['autoPrintLabel'] ?? false;
        
        final savedPrinterName = data['printerName'] as String?;
        if (savedPrinterName != null) {
          await scanPrinters();
          // Saqlangan printerni topish
          final matchingPrinter = _availablePrinters.where(
            (p) => p.name == savedPrinterName
          ).firstOrNull;
          
          if (matchingPrinter != null) {
            await selectPrinter(matchingPrinter);
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading printer settings: $e');
    }
  }

  /// Sozlamalarni saqlash
  Future<void> _saveSettings() async {
    try {
      await _firestore.collection('settings').doc('printer').set({
        'printerName': _selectedPrinter?.name,
        'autoPrintReceipt': _autoPrintReceipt,
        'autoPrintLabel': _autoPrintLabel,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving printer settings: $e');
    }
  }

  /// Auto print sozlamalarini o'zgartirish
  Future<void> setAutoPrintReceipt(bool value) async {
    _autoPrintReceipt = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setAutoPrintLabel(bool value) async {
    _autoPrintLabel = value;
    await _saveSettings();
    notifyListeners();
  }

  /// Chek chop etish
  Future<bool> printReceipt({
    required String shopName,
    required String orderNumber,
    required List<ReceiptItem> items,
    required int subtotal,
    int discount = 0,
    required int total,
    String? cashierName,
    String paymentMethod = 'Naqd',
  }) async {
    if (_selectedPrinter == null) {
      debugPrint('Printer not selected');
      return false;
    }

    return _printerService.printReceipt(
      shopName: shopName,
      orderNumber: orderNumber,
      items: items,
      subtotal: subtotal,
      discount: discount,
      total: total,
      cashierName: cashierName,
      paymentMethod: paymentMethod,
    );
  }

  /// Mahsulot yorlig'i chop etish
  Future<bool> printProductLabel({
    required String productName,
    required String barcode,
    required String price,
    required String size,
    String? color,
    int copies = 1,
  }) async {
    if (_selectedPrinter == null) {
      debugPrint('Printer not selected');
      return false;
    }

    return _printerService.printProductLabel(
      productName: productName,
      barcode: barcode,
      price: price,
      size: size,
      color: color,
      copies: copies,
    );
  }

  /// Test chop etish
  Future<bool> printTestLabel() async {
    return printProductLabel(
      productName: 'Test Mahsulot',
      barcode: '890123456789',
      price: '150000',
      size: 'M',
      color: 'Qora',
    );
  }
}
