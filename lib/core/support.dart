import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';

/// فتح محادثة الدعم على تلغرام + نسخ رسالة جاهزة (للدعم والمساعدة فقط)
/// Opens Telegram support chat with a prepared message (support only).
Future<void> contactSupport(BuildContext context, {String topic = 'مساعدة'}) async {
  final user = Supabase.instance.client.auth.currentUser;
  final msg = 'السلام عليكم،\nأحتاج مساعدة في تطبيق سهمي.\n'
      '📌 الموضوع: $topic\n📧 الحساب: ${user?.email ?? '-'}';
  await Clipboard.setData(ClipboardData(text: msg));
  var ok = false;
  for (final u in [AppConfig.telegramDeepLink, AppConfig.telegramUrl]) {
    try {
      ok = await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (ok) break;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(ok
        ? 'تم نسخ الرسالة، الصقها في المحادثة'
        : 'تعذّر فتح تلغرام. المعرف: @${AppConfig.telegramHandle} (تم نسخ الرسالة)'),
  ));
}

class SupportButton extends StatelessWidget {
  final String topic;
  const SupportButton({super.key, this.topic = 'مساعدة'});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => contactSupport(context, topic: topic),
        icon: const Icon(Icons.support_agent),
        label: const Text('تواصل مع الدعم'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
}
