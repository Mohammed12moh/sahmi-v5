import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/haptics.dart';
import '../../core/password_strength.dart';
import '../../core/support.dart';
import '../../core/theme.dart';
import '../auth/auth_repository.dart';

/// الإعدادات والأمان / Settings & security
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _pw = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() { _pw.dispose(); super.dispose(); }

  Future<void> _change() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(supabaseProvider).auth.updateUser(UserAttributes(password: _pw.text));
      _pw.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور')));
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'تعذّر الاتصال، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = passwordStrength(_pw.text);
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات والأمان')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('عام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        SwitchListTile(
          value: Haptics.enabled,
          title: const Text('الاهتزاز اللمسي'),
          onChanged: (v) async {
            await Haptics.setEnabled(v);
            if (mounted) setState(() {});
          },
        ),
        const ListTile(
          leading: Icon(Icons.language, color: C.green),
          title: Text('اللغة'),
          trailing: Text('العربية', style: TextStyle(color: Colors.white60)),
        ),
        const Divider(color: Colors.white12, height: 32),
        const Text('الأمان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Form(
          key: _form,
          child: Column(children: [
            TextFormField(
              controller: _pw,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
              validator: (v) => (v ?? '').length >= 8 ? null : '8 أحرف على الأقل',
            ),
            if (_pw.text.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('القوة: ${pwLabels[s]}', style: const TextStyle(color: C.gold, fontSize: 12)),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
              validator: (v) => v == _pw.text ? null : 'غير متطابقة',
            ),
            if (_error != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: C.red))),
            const SizedBox(height: 16),
            GlowButton('تغيير كلمة المرور', loading: _saving, onPressed: _change),
          ]),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => ref.read(supabaseProvider).auth.signOut(scope: SignOutScope.global),
          icon: const Icon(Icons.devices),
          label: const Text('تسجيل الخروج من كل الأجهزة'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: Colors.white),
        ),
        const SizedBox(height: 12),
        const SupportButton(topic: 'الأمان'),
      ]),
    );
  }
}
