import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/category_icons.dart';
import '../../core/l10n/locale_provider.dart';
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
    final loc = context.watch<LocaleProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                loc.t('nav.categories'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddCategoryDialog,
                icon: const Icon(Icons.add),
                label: Text(loc.t('common.add')),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                        Icon(Icons.category,
                            size: 64,
                            color: AppTheme.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(loc.t('common.empty'),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: provider.categories.length,
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];
                      return _CategoryListItem(
                        key: ValueKey(category.id),
                        category: category,
                        loc: loc,
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
      builder: (dialogCtx) => _CategoryDialog(
        onSave: (name, icon) async {
          final provider = dialogCtx.read<CategoryProvider>();
          final order = provider.categories.length + 1;
          await provider.addCategory(
              ProductCategory(name: name, icon: icon, order: order));
          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
        },
      ),
    );
  }

  void _showEditCategoryDialog(ProductCategory category) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _CategoryDialog(
        category: category,
        onSave: (name, icon) async {
          final provider = dialogCtx.read<CategoryProvider>();
          await provider.updateCategory(
              category.id!, category.copyWith(name: name, icon: icon));
          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
        },
      ),
    );
  }

  void _confirmDelete(ProductCategory category) {
    final loc = context.read<LocaleProvider>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(loc.t('common.delete')),
        content: Text('"${category.name}" — ${loc.t('common.delete')}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(loc.t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = dialogCtx.read<CategoryProvider>();
              final success = await provider.deleteCategory(category.id!);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.isUz
                        ? 'Bu kategoriyada mahsulotlar bor!'
                        : 'В этой категории есть товары!'),
                    backgroundColor: AppTheme.accentRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: Text(loc.t('common.delete')),
          ),
        ],
      ),
    );
  }
}

class _CategoryListItem extends StatelessWidget {
  final ProductCategory category;
  final LocaleProvider loc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryListItem({
    super.key,
    required this.category,
    required this.loc,
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(CategoryIcons.iconFor(category.icon),
                color: AppTheme.accentOrange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.textPrimary),
                ),
                Text(
                  '${category.productCount} ${loc.t('common.qty').toLowerCase()}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: AppTheme.textSecondary),
            tooltip: loc.t('common.edit'),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: AppTheme.accentRed),
            tooltip: loc.t('common.delete'),
          ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final ProductCategory? category;
  final Future<void> Function(String name, String? icon) onSave;

  const _CategoryDialog({this.category, required this.onSave});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedIcon;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    final existing = widget.category?.icon;
    _selectedIcon = (existing != null && CategoryIcons.keys.contains(existing))
        ? existing
        : 'clothes';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final isEditing = widget.category != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        blur: 20,
        opacity: 0.95,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isEditing ? loc.t('common.edit') : loc.t('common.add'),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.t('common.name'),
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? loc.t('common.error')
                          : null,
                ),
                const SizedBox(height: 20),
                Text('${loc.t('product.image')} / ${loc.t('common.category')}:',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: CategoryIcons.keys.map((key) {
                        final isSelected = _selectedIcon == key;
                        return InkWell(
                          onTap: () => setState(() {
                            _selectedIcon = key;
                            // Nom bo'sh bo'lsa, tanlangan ikonka nomini taklif qil
                            if (_nameController.text.trim().isEmpty) {
                              _nameController.text =
                                  CategoryIcons.label(key, loc.lang);
                            }
                          }),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 64,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accentOrange.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accentOrange
                                    : AppTheme.glassBorder,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(CategoryIcons.iconFor(key),
                                    color: isSelected
                                        ? AppTheme.accentOrange
                                        : AppTheme.textSecondary),
                                const SizedBox(height: 4),
                                Text(
                                  CategoryIcons.label(key, loc.lang),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc.t('common.cancel')),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(loc.t('common.save')),
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
    if (mounted) setState(() => _isSaving = false);
  }
}
