import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

/// Rasm yuklash servisi - Firebase Storage
class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Bir nechta rasm tanlash (Web uchun)
  Future<List<PlatformFile>> pickImages({int maxImages = 5}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // Web uchun kerak
      );

      if (result == null) return [];

      // Max rasm sonini cheklash
      final files = result.files.take(maxImages).toList();
      return files;
    } catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }

  /// Rasmni Firebase Storage ga yuklash
  Future<String?> uploadImage({
    required Uint8List imageBytes,
    required String productId,
    required String fileName,
  }) async {
    try {
      // Unique fayl nomi
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last.toLowerCase();
      final storagePath = 'products/$productId/${timestamp}_$fileName';

      final ref = _storage.ref().child(storagePath);
      
      // Content type
      String contentType = 'image/jpeg';
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      }

      // Yuklash
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: contentType),
      );

      // Progress tracking
      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Ko'p rasmlarni yuklash
  Future<List<String>> uploadMultipleImages({
    required List<PlatformFile> files,
    required String productId,
  }) async {
    final urls = <String>[];

    for (final file in files) {
      if (file.bytes != null) {
        final url = await uploadImage(
          imageBytes: file.bytes!,
          productId: productId,
          fileName: file.name,
        );
        if (url != null) {
          urls.add(url);
        }
      }
    }

    return urls;
  }

  /// Rasmni o'chirish
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  /// Mahsulotning barcha rasmlarini o'chirish
  Future<void> deleteAllProductImages(String productId) async {
    try {
      final ref = _storage.ref().child('products/$productId');
      final result = await ref.listAll();
      
      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('Error deleting product images: $e');
    }
  }
}
