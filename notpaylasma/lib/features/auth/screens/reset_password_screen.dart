import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../core/services/app_dependencies.dart';
import '../../../repositories/auth_repository.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/feedback.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _code = TextEditingController(),
      _password = TextEditingController();
  PasswordResetRequest? _request;
  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    try {
      if (_request == null) {
        final request = await auth.run(
          () => auth.repository.requestPasswordReset(_email.text),
        );
        if (mounted) {
          if (request.demoCode == null) {
            showMessage(
              context,
              'Şifre yenileme e-postasındaki bağlantıyı izleyin.',
            );
            Navigator.of(context).pop();
          } else {
            setState(() => _request = request);
          }
        }
      } else {
        await auth.run(
          () => auth.repository.confirmPasswordReset(
            _request!.id,
            _code.text,
            _password.text,
          ),
        );
        if (mounted) {
          showMessage(
            context,
            'Şifreniz değiştirildi. Yeni şifreyle giriş yapabilirsiniz.',
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Şifreyi yenile')),
    body: SafeArea(
      child: PageLayout(
        title: 'Hesabına yeniden eriş.',
        subtitle: context.read<AuthProvider>().repository.usesEmailPasswordReset
            ? 'Şifrenizi yenilemek için e-posta adresinize bir bağlantı gönderilir.'
            : context.read<AppDependencies>().isLocalJson
            ? 'Yerel hesap kurtarma kodu bu cihazda gösterilir. E-posta gönderilmez; bu cihazdaki verilerin güvenliği cihaz erişimine bağlıdır.'
            : 'Demo akışı: e-posta gönderilmez. Kod yalnızca burada gösterilir; gerçek hesap güvenliği sağlamaz.',
        children: [
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  readOnly: _request != null,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                  validator: Validators.email,
                ),
                if (_request != null) ...[
                  const SizedBox(height: 16),
                  SelectableText(
                    '${context.read<AppDependencies>().isLocalJson ? 'Yerel kurtarma kodu' : 'Demo doğrulama kodu'}: ${_request!.demoCode}\n5 dakika geçerli, en fazla 5 deneme.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _code,
                    decoration: const InputDecoration(
                      labelText: 'Doğrulama kodu',
                    ),
                    validator: (v) => Validators.text(v, 'Kod', 6, 6),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Yeni şifre'),
                    validator: Validators.password,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: context.watch<AuthProvider>().busy
                      ? null
                      : _submit,
                  child: Text(
                    _request == null
                        ? (context
                                  .read<AuthProvider>()
                                  .repository
                                  .usesEmailPasswordReset
                              ? 'Yenileme bağlantısı gönder'
                              : (context.read<AppDependencies>().isLocalJson
                                    ? 'Kurtarma kodu oluştur'
                                    : 'Demo kodu oluştur'))
                        : 'Şifreyi değiştir',
                  ),
                ),
                if (_request != null)
                  TextButton(
                    onPressed: () => setState(() {
                      _request = null;
                      _code.clear();
                      _password.clear();
                    }),
                    child: const Text('Yeni kod iste'),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
