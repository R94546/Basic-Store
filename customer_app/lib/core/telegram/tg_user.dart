/// Telegram Mini App foydalanuvchisi
class TgUser {
  final String id;
  final String firstName;
  final String? lastName;
  final String? username;
  final String? photoUrl;
  final String? languageCode;

  TgUser({
    required this.id,
    required this.firstName,
    this.lastName,
    this.username,
    this.photoUrl,
    this.languageCode,
  });

  String get fullName =>
      [firstName, if (lastName != null && lastName!.isNotEmpty) lastName]
          .join(' ')
          .trim();
}
