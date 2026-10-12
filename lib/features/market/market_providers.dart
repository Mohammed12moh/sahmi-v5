import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_repository.dart';
import 'market_data.dart';
import 'models.dart';
import 'signal_engine.dart';

final simulatorProvider = Provider((_) => MarketSimulator());

/// بث الأسعار (محاكاة) كل 3 ثوانٍ / simulated live feed
final marketProvider = StreamProvider<List<Stock>>((ref) async* {
  final sim = ref.watch(simulatorProvider);
  await Future<void>.delayed(const Duration(milliseconds: 700));
  yield sim.snapshot();
  await for (final _ in Stream<void>.periodic(const Duration(seconds: 3))) {
    sim.tick();
    yield sim.snapshot();
  }
});

final signalsProvider = Provider<Map<String, Signal>>((ref) {
  final stocks = ref.watch(marketProvider).valueOrNull ?? const <Stock>[];
  return {for (final s in stocks) s.symbol: SignalEngine.analyze(s)};
});

final stockProvider = Provider.family<Stock?, String>((ref, symbol) {
  final stocks = ref.watch(marketProvider).valueOrNull ?? const <Stock>[];
  for (final s in stocks) {
    if (s.symbol == symbol) return s;
  }
  return null;
});

/// قائمة المراقبة (محفوظة في Supabase) / watchlist persisted in Supabase
class WatchlistNotifier extends StateNotifier<Set<String>> {
  final SupabaseClient _db;
  WatchlistNotifier(this._db) : super(const {}) { _load(); }

  String? get _uid => _db.auth.currentUser?.id;

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final rows = await _db.from('watchlist').select('symbol').eq('user_id', uid);
      state = {for (final r in rows) r['symbol'] as String};
    } catch (_) {}
  }

  Future<void> toggle(String symbol) async {
    final uid = _uid;
    if (uid == null) return;
    final had = state.contains(symbol);
    state = had ? ({...state}..remove(symbol)) : {...state, symbol};
    try {
      if (had) {
        await _db.from('watchlist').delete().eq('user_id', uid).eq('symbol', symbol);
      } else {
        await _db.from('watchlist').insert({'user_id': uid, 'symbol': symbol});
      }
    } catch (_) {
      state = had ? {...state, symbol} : ({...state}..remove(symbol)); // تراجع / rollback
    }
  }
}

final watchlistProvider = StateNotifierProvider<WatchlistNotifier, Set<String>>(
    (ref) => WatchlistNotifier(ref.watch(supabaseProvider)));

/// الملف الشخصي مع تحديث فوري للرصيد (Realtime)
final profileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final db = ref.watch(supabaseProvider);
  final uid = db.auth.currentUser?.id;
  if (uid == null) return Stream<Map<String, dynamic>?>.empty();
  return db
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', uid)
      .map((rows) => rows.isEmpty ? null : rows.first);
});
