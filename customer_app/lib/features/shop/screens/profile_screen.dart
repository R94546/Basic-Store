import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/functions_call.dart';
import 'package:customer_app/core/customer_profile.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/l10n/locale_provider.dart';
import 'package:customer_app/core/telegram/telegram_service.dart';
import 'orders_history_screen.dart';

// Telegram brendi ko'ki
const Color _tgBlue = Color(0xFF2AABEE);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = false;
  String? _botId; // oldindan yuklanadi (popup user-gesture ichida ochilishi uchun)
  StreamSubscription<User?>? _authSub;

  // Ko'rsatiladigan profil (Mini App yoki web-login'dan)
  String _name = '';
  String _username = '';
  String _photo = '';

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.userChanges().listen((_) {
      if (mounted) _reloadProfile();
    });
    if (kIsWeb && !TelegramService.isInTelegram) {
      _fetchBotId();
    }
    _reloadProfile();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  bool get _isTgLoggedIn {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return TelegramService.isInTelegram || uid.startsWith('tg_');
  }

  bool get _showLoginButton {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return kIsWeb &&
        !TelegramService.isInTelegram &&
        TelegramService.canWebLogin &&
        !uid.startsWith('tg_');
  }

  /// Profil ma'lumotini aniqlaydi: Mini App -> initData; aks holda web-login
  /// saqlangan ma'lumot (agar tg_ bilan kirgan bo'lsa).
  Future<void> _reloadProfile() async {
    String name = '', username = '', photo = '';
    final tg = TelegramService.user;
    if (tg != null) {
      name = tg.fullName;
      username = tg.username ?? '';
      photo = tg.photoUrl ?? '';
    } else {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.startsWith('tg_')) {
        name = await CustomerProfile.name();
        username = await CustomerProfile.username();
        photo = await CustomerProfile.photo();
      }
    }
    if (mounted) {
      setState(() {
        _name = name;
        _username = username;
        _photo = photo;
      });
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

  Future<void> _login() async {
    final loc = context.read<LocaleProvider>();
    if (!TelegramService.canWebLogin) {
      _showError(loc, 'widget yuklanmadi');
      return;
    }
    setState(() => _loading = true);
    try {
      // 1) Bot ID — oldindan yuklangan bo'lsa darhol
      var botId = _botId ?? '';
      if (botId.isEmpty) {
        final infoRes = await callFunction('telegramLoginInfo');
        botId = (infoRes?['botId'] ?? '').toString();
        _botId = botId;
      }
      if (botId.isEmpty) throw Exception('bot id bo\'sh');

      // 2) Login Widget popup — bekor qilinsa null
      final user = await TelegramService.widgetLogin(botId);
      if (user == null) return;

      // 3) Server HMAC tekshirib tg_<id> custom token beradi
      final authRes = await callFunction('telegramLoginAuth', user);
      final token = (authRes?['token'] ?? '').toString();
      if (token.isEmpty) throw Exception('token yo\'q');

      // 4) Kirish — uid endi tg_<id> (Mini App bilan bir xil)
      await FirebaseAuth.instance.signInWithCustomToken(token);

      // 5) Profilni saqlaymiz (web'da keyin ko'rsatish uchun)
      final fn = (user['first_name'] ?? '').toString();
      final ln = (user['last_name'] ?? '').toString();
      final name = [fn, ln].where((s) => s.isNotEmpty).join(' ').trim();
      await CustomerProfile.saveTg(
        name: name,
        username: (user['username'] ?? '').toString(),
        photo: (user['photo_url'] ?? '').toString(),
      );
      await _reloadProfile();
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
    final loc = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Sarlavha
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                loc.t('profile.title').toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
            ),

            // Profil kartasi
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: _ProfileHeaderCard(
                name: _name,
                username: _username,
                photo: _photo,
                isTgLoggedIn: _isTgLoggedIn,
                welcome: loc.t('home.welcome'),
              ),
            ),

            // «Telegram bilan kirish» (faqat kirmagan bo'lsa)
            if (_showLoginButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: _TgLoginButton(
                  loading: _loading,
                  label: loc.t('profile.tgLogin'),
                  hint: loc.t('profile.tgLoginHint'),
                  onTap: _login,
                ),
              ),

            const SizedBox(height: 20),

            // TIL
            _SectionLabel(loc.t('profile.language')),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Row(
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
            ),

            const SizedBox(height: 28),

            // MENYU
            _SectionLabel(loc.t('profile.title')),
            _MenuTile(
              icon: Icons.receipt_long_outlined,
              title: loc.t('profile.myOrders'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersHistoryScreen()),
                );
              },
            ),
            _MenuTile(
              icon: Icons.headset_mic_outlined,
              title: loc.t('profile.contact'),
              onTap: () {},
            ),
            _MenuTile(
              icon: Icons.info_outline,
              title: loc.t('profile.about'),
              onTap: () {},
            ),

            const SizedBox(height: 36),

            // Brend footer
            Center(
              child: Text(
                'BASIC STORE',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 13,
                  letterSpacing: 4,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Profil boshi — avatar + ism + @username + Telegram belgisi
class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String username;
  final String photo;
  final bool isTgLoggedIn;
  final String welcome;

  const _ProfileHeaderCard({
    required this.name,
    required this.username,
    required this.photo,
    required this.isTgLoggedIn,
    required this.welcome,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty ? name : welcome;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CustomerTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              shape: BoxShape.circle,
              border: Border.all(
                color: isTgLoggedIn ? _tgBlue : Colors.grey.shade300,
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: (photo.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: photo,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.grey, size: 32),
                  )
                : const Icon(Icons.person, color: Colors.grey, size: 32),
          ),
          const SizedBox(width: 16),
          // Ism / username / belgi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 8),
                if (isTgLoggedIn)
                  _Badge(
                    color: _tgBlue,
                    icon: Icons.verified,
                    text: 'Telegram',
                  )
                else
                  _Badge(
                    color: Colors.grey.shade500,
                    icon: Icons.person_outline,
                    text: 'Mehmon',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _Badge({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// «Telegram bilan kirish» tugmasi + izoh
class _TgLoginButton extends StatelessWidget {
  final bool loading;
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _TgLoginButton({
    required this.loading,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _tgBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _tgBlue.withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 19),
            label: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.lock_outline, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hint,
                style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Colors.grey[500],
        ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
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

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
