import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity_log.dart';

/// Jurnal (admin amallari logi) — kim, qachon, nima qildi.
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _entity = '';

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final isUz = loc.isUz;
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
                const Icon(Icons.history_edu_rounded,
                    color: AppTheme.accentOrange),
                const SizedBox(width: 12),
                Text(loc.t('nav.logs'),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Entity filtrlari
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kLogEntities.map((e) {
                  final selected = _entity == e.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(isUz ? e.$2 : e.$3),
                      selected: selected,
                      onSelected: (_) => setState(() => _entity = e.$1),
                      selectedColor: AppTheme.accentOrange.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.accentOrange,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppTheme.accentOrange
                            : AppTheme.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GlassCard(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('activity_logs')
                    .orderBy('createdAt', descending: true)
                    .limit(400)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('${loc.t('common.error')}',
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                    );
                  }
                  var logs = (snap.data?.docs ?? [])
                      .map((d) => ActivityLog.fromFirestore(d))
                      .toList();
                  if (_entity.isNotEmpty) {
                    logs = logs.where((l) => l.entity == _entity).toList();
                  }
                  if (logs.isEmpty) {
                    return Center(
                      child: Text(loc.t('common.empty'),
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                    );
                  }
                  return ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _tile(loc, isUz, logs[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(LocaleProvider loc, bool isUz, ActivityLog log) {
    final meta = kLogActions[log.action];
    final color = meta?.color ?? AppTheme.textSecondary;
    final label = meta == null
        ? log.action
        : (isUz ? meta.uz : meta.ru);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(meta?.icon ?? Icons.circle, color: color, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      subtitle: Text(
        '${log.details ?? ''}${log.details != null ? ' • ' : ''}${log.userEmail}',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        DateFormat('dd.MM.yyyy\nHH:mm:ss').format(log.createdAt),
        textAlign: TextAlign.right,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
      ),
    );
  }
}
