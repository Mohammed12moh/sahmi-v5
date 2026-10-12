import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/support.dart';
import '../../core/theme.dart';
import '../../core/haptics.dart';
import '../market/market_providers.dart';
import '../market/widgets.dart';
import 'levels.dart';
import 'referral_providers.dart';

/// لوحة الدعوة / Referral dashboard
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});
  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  String _period = 'week';

  String _text(String code) =>
      'جرّب تطبيق سهمي لمحاكاة التداول (نسخة تعليمية برصيد تجريبي).\nاستخدم رمز الدعوة: $code';

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    Haptics.selection();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرمز')));
  }

  void _qr(String code) => showModalBottomSheet<void>(
        context: context,
        backgroundColor: C.surface,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: C.gold)),
            const SizedBox(height: 16),
            QrImageView(data: _text(code), size: 220, backgroundColor: Colors.white),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final summary = ref.watch(referralSummaryProvider);
    final code = (profile.valueOrNull?['invite_code'] as String?) ?? '';
    final count = summary.valueOrNull?.count ?? 0;
    final lvl = levelFor(count), next = nextLevel(count);
    final enc = Uri.encodeComponent(_text(code));

    Widget channel(IconData i, String l, VoidCallback f) => InkWell(
          onTap: code.isEmpty ? null : f,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [Icon(i, color: C.green), const SizedBox(height: 4), Text(l, style: const TextStyle(fontSize: 11))]),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('ادعُ أصدقاءك')),
      body: RefreshIndicator(
        color: C.green,
        onRefresh: () async {
          ref.invalidate(referralSummaryProvider);
          ref.invalidate(leaderboardProvider(_period));
        },
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // بطاقة ذهبية / golden card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                  begin: Alignment.topRight, end: Alignment.bottomLeft,
                  colors: [Color(0xFFFFE259), Color(0xFFFFA751)]),
              boxShadow: [BoxShadow(color: C.gold.withValues(alpha: .35), blurRadius: 30, offset: const Offset(0, 12))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${lvl.emoji} مستوى ${lvl.name}', style: const TextStyle(color: C.navy, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text('رمز دعوتك', style: TextStyle(color: C.navy)),
              Text(code.isEmpty ? '••••••••' : code,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: C.navy, letterSpacing: 4)),
              const SizedBox(height: 14),
              Row(children: [
                _goldBtn(Icons.copy, 'نسخ', code.isEmpty ? null : () => _copy(code)),
                const SizedBox(width: 8),
                _goldBtn(Icons.share, 'مشاركة', code.isEmpty ? null : () => Share.share(_text(code))),
                const SizedBox(width: 8),
                _goldBtn(Icons.qr_code, 'QR', code.isEmpty ? null : () => _qr(code)),
              ]),
            ]),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, color: Colors.white24),
          const SizedBox(height: 16),

          // التقدم / progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$count صديق سجّلوا برمزك', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: levelProgress(count), minHeight: 10, color: lvl.color, backgroundColor: Colors.white12),
              ),
              const SizedBox(height: 6),
              Text(next == null ? 'وصلت لأعلى مستوى 💎' : 'باقي ${next.min - count} للوصول إلى ${next.emoji} ${next.name}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),

          // قنوات المشاركة / share channels
          const Text('شارك عبر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            channel(Icons.chat, 'واتساب', () => _open('https://wa.me/?text=$enc')),
            channel(Icons.send, 'تلغرام', () => _open('https://t.me/share/url?url=%20&text=$enc')),
            channel(Icons.email_outlined, 'بريد', () => _open('mailto:?subject=${Uri.encodeComponent('سهمي')}&body=$enc')),
            channel(Icons.sms_outlined, 'رسالة', () => _open('sms:?body=$enc')),
            channel(Icons.alternate_email, 'X', () => _open('https://twitter.com/intent/tweet?text=$enc')),
            channel(Icons.more_horiz, 'المزيد', () => Share.share(_text(code))),
          ]),
          const SizedBox(height: 20),

          // جدول المكافآت / rewards
          const Text('مكافآت المستويات (نقاط XP)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final l in refLevels)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.card, borderRadius: BorderRadius.circular(12),
                border: l == lvl ? Border.all(color: l.color) : null,
              ),
              child: Row(children: [
                Text('${l.emoji} ${l.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text(l.max == null ? '${l.min}+' : '${l.min}-${l.max}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                Text('${l.xpPerFriend} XP / صديق', style: TextStyle(color: l.color, fontWeight: FontWeight.w800)),
              ]),
            ),
          const SizedBox(height: 20),

          // لوحة المتصدرين / leaderboard
          const Text('لوحة المتصدرين 🏆', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(children: [
            for (final p in const [('week', 'أسبوعية'), ('month', 'شهرية'), ('all', 'شاملة')])
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: Text(p.$2),
                  selected: _period == p.$1,
                  selectedColor: C.green,
                  labelStyle: TextStyle(color: _period == p.$1 ? C.navy : Colors.white),
                  onSelected: (_) => setState(() => _period = p.$1),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          ref.watch(leaderboardProvider(_period)).when<Widget>(
                loading: () => const SkeletonList(count: 3),
                error: (_, __) => ErrorView(message: 'تعذّر تحميل المتصدرين', onRetry: () => ref.invalidate(leaderboardProvider(_period))),
                data: (rows) {
                  if (rows.isEmpty) return const EmptyView(message: 'لا يوجد متصدرون بعد', icon: Icons.emoji_events_outlined);
                  const medals = ['🥇', '🥈', '🥉'];
                  return Column(children: [
                    for (final r in rows)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          SizedBox(
                            width: 36,
                            child: Text(((r['rank'] as num).toInt() <= 3) ? medals[(r['rank'] as num).toInt() - 1] : '#${r['rank']}'),
                          ),
                          Expanded(child: Text('${r['username']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                          Text('${r['invites']} دعوة', style: const TextStyle(color: C.gold)),
                        ]),
                      ),
                  ]);
                },
              ),
          const SizedBox(height: 20),

          // آخر المسجلين / recent
          summary.when<Widget>(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => ErrorView(message: 'تعذّر تحميل الدعوات', onRetry: () => ref.invalidate(referralSummaryProvider)),
            data: (s) => s.recent.isEmpty
                ? const EmptyView(message: 'لم يسجّل أحد برمزك بعد', icon: Icons.group_add_outlined)
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('آخر المسجلين', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    for (final r in s.recent)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_outline, color: C.green),
                        title: Text('${r['username']}'),
                        trailing: Text(
                          DateFormat('yyyy-MM-dd', 'en').format(DateTime.parse('${r['created_at']}').toLocal()),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                  ]),
          ),
          const SizedBox(height: 12),
          const SupportButton(topic: 'الدعوات'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('المكافآت نقاط XP رمزية داخل التطبيق التجريبي ولا قيمة نقدية لها.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  Widget _goldBtn(IconData i, String l, VoidCallback? f) => Expanded(
        child: ElevatedButton.icon(
          onPressed: f,
          icon: Icon(i, size: 18),
          label: Text(l),
          style: ElevatedButton.styleFrom(
            backgroundColor: C.navy, foregroundColor: C.gold,
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      );
}
