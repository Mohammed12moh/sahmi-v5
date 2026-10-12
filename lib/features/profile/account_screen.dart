import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../auth/auth_repository.dart';
import '../market/market_providers.dart';

/// معلومات الحساب وتعديلها / Account info & edit
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController();
  final _district = TextEditingController(), _address = TextEditingController();
  String? _city;
  bool _loaded = false, _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _district, _address]) { c.dispose(); }
    super.dispose();
  }

  void _fill(Map<String, dynamic> p) {
    _name.text = (p['full_name'] as String?) ?? '';
    _phone.text = (p['phone'] as String?) ?? '+964';
    _district.text = (p['district'] as String?) ?? '';
    _address.text = (p['address'] as String?) ?? '';
    final c = p['city'] as String?;
    _city = iraqGovernorates.contains(c) ? c : null;
    _loaded = true;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final db = ref.read(supabaseProvider);
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      await db.from('profiles').update({
        'full_name': _name.text.trim(),
        'phone': _phone.text.replaceAll(' ', ''),
        'city': _city,
        'district': _district.text.trim(),
        'address': _address.text.trim(),
      }).eq('id', uid);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات')));
    } on PostgrestException {
      setState(() => _error = 'تعذّر الحفظ');
    } catch (_) {
      setState(() => _error = 'تعذّر الاتصال، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final email = ref.watch(supabaseProvider).auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('معلومات الحساب')),
      body: profile.when<Widget>(
        loading: () => const Center(child: CircularProgressIndicator(color: C.gold)),
        error: (_, __) => const Center(child: Text('تعذّر تحميل الحساب')),
        data: (p) {
          if (p == null) return const Center(child: Text('لا توجد بيانات'));
          if (!_loaded) _fill(p);
          return Form(
            key: _form,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              TextFormField(initialValue: email, enabled: false, textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'البريد (غير قابل للتعديل)')),
              const SizedBox(height: 12),
              TextFormField(initialValue: '${p['username']}', enabled: false, textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'اسم المستخدم (ثابت)')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                validator: (v) => RegExp(r'^\+9647[3-9]\d{8}$').hasMatch((v ?? '').replaceAll(' ', '')) ? null : 'مثال: +9647701234567',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _city,
                decoration: const InputDecoration(labelText: 'المحافظة'),
                items: [for (final g in iraqGovernorates) DropdownMenuItem(value: g, child: Text(g))],
                validator: (v) => v == null ? 'مطلوب' : null,
                onChanged: (v) => setState(() => _city = v),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _district, decoration: const InputDecoration(labelText: 'المنطقة / الحي')),
              const SizedBox(height: 12),
              TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'العنوان (اختياري)')),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: C.red))),
              const SizedBox(height: 20),
              GlowButton('حفظ', loading: _saving, onPressed: _save),
            ]),
          );
        },
      ),
    );
  }
}
