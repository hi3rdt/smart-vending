import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_vending_ui/data/catalog.dart';
import 'package:smart_vending_ui/theme/sv_theme.dart';
import 'package:smart_vending_ui/theme/sv_tokens.dart';
import 'package:smart_vending_ui/util/money.dart';
import 'package:smart_vending_ui/widgets/cart.dart';
import 'package:smart_vending_ui/widgets/session_stepper.dart';

Widget _host(Widget child, {bool dark = false}) => MaterialApp(
      theme: dark ? SvTheme.dark(googleFonts: false) : SvTheme.light(googleFonts: false),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  group('formatVnd', () {
    test('groups thousands with dots and puts the symbol after a NBSP', () {
      expect(formatVnd(0), '0 ₫');
      expect(formatVnd(999), '999 ₫');
      expect(formatVnd(1000), '1.000 ₫');
      expect(formatVnd(25000), '25.000 ₫');
      expect(formatVnd(1234567), '1.234.567 ₫');
    });
    test('uses a true minus sign and optional plus', () {
      expect(formatVnd(-5000), '−5.000 ₫');
      expect(formatVnd(5000, signed: true), '+5.000 ₫');
    });
    test('formatDelta', () {
      expect(formatDelta(3), '+3');
      expect(formatDelta(-2), '−2');
      expect(formatDelta(0), '0');
    });
  });

  group('cart math', () {
    const List<CartLine> lines = <CartLine>[
      CartLine(sku: 'A', name: 'Coke', quantity: 2, unitPrice: 12000),
      CartLine(sku: 'B', name: 'Oishi', quantity: 1, unitPrice: 8000),
      CartLine(sku: 'C', name: 'Lavie', quantity: 1, unitPrice: 6000, change: CartChange.removed),
      CartLine(sku: 'D', name: 'Zero', quantity: 0, unitPrice: 9000),
    ];
    test('removed and zero-quantity lines are excluded', () {
      expect(cartSubtotal(lines), 32000);
      expect(cartItemCount(lines), 3);
    });
  });

  testWidgets('SvCart renders lines, badge and subtotal in both themes', (WidgetTester tester) async {
    const List<CartLine> lines = <CartLine>[
      CartLine(sku: 'A', name: 'Coca-Cola lon 330 ml', quantity: 2, unitPrice: 12000, change: CartChange.added),
      CartLine(sku: 'B', name: 'Nước suối Lavie 500 ml', quantity: 0, unitPrice: 6000, change: CartChange.removed),
    ];
    for (final bool dark in <bool>[false, true]) {
      await tester.pumpWidget(_host(const SvCart(lines: lines, live: true), dark: dark));
      await tester.pumpAndSettle();
      expect(find.text('Giỏ hàng của bạn'), findsOneWidget);
      expect(find.text(formatVnd(24000)), findsOneWidget); // subtotal
      expect(find.text('Tạm tính (2 món)'), findsOneWidget);
      expect(find.text('2'), findsNWidgets(2)); // count badge + quantity bubble
      expect(tester.takeException(), isNull);
    }
  });

  test('five server states map onto three customer steps', () {
    expect(customerStepOf(SessionState.authorized), 0);
    expect(customerStepOf(SessionState.unlocked), 1);
    expect(customerStepOf(SessionState.shopping), 1);
    expect(customerStepOf(SessionState.finalizing), 2);
    expect(customerStepOf(SessionState.completed), 3);
  });

  testWidgets('SessionStepper shows the three Vietnamese steps in every state', (WidgetTester tester) async {
    for (final SessionState s in SessionState.values) {
      await tester.pumpWidget(_host(SessionStepper(state: s)));
      // `finalizing` shows a looping spinner, so pump a frame instead of settling.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Quét mã'), findsOneWidget);
      expect(find.text('Lấy đồ'), findsOneWidget);
      expect(find.text('Đóng cửa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    // Server state names never reach the customer.
    expect(find.textContaining('Finalizing'), findsNothing);
  });

  testWidgets('SessionStepper fits a 320px-wide phone without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(const SessionStepper(state: SessionState.finalizing, failed: true)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('catalog', () {
    test('cabinet A-03 holds 4 products, 6 items, all 12.000 ₫', () {
      expect(kCabinetA03.length, 4);
      expect(kCabinetA03.fold<int>(0, (int s, Product p) => s + p.initialStock), 6);
      expect(kCabinetA03.every((Product p) => p.priceVnd == 12000), isTrue);
      expect(kCabinetA03.map((Product p) => p.sku).toSet().length, 4); // unique SKUs
    });

    test('weight delta -> item count respects tolerance', () {
      final Product milo = productBySku('milo_180ml')!;
      expect(milo.itemsFromWeightDelta(-190), -1);
      expect(milo.itemsFromWeightDelta(-181), -1); // within ±12 g
      expect(milo.itemsFromWeightDelta(-380), -2);
      expect(milo.itemsFromWeightDelta(195), 1); // put back
      expect(milo.itemsFromWeightDelta(-60), isNull); // noise / foreign object
      expect(milo.itemsFromWeightDelta(-285), isNull); // between 1 and 2 items

      final Product pocky = productByAiLabel('pocky')!;
      expect(pocky.itemsFromWeightDelta(-48), -1);
      expect(pocky.itemsFromWeightDelta(-56), isNull); // 8 g off > ±7 g
    });
  });

  test('logo paths: one light and one reversed file per arrangement', () {
    expect(SvLogo.path(SvLogoKind.icon, Brightness.light), 'assets/logo/A-open-cabinet_icon.svg');
    expect(SvLogo.path(SvLogoKind.stacked, Brightness.dark), 'assets/logo/A-open-cabinet_lockup-stacked_dark.svg');
    expect(SvLogo.all.toSet().length, 6);
  });
}
