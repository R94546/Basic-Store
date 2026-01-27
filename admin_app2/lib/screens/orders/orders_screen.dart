import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().listenToOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                'Buyurtmalar',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Refresh Button
              IconButton(
                onPressed: () => context.read<OrderProvider>().loadOrders(),
                icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabs
          GlassCard(
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.accentOrange,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.accentOrange,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Consumer<OrderProvider>(
                    builder: (context, provider, _) {
                      final count = provider.pendingOrders.length;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Yangi'),
                          if (count > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const Tab(text: 'Jarayonda'),
                const Tab(text: 'Yakunlangan'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentOrange,
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _OrderList(orders: provider.pendingOrders),
                    _OrderList(orders: provider.activeOrders),
                    _OrderList(orders: provider.completedOrders),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<CustomerOrder> orders;

  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Buyurtmalar yo\'q',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Order ID
              Text(
                '#${order.id?.substring(0, 8).toUpperCase() ?? 'N/A'}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: order.status.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(order.status.icon, size: 14, color: order.status.color),
                    const SizedBox(width: 4),
                    Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: order.status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Date
              Text(
                dateFormat.format(order.createdAt),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          
          // Customer Info
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                order.customerName,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.phone_outlined, color: AppTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                order.customerPhone,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
          
          if (order.customerAddress != null && order.customerAddress!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppTheme.textSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerAddress!,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Items
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} ${item.size != null ? '(${item.size})' : ''} x${item.quantity}',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${_formatPrice(item.totalPrice)} so\'m',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Total & Actions
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jami:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  Text(
                    '${_formatPrice(order.total)} so\'m',
                    style: const TextStyle(
                      color: AppTheme.accentOrange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Action buttons based on status
              if (order.status == OrderStatus.pending) ...[
                _ActionButton(
                  label: 'Bekor qilish',
                  color: Colors.red,
                  onPressed: () => _updateStatus(context, OrderStatus.cancelled),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Tasdiqlash',
                  color: Colors.green,
                  onPressed: () => _updateStatus(context, OrderStatus.confirmed),
                ),
              ] else if (order.status == OrderStatus.confirmed) ...[
                _ActionButton(
                  label: 'Tayyorlash',
                  color: Colors.purple,
                  onPressed: () => _updateStatus(context, OrderStatus.processing),
                ),
              ] else if (order.status == OrderStatus.processing) ...[
                _ActionButton(
                  label: 'Yuborish',
                  color: Colors.cyan,
                  onPressed: () => _updateStatus(context, OrderStatus.shipped),
                ),
              ] else if (order.status == OrderStatus.shipped) ...[
                _ActionButton(
                  label: 'Yetkazildi',
                  color: Colors.green,
                  onPressed: () => _updateStatus(context, OrderStatus.delivered),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, OrderStatus newStatus) async {
    final provider = context.read<OrderProvider>();
    final success = await provider.updateOrderStatus(order.id!, newStatus);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Buyurtma holati yangilandi' 
              : 'Xatolik yuz berdi'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
