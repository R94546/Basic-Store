import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Profil avatarini ko'rsatuvchi widget.
///
/// MUHIM: Flutter web (CanvasKit) tashqi domen (masalan Telegram `t.me/i/userpic/…`)
/// rasmlarini CORS sababli TUVALGA chiza olmaydi — natijada rasm ko'rinmaydi.
/// Web'da `Image.network(webHtmlElementStrategy: prefer)` rasmni HTML `<img>`
/// elementi orqali chizadi (CORS shart emas). Mobil/Mini App'da esa
/// `CachedNetworkImage` (keshli) ishlatiladi.
class AvatarImage extends StatelessWidget {
  final String url;
  final double size;
  final Widget fallback;

  const AvatarImage({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return fallback;
    if (kIsWeb) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Rasmni HTML <img> orqali chizish -> CORS'siz Telegram rasmi ko'rinadi
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
