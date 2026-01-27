import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/telegram_provider.dart';
import '../../providers/printer_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TelegramProvider>().loadSettings();
      context.read<PrinterProvider>().loadSettings();
    });
  }

  void _showTelegramSettings() {
    showDialog(
      context: context,
      builder: (context) => const _TelegramSettingsDialog(),
    );
  }

  void _showPrinterSettings() {
    showDialog(
      context: context,
      builder: (context) => const _PrinterSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: const Row(
              children: [
                Text(
                  'Sozlamalar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Settings Grid
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    children: [
                      _SettingsCard(
                        icon: Icons.store,
                        title: 'Do\'kon ma\'lumotlari',
                        subtitle: 'Nomi, manzil, telefon',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tez orada qo\'shiladi...')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Printer Settings
                      Consumer<PrinterProvider>(
                        builder: (context, printerProvider, _) {
                          return _SettingsCard(
                            icon: Icons.print,
                            title: 'Printer sozlamalari',
                            subtitle: printerProvider.isConfigured 
                                ? printerProvider.selectedPrinter!.name
                                : 'Sozlanmagan',
                            onTap: _showPrinterSettings,
                            trailing: printerProvider.isConfigured
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.accentGreen,
                                  )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<TelegramProvider>(
                        builder: (context, telegramProvider, _) {
                          return _SettingsCard(
                            icon: Icons.telegram,
                            title: 'Telegram bot',
                            subtitle: telegramProvider.isConfigured 
                                ? (telegramProvider.isEnabled ? 'Faol ✓' : 'O\'chirilgan')
                                : 'Sozlanmagan',
                            onTap: _showTelegramSettings,
                            trailing: telegramProvider.isConfigured
                                ? Icon(
                                    Icons.check_circle,
                                    color: telegramProvider.isEnabled 
                                        ? AppTheme.accentGreen 
                                        : AppTheme.textSecondary,
                                  )
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Right Column
                Expanded(
                  child: Column(
                    children: [
                      _SettingsCard(
                        icon: Icons.people,
                        title: 'Xodimlar',
                        subtitle: 'Foydalanuvchilar boshqaruvi',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tez orada qo\'shiladi...')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _SettingsCard(
                        icon: Icons.backup,
                        title: 'Zaxira nusxa',
                        subtitle: 'Ma\'lumotlarni eksport qilish',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tez orada qo\'shiladi...')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _SettingsCard(
                        icon: Icons.info,
                        title: 'Dastur haqida',
                        subtitle: 'Versiya: 1.0.0',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'Ayollar Kiyim Admin',
                            applicationVersion: '1.0.0',
                            applicationLegalese: '© 2026 Basic Store',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.accentOrange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Printer sozlamalari dialogi
class _PrinterSettingsDialog extends StatefulWidget {
  const _PrinterSettingsDialog();

  @override
  State<_PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends State<_PrinterSettingsDialog> {
  bool _isScanning = false;
  bool _isPrintingTest = false;

  @override
  void initState() {
    super.initState();
    _scanPrinters();
  }

  Future<void> _scanPrinters() async {
    setState(() => _isScanning = true);
    await context.read<PrinterProvider>().scanPrinters();
    setState(() => _isScanning = false);
  }

  Future<void> _printTestLabel() async {
    setState(() => _isPrintingTest = true);
    final success = await context.read<PrinterProvider>().printTestLabel();
    setState(() => _isPrintingTest = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Test yorlig\'i chop etildi!' 
              : 'Xato! Printer ulanishini tekshiring.'),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        blur: 20,
        opacity: 0.95,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.print,
                      color: AppTheme.accentOrange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Printer Sozlamalari',
                    style: TextStyle(
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
              
              const SizedBox(height: 20),
              
              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Xprinter XP-370B termal printer aniqlandi. Printerni USB orqali ulang va drayverini o\'rnating.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Printer List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mavjud printerlar:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: _isScanning ? null : _scanPrinters,
                    icon: _isScanning 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Yangilash'),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Consumer<PrinterProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (provider.availablePrinters.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: const Center(
                        child: Text(
                          'Printer topilmadi.\nUSB kabelini ulang va qayta skanerlang.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    );
                  }

                  return Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.availablePrinters.length,
                      itemBuilder: (context, index) {
                        final printer = provider.availablePrinters[index];
                        final isSelected = provider.selectedPrinter?.name == printer.name;
                        
                        return ListTile(
                          leading: Icon(
                            Icons.print,
                            color: isSelected ? AppTheme.accentOrange : AppTheme.textSecondary,
                          ),
                          title: Text(
                            printer.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            printer.isDefault ? 'Default printer' : '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppTheme.accentGreen)
                              : null,
                          onTap: () async {
                            await provider.selectPrinter(printer);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${printer.name} tanlandi'),
                                  backgroundColor: AppTheme.accentGreen,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Auto Print Options
              Consumer<PrinterProvider>(
                builder: (context, provider, _) {
                  return Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Chekni avtomatik chop etish'),
                        subtitle: const Text('Har bir sotuvdan keyin'),
                        value: provider.autoPrintReceipt,
                        onChanged: (v) => provider.setAutoPrintReceipt(v),
                        activeColor: AppTheme.accentOrange,
                      ),
                      SwitchListTile(
                        title: const Text('Yorliqni avtomatik chop etish'),
                        subtitle: const Text('Yangi mahsulot qo\'shganda'),
                        value: provider.autoPrintLabel,
                        onChanged: (v) => provider.setAutoPrintLabel(v),
                        activeColor: AppTheme.accentOrange,
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Test Button
              SizedBox(
                width: double.infinity,
                child: Consumer<PrinterProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton.icon(
                      onPressed: provider.isConfigured && !_isPrintingTest
                          ? _printTestLabel
                          : null,
                      icon: _isPrintingTest 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print),
                      label: const Text('Test yorlig\'i chop etish'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Telegram Bot sozlamalari dialogi
class _TelegramSettingsDialog extends StatefulWidget {
  const _TelegramSettingsDialog();

  @override
  State<_TelegramSettingsDialog> createState() => _TelegramSettingsDialogState();
}

class _TelegramSettingsDialogState extends State<_TelegramSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _botTokenController = TextEditingController();
  final _chatIdController = TextEditingController();
  
  bool _isEnabled = false;
  bool _orderNotifications = true;
  bool _stockAlerts = true;
  bool _dailyReports = false;
  bool _isSaving = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final provider = context.read<TelegramProvider>();
    _isEnabled = provider.isEnabled;
    _orderNotifications = provider.orderNotifications;
    _stockAlerts = provider.stockAlerts;
    _dailyReports = provider.dailyReports;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await context.read<TelegramProvider>().saveSettings(
        botToken: _botTokenController.text.trim(),
        chatId: _chatIdController.text.trim(),
        isEnabled: _isEnabled,
        orderNotifications: _orderNotifications,
        stockAlerts: _stockAlerts,
        dailyReports: _dailyReports,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telegram sozlamalari saqlandi!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xato: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  Future<void> _testConnection() async {
    if (_botTokenController.text.isEmpty || _chatIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avval token va chat ID kiriting'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    setState(() => _isTesting = true);

    await context.read<TelegramProvider>().saveSettings(
      botToken: _botTokenController.text.trim(),
      chatId: _chatIdController.text.trim(),
      isEnabled: true,
    );

    final success = await context.read<TelegramProvider>().sendTestMessage();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Test xabari yuborildi! Telegramni tekshiring.' 
              : 'Xato! Token yoki Chat ID noto\'g\'ri.'),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
    }

    setState(() => _isTesting = false);
  }

  @override
  void dispose() {
    _botTokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        blur: 20,
        opacity: 0.95,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 500,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0088CC).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.telegram,
                        color: Color(0xFF0088CC),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Telegram Bot Sozlamalari',
                      style: TextStyle(
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
                
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📌 Qanday sozlash:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('1. @BotFather ga /newbot yozing'),
                      Text('2. Bot nomini va username kiriting'),
                      Text('3. Olingan tokenni quyiga kiriting'),
                      Text('4. @userinfobot orqali Chat ID oling'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _botTokenController,
                  decoration: const InputDecoration(
                    labelText: 'Bot Token',
                    hintText: '123456:ABC-DEF1234ghIkl...',
                    prefixIcon: Icon(Icons.key),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Bot tokenini kiriting';
                    if (!value.contains(':')) return 'Token formati noto\'g\'ri';
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _chatIdController,
                  decoration: const InputDecoration(
                    labelText: 'Chat ID',
                    hintText: '-1001234567890',
                    prefixIcon: Icon(Icons.chat),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Chat ID kiriting';
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                SwitchListTile(
                  title: const Text('Xabarnomalar faol'),
                  value: _isEnabled,
                  onChanged: (v) => setState(() => _isEnabled = v),
                  activeColor: AppTheme.accentOrange,
                ),
                
                const Divider(),
                
                CheckboxListTile(
                  title: const Text('Yangi buyurtmalar'),
                  subtitle: const Text('Har bir buyurtmada xabar'),
                  value: _orderNotifications,
                  onChanged: (v) => setState(() => _orderNotifications = v ?? true),
                  activeColor: AppTheme.accentOrange,
                ),
                CheckboxListTile(
                  title: const Text('Stock Alert'),
                  subtitle: const Text('Mahsulot tugaganda'),
                  value: _stockAlerts,
                  onChanged: (v) => setState(() => _stockAlerts = v ?? true),
                  activeColor: AppTheme.accentOrange,
                ),
                CheckboxListTile(
                  title: const Text('Kunlik hisobot'),
                  subtitle: const Text('Har kuni savdo statistikasi'),
                  value: _dailyReports,
                  onChanged: (v) => setState(() => _dailyReports = v ?? false),
                  activeColor: AppTheme.accentOrange,
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: const Text('Test'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
                        icon: _isSaving 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: const Text('Saqlash'),
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
}
