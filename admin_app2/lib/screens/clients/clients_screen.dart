import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/client.dart';
import '../../models/debt.dart';
import '../../providers/client_provider.dart';
import '../../providers/debt_provider.dart';

/// Mijozlar va nasiyalar boshqaruvi
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedClientId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients();
      context.read<DebtProvider>().loadDebts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _money(int v) =>
      NumberFormat('#,###', 'ru').format(v).replaceAll(',', ' ');

  List<Client> _filtered(List<Client> clients) {
    if (_query.trim().isEmpty) return clients;
    final q = _query.toLowerCase().trim();
    return clients.where((c) {
      final name = c.name.toLowerCase();
      final phone = (c.phone ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final clientProvider = context.watch<ClientProvider>();
    final debtProvider = context.watch<DebtProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(loc, debtProvider),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 900;
                final clients = _filtered(clientProvider.clients);
                final list = _buildClientList(loc, clientProvider, debtProvider, clients);
                final detail = _buildDetail(loc, clientProvider, debtProvider);

                if (narrow) {
                  return Column(
                    children: [
                      Expanded(flex: 2, child: list),
                      const SizedBox(height: 16),
                      Expanded(flex: 3, child: detail),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: list),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: detail),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== Header =====
  Widget _buildHeader(LocaleProvider loc, DebtProvider debtProvider) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            loc.t('clients.title'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 16, color: AppTheme.accentRed),
                const SizedBox(width: 6),
                Text(
                  '${loc.t('clients.outstanding')}: ${_money(debtProvider.totalOutstanding)} ${loc.t('common.sum')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentRed,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 240,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: loc.t('common.search'),
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _clientDialog(loc),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(loc.t('clients.new')),
          ),
        ],
      ),
    );
  }

  // ===== Mijozlar ro'yxati =====
  Widget _buildClientList(
    LocaleProvider loc,
    ClientProvider clientProvider,
    DebtProvider debtProvider,
    List<Client> clients,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('nav.clients'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: clientProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : clients.isEmpty
                    ? Center(
                        child: Text(
                          loc.t('common.empty'),
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: clients.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = clients[i];
                          final outstanding = c.id == null
                              ? 0
                              : debtProvider.outstandingByClient(c.id!);
                          final selected = c.id == _selectedClientId;
                          return Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.accentOrange.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onTap: () =>
                                  setState(() => _selectedClientId = c.id),
                              title: Text(
                                c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              subtitle: (c.phone != null && c.phone!.isNotEmpty)
                                  ? Text(
                                      c.phone!,
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary),
                                    )
                                  : null,
                              trailing: Text(
                                outstanding > 0
                                    ? '${_money(outstanding)} ${loc.t('common.sum')}'
                                    : loc.t('clients.noDebt'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: outstanding > 0
                                      ? AppTheme.accentRed
                                      : AppTheme.accentGreen,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ===== Tanlangan mijoz tafsiloti =====
  Widget _buildDetail(
    LocaleProvider loc,
    ClientProvider clientProvider,
    DebtProvider debtProvider,
  ) {
    Client? client;
    for (final c in clientProvider.clients) {
      if (c.id == _selectedClientId) {
        client = c;
        break;
      }
    }

    if (client == null) {
      return GlassCard(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_alt_rounded,
                  size: 64, color: AppTheme.accentOrange.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                loc.t('clients.title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mijozni tanlang',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final c = client;
    final debts = c.id == null ? <Debt>[] : debtProvider.byClient(c.id!);
    final outstanding =
        c.id == null ? 0 : debtProvider.outstandingByClient(c.id!);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mijoz sarlavhasi
          Row(
            children: [
              Expanded(
                child: Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: loc.t('common.edit'),
                onPressed: () => _clientDialog(loc, existing: c),
                icon: const Icon(Icons.edit, color: AppTheme.accentOrange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (c.phone != null && c.phone!.isNotEmpty)
            _infoLine(Icons.phone, c.phone!),
          if (c.address != null && c.address!.isNotEmpty)
            _infoLine(Icons.location_on_outlined, c.address!),
          if (c.note != null && c.note!.isNotEmpty)
            _infoLine(Icons.sticky_note_2_outlined, c.note!),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '${loc.t('clients.totalDebt')}: ',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                Text(
                  outstanding > 0
                      ? '${_money(outstanding)} ${loc.t('common.sum')}'
                      : loc.t('clients.noDebt'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: outstanding > 0
                        ? AppTheme.accentRed
                        : AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.t('clients.debts'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: debts.isEmpty
                ? Center(
                    child: Text(
                      loc.t('clients.noDebt'),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: debts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _debtCard(loc, debtProvider, debts[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _debtCard(LocaleProvider loc, DebtProvider debtProvider, Debt debt) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: debt.isOverdue
              ? AppTheme.accentRed.withOpacity(0.4)
              : Colors.white.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (debt.saleNumber != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${loc.t('debt.fromSale')} #${debt.saleNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (debt.isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.t('debt.overdue'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentRed,
                    ),
                  ),
                ),
              const Spacer(),
              if (debt.isPaid)
                const Icon(Icons.check_circle,
                    color: AppTheme.accentGreen, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _amountTile(loc.t('debt.amount'),
                    _money(debt.amount), AppTheme.textPrimary),
              ),
              Expanded(
                child: _amountTile(loc.t('debt.paid'),
                    _money(debt.paid), AppTheme.accentGreen),
              ),
              Expanded(
                child: _amountTile(loc.t('debt.remaining'),
                    _money(debt.remaining), AppTheme.accentRed),
              ),
            ],
          ),
          if (debt.dueDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${loc.t('debt.dueDate')}: ${DateFormat('dd.MM.yyyy').format(debt.dueDate!)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
          if (!debt.isPaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _payDialog(loc, debtProvider, debt),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(loc.t('debt.pay')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amountTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: color)),
      ],
    );
  }

  // ===== To'lov dialogi =====
  void _payDialog(LocaleProvider loc, DebtProvider debtProvider, Debt debt) {
    final controller = TextEditingController(text: debt.remaining.toString());
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(loc.t('debt.pay')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.t('debt.remaining')}: ${_money(debt.remaining)} ${loc.t('common.sum')}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.t('debt.amount'),
                suffixText: loc.t('common.sum'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(loc.t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              var amount = int.tryParse(controller.text) ?? 0;
              if (amount <= 0 || debt.id == null) return;
              if (amount > debt.remaining) amount = debt.remaining;
              await debtProvider.payDebt(debt.id!, amount);
              await debtProvider.loadDebts();
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: Text(loc.t('debt.pay')),
          ),
        ],
      ),
    );
  }

  // ===== Mijoz qo'shish / tahrirlash dialogi =====
  void _clientDialog(LocaleProvider loc, {Client? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final addressController =
        TextEditingController(text: existing?.address ?? '');
    final noteController = TextEditingController(text: existing?.note ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(existing == null
            ? loc.t('clients.new')
            : loc.t('common.edit')),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: loc.t('clients.name')),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '!' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: loc.t('clients.phone')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration:
                      InputDecoration(labelText: loc.t('clients.address')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: loc.t('common.note')),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(loc.t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final address = addressController.text.trim();
              final note = noteController.text.trim();
              final provider = context.read<ClientProvider>();

              if (existing == null) {
                await provider.addClient(Client(
                  name: name,
                  phone: phone.isEmpty ? null : phone,
                  address: address.isEmpty ? null : address,
                  note: note.isEmpty ? null : note,
                  createdAt: DateTime.now(),
                ));
              } else {
                await provider.updateClient(Client(
                  id: existing.id,
                  name: name,
                  phone: phone.isEmpty ? null : phone,
                  address: address.isEmpty ? null : address,
                  note: note.isEmpty ? null : note,
                  createdAt: existing.createdAt,
                ));
              }
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: Text(loc.t('common.save')),
          ),
        ],
      ),
    );
  }
}
