import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_repository.dart';

typedef ReferralSummary = ({int count, List<Map<String, dynamic>> recent});

final referralSummaryProvider = FutureProvider.autoDispose<ReferralSummary>((ref) async {
  final db = ref.watch(supabaseProvider);
  final r = Map<String, dynamic>.from(await db.rpc('my_referral_summary') as Map);
  return (
    count: (r['count'] as num).toInt(),
    recent: List<Map<String, dynamic>>.from(r['recent'] as List),
  );
});

/// period: week | month | all
final leaderboardProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, period) async {
  final db = ref.watch(supabaseProvider);
  final rows = await db.rpc('referral_leaderboard', params: {'p_period': period});
  return List<Map<String, dynamic>>.from(rows as List);
});
