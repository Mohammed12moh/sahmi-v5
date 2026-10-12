import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_repository.dart';

/// عند فتح التطبيق: تحديث الـ Streak ثم فحص الشارات
final dailyCheckInProvider = FutureProvider<({int streak, List<String> newBadges})>((ref) async {
  final db = ref.watch(supabaseProvider);
  final streak = ((await db.rpc('touch_daily')) as num).toInt();
  final badges = List<String>.from(await db.rpc('check_badges') as List);
  return (streak: streak, newBadges: badges);
});

final myBadgesProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final db = ref.watch(supabaseProvider);
  final rows = await db.from('user_badges').select('badge');
  return {for (final r in rows) r['badge'] as String};
});

final challengeProgressProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final db = ref.watch(supabaseProvider);
  return Map<String, dynamic>.from(await db.rpc('challenge_progress') as Map);
});
