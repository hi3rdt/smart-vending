// SessionStepper - three friendly step pills for customers:
//   Quét mã -> Lấy đồ -> Đóng cửa
//
// The server keeps five states; customers never see their names:
//   authorized          -> step 1 "Quét mã"
//   unlocked, shopping  -> step 2 "Lấy đồ"
//   finalizing          -> step 3 "Đóng cửa" (spinner: "Đang tính tiền…")
//   completed           -> all steps done
//
// Rules (brand book):
//  * Drive `state` ONLY from the server, never from a client guess.
//  * `failed` (payment not taken) turns step 3 amber (SvColors.warm), never red:
//    pair it with the "Chưa trừ tiền đâu nhé" screen.

import 'package:flutter/material.dart';

import '../theme/sv_tokens.dart';

/// Server-side session states.
enum SessionState { authorized, unlocked, shopping, finalizing, completed }

/// Customer-facing step index (0..2), or 3 when everything is done.
int customerStepOf(SessionState s) => switch (s) {
      SessionState.authorized => 0,
      SessionState.unlocked || SessionState.shopping => 1,
      SessionState.finalizing => 2,
      SessionState.completed => 3,
    };

const List<String> kSvCustomerSteps = <String>['Quét mã', 'Lấy đồ', 'Đóng cửa'];

enum _PillStatus { done, current, waiting, warm, todo }

class SessionStepper extends StatelessWidget {
  const SessionStepper({super.key, required this.state, this.failed = false});

  final SessionState state;
  final bool failed;

  static const Duration _anim = Duration(milliseconds: 200);

  _PillStatus _statusOf(int index, int current) {
    if (index < current) return _PillStatus.done;
    if (index > current) return _PillStatus.todo;
    if (failed) return _PillStatus.warm;
    return state == SessionState.finalizing ? _PillStatus.waiting : _PillStatus.current;
  }

  String _semantics(int current) {
    if (current >= kSvCustomerSteps.length) return 'Đã mua xong';
    if (failed) return 'Chưa trừ tiền, cần nạp thêm để thanh toán';
    return 'Bước ${current + 1} trên 3: ${kSvCustomerSteps[current]}';
  }

  @override
  Widget build(BuildContext context) {
    final SvColors c = SvColors.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final int current = customerStepOf(state);

    return Semantics(
      container: true,
      liveRegion: true,
      label: _semantics(current),
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            for (int i = 0; i < kSvCustomerSteps.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: SvSpace.s2),
              Expanded(
                child: _StepPill(
                  index: i,
                  label: kSvCustomerSteps[i],
                  status: _statusOf(i, current),
                  colors: c,
                  text: t,
                  anim: reduceMotion ? Duration.zero : _anim,
                  spin: !reduceMotion,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.index,
    required this.label,
    required this.status,
    required this.colors,
    required this.text,
    required this.anim,
    required this.spin,
  });

  final int index;
  final String label;
  final _PillStatus status;
  final SvColors colors;
  final TextTheme text;
  final Duration anim;
  final bool spin;

  @override
  Widget build(BuildContext context) {
    final SvColors c = colors;
    final (Color bg, Color fg) = switch (status) {
      _PillStatus.done => (c.brand, c.onBrand),
      _PillStatus.current || _PillStatus.waiting => (c.brandSoft, c.brand),
      _PillStatus.warm => (c.warm, c.onWarm),
      _PillStatus.todo => (c.surfaceSunken, c.inkMuted),
    };

    final Widget marker = switch (status) {
      _PillStatus.done => Icon(Icons.check_rounded, size: 14, color: fg),
      _PillStatus.warm => Icon(Icons.priority_high_rounded, size: 14, color: fg),
      _PillStatus.waiting => SizedBox(
          width: 12,
          height: 12,
          child: spin
              ? CircularProgressIndicator(strokeWidth: 2, color: fg)
              : Icon(Icons.hourglass_top_rounded, size: 12, color: fg),
        ),
      _ => Text('${index + 1}', style: text.labelSmall?.copyWith(color: fg)),
    };

    return AnimatedContainer(
      duration: anim,
      height: 32,
      padding: const EdgeInsets.fromLTRB(5, 5, SvSpace.s2, 5),
      decoration: BoxDecoration(color: bg, borderRadius: SvRadius.pillAll),
      child: Row(
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status == _PillStatus.done ? Colors.transparent : c.surfaceRaised,
              border: status == _PillStatus.done ? Border.all(color: c.onBrand, width: 1.5) : null,
            ),
            child: marker,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
