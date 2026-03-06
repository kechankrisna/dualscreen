/// `dualscreen` — Flutter plugin for multi-window (desktop) and
/// dual-display / secondary-screen (Android POS) support.
///
/// ## Usage
///
/// ```dart
/// import 'package:dualscreen/dualscreen.dart';
///
/// final manager = await MultiWindowManager.instance();
///
/// if (await manager.isSupported()) {
///   // Desktop: open a new independent OS window
///   await manager.openSubWindow({'title': 'My Sub Window'});
///
///   // Android POS: push a state to the customer-facing display
///   await manager.sendStateToSubDisplay(
///     OrderSummaryState(items: cart, total: 49.99),
///   );
/// }
/// ```
///
/// The Android sub-screen requires a Dart entry point annotated with
/// `@pragma('vm:entry-point')` named `subScreenMain` in your app:
///
/// ```dart
/// @pragma('vm:entry-point')
/// void subScreenMain() {
///   WidgetsFlutterBinding.ensureInitialized();
///   runApp(const MySubScreenApp());
/// }
/// ```
library dualscreen;

export 'src/multi_window_manager.dart';
export 'src/sub_display_state.dart';
