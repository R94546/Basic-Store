import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/theme/app_theme.dart';

/// Ko'p rasm tanlash va ko'rsatish uchun widget
class ImagePickerWidget extends StatefulWidget {
  final List<String> existingImages;
  final Function(List<PlatformFile>) onImagesSelected;
  final int maxImages;

  const ImagePickerWidget({
    super.key,
    this.existingImages = const [],
    required this.onImagesSelected,
    this.maxImages = 5,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  List<PlatformFile> _selectedFiles = [];

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result == null) return;

      final totalImages = widget.existingImages.length + _selectedFiles.length + result.files.length;
      if (totalImages > widget.maxImages) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maksimum ${widget.maxImages} ta rasm!'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }

      final remainingSlots = widget.maxImages - widget.existingImages.length - _selectedFiles.length;
      final filesToAdd = result.files.take(remainingSlots).toList();

      setState(() {
        _selectedFiles.addAll(filesToAdd);
      });

      widget.onImagesSelected(_selectedFiles);
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    widget.onImagesSelected(_selectedFiles);
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = widget.existingImages.length + _selectedFiles.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rasmlar ($totalCount/${widget.maxImages})',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextButton.icon(
              onPressed: totalCount < widget.maxImages ? _pickImages : null,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Qo\'shish'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Mavjud rasmlar
              ...widget.existingImages.asMap().entries.map((entry) {
                return _ImageTile(
                  child: CachedNetworkImage(
                    imageUrl: entry.value,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                  ),
                  onRemove: null, // Mavjud rasmlarni o'chirish alohida boshqariladi
                );
              }),
              
              // Yangi tanlangan rasmlar
              ..._selectedFiles.asMap().entries.map((entry) {
                return _ImageTile(
                  child: Image.memory(
                    entry.value.bytes!,
                    fit: BoxFit.cover,
                  ),
                  onRemove: () => _removeNewImage(entry.key),
                  isNew: true,
                );
              }),
              
              // Qo'shish tugmasi
              if (totalCount < widget.maxImages)
                _AddImageButton(onTap: _pickImages),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onRemove;
  final bool isNew;

  const _ImageTile({
    required this.child,
    this.onRemove,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew ? AppTheme.accentOrange : AppTheme.glassBorder,
          width: isNew ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (onRemove != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (isNew)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Yangi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.glassBorder,
            width: 2,
            style: BorderStyle.solid,
          ),
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Rasm qo\'shish',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
