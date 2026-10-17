// Đăng nhập: email + password, links to forgot-password and the two sign-up
// paths (email, QR invite). Errors follow the brand book: inline under the
// field for input problems, a warm note for a rejected sign-in.

import 'package:flutter/material.dart';

import '../../auth/auth_repository.dart';
import '../../auth/auth_validators.dart';
import '../../auth/session_controller.dart';
import '../../theme/sv_tokens.dart';
import '../../widgets/logo.dart';
import '../../widgets/note.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.session, this.onScanInvite, this.showDemoAccounts = false});

  final SessionController session;

  /// Opens the camera and returns the scanned invite payload (null if cancelled).
  /// Wire to mobile_scanner in the app shell; when null, the invite path asks
  /// for the code by hand.
  final Future<String?> Function()? onScanInvite;

  /// Shows the demo accounts card (FakeAuthRepository only).
  final bool showDemoAccounts;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _submitted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.session.lastSignOutReason; // e.g. session expired
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    try {
      await widget.session.signIn(_email.text.trim(), _password.text);
      // The app shell listens to SessionController and swaps to Home.
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _password.clear();
      });
    }
  }

  void _fill(String email, String pw) {
    _email.text = email;
    _password.text = pw;
    setState(() => _error = null);
  }

  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final SvColors c = SvColors.of(context);
    final TextTheme t = Theme.of(context).textTheme;

    return Scaffold(
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
                  padding: const EdgeInsets.fromLTRB(SvSpace.s4, SvSpace.s6, SvSpace.s4, SvSpace.s6),
                  children: <Widget>[
                    const Center(child: SvLogoImage(kind: SvLogoKind.icon, height: 64)),
                    const SizedBox(height: SvSpace.s2),
                    Text('Smart Vending', textAlign: TextAlign.center, style: t.titleLarge),
                    Text('Quét mã, lấy đồ, đóng cửa là xong.', textAlign: TextAlign.center, style: t.bodySmall),
                    const SizedBox(height: SvSpace.s6),
                    Text('Đăng nhập', style: t.titleLarge),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: SvSpace.s3),
                      SvNote(title: 'Chưa đăng nhập được', message: _error),
                    ],
                    const SizedBox(height: SvSpace.s4),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.username, AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Email', hintText: 'ban@example.com'),
                      validator: validateEmail,
                      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: SvSpace.s4),
                    TextFormField(
                      controller: _password,
                      focusNode: _passwordFocus,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Ít nhất 6 ký tự',
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: validateSignInPassword,
                      onFieldSubmitted: (_) => busy ? null : _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _open(ForgotPasswordScreen(session: widget.session, initialEmail: _email.text)),
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                    FilledButton(
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.inkMuted)),
                                const SizedBox(width: SvSpace.s2),
                                const Text('Đang đăng nhập…'),
                              ],
                            )
                          : const Text('Đăng nhập'),
                    ),
                    const SizedBox(height: SvSpace.s4),
                    Row(children: <Widget>[
                      const Expanded(child: Divider()),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: SvSpace.s3), child: Text('hoặc', style: t.bodySmall)),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: SvSpace.s4),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: const Text('Đăng ký nhanh bằng QR mời'),
                      onPressed: busy
                          ? null
                          : () => _open(RegisterScreen(session: widget.session, viaInvite: true, onScanInvite: widget.onScanInvite)),
                    ),
                    const SizedBox(height: SvSpace.s2),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text('Chưa có tài khoản?', style: t.bodySmall),
                        TextButton(
                          onPressed: busy ? null : () => _open(RegisterScreen(session: widget.session)),
                          child: const Text('Tạo bằng email'),
                        ),
                      ],
                    ),
                    if (widget.showDemoAccounts) ...<Widget>[
                      const SizedBox(height: SvSpace.s3),
                      _DemoAccounts(onFill: _fill),
                    ],
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

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.onFill});

  final void Function(String email, String password) onFill;

  @override
  Widget build(BuildContext context) {
    final SvColors c = SvColors.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(SvSpace.s3),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: SvRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Tài khoản demo', style: t.labelMedium),
          Text('Khách: demo@smartvending.vn · 123456\nQuản trị: admin@smartvending.vn · admin123', style: t.bodySmall),
          const SizedBox(height: SvSpace.s2),
          Wrap(spacing: SvSpace.s2, runSpacing: SvSpace.s2, children: <Widget>[
            OutlinedButton(onPressed: () => onFill('demo@smartvending.vn', '123456'), child: const Text('Điền tài khoản khách')),
            OutlinedButton(onPressed: () => onFill('admin@smartvending.vn', 'admin123'), child: const Text('Điền tài khoản quản trị')),
          ]),
        ],
      ),
    );
  }
}
