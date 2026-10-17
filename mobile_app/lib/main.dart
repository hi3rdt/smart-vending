// Demo: replays a shopping session (normal purchase + put-back) against the
// widgets, the way the app reacts to server events. Swap `_DemoSession` for the
// real WebSocket/SSE stream of session + cart events from your backend.

import 'dart:async';

import 'package:flutter/material.dart';

import 'data/catalog.dart';
import 'theme/sv_theme.dart';
import 'theme/sv_tokens.dart';
import 'util/money.dart';
import 'widgets/cart.dart';
import 'widgets/logo.dart';
import 'widgets/session_stepper.dart';

void main() => runApp(const SmartVendingDemoApp());

class SmartVendingDemoApp extends StatefulWidget {
  const SmartVendingDemoApp({super.key});

  @override
  State<SmartVendingDemoApp> createState() => _SmartVendingDemoAppState();
}

class _SmartVendingDemoAppState extends State<SmartVendingDemoApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Vending',
      debugShowCheckedModeBanner: false,
      theme: SvTheme.light(),
      darkTheme: SvTheme.dark(),
      themeMode: _mode,
      home: SessionScreen(
        // Starts from the system setting, then flips between explicit light/dark.
        onToggleTheme: () => setState(() {
          // No MediaQuery above MaterialApp yet, so read the platform directly.
          final bool systemDark =
              WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
          final bool isDark = _mode == ThemeMode.dark || (_mode == ThemeMode.system && systemDark);
          _mode = isDark ? ThemeMode.light : ThemeMode.dark;
        }),
      ),
    );
  }
}

/// One scripted server event.
typedef _Event = ({SessionState state, List<CartLine> lines, bool failed});

// Demo lines built from the real cabinet catalog.
final Product _milo = productBySku('milo_180ml')!;
final Product _pepsi = productBySku('pepsi_can_330ml')!;
final Product _nabati = productBySku('nabati_cheese_50g')!;
final Product _pocky = productBySku('pocky_strawberry_38g')!;

final List<_Event> _script = <_Event>[
  (state: SessionState.authorized, lines: const <CartLine>[], failed: false),
  (state: SessionState.unlocked, lines: const <CartLine>[], failed: false),
  (state: SessionState.shopping, lines: <CartLine>[_milo.toCartLine(1, change: CartChange.added)], failed: false),
  (
    state: SessionState.shopping,
    lines: <CartLine>[_milo.toCartLine(1), _pepsi.toCartLine(1, change: CartChange.added)],
    failed: false,
  ),
  (
    state: SessionState.shopping,
    lines: <CartLine>[_milo.toCartLine(1), _pepsi.toCartLine(1), _pocky.toCartLine(1, change: CartChange.added)],
    failed: false,
  ),
  (
    // Customer changes their mind and puts the Pocky back.
    state: SessionState.shopping,
    lines: <CartLine>[_milo.toCartLine(1), _pepsi.toCartLine(1), _pocky.toCartLine(0, change: CartChange.removed)],
    failed: false,
  ),
  (
    state: SessionState.shopping,
    lines: <CartLine>[_milo.toCartLine(1), _pepsi.toCartLine(1), _nabati.toCartLine(1, change: CartChange.added)],
    failed: false,
  ),
  (
    state: SessionState.finalizing,
    lines: <CartLine>[_milo.toCartLine(1), _pepsi.toCartLine(1), _nabati.toCartLine(1)],
    failed: false,
  ),
  (
    state: SessionState.completed,
    lines: <CartLine>[_milo.toCartLine(1), _pepsi.toCartLine(1), _nabati.toCartLine(1)],
    failed: false,
  ),
];

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  int _step = 0;
  Timer? _timer;

  _Event get _event => _script[_step];

  @override
  void initState() {
    super.initState();
    _schedule(); // no setState here: _step already starts at 0
  }

  void _replay() {
    setState(() => _step = 0);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    // 1.6 s per event is slow enough to read each state on a device.
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (Timer t) {
      if (!mounted || _step >= _script.length - 1) {
        t.cancel();
        return;
      }
      setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // avoid setState after dispose
    super.dispose();
  }

  String get _headline => switch (_event.state) {
        SessionState.authorized => 'Đang mở tủ…',
        SessionState.unlocked => 'Tủ mở rồi! Mời bạn lấy đồ',
        SessionState.shopping => 'Lấy thêm gì nữa không?',
        SessionState.finalizing => 'Đang tính tiền…',
        SessionState.completed => 'Xong rồi, cảm ơn bạn!',
      };

  @override
  Widget build(BuildContext context) {
    final SvColors c = SvColors.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final bool done = _event.state == SessionState.completed;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SvLogoImage(height: 28),
            const SizedBox(width: SvSpace.s2),
            Text('Tủ A-03', style: t.titleMedium),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Đổi giao diện sáng/tối',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.contrast_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(SvSpace.s4),
          children: <Widget>[
            const SizedBox(height: SvSpace.s4),
            Text(_headline, style: t.titleLarge),
            if (done)
              Padding(
                padding: const EdgeInsets.only(top: SvSpace.s1),
                child: Text(
                  'Đã trừ ${formatVnd(cartSubtotal(_event.lines))} trong ví',
                  style: t.bodyLarge?.copyWith(color: c.inkMuted),
                ),
              ),
            const SizedBox(height: SvSpace.s6),
            SessionStepper(state: _event.state, failed: _event.failed),
            const SizedBox(height: SvSpace.s6),
            SvCart(
              lines: _event.lines,
              live: _event.state == SessionState.unlocked || _event.state == SessionState.shopping,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(SvSpace.s4),
        child: FilledButton(
          onPressed: done ? _replay : null,
          child: Text(done ? 'Xem lại demo' : 'Đóng cửa là tự thanh toán'),
        ),
      ),
    );
  }
}
