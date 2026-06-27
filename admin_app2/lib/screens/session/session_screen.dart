import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cash_session.dart';
import '../../providers/session_provider.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadCurrentSession();
      context.read<SessionProvider>().loadHistory();
    });
  }

  String _money(int v) =>
      NumberFormat('#,###', 'ru').format(v).replaceAll(',', ' ');

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Consumer<SessionProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Text(loc.t('session.title'),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: provider.isOpen
                            ? AppTheme.accentGreen.withOpacity(0.15)
                            : AppTheme.textSecondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        provider.isOpen
                            ? loc.t('session.open.status')
                            : loc.t('session.closed.status'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: provider.isOpen
                              ? AppTheme.accentGreen
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: provider.isOpen
                    ? _buildOpenSession(loc, provider)
                    : _buildClosedState(loc, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===== Smena ochiq =====
  Widget _buildOpenSession(LocaleProvider loc, SessionProvider provider) {
    final s = provider.current!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chap — info + amallar
        Expanded(
          flex: 2,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(loc.t('session.openingCash'),
                          '${_money(s.openingCash)} ${loc.t('common.sum')}',
                          AppTheme.accentOrange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<int>(
                        future: provider.expectedCashNow(),
                        builder: (context, snap) => _infoTile(
                          loc.t('session.expected'),
                          '${_money(snap.data ?? 0)} ${loc.t('common.sum')}',
                          AppTheme.accentGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(loc.t('session.cashIn'),
                          '+${_money(s.movementsIn)}', AppTheme.accentGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoTile(loc.t('session.cashOut'),
                          '-${_money(s.movementsOut)}', AppTheme.accentRed),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Smena savdosi (to'lov turlari bo'yicha)
                FutureBuilder<SessionSummary>(
                  future: provider.sessionSummary(),
                  builder: (context, snap) {
                    final sum = snap.data ?? const SessionSummary();
                    return Row(
                      children: [
                        Expanded(
                          child: _infoTile(loc.t('session.cashSales'),
                              _money(sum.cashSales), AppTheme.accentGreen),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoTile(loc.t('session.cardSales'),
                              _money(sum.cardSales), AppTheme.accentOrange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoTile(loc.t('session.debtSales'),
                              _money(sum.debtSales), AppTheme.accentRed),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoTile(loc.t('session.salesCount'),
                              '${sum.salesCount}', AppTheme.textPrimary),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _movementDialog(loc, provider, 'in'),
                        icon: const Icon(Icons.add),
                        label: Text(loc.t('session.cashIn')),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _movementDialog(loc, provider, 'out'),
                        icon: const Icon(Icons.remove),
                        label: Text(loc.t('session.cashOut')),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentRed),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _closeDialog(loc, provider),
                    icon: const Icon(Icons.lock_outline),
                    label: Text(loc.t('session.close')),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Expanded(
                  child: s.movements.isEmpty
                      ? Center(
                          child: Text(loc.t('common.empty'),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary)))
                      : ListView(
                          children: s.movements.reversed
                              .map((m) => ListTile(
                                    dense: true,
                                    leading: Icon(
                                      m.isIn
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: m.isIn
                                          ? AppTheme.accentGreen
                                          : AppTheme.accentRed,
                                    ),
                                    title: Text(m.reason),
                                    trailing: Text(
                                      '${m.isIn ? '+' : '-'}${_money(m.amount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: m.isIn
                                            ? AppTheme.accentGreen
                                            : AppTheme.accentRed,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // O'ng — tarix
        Expanded(child: _buildHistory(loc, provider)),
      ],
    );
  }

  // ===== Smena yopiq — ochish =====
  Widget _buildClosedState(LocaleProvider loc, SessionProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: GlassCard(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.point_of_sale,
                      size: 64,
                      color: AppTheme.accentOrange.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(loc.t('session.closed.status'),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openDialog(loc, provider),
                    icon: const Icon(Icons.lock_open),
                    label: Text(loc.t('session.open')),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildHistory(loc, provider)),
      ],
    );
  }

  Widget _buildHistory(LocaleProvider loc, SessionProvider provider) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.t('nav.session') + ' — ' + loc.t('common.total'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Expanded(
            child: provider.history.isEmpty
                ? Center(
                    child: Text(loc.t('common.empty'),
                        style: const TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    itemCount: provider.history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final h = provider.history[i];
                      final diff = h.difference ?? 0;
                      return ListTile(
                        dense: true,
                        title: Text(
                          DateFormat('dd.MM.yyyy HH:mm').format(h.openedAt),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                        subtitle: Text(
                          h.isOpen
                              ? loc.t('session.open.status')
                              : '${loc.t('session.expected')}: ${_money(h.expectedCash ?? 0)} • ${loc.t('session.difference')}: ${_money(diff)}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        trailing: h.isOpen
                            ? null
                            : Icon(
                                diff == 0
                                    ? Icons.check_circle
                                    : Icons.warning_amber,
                                color: diff == 0
                                    ? AppTheme.accentGreen
                                    : AppTheme.accentRed,
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        ],
      ),
    );
  }

  // ===== Dialoglar =====
  void _openDialog(LocaleProvider loc, SessionProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(loc.t('session.open')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: InputDecoration(
            labelText: loc.t('session.openingCash'),
            suffixText: loc.t('common.sum'),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(loc.t('common.cancel'))),
          ElevatedButton(
            onPressed: () async {
              final cash = int.tryParse(controller.text) ?? 0;
              final ok = await provider.openSession(cash);
              if (ok) provider.loadHistory();
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: Text(loc.t('common.confirm')),
          ),
        ],
      ),
    );
  }

  void _movementDialog(
      LocaleProvider loc, SessionProvider provider, String type) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
            type == 'in' ? loc.t('session.cashIn') : loc.t('session.cashOut')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.t('common.price'),
                suffixText: loc.t('common.sum'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(labelText: loc.t('session.reason')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(loc.t('common.cancel'))),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              await provider.addMovement(
                  type, amount, reasonController.text.trim());
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: Text(loc.t('common.confirm')),
          ),
        ],
      ),
    );
  }

  void _closeDialog(LocaleProvider loc, SessionProvider provider) {
    showDialog<CashSession>(
      context: context,
      builder: (_) => _CloseSessionDialog(provider: provider),
    ).then((closed) {
      provider.loadHistory();
      if (closed != null && mounted) _showResult(loc, closed);
    });
  }

  void _showResult(LocaleProvider loc, CashSession s) {
    final diff = s.difference ?? 0;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(loc.t('session.closed.status')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resultRow(loc.t('session.expected'), _money(s.expectedCash ?? 0)),
            _resultRow(loc.t('session.closingCash'), _money(s.closingCash ?? 0)),
            const Divider(),
            _resultRow(loc.t('session.difference'), _money(diff),
                color: diff == 0
                    ? AppTheme.accentGreen
                    : AppTheme.accentRed),
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(loc.t('common.close'))),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

/// Smena yopish dialogi — kutilgan naqdni ko'rsatadi va sanagan summa
/// kiritilganda farqni JONLI hisoblaydi.
class _CloseSessionDialog extends StatefulWidget {
  final SessionProvider provider;
  const _CloseSessionDialog({required this.provider});

  @override
  State<_CloseSessionDialog> createState() => _CloseSessionDialogState();
}

class _CloseSessionDialogState extends State<_CloseSessionDialog> {
  final _ctrl = TextEditingController();
  int? _expected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.provider.expectedCashNow().then((v) {
      if (mounted) setState(() => _expected = v);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _money(int v) =>
      NumberFormat('#,###', 'ru').format(v).replaceAll(',', ' ');

  @override
  Widget build(BuildContext context) {
    final loc = context.read<LocaleProvider>();
    final counted = int.tryParse(_ctrl.text) ?? 0;
    final diff = _expected == null ? null : counted - _expected!;
    return AlertDialog(
      title: Text(loc.t('session.close')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.t('session.expected'),
                  style: const TextStyle(color: AppTheme.textSecondary)),
              Text(
                _expected == null
                    ? '...'
                    : '${_money(_expected!)} ${loc.t('common.sum')}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: loc.t('session.closingCash'),
              suffixText: loc.t('common.sum'),
            ),
          ),
          if (diff != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.t('session.difference'),
                      style: const TextStyle(color: AppTheme.textSecondary)),
                  Text(
                    '${_money(diff)} ${loc.t('common.sum')}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: diff == 0
                            ? AppTheme.accentGreen
                            : AppTheme.accentRed),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('common.cancel'))),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  final closed = await widget.provider.closeSession(counted);
                  if (context.mounted) Navigator.pop(context, closed);
                },
          child: Text(loc.t('common.confirm')),
        ),
      ],
    );
  }
}
