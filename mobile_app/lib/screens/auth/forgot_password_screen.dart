// Quên mật khẩu: request a reset link. The confirmation is shown for any
// email so the screen never reveals which emails have accounts.

import 'package:flutter/material.dart';

import '../../auth/auth_validators.dart';
import '../../auth/session_controller.dart';
import '../../theme/sv_tokens.dart';
import '../../widgets/note.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.session, this.initialEmail = ''});

  final SessionController session;
  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail);
  String? _sentTo;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _error = null);
    try {
      await widget.session.requestPasswordReset(_email.text.trim());
      if (mounted) setState(() => _sentTo = _email.text.trim());
    } on Object catch (_) {
      if (mounted) setState(() => _error = 'Chưa gửi được. Kiểm tra mạng rồi thử lại nhé.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Quên mật khẩu', style: t.titleMedium)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.session,
          builder: (BuildContext context, _) {
            final bool busy = widget.session.busy;
            if (_sentTo != null) {
              return ListView(
                padding: const EdgeInsets.all(SvSpace.s4),
                children: <Widget>[
                  SvNote(
                    tone: SvNoteTone.soft,
                    icon: Icons.mail_outline_rounded,
                    title: 'Đã gửi link đặt lại mật khẩu',
                    message: 'Kiểm tra hộp thư $_sentTo và làm theo hướng dẫn nhé. Link có hiệu lực trong 15 phút.',
                  ),
                  const SizedBox(height: SvSpace.s4),
                  FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Về đăng nhập')),
                ],
              );
            }
            return Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(SvSpace.s4),
                children: <Widget>[
                  Text('Nhập email đã đăng ký, app sẽ gửi link để bạn đặt mật khẩu mới.', style: t.bodySmall),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: SvSpace.s3),
                    SvNote(title: 'Chưa gửi được', message: _error),
                  ],
                  const SizedBox(height: SvSpace.s4),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'ban@example.com'),
                    validator: validateEmail,
                    onFieldSubmitted: (_) => busy ? null : _submit(),
                  ),
                  const SizedBox(height: SvSpace.s6),
                  FilledButton(onPressed: busy ? null : _submit, child: Text(busy ? 'Đang gửi…' : 'Gửi link đặt lại')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
