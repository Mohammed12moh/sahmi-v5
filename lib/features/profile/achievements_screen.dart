import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../auth/auth_repository.dart';
import '../game/game_defs.dart';
import '../game/game_providers.dart';
import '../market/market_providers.dart';
import '../market/widgets.dart';

/// الإنجازات: Streak + شارات + تحديات
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  Future<void> _claim(BuildContext context, WidgetRef ref, ChallengeDef c) async {
    try {
      final xp = ((await ref.read(supabaseProvider).rpc('claim_challenge', params: {'p_id': c.id})) as num).toInt();
      Haptics.heavy();
      ref.invalidate(challengeProgressProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+$xp XP 🎉')));
      }
    } on PostgrestException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر استلام المكافأة')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final streak = (profile?['streak'] as num?)?.toInt() ?? 0;
    final xp = (profile?['xp'] as num?)?.toInt() ?? 0;
    final badges = ref.watch(myBadgesProvider);
    final progress = ref.watch(challengeProgressProvider);
    final filled = streak == 0 ? 0 : ((streak - 1) % 7) + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('الإنجازات والتحديات')),
      body: RefreshIndicator(
        color: C.green,
        onRefresh: () async {
          ref.invalidate(myBadgesProvider);
          ref.invalidate(challengeProgressProvider);
        },
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: [Color(0xFF3A1F00), Color(0xFF7A3E00)]),
              border: Border.all(color: C.gold.withValues(alpha: .4)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🔥 $streak يوم متتالي', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('$xp XP', style: const TextStyle(color: C.gold, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Row(children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Container(
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                          color: i < filled ? C.gold : Colors.white24, borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('التحديات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          progress.when<Widget>(
            loading: () => const SkeletonList(count: 4),
            error: (_, __) => ErrorView(message: 'تعذّر تحميل التحديات', onRetry: () => ref.invalidate(challengeProgressProvider)),
            data: (p) {
              final claimed = List<String>.from(p['claimed'] as List);
              return Column(children: [
                for (final c in challengeDefs) _challenge(context, ref, c, p, claimed.contains(c.id)),
              ]);
            },
          ),
          const SizedBox(height: 20),
          const Text('الشارات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          badges.when<Widget>(
            loading: () => const SkeletonList(count: 2),
            error: (_, __) => ErrorView(message: 'تعذّر تحميل الشارات', onRetry: () => ref.invalidate(myBadgesProvider)),
            data: (earned) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [for (final b in badgeDefs) _badge(b, earned.contains(b.id))],
            ),
          ),
          const Disclaimer(),
        ]),
      ),
    );
  }

  Widget _badge(BadgeDef b, bool on) => Opacity(
        opacity: on ? 1 : .4,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(16),
            border: on ? Border.all(color: C.gold.withValues(alpha: .6)) : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(on ? b.emoji : '🔒', style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.center),
            Text(b.desc, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
          ]),
        ),
      );

  Widget _challenge(BuildContext context, WidgetRef ref, ChallengeDef c, Map<String, dynamic> p, bool claimed) {
    final v = challengeValue(p, c);
    final done = v >= c.target;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                child: Text(c.weekly ? 'أسبوعي' : 'يومي', style: const TextStyle(fontSize: 10)),
              ),
            ]),
            Text(c.desc, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (v / c.target).clamp(0.0, 1.0).toDouble(), minHeight: 8,
                color: done ? C.green : C.gold, backgroundColor: Colors.white12,
              ),
            ),
            const SizedBox(height: 4),
            Text('${v > c.target ? c.target : v}/${c.target}  •  +${c.xp} XP', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
        const SizedBox(width: 12),
        claimed
            ? const Icon(Icons.check_circle, color: C.green)
            : ElevatedButton(
                onPressed: done ? () => _claim(context, ref, c) : null,
                style: ElevatedButton.styleFrom(minimumSize: const Size(72, 40)),
                child: const Text('استلم'),
              ),
      ]),
    );
  }
}
