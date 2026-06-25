import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/l10n/locale_provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

/// OrderStatus -> tarjima kaliti
String orderStatusLabel(LocaleProvider loc, OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return loc.t('orderStatus.pending');
    case OrderStatus.confirmed:
      return loc.t('orderStatus.confirmed');
    case OrderStatus.processing:
      return loc.t('orderStatus.processing');
    case OrderStatus.shipped:
      return loc.t('orderStatus.shipped');
    case OrderStatus.delivered:
      return loc.t('orderStatus.delivered');
    case OrderStatus.cancelled:
      return loc.t('orderStatus.cancelled');
  }
}

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _hasPhone = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    String? phone;
    try {
      final prefs = await SharedPreferences.getInstance();
      phone = prefs.getString('customer_phone');
    } catch (_) {
      phone = null;
    }

    if (!mounted) return;

    if (phone == null || phone.trim().isEmpty) {
      setState(() => _hasPhone = false);
      return;
    }

    setState(() => _hasPhone = true);
    await context.read<OrderProvider>().loadOrdersByPhone(phone);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.t('orders.title').toUpperCase(),
          style: GoogleFonts.playfairDisplay(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 1.5,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
          tabs: [
            Tab(text: loc.t('orders.active').toUpperCase()),
            Tab(text: loc.t('orders.completed').toUpperCase()),
          ],
        ),
      ),
      body: !_hasPhone
          ? _EmptyState(message: loc.t('orders.noPhone'))
          : Consumer<OrderProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }

                if (provider.orders.isEmpty) {
                  return _EmptyState(message: loc.t('orders.empty'));
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _OrdersList(orders: provider.activeOrders),
                    _OrdersList(orders: provider.completedOrders),
                  ],
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            loc.t('orders.empty').toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: const RoundedRectangleBorder(),
            ),
            child: Text(loc.t('cart.continueShopping').toUpperCase()),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<CustomerOrder> orders;

  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    if (orders.isEmpty) {
      return Center(
        child: Text(
          loc.t('orders.empty'),
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _OrderCard(order: orders[index]);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final CustomerOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'ORDER #${order.id?.substring(0, 8).toUpperCase() ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                _StatusBadge(status: order.status),
              ],
            ),
          ),

          // Items list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          if (item.imageUrl != null)
                            Container(
                              width: 50,
                              height: 50,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                image: DecorationImage(
                                  image: NetworkImage(item.imageUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (item.size != null || item.color != null)
                                  Text(
                                    [item.size, item.color]
                                        .where((e) => e != null)
                                        .join(' / '),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            'x${item.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )),
                if (order.items.length > 3)
                  Text(
                    '+${order.items.length - 3}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(order.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatPrice(order.total)} ${loc.t('common.sum')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (order.status == OrderStatus.pending)
                  TextButton(
                    onPressed: () => _cancelOrder(context),
                    child: Text(
                      loc.t('orders.cancel').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(BuildContext context) async {
    final loc = context.read<LocaleProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: Text(loc.t('orders.cancel')),
        content: Text(loc.t('orders.cancel')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.t('common.close').toUpperCase()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.t('orders.cancel').toUpperCase(),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success =
          await context.read<OrderProvider>().cancelOrder(order.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? loc.t('orders.cancel') : loc.t('common.error')),
          ),
        );
      }
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    Color color;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case OrderStatus.processing:
        color = Colors.purple;
        break;
      case OrderStatus.shipped:
        color = Colors.cyan;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        orderStatusLabel(loc, status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
