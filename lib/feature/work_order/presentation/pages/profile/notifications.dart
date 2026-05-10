import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const Color _textPrimary = Color(0xFF282A37);
  static const Color _textSecondary = Color(0xFF515978);
  static const Color _accentBlue = Color(0xFF156CD7);
  static const Color _blueSoft = Color(0xFFEEF7FF);
  static const Color _cardSoft = Color(0xFFF6F7F9);
  static const Color _lineColor = Color(0xFFECEDF2);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ListView(
          padding: EdgeInsets.fromLTRB(16, topInset + 18, 16, 20),
          children: const [
            _NotificationsHeader(),
            SizedBox(height: 18),
            _SectionTitle(title: 'Today'),
            _NotificationItem(
              initials: 'CR',
              actor: 'Ronaldo',
              content: 'Liked your posted',
              subtitle: 'Favourites Places - 2h ago',
              avatarColor: Color(0xFFE99C11),
              hasHeart: false,
              isUnread: true,
            ),
            _NotificationItem(
              initials: 'CS',
              actor: 'Costas',
              content: 'Liked your posted',
              subtitle: 'Favourites Places - 2h ago',
              avatarColor: Color(0xFF0A043C),
              hasHeart: false,
              isUnread: true,
            ),
            _NotificationItem(
              initials: 'JD',
              actor: 'Jeremy',
              content: 'mention you in new post',
              subtitle: '@jeremypasos - 2h ago',
              avatarColor: Color(0xFFE1260D),
              hasHeart: true,
              isUnread: true,
            ),
            SizedBox(height: 8),
            _SectionTitle(title: 'This Week'),
            _NotificationItem(
              initials: 'MC',
              actor: 'Malika',
              content: 'Liked your posted',
              subtitle: 'Favourites Places - 2h ago',
              avatarColor: Color(0xFFF39200),
              hasHeart: true,
              isUnread: true,
            ),
            _NotificationItem(
              initials: 'JF',
              actor: 'Jonathan',
              content: 'Liked your posted',
              subtitle: 'Favourites Places - 2h ago',
              avatarColor: Color(0xFF8F77F6),
              hasHeart: true,
              isUnread: true,
            ),
            _NotificationItem(
              initials: 'WA',
              actor: 'Warren Buffet',
              content: 'Liked your posted',
              subtitle: 'Favourites Places - 2h ago',
              avatarColor: Color(0xFF156CD7),
              hasHeart: true,
              isUnread: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: NotificationsPage._blueSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: NotificationsPage._accentBlue,
                  size: 20,
                ),
              ),
            ),
            const Spacer(),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: NotificationsPage._blueSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: NotificationsPage._accentBlue,
                    size: 20,
                  ),
                ),
                // Red badge marker requested on the header action.
                const Positioned(
                  top: -1,
                  right: -1,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: Color(0xFFFF4D4F),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Notifications',
          style: TextStyle(
            color: NotificationsPage._textPrimary,
            fontSize: 34 / 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              color: NotificationsPage._textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(text: 'You have '),
              TextSpan(
                text: '2 Notifications',
                style: TextStyle(
                  color: NotificationsPage._accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: ' today.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 32 / 1.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String initials;
  final String actor;
  final String content;
  final String subtitle;
  final Color avatarColor;
  final bool hasHeart;
  final bool isUnread;

  const _NotificationItem({
    required this.initials,
    required this.actor,
    required this.content,
    required this.subtitle,
    required this.avatarColor,
    required this.hasHeart,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: NotificationsPage._lineColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isUnread ? NotificationsPage._accentBlue : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18 / 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: NotificationsPage._textSecondary,
                      fontSize: 30 / 2.2,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      TextSpan(
                        text: actor,
                        style: const TextStyle(
                          color: NotificationsPage._accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ' $content'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: NotificationsPage._textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 50,
            decoration: BoxDecoration(
              color: NotificationsPage._cardSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: hasHeart
                ? const Icon(
                    Icons.favorite,
                    color: NotificationsPage._accentBlue,
                    size: 14,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
