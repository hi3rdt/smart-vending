// Tạo tài khoản: by email, or "quick registration" from a registration QR
// that carries an invite code (viaInvite: true makes the code required).

import 'package:flutter/material.dart';

import '../../auth/auth_repository.dart';
import '../../auth/auth_validators.dart';
import '../../auth/session_controller.dart';
import '../../theme/sv_tokens.dart';
import '../../widgets/note.dart';

/// Pulls the invite code out of a scanned QR payload. Accepts the bare code
/// ("SV-A03-7K2Q") or a link carrying it ("https://.../join?code=SV-A03-7K2Q").
String? inviteCodeFromQr(String payload) {
  final String raw = payload.trim();
  final Uri? uri = Uri.tryParse(raw);
  final String candidate = (uri != null && uri.hasScheme) ? (uri.queryParameters['code'] ?? '') : raw;
  final String code = normalizeInviteCode(candidate);
  return validateInviteCode(code, required: true) == null ? code : null;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.session, this.viaInvite = false, this.onScanInvite, this.initialInviteCode});

  final SessionController session;
  final bool viaInvite;
  final Future<String?> Function()? onScanInvite;
  final String? initialInviteCode;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  late final TextEditingController _invite = TextEditingController(text: widget.initialInviteCode ?? '');
  bool _obscure = true;
  bool _submitted = false;
  String? _error;
  String? _scanNote;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_name, _email, _password, _confirm, _invite]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _scan() async {
    final String? payload = await widget.onScanInvite?.call();
    if (!mounted || payload == null) return;
    final String? code = inviteCodeFromQr(payload);
    setState(() {
      if (code != null) {
        _invite.text = code;
        _scanNote = 'Đã đọc mã mời $code';
      } else {
        _scanNote = null;
        _error = 'QR này không phải mã mời Smart Vending. Thử quét lại nhé.';
      }
    });
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    try {
      final String code = normalizeInviteCode(_invite.text);
      await widget.session.signUp(
        name: _name.text,
        email: _email.text.trim(),
        password: _password.text,
        inviteCode: code.isEmpty ? null : code,
      );
      if (!mounted) return;
      // Signed in: return to the root so the shell shows Home.
      Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.viaInvite ? 'Đăng ký bằng QR mời' : 'Tạo tài khoản', style: t.titleMedium)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.session,
          builder: (BuildContext context, _) {
            final bool busy = widget.session.busy;
            return Form(
              key: _form,
              autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
              child: AutofillGroup(
                child: ListView(
                  padding: const EdgeInsets.all(SvSpace.s4),
                  children: <Widget>[
                    Text(
                      widget.viaInvite
                          ? 'QR mời được dán cạnh tủ hoặc do quản trị viên gửi cho bạn.'
                          : 'Dùng email để nhận hoá đơn và lấy lại mật khẩu.',
                      style: t.bodySmall,
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: SvSpace.s3),
                      SvNote(title: 'Chưa tạo được tài khoản', message: _error),
                    ],
                    if (_scanNote != null) ...<Widget>[
                      const SizedBox(height: SvSpace.s3),
                      SvNote(title: 'Mã mời hợp lệ', message: _scanNote, tone: SvNoteTone.soft),
                    ],
                    if (widget.viaInvite) ...<Widget>[
                      const SizedBox(height: SvSpace.s4),
                      if (widget.onScanInvite != null)
                        FilledButton.icon(
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Quét QR mời'),
                          onPressed: busy ? null : _scan,
                        ),
                      const SizedBox(height: SvSpace.s3),
                      TextFormField(
                        controller: _invite,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: 'Mã mời', hintText: 'SV-A03-7K2Q'),
                        validator: (String? v) => validateInviteCode(v, required: true),
                      ),
                    ],
                    const SizedBox(height: SvSpace.s4),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.name],
                      decoration: const InputDecoration(labelText: 'Họ và tên', hintText: 'Nguyễn Văn An'),
                      validator: validateName,
                    ),
                    const SizedBox(height: SvSpace.s4),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Email', hintText: 'ban@example.com'),
                      validator: validateEmail,
                    ),
                    const SizedBox(height: SvSpace.s4),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Ít nhất $kMinPasswordLength ký tự',
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: validateNewPassword,
                    ),
                    const SizedBox(height: SvSpace.s4),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu'),
                      validator: (String? v) => validateConfirmPassword(v, _password.text),
                      onFieldSubmitted: (_) => busy ? null : _submit(),
                    ),
                    const SizedBox(height: SvSpace.s6),
                    FilledButton(
                      onPressed: busy ? null : _submit,
                      child: Text(busy ? 'Đang tạo tài khoản…' : 'Tạo tài khoản'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
