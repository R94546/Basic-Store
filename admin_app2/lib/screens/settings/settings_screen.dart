import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/telegram_provider.dart';
import '../../providers/printer_provider.dart';
import '../../providers/auth_provider.dart';

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

  void _showLanguageDialog() {
    final loc = context.read<LocaleProvider>();
    showDialog(
      context: context,
      builder: (dialogCtx) => SimpleDialog(
        title: Text(loc.t('settings.language')),
        children: [
          RadioListTile<String>(
            value: 'uz',
            groupValue: loc.lang,
            title: const Text("O'zbekcha"),
            activeColor: AppTheme.accentOrange,
            onChanged: (v) {
              loc.setLang('uz');
              Navigator.pop(dialogCtx);
            },
          ),
          RadioListTile<String>(
            value: 'ru',
            groupValue: loc.lang,
            title: const Text('Русский'),
            activeColor: AppTheme.accentOrange,
            onChanged: (v) {
              loc.setLang('ru');
              Navigator.pop(dialogCtx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(
                  loc.t('nav.settings'),
                  style: const TextStyle(
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
                        icon: Icons.language,
                        title: loc.t('settings.language'),
                        subtitle: loc.isUz ? "O'zbekcha" : 'Русский',
                        onTap: _showLanguageDialog,
                        trailing: Text(
                          loc.lang.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SettingsCard(
                        icon: Icons.store,
                        title: loc.t('settings.store'),
                        subtitle: loc.t('settings.storeSubtitle'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.t('settings.comingSoon'))),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Printer Settings
                      Consumer<PrinterProvider>(
                        builder: (context, printerProvider, _) {
                          return _SettingsCard(
                            icon: Icons.print,
                            title: loc.t('settings.printerSettings'),
                            subtitle: printerProvider.isConfigured
                                ? printerProvider.selectedPrinter!.name
                                : loc.t('settings.notConfigured'),
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
                            title: loc.t('settings.telegramBot'),
                            subtitle: telegramProvider.isConfigured
                                ? (telegramProvider.isEnabled
                                    ? loc.t('settings.active')
                                    : loc.t('settings.disabled'))
                                : loc.t('settings.notConfigured'),
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
                        title: loc.t('settings.staff'),
                        subtitle: loc.t('settings.staffSubtitle'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.t('settings.comingSoon'))),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _SettingsCard(
                        icon: Icons.backup,
                        title: loc.t('settings.backup'),
                        subtitle: loc.t('settings.backupSubtitle'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.t('settings.comingSoon'))),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _SettingsCard(
                        icon: Icons.info,
                        title: loc.t('settings.about'),
                        subtitle: '${loc.t('settings.version')}: 1.0.0',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'Ayollar Kiyim Admin',
                            applicationVersion: '1.0.0',
                            applicationLegalese: '© 2026 Basic Store',
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _SettingsCard(
                        icon: Icons.logout,
                        title: loc.t('auth.logout'),
                        subtitle: context
                                .watch<AuthProvider>()
                                .currentUser
                                ?.email ??
                            '',
                        color: AppTheme.accentRed,
                        onTap: () {
                          context.read<AuthProvider>().signOut();
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
  final Color? color;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.accentOrange;
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: accent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color ?? AppTheme.textPrimary,
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
    final loc = context.read<LocaleProvider>();
    setState(() => _isPrintingTest = true);
    final success = await context.read<PrinterProvider>().printTestLabel();
    setState(() => _isPrintingTest = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? loc.t('printer.testPrinted')
              : loc.t('printer.testError')),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        blur: 20,
        opacity: 0.95,
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SizedBox(
          width: 500,
          child: SingleChildScrollView(
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
                  Text(
                    loc.t('printer.title'),
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
              
              const SizedBox(height: 20),
              
              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.t('printer.info'),
                        style: const TextStyle(fontSize: 13),
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
                  Text(
                    loc.t('printer.available'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
                    label: Text(loc.t('printer.refresh')),
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
                      child: Center(
                        child: Text(
                          loc.t('printer.notFound'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary),
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
                            printer.isDefault ? loc.t('printer.default') : '',
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
                                  content: Text('${printer.name} ${loc.t('printer.selected')}'),
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
                        title: Text(loc.t('printer.autoReceipt')),
                        subtitle: Text(loc.t('printer.autoReceiptDesc')),
                        value: provider.autoPrintReceipt,
                        onChanged: (v) => provider.setAutoPrintReceipt(v),
                        activeColor: AppTheme.accentOrange,
                      ),
                      SwitchListTile(
                        title: Text(loc.t('printer.autoLabel')),
                        subtitle: Text(loc.t('printer.autoLabelDesc')),
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
                      label: Text(loc.t('printer.testLabel')),
                    );
                  },
                ),
              ),
            ],
          ),
          ),
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
    final loc = context.read<LocaleProvider>();

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
          SnackBar(
            content: Text(loc.t('telegram.saved')),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.t('common.error')}: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  Future<void> _testConnection() async {
    final loc = context.read<LocaleProvider>();
    if (_botTokenController.text.isEmpty || _chatIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('telegram.enterFirst')),
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
              ? loc.t('telegram.testSent')
              : loc.t('telegram.testError')),
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
    final loc = context.watch<LocaleProvider>();
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        blur: 20,
        opacity: 0.95,
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SizedBox(
          width: 500,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                    Text(
                      loc.t('telegram.title'),
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
                
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.t('telegram.howTo'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(loc.t('telegram.step1')),
                      Text(loc.t('telegram.step2')),
                      Text(loc.t('telegram.step3')),
                      Text(loc.t('telegram.step4')),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _botTokenController,
                  decoration: InputDecoration(
                    labelText: loc.t('telegram.botToken'),
                    hintText: '123456:ABC-DEF1234ghIkl...',
                    prefixIcon: const Icon(Icons.key),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return loc.t('telegram.enterToken');
                    if (!value.contains(':')) return loc.t('telegram.tokenFormat');
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
                    if (value == null || value.isEmpty) return loc.t('telegram.enterChatId');
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                SwitchListTile(
                  title: Text(loc.t('telegram.notifyEnabled')),
                  value: _isEnabled,
                  onChanged: (v) => setState(() => _isEnabled = v),
                  activeColor: AppTheme.accentOrange,
                ),

                const Divider(),

                CheckboxListTile(
                  title: Text(loc.t('telegram.newOrders')),
                  subtitle: Text(loc.t('telegram.newOrdersDesc')),
                  value: _orderNotifications,
                  onChanged: (v) => setState(() => _orderNotifications = v ?? true),
                  activeColor: AppTheme.accentOrange,
                ),
                CheckboxListTile(
                  title: Text(loc.t('telegram.stockAlert')),
                  subtitle: Text(loc.t('telegram.stockAlertDesc')),
                  value: _stockAlerts,
                  onChanged: (v) => setState(() => _stockAlerts = v ?? true),
                  activeColor: AppTheme.accentOrange,
                ),
                CheckboxListTile(
                  title: Text(loc.t('telegram.dailyReport')),
                  subtitle: Text(loc.t('telegram.dailyReportDesc')),
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
                        label: Text(loc.t('telegram.test')),
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
                        label: Text(loc.t('common.save')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
