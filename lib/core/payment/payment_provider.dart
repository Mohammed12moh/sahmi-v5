/// طبقة الدفع المنفصلة / Pluggable payment layer.
/// حالياً: DemoPaymentProvider (رصيد وهمي). لاحقاً: استبدله بوسيط مرخّص
/// فقط بعد ترخيص ومراجعة قانونية.
abstract class PaymentProvider {
  String get name;
  bool get isDemo;
  Future<void> deposit({required double amount});
  Future<void> withdraw({required double amount, required String details});
}

class DemoPaymentProvider implements PaymentProvider {
  final Future<void> Function(double) _credit;
  DemoPaymentProvider(this._credit);
  @override
  String get name => 'رصيد تجريبي';
  @override
  bool get isDemo => true;
  @override
  Future<void> deposit({required double amount}) => _credit(amount);
  @override
  Future<void> withdraw({required double amount, required String details}) async {
    throw UnsupportedError('السحب غير متاح في الوضع التجريبي');
  }
}
