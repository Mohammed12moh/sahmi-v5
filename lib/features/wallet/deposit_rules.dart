/// قواعد الشحن التجريبي / Demo deposit rules (mirrors server-side checks)
const minDeposit = 10.0;
const maxDeposit = 1000.0;
const bonusThreshold = 50.0;
const bonusAmount = 5.0;
const depositPresets = [10, 25, 50, 100, 200, 500, 1000];

String? validateDepositAmount(double? a) {
  if (a == null) return 'أدخل مبلغاً صحيحاً';
  if (a < minDeposit || a > maxDeposit) return 'المبلغ بين 10 و1000';
  return null;
}

double bonusFor(double a) => a >= bonusThreshold ? bonusAmount : 0;
