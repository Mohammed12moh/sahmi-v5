import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_repository.dart';
import 'portfolio_models.dart';

class TradeResult {
  final double balance, pnl;
  final List<String> newBadges;
  const TradeResult(this.balance, this.pnl, this.newBadges);
}

class TradeRepository {
  final SupabaseClient _db;
  TradeRepository(this._db);

  Future<TradeResult> execute(String symbol, String side, int qty, double price) async {
    final r = Map<String, dynamic>.from(await _db.rpc('execute_trade', params: {
      'p_symbol': symbol, 'p_side': side, 'p_qty': qty, 'p_price': price,
    }) as Map);
    return TradeResult(
      (r['balance'] as num).toDouble(),
      (r['pnl'] as num).toDouble(),
      List<String>.from(r['new_badges'] as List),
    );
  }
}

final tradeRepoProvider = Provider((ref) => TradeRepository(ref.watch(supabaseProvider)));

final holdingsProvider = FutureProvider.autoDispose<List<Holding>>((ref) async {
  final db = ref.watch(supabaseProvider);
  final rows = await db.from('holdings').select().order('symbol');
  return [for (final r in rows) Holding.fromRow(r)];
});

final tradesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(supabaseProvider);
  final rows = await db.from('trades').select().order('created_at', ascending: false).limit(100);
  return List<Map<String, dynamic>>.from(rows);
});
