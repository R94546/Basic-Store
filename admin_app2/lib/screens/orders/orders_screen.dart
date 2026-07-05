import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';

/// Buyurtmalar — mijoz_app dan kelgan buyurtmalarni boshqarish ekrani.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _filter = 0; // 0 = yangi, 1 = faol, 2 = yakunlangan

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Real-time tinglovchi
      context.read<OrderProvider>().listenToOrders();
      // Shtrix kodlarni ko'rsatish uchun mahsulotlar (yuklanmagan bo'lsa)
      final products = context.read<ProductProvider>();
      if (products.products.isEmpty) products.loadProducts();
    });
  }

  /// Mingliklarni bo'sh joy bilan ajratadi: 1234567 -> 1 234 567
  String _money(int value) {
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return (value < 0 ? '-' : '') + buf.toString();
  }

  String _statusLabel(LocaleProvider loc, OrderStatus s) =>
      loc.t('orderStatus.${s.name}');

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final provider = context.watch<OrderProvider>();

    final List<CustomerOrder> list;
    switch (_filter) {
      case 1:
        list = provider.activeOrders;
        break;
      case 2:
        list = provider.completedOrders;
        break;
      default:
        list = provider.pendingOrders;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== Header =====
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: AppTheme.accentOrange, size: 28),
              const SizedBox(width: 12),
              Text(
                loc.t('nav.orders'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (provider.todayOrdersCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${loc.t('common.today')}: ${provider.todayOrdersCount}',
                    style: const TextStyle(
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== Filtr segmentlari =====
          _FilterTabs(
            selected: _filter,
            labels: [
              '${loc.t('ordersAdmin.new')} (${provider.pendingOrders.length})',
              '${loc.t('ordersAdmin.active')} (${provider.activeOrders.length})',
              '${loc.t('ordersAdmin.completed')} (${provider.completedOrders.length})',
            ],
            onSelected: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 16),

          // ===== Ro'yxat =====
          Expanded(
            child: provider.isLoading && list.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.accentOrange))
                : list.isEmpty
                    ? _EmptyState(text: loc.t('ordersAdmin.empty'))
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) => _OrderCard(
                          order: list[i],
                          loc: loc,
                          money: _money,
                          statusLabel: _statusLabel,
                          onChangeStatus: (status) =>
                              _changeStatus(list[i], status, loc),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(
      CustomerOrder order, OrderStatus status, LocaleProvider loc) async {
    if (order.id == null) return;
    final ok = await context
        .read<OrderProvider>()
        .updateOrderStatus(order.id!, status);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${loc.t('ordersAdmin.statusUpdated')}: ${loc.t('orderStatus.${status.name}')}'),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('common.error')),
          backgroundColor: AppTheme.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Filtr segmentlari (Yangi / Faol / Yakunlangan)
class _FilterTabs extends StatelessWidget {
  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  const _FilterTabs({
    required this.selected,
    required this.labels,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: selected == i
                        ? AppTheme.accentOrange
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected == i
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
                fontSize: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Bitta buyurtma kartochkasi
class _OrderCard extends StatelessWidget {
  final CustomerOrder order;
  final LocaleProvider loc;
  final String Function(int) money;
  final String Function(LocaleProvider, OrderStatus) statusLabel;
  final ValueChanged<OrderStatus> onChangeStatus;

  const _OrderCard({
    required this.order,
    required this.loc,
    required this.money,
    required this.statusLabel,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd.MM HH:mm').format(order.createdAt);
    final products = context.watch<ProductProvider>();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Mijoz qatori =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(photo: order.customerPhoto),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            order.customerName.isEmpty
                                ? loc.t('pos.customer')
                                : order.customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (order.customerUsername != null &&
                            order.customerUsername!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '@${order.customerUsername}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          order.customerPhone,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Vaqt + holat
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  _StatusBadge(
                    status: order.status,
                    label: statusLabel(loc, order.status),
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 24),

          // ===== Mahsulotlar (shtrix kod bilan) =====
          ...order.items.map((item) {
            final barcode = products.barcodeForItem(
              item.productId,
              size: item.size,
              color: item.color,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _itemTitle(item),
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${money(item.totalPrice)} ${loc.t('common.sum')}',
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  if (barcode != null && barcode.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_2,
                              size: 14, color: AppTheme.accentOrange),
                          const SizedBox(width: 4),
                          SelectableText(
                            barcode,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),

          // ===== Manzil / izoh =====
          if (order.customerAddress != null &&
              order.customerAddress!.isNotEmpty)
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: order.customerAddress!,
            ),
          if (order.customerLat != null && order.customerLng != null)
            InkWell(
              onTap: () => launchUrl(
                Uri.parse(
                    'https://www.google.com/maps?q=${order.customerLat},${order.customerLng}'),
                mode: LaunchMode.externalApplication,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined,
                        size: 18, color: AppTheme.accentOrange),
                    const SizedBox(width: 8),
                    Text(
                      loc.t('orders.openMap'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.accentOrange,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (order.notes != null && order.notes!.isNotEmpty)
            _InfoRow(
              icon: Icons.sticky_note_2_outlined,
              text: order.notes!,
            ),

          const SizedBox(height: 8),

          // ===== Jami + holat boshqaruvi =====
          Row(
            children: [
              Text(
                '${loc.t('common.total')}: ',
                style: const TextStyle(
                    fontSize: 15, color: AppTheme.textSecondary),
              ),
              Text(
                '${money(order.total)} ${loc.t('common.sum')}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              _StatusMenu(
                current: order.status,
                loc: loc,
                onSelected: onChangeStatus,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _itemTitle(CartItem item) {
    final variant = [item.size, item.color]
        .where((e) => e != null && e.isNotEmpty)
        .join(' / ');
    final name = variant.isEmpty ? item.name : '${item.name} ($variant)';
    return '$name x${item.quantity}';
  }
}

class _Avatar extends StatelessWidget {
  final String? photo;
  const _Avatar({this.photo});

  @override
  Widget build(BuildContext context) {
    const double size = 46;
    if (photo != null && photo!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photo!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _fallback(),
          errorWidget: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: AppTheme.accentOrange),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final String label;
  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Holatni o'zgartirish menyusi
class _StatusMenu extends StatelessWidget {
  final OrderStatus current;
  final LocaleProvider loc;
  final ValueChanged<OrderStatus> onSelected;

  const _StatusMenu({
    required this.current,
    required this.loc,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Mavjud o'tkazish variantlari (joriy holatdan tashqari hammasi)
    final options = OrderStatus.values.where((s) => s != current).toList();

    return PopupMenuButton<OrderStatus>(
      tooltip: loc.t('ordersAdmin.changeStatus'),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final s in options)
          PopupMenuItem<OrderStatus>(
            value: s,
            child: Row(
              children: [
                Icon(s.icon, size: 18, color: s.color),
                const SizedBox(width: 10),
                Text(loc.t('orderStatus.${s.name}')),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.accentOrange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.t('ordersAdmin.changeStatus'),
              style: const TextStyle(
                color: AppTheme.accentOrange,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                color: AppTheme.accentOrange, size: 20),
          ],
        ),
      ),
    );
  }
}
