import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/strings.dart';
import '../../supabase/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(supabaseClientProvider)
          .auth
          .signInWithPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
      // router redirect ไปหน้าหลักเองเมื่อ auth state เปลี่ยน
    } on AuthException {
      // ไม่ log อีเมล/รหัสผ่าน (PDPA)
      if (mounted) setState(() => _error = S.loginFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AnnounceStrip(S.announce),
            const PillHeader(title: S.appTitle),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(S.loginEyebrow, style: t.labelSmall),
                              const SizedBox(height: 12),
                              Text(S.loginTitle, style: t.headlineMedium),
                              const SizedBox(height: 8),
                              Text(
                                S.loginSubtitle,
                                style: t.bodySmall?.copyWith(color: p.muted),
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                controller: _email,
                                decoration: const InputDecoration(
                                  labelText: S.email,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? S.emailRequired
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _password,
                                decoration: const InputDecoration(
                                  labelText: S.password,
                                ),
                                obscureText: true,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? S.passwordRequired
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              if (_error != null) ...[
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              FilledButton(
                                onPressed: _busy ? null : _submit,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: _busy
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(S.login),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
