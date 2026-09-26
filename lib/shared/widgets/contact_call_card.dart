import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import 'app_card.dart';
import 'initials_avatar.dart';

/// Contact row with a tap-to-call button — ported from the Partner app's
/// `ContactCallCard`. This app shows phone numbers as plain text today
/// (member cards, booking detail); this gives the same one-tap `tel:`
/// affordance the partner side already has for a booking's contact.
/// Copies the number instead when the device can't place calls
/// (simulator, desktop).
class ContactCallCard extends StatelessWidget {
  const ContactCallCard({
    super.key,
    required this.name,
    required this.phone,
    this.label = 'ผู้ติดต่อ',
  });

  final String name;
  final String phone;
  final String label;

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri).onError((_, _) => false);
    if (launched || !context.mounted) return;
    await Clipboard.setData(ClipboardData(text: phone));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('โทรไม่ได้บนอุปกรณ์นี้ คัดลอกเบอร์ $phone แล้ว')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        children: [
          InitialsAvatar(name: name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(name, style: textTheme.titleSmall),
                Text(phone, style: textTheme.bodySmall),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () => _call(context),
            icon: const Icon(Icons.call_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(44, 44),
            ),
          ),
        ],
      ),
    );
  }
}
