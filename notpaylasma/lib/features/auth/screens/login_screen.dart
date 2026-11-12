import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../core/services/app_dependencies.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/app_loading_screen.dart';
import '../../../shared/widgets/app_brand.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _obscure = true;
  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    try {
      await auth.run(() => auth.repository.signIn(_email.text, _password.text));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    if (busy) {
      return const AppLoadingScreen(message: 'Giriş yapılıyor…');
    }
    final firebase = context.read<AppDependencies>().isFirebase;
    final localJson = context.read<AppDependencies>().isLocalJson;
    return Scaffold(
      appBar: AppBar(title: const AppBrand()),
      body: SafeArea(
        child: PageLayout(
          title: 'Tekrar hoş geldin.',
          subtitle: 'Bilgini paylaş, birlikte öğrenelim.',
          children: [
            const SizedBox(height: 20),
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    key: const ValueKey('login-email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('login-password'),
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Şifreyi göster' : 'Şifreyi gizle',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (v) =>
                        (v ?? '').isEmpty ? 'Şifrenizi girin.' : null,
                    onFieldSubmitted: (_) {
                      if (!busy) _login();
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy ? null : _login,
                    child: Text(busy ? 'Giriş yapılıyor…' : 'Giriş yap'),
                  ),
                ],
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                  child: const Text('Hesap oluştur'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ResetPasswordScreen(),
                          ),
                        ),
                  child: const Text('Şifremi unuttum'),
                ),
              ],
            ),
            if (!firebase && !localJson) ...[
              const Divider(),
              const Text(
                'Örnek hesaplar: ayse@example.com veya mehmet@example.com\nŞifre: NotPaylas123!',
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () {
                        _email.text = 'ayse@example.com';
                        _password.text = 'NotPaylas123!';
                        _login();
                      },
                child: const Text('Ayşe ile demo girişi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
