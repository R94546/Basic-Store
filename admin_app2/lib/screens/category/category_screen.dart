import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';

/// Kategoriyalarni boshqarish ekrani
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Kategoriyalar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddCategoryDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Yangi kategoriya'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Kategoriyalar ro'yxati
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (provider.categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'Kategoriyalar yo\'q',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: ReorderableListView.builder(
                    itemCount: provider.categories.length,
                    onReorder: (oldIndex, newIndex) {
                      // TODO: Tartibni o'zgartirish
                    },
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];
                      return _CategoryListItem(
                        key: ValueKey(category.id),
                        category: category,
                        onEdit: () => _showEditCategoryDialog(category),
                        onDelete: () => _confirmDelete(category),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        onSave: (name, icon) async {
          final provider = context.read<CategoryProvider>();
          final order = provider.categories.length + 1;
          
          await provider.addCategory(Category(
            name: name,
            icon: icon,
            order: order,
          ));
          
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        category: category,
        onSave: (name, icon) async {
          final provider = context.read<CategoryProvider>();
          
          await provider.updateCategory(
            category.id!,
            category.copyWith(name: name, icon: icon),
          );
          
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmDelete(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirish'),
        content: Text("\"${category.name}\" kategoriyasini o'chirasizmi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<CategoryProvider>();
              final success = await provider.deleteCategory(category.id!);
              
              if (mounted) {
                Navigator.pop(context);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu kategoriyada mahsulotlar bor!'),
                      backgroundColor: AppTheme.accentRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }
}

class _CategoryListItem extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryListItem({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          // Emoji/Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                category.icon ?? '📦',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Nomi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${category.productCount} ta mahsulot',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: AppTheme.textSecondary),
            tooltip: 'Tahrirlash',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: AppTheme.accentRed),
            tooltip: 'O\'chirish',
          ),
          
          // Drag handle
          const Icon(Icons.drag_handle, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final Category? category;
  final Future<void> Function(String name, String? icon) onSave;

  const _CategoryDialog({
    this.category,
    required this.onSave,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _selectedIcon;
  bool _isSaving = false;

  final List<String> _icons = [
    '👗', '👖', '🩱', '👚', '🥻', '🧥', '👔', '👕',
    '🏃', '👠', '👟', '👜', '🎒', '📦', '✨', '🌟',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? _icons.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        blur: 20,
        opacity: 0.95,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      isEditing ? 'Kategoriyani tahrirlash' : 'Yangi kategoriya',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Icon tanlash
                const Text(
                  'Icon:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _icons.map((icon) {
                    final isSelected = _selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.accentOrange.withOpacity(0.2)
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentOrange : AppTheme.glassBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                
                // Nom
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kategoriya nomi',
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomni kiriting';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Bekor'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isEditing ? 'Saqlash' : 'Qo\'shish'),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    await widget.onSave(_nameController.text.trim(), _selectedIcon);
    
    setState(() => _isSaving = false);
  }
}
