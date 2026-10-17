// Live cart for a shopping session.
//
// The cart MIRRORS what the cabinet (cameras + load cells -> Raspberry Pi ->
// server) has recorded. The customer cannot edit quantities here, and there is
// no "Pay" button: payment happens server-side when the door closes.

import 'package:flutter/material.dart';

import '../theme/sv_theme.dart' show kSvTabular;
import '../theme/sv_tokens.dart';
import '../util/money.dart';

/// Latest cabinet event for a line.
enum CartChange { added, removed }

/// One cart line as reported by the server. Money is int dong (never double).
@immutable
class CartLine {
  const CartLine({
    required this.sku,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
    this.change,
  }) : assert(quantity >= 0),
       assert(unitPrice >= 0);

  final String sku;
  final String name;
  final int quantity;
  final int unitPrice;
  final String? imageUrl;
  final CartChange? change;

  bool get isRemoved => change == CartChange.removed || quantity == 0;

  /// Line total in dong; removed lines contribute 0.
  int get total => isRemoved ? 0 : quantity * unitPrice;

  CartLine copyWith({int? quantity, CartChange? change, bool clearChange = false}) => CartLine(
        sku: sku,
        name: name,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
        imageUrl: imageUrl,
        change: clearChange ? null : (change ?? this.change),
      );
}

/// Sum of live lines. Display-only: the server's finalized order is the
/// amount that is actually charged.
int cartSubtotal(Iterable<CartLine> lines) => lines.fold<int>(0, (int sum, CartLine l) => sum + l.total);

int cartItemCount(Iterable<CartLine> lines) =>
    lines.fold<int>(0, (int sum, CartLine l) => sum + (l.isRemoved ? 0 : l.quantity));

/// One product row: thumbnail, name, "qty × unit price", line total.
class CartItemTile extends StatefulWidget {
  const CartItemTile({super.key, required this.line});

  final CartLine line;

  @override
  State<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<CartItemTile> with SingleTickerProviderStateMixin {
  // One 200ms highlight when an item is (re-)added. No loops.
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1, // 1 = settled (no highlight)
  );

  @override
  void initState() {
    super.initState();
    if (widget.line.change == CartChange.added) _playFlash();
  }

  @override
  void didUpdateWidget(CartItemTile old) {
    super.didUpdateWidget(old);
    final bool becameAdded = widget.line.change == CartChange.added &&
        (old.line.change != CartChange.added || widget.line.quantity > old.line.quantity);
    if (becameAdded) _playFlash();
  }

  void _playFlash() {
    // Respect OS "reduce motion"; schedule after first frame so MediaQuery is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || MediaQuery.of(context).disableAnimations) return;
      _flash.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SvColors c = SvColors.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final CartLine line = widget.line;
    final bool removed = line.isRemoved;

    final String meta = removed ? 'Không tính tiền' : '${formatVnd(line.unitPrice)} / món';
    final String? note = line.change == CartChange.added
        ? 'Vừa lấy'
        : removed
            ? 'Đã trả lại kệ'
            : null;

    return MergeSemantics(
      child: AnimatedBuilder(
        animation: _flash,
        builder: (BuildContext context, Widget? child) => DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(c.surfaceSunken, c.surfaceSunken.withAlpha(0), _flash.value),
            borderRadius: SvRadius.smAll,
          ),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SvSpace.s3),
          child: Row(
            children: <Widget>[
              _Thumb(imageUrl: line.imageUrl, name: line.name),
              const SizedBox(width: SvSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      line.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(
                        color: removed ? c.inkMuted : c.ink,
                        decoration: removed ? TextDecoration.lineThrough : null,
                        decorationColor: c.inkMuted,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: meta,
                        style: t.bodySmall?.copyWith(fontFeatures: kSvTabular),
                        children: <InlineSpan>[
                          if (note != null)
                            TextSpan(
                              text: ' · $note',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: removed ? c.inkMuted : c.brand,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SvSpace.s3),
              // Big quantity bubble: easier to scan than a line total.
              Semantics(
                label: 'Số lượng ${removed ? 0 : line.quantity}',
                excludeSemantics: true,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: SvSpace.s2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: removed ? c.surfaceSunken : c.brandSoft,
                    borderRadius: SvRadius.pillAll,
                  ),
                  child: Text(
                    '${removed ? 0 : line.quantity}',
                    style: t.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: kSvTabular,
                      color: removed ? c.inkMuted : c.brand,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  static const double size = 48;

  @override
  Widget build(BuildContext context) {
    final SvColors c = SvColors.of(context);
    final Widget fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: c.surfaceSunken,
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: c.inkMuted),
      ),
    );

    return ClipRRect(
      borderRadius: SvRadius.smAll,
      child: imageUrl == null
          ? fallback
          : Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Decode at display size: product photos are often far larger than 48px.
              cacheWidth: (size * MediaQuery.of(context).devicePixelRatio).round(),
              errorBuilder: (_, __, ___) => fallback,
              excludeFromSemantics: true,
            ),
    );
  }
}

/// The live cart card: header, rows, subtotal.
class SvCart extends StatelessWidget {
  const SvCart({
    super.key,
    required this.lines,
    this.live = false,
    this.emptyText = 'Lấy một món trên kệ, giỏ sẽ tự hiện ở đây.',
  });

  /// Lines in first-pick-up order, keyed by SKU.
  final List<CartLine> lines;

  /// True while the session is unlocked/shopping (shows the live dot).
  final bool live;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final SvColors c = SvColors.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final int count = cartItemCount(lines);
    final int subtotal = cartSubtotal(lines);

    return Container(
      padding: const EdgeInsets.all(SvSpace.s4),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: SvRadius.lgAll,
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(header: true, child: Text('Giỏ hàng của bạn', style: t.titleMedium)),
                    Row(
                      children: <Widget>[
                        if (live) ...<Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: SvSpace.s2),
                        ],
                        Text('Tủ ghi nhận bằng cân + camera', style: t.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              Semantics(
                label: '$count món',
                excludeSemantics: true,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: SvSpace.s2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.accent, borderRadius: SvRadius.pillAll),
                  child: Text(
                    '$count',
                    style: t.labelSmall?.copyWith(color: c.onAccent, fontFeatures: kSvTabular),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SvSpace.s2),

          // Rows
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: SvSpace.s6),
              child: Column(
                children: <Widget>[
                  Icon(Icons.back_hand_outlined, size: 32, color: c.brand),
                  const SizedBox(height: SvSpace.s1),
                  Text('Giỏ hàng đang trống', style: t.titleSmall),
                  Text(emptyText, textAlign: TextAlign.center, style: t.bodySmall),
                ],
              ),
            )
          else
            for (int i = 0; i < lines.length; i++) ...<Widget>[
              if (i > 0) const Divider(),
              // Key by SKU so the row's flash state follows the product, not the index.
              CartItemTile(key: ValueKey<String>(lines[i].sku), line: lines[i]),
            ],

          // Footer
          const SizedBox(height: SvSpace.s1),
          const Divider(),
          const SizedBox(height: SvSpace.s3),
          Semantics(
            liveRegion: true, // announce subtotal changes to screen readers
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Tạm tính ($count món)', style: t.bodySmall),
                      Text(
                        formatVnd(subtotal),
                        style: t.titleLarge?.copyWith(fontFeatures: kSvTabular),
                      ),
                    ],
                  ),
                ),
                // Payment is automatic: remind instead of offering a pay button.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    'Đóng cửa là tự thanh toán',
                    textAlign: TextAlign.right,
                    style: t.labelSmall?.copyWith(color: c.inkMuted, fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
