import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/payment/payment_provider.dart';
import '../auth/auth_repository.dart';

/// مزوّد الدفع الحالي: تجريبي. لاحقاً استبدله بمزوّد وسيط مرخّص.
final paymentProvider = Provider<PaymentProvider>((ref) {
  final db = ref.watch(supabaseProvider);
  return DemoPaymentProvider((amount) async {
    await db.rpc('demo_deposit', params: {'p_amount': amount});
  });
});

final transactionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(supabaseProvider);
  final rows = await db.from('transactions').select().order('created_at', ascending: false).limit(100);
  return List<Map<String, dynamic>>.from(rows);
});
