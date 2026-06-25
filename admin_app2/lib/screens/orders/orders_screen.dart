import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';

/// Buyurtmalar — vaqtincha zaglushka ("Ishlab chiqilmoqda" / "На этапе разработки").
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.construction_rounded,
                    size: 72, color: AppTheme.accentOrange),
              ),
              const SizedBox(height: 24),
              Text(
                loc.t('orders.dev'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc.t('orders.devDesc'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
