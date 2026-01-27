import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../widgets/image_picker_widget.dart';
import '../../services/image_upload_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _imageUploadService = ImageUploadService();
  
  String _selectedCategory = 'Ko\'ylak';
  String _selectedSize = 'M';
  String _generatedBarcode = '';
  bool _isSaving = false;
  
  // Image upload
  List<PlatformFile> _selectedImages = [];

  final List<String> categories = [
    'Ko\'ylak',
    'Shim',
    'Yubka',
    'Bluzka',
    'Ko\'stum',
    'Palto',
    'Kurtka',
    'Sport',
    'Boshqa',
  ];

  final List<String> sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];

  @override
  void initState() {
    super.initState();
    _generateBarcode();
  }

  void _generateBarcode() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    final randomPart = random.nextInt(9999).toString().padLeft(4, '0');
    _generatedBarcode = '890$timestamp$randomPart'.substring(0, 13);
    setState(() {});
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Temp product ID for image upload
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Upload images first
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _imageUploadService.uploadMultipleImages(
          files: _selectedImages,
          productId: tempId,
        );
      }

      final product = Product(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        size: _selectedSize,
        price: int.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        barcode: _generatedBarcode,
        images: imageUrls,  // Uploaded image URLs
      );

      await context.read<ProductProvider>().addProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} saqlandi!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _nameController.clear();
        _priceController.clear();
        _quantityController.clear();
        _selectedImages = [];
        _generateBarcode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sklad - Tovar Qo\'shish'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Widget
              ImagePickerWidget(
                onImagesSelected: (files) {
                  setState(() => _selectedImages = files);
                },
                maxImages: 5,
              ),
              
              const SizedBox(height: 24),

              // Barcode display
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Shtrix Kod',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _generatedBarcode,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _generateBarcode,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yangilash'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tovar nomi',
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tovar nomini kiriting';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategoriya',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),

              const SizedBox(height: 16),

              // Size
              DropdownButtonFormField<String>(
                value: _selectedSize,
                decoration: const InputDecoration(
                  labelText: 'Razmer',
                  prefixIcon: Icon(Icons.straighten),
                ),
                items: sizes.map((size) {
                  return DropdownMenuItem(value: size, child: Text(size));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSize = value!);
                },
              ),

              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Narxi (so\'m)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Narxni kiriting';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Soni (dona)',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Sonini kiriting';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Save button
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveProduct,
                icon: _isSaving 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saqlanmoqda...' : 'Saqlash'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
