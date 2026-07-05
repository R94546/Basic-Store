import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/functions_call.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/l10n/locale_provider.dart';
import 'package:customer_app/core/telegram/telegram_service.dart';
import 'orders_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.t('profile.title').toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Telegram foydalanuvchisi (Telegram'da ochilganda)
                  _buildUserHeader(loc),

                  // Oddiy brauzerda «Telegram bilan kirish» (yagona akkaunt)
                  const _TelegramWebLoginTile(),

                  // Language switch
                  Text(
                    loc.t('profile.language').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _LangChip(
                          label: "O'zbekcha",
                          selected: loc.isUz,
                          onTap: () => loc.setLang('uz'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LangChip(
                          label: 'Русский',
                          selected: !loc.isUz,
                          onTap: () => loc.setLang('ru'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // My orders
                  _ProfileMenuItem(
                    title: loc.t('profile.myOrders').toUpperCase(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrdersHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuItem(
                    title: loc.t('profile.contact').toUpperCase(),
                    onTap: () {},
                  ),
                  _ProfileMenuItem(
                    title: loc.t('profile.about').toUpperCase(),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(LocaleProvider loc) {
    final tg = TelegramService.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: (tg?.photoUrl != null && tg!.photoUrl!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: tg.photoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.grey),
                  )
                : const Icon(Icons.person, color: Colors.grey, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tg?.fullName.isNotEmpty == true
                      ? tg!.fullName
                      : loc.t('home.welcome'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (tg?.username != null)
                  Text('@${tg!.username}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Oddiy brauzerda (Mini App EMAS) «Telegram bilan kirish» tugmasi.
/// Web'da, Telegram ichida emas va hali tg_ akkaunti bilan kirmagan bo'lsa
/// ko'rinadi. Kirgach — server AYNAN SHU tg_<id> uid beradi, shu orqali web va
/// Mini App bitta akkaunt (buyurtma tarixi birlashadi).
class _TelegramWebLoginTile extends StatefulWidget {
  const _TelegramWebLoginTile();

  @override
  State<_TelegramWebLoginTile> createState() => _TelegramWebLoginTileState();
}

class _TelegramWebLoginTileState extends State<_TelegramWebLoginTile> {
  bool _loading = false;
  String? _botId; // oldindan yuklanadi (popup user-gesture ichida ochilishi uchun)
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    // Kirgan/chiqilgandan keyin holatni yangilash uchun auth'ni kuzatamiz
    _authSub = FirebaseAuth.instance.userChanges().listen((_) {
      if (mounted) setState(() {});
    });
    // Bot ID'ni OLDINDAN yuklab qo'yamiz — shunda tugma bosilganda popup
    // to'g'ridan-to'g'ri (await'siz) ochiladi va brauzer uni bloklamaydi.
    if (kIsWeb && !TelegramService.isInTelegram) {
      _fetchBotId();
    }
  }

  Future<void> _fetchBotId() async {
    try {
      final res = await callFunction('telegramLoginInfo');
      final id = (res?['botId'] ?? '').toString();
      if (mounted && id.isNotEmpty) setState(() => _botId = id);
    } catch (_) {
      // Jim — tap paytida qayta urinamiz
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _login() async {
    final loc = context.read<LocaleProvider>();
    if (!TelegramService.canWebLogin) {
      _showError(loc, 'widget yuklanmadi');
      return;
    }
    setState(() => _loading = true);
    try {
      // 1) Bot ID — oldindan yuklangan bo'lsa darhol, aks holda shu yerda
      //    (bosishdan ~5s ichida window.open baribir ochiladi — transient
      //    user activation). Maxfiy token OCHILMAYDI, faqat ochiq id.
      var botId = _botId ?? '';
      if (botId.isEmpty) {
        final infoRes = await callFunction('telegramLoginInfo');
        botId = (infoRes?['botId'] ?? '').toString();
        _botId = botId;
      }
      if (botId.isEmpty) throw Exception('bot id bo\'sh');

      // 2) Login Widget popup — bekor qilinsa null (jim o'tamiz)
      final user = await TelegramService.widgetLogin(botId);
      if (user == null) return;

      // 3) Server HMAC tekshirib tg_<id> custom token beradi
      final authRes = await callFunction('telegramLoginAuth', user);
      final token = (authRes?['token'] ?? '').toString();
      if (token.isEmpty) throw Exception('token yo\'q');

      // 4) Kirish — uid endi tg_<id> (Mini App bilan bir xil)
      await FirebaseAuth.instance.signInWithCustomToken(token);
      // userChanges tinglovchisi UI'ni yangilaydi
    } catch (e) {
      if (mounted) _showError(loc, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(LocaleProvider loc, [String? detail]) {
    if (!mounted) return;
    final base = loc.t('profile.tgLoginError');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(detail == null ? base : '$base ($detail)'),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Faqat oddiy brauzerda: Mini App'da kerak emas, mobil'da widget yo'q
    if (!kIsWeb ||
        TelegramService.isInTelegram ||
        !TelegramService.canWebLogin) {
      return const SizedBox.shrink();
    }

    final loc = context.watch<LocaleProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final loggedIn = uid.startsWith('tg_');

    if (loggedIn) {
      // Allaqachon Telegram akkaunti bilan kirgan
      return Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF2AABEE), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.t('profile.tgLoggedIn'),
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );
    }

    // Kirish tugmasi
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2AABEE), // Telegram ko'k
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(
                loc.t('profile.tgLogin').toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.t('profile.tgLoginHint'),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.black,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
