import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/support.dart';
import '../../core/theme.dart';
import '../chat/chat_room.dart';
import '../auth/auth_repository.dart';
import '../game/game_providers.dart';
import '../market/market_providers.dart';

/// الملف الشخصي / Profile
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final badges = ref.watch(myBadgesProvider).valueOrNull?.length ?? 0;
    final email = ref.watch(supabaseProvider).auth.currentUser?.email ?? '';

    Widget tile(IconData i, String t, VoidCallback f) => ListTile(
          leading: Icon(i, color: C.green),
          title: Text(t),
          trailing: const Icon(Icons.chevron_left, color: Colors.white38),
          onTap: f,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        profile.when<Widget>(
          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: C.gold))),
          error: (_, __) => const SizedBox(height: 120, child: Center(child: Text('تعذّر تحميل الحساب'))),
          data: (p) {
            final name = (p?['full_name'] as String?) ?? '';
            final xp = (p?['xp'] as num?)?.toInt() ?? 0;
            final streak = (p?['streak'] as num?)?.toInt() ?? 0;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(24)),
              child: Column(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: C.surface,
                  child: Text(name.isEmpty ? '؟' : name.substring(0, 1),
                      style: const TextStyle(fontSize: 30, color: C.gold, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                Text(name.isEmpty ? 'مستخدم سهمي' : name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('@${p?['username'] ?? ''}  •  $email',
                    textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 16),
                Row(children: [
                  _stat('XP', '$xp'),
                  _stat('🔥 الأيام', '$streak'),
                  _stat('🏅 الشارات', '$badges'),
                ]),
              ]),
            );
          },
        ),
        const SizedBox(height: 12),
        tile(Icons.person_outline, 'معلومات الحساب', () => context.push('/account')),
        tile(Icons.emoji_events_outlined, 'الإنجازات والتحديات', () => context.push('/achievements')),
        tile(Icons.card_giftcard, 'ادعُ أصدقاءك', () => context.push('/referral')),
        tile(Icons.forum_outlined, 'غرف الدردشة', () => showRoomsDialog(context)),
        tile(Icons.receipt_long, 'سجل المعاملات', () => context.push('/transactions')),
        tile(Icons.settings_outlined, 'الإعدادات والأمان', () => context.push('/settings')),
        tile(Icons.help_outline, 'المساعدة', () => context.push('/help')),
        tile(Icons.info_outline, 'عن التطبيق', () => showAboutDialog(
              context: context,
              applicationName: 'سهمي',
              applicationVersion: '0.4.0',
              children: const [Text('تطبيق تعليمي لمحاكاة التداول برصيد وبيانات افتراضية. ليس نصيحة استثمارية.')],
            )),
        const SizedBox(height: 12),
        const SupportButton(topic: 'الحساب'),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => ref.read(authRepoProvider).signOut(),
          icon: const Icon(Icons.logout, color: C.red),
          label: const Text('تسجيل الخروج', style: TextStyle(color: C.red)),
        ),
      ]),
    );
  }

  Widget _stat(String l, String v) => Expanded(
        child: Column(children: [
          Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: C.gold)),
          Text(l, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      );
}
