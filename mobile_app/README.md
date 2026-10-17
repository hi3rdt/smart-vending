# Smart Vending — mobile app UI (Flutter)

Customer and admin app for the Smart Grab-and-Go vending cabinet. This folder holds the **UI foundation**: design tokens, light/dark theme, core widgets, the product catalog of cabinet A-03 and the logo assets. Screens and networking (session/cart WebSocket, wallet API) build on top of it.

## Design direction

- **Friendly, Vietnamese-first.** Customers only see three steps — *Quét mã → Lấy đồ → Đóng cửa*. The server's five session states (`authorized`, `unlocked`, `shopping`, `finalizing`, `completed`) stay internal (`customerStepOf()` maps them).
- **Colours come from the Open Cabinet logo.** Light: navy `#0E1B3D` leads (buttons, text), mint `#2EE6A8` highlights. Dark: mint leads on a navy night. Amber (`warm`) is only for gentle heads-ups (low balance, door left open). Every text/background pair is ≥ 4.5:1 in both themes.
- **Never claim a payment before the server confirms it.** The cart mirrors what the cabinet recorded; there is no pay button — closing the door pays.
- Full brand book (tokens, copy rules, component guidelines) lives in the **Smart Vending design system** artifact on Claude; ask Hiệp for access.

## Layout

```
lib/
  theme/sv_tokens.dart     SvColors (ThemeExtension, light + dark), SvSpace, SvRadius, SvLogo paths
  theme/sv_theme.dart      SvTheme.light() / SvTheme.dark() -> ThemeData (Be Vietnam Pro, buttons, inputs, nav bar)
  util/money.dart          formatVnd(25000) -> "25.000 ₫", formatDelta()
  data/catalog.dart        Product model + kCabinetA03 (4 SKUs, 2 shelves x 2 zones), weight-delta -> item count
  widgets/session_stepper.dart  3-step customer progress (driven by server state)
  widgets/cart.dart        CartLine, CartItemTile, SvCart (live cart, quantity bubbles, subtotal)
  widgets/logo.dart        SvLogoImage(kind: icon | horizontal | stacked) - picks the light or reversed file by theme
  widgets/note.dart        SvNote: warm (amber) / soft (mint) inline notes
  auth/auth_validators.dart  Email, password, name, invite-code validators (Vietnamese messages)
  auth/auth_repository.dart  AuthRepository contract + FakeAuthRepository (demo accounts, token rotation)
  auth/session_controller.dart  SessionController: sign-in/up/out, auto refresh before token expiry
  screens/auth/            LoginScreen, RegisterScreen (email or QR invite), ForgotPasswordScreen
  main.dart                Demo: sign in, then replay one shopping session against the widgets
assets/
  logo/                    6 SVGs: icon, horizontal, stacked x (light, _dark)
  app_icon/                icon_1024.png (opaque) + icon_foreground_1024.png (adaptive icon foreground)
test/widgets_test.dart     VND formatting, cart math, catalog/weight tolerance, stepper, logo paths
test/auth_test.dart        Validators, QR invite parsing, fake repo, token refresh, login screen
```

## Getting started

```bash
cd mobile_app
flutter create --platforms=android,ios .   # first time only: generates android/ and ios/, keeps lib/
flutter pub get
flutter test
dart run flutter_launcher_icons            # writes the app icon into android/ and ios/
flutter run
```

Requires Flutter ≥ 3.24 (Dart ≥ 3.5).

## Using the theme

```dart
MaterialApp(
  theme: SvTheme.light(),
  darkTheme: SvTheme.dark(),
  themeMode: ThemeMode.system,
);

// Inside a widget
final SvColors c = SvColors.of(context);   // tokens Material has no slot for (warm, brandSoft, ...)
Text(formatVnd(order.totalVnd), style: Theme.of(context).textTheme.titleLarge);
const SvLogoImage(kind: SvLogoKind.horizontal, height: 40);
```

## Sign-in

- Demo accounts (FakeAuthRepository): `demo@smartvending.vn` / `123456` (customer), `admin@smartvending.vn` / `admin123` (admin).
- Replace `FakeAuthRepository` with an HTTP client implementing `AuthRepository` (`/auth/login`, `/auth/register`, `/auth/refresh`, `/auth/forgot`). Store the refresh token with `flutter_secure_storage` and call `SessionController.restore()` at startup.
- `SessionController` refreshes the access token 60 s before expiry; if refresh fails the user is signed out and the login screen explains why.
- QR invite: pass `onScanInvite` (e.g. a `mobile_scanner` page returning the raw payload) to `LoginScreen`; `inviteCodeFromQr()` accepts a bare `SV-A03-7K2Q` or a link with `?code=`.
- Admin-only UI checks `user.canAdmin`; the server must enforce roles too.

## Rules for contributors

- Money is always `int` dong — never `double`.
- Drive `SessionStepper.state` and the cart only from server events; never from a client guess (e.g. door-closed alone ≠ completed).
- Use tokens (`SvColors`, `SvSpace`, `SvRadius`) instead of literal colours and sizes.
- UI copy in Vietnamese, sentence case, no all-caps; code, comments and docs in English.
- Logo files are used as supplied: pick the file by theme, never tint or redraw.

## Hardware note (catalog)

`Nabati` (52 ± 7 g) and `Pocky` (48 ± 7 g) overlap between 45–55 g. If shelf 2 uses one load cell for zones C and D, weight alone cannot tell them apart — the camera label (`nabati` / `pocky`) must decide. `Product.itemsFromWeightDelta()` returns `null` for ambiguous readings instead of guessing.
