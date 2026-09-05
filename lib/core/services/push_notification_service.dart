import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../../domain/repositories/user_repository.dart';
import '../../firebase_options.dart';
import '../utils/currency_formatter.dart';
import 'package:logger/logger.dart';

/// Service responsible for handling Firebase Cloud Messaging (FCM) push notifications.
///
/// **Payload Contract (expected from backend):**
/// ```json
/// {
///   "type": "sell" | "buy",
///   "ticker": "ENGRO",
///   "positionId": "...",
///   "alertId": "...",
///   "price": "123.45",
///   "targetPrice": "120.00"
/// }
/// ```
///
/// The backend sends this as a **data-only** message — deliberately no
/// `notification` field, so this contract (not FCM's own auto-display) is the
/// single source of truth for what the user sees and where a tap routes.
/// That means nothing shows up for free: every visible state (foreground,
/// background, terminated) has to build its own notification from `data`, and
/// that's what the functions in this file do.
///
/// The notification shows `targetPrice` (what the user actually set), not
/// `price` (the live price that made this fire) — those two only coincide by
/// chance, and showing the live price read as a bug: the user wants to see
/// the number they set, not whatever the market happened to be at.

const String _androidNotificationChannelId = 'stock_alerts';
const String _androidNotificationChannelName = 'Stock Alerts';
const String _androidNotificationChannelDescription =
    'Notifications for stock price alerts and updates';

/// Human-readable title/body derived from the payload contract above.
class NotificationContent {
  final String title;
  final String body;
  const NotificationContent({required this.title, required this.body});
}

/// Pure and top-level so it's usable from both the running app and the
/// background isolate below, and directly unit-testable without touching
/// Firebase or a widget tree.
///
/// Returns null for a malformed/unrecognised payload — untrusted input (it
/// arrives from outside the app) must degrade to "show nothing", never to a
/// confusing notification with blank or garbled text.
NotificationContent? buildNotificationContent(Map<String, dynamic> data) {
  final type = data['type'] as String?;
  final ticker = data['ticker'] as String?;
  if (ticker == null || ticker.isEmpty) return null;

  // FCM data payloads are always strings — a malformed/absent target price
  // falls back to a still-useful, if less specific, message rather than
  // showing nothing or crashing on untrusted input.
  final targetValue = double.tryParse(data['targetPrice']?.toString() ?? '');
  final targetText = targetValue != null ? ' at ${AppCurrencyFormatter.format(targetValue)}' : '';

  switch (type) {
    case 'sell':
      return NotificationContent(
        title: '$ticker hits your Sell target',
        body: '$ticker has reached your target price$targetText.',
      );
    case 'buy':
      return NotificationContent(
        title: '$ticker hits your Buy target',
        body: '$ticker has dropped to your target price$targetText.',
      );
    default:
      return null;
  }
}

NotificationDetails _notificationDetails() {
  const androidDetails = AndroidNotificationDetails(
    _androidNotificationChannelId,
    _androidNotificationChannelName,
    channelDescription: _androidNotificationChannelDescription,
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('stock_alert'),
  );
  const iosDetails = DarwinNotificationDetails(sound: 'stock_alert.wav');
  return const NotificationDetails(android: androidDetails, iOS: iosDetails);
}

InitializationSettings _initializationSettings() {
  // 'ic_launcher' only exists as a mipmap resource (the adaptive launcher
  // icon) — flutter_local_notifications requires a drawable, which only
  // 'ic_launcher_foreground' (the adaptive icon's foreground layer) is.
  const androidInit = AndroidInitializationSettings('ic_launcher_foreground');
  const iosInit = DarwinInitializationSettings();
  return const InitializationSettings(android: androidInit, iOS: iosInit);
}

/// Fires when a data-only FCM message arrives while the app is backgrounded
/// *or fully terminated*. Android/iOS spin up a throwaway isolate purely to
/// run this — nothing else in the app is alive, which is why it must be a
/// top-level function (not a method) and reinitialise everything it needs
/// from scratch, including Firebase itself.
///
/// This is the missing piece that made push alerts invisible whenever the
/// app was closed: without a registered background handler, a data-only
/// message (which is all the backend ever sends) has no automatic display at
/// all — FCM's own system-tray rendering only ever triggers for a
/// `notification` field, which this payload deliberately doesn't have.
///
/// [localNotifications] is test-only injection — an optional named parameter
/// keeps this assignable to FCM's required `Future<void> Function(RemoteMessage)`
/// handler signature, so production registration is unaffected.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message, {
  FlutterLocalNotificationsPlugin? localNotifications,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  final content = buildNotificationContent(message.data);
  if (content == null) return;

  final notifications = localNotifications ?? FlutterLocalNotificationsPlugin();
  await notifications.initialize(settings: _initializationSettings());
  await notifications.show(
    id: message.hashCode,
    title: content.title,
    body: content.body,
    notificationDetails: _notificationDetails(),
    payload: jsonEncode(message.data),
  );
}

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging;
  final UserRepository _userRepository;
  final GoRouter _router;
  final Logger _logger;
  final FlutterLocalNotificationsPlugin _localNotifications;

  bool _isInitialized = false;

  // Process-lifetime, not instance-lifetime: a new PushNotificationService is
  // constructed for every signed-in user (pushNotificationServiceProvider
  // depends on userRepositoryProvider), but getInitialMessage() and
  // getNotificationAppLaunchDetails() both describe how the OS process was
  // launched — that fact doesn't change on a logout/login inside the same
  // running app. Without this guard, switching accounts replayed whatever
  // notification originally cold-started the app and re-routed to its
  // ticker, even for a brand-new account with no such position.
  static bool _coldStartRouteHandled = false;

  @visibleForTesting
  static void resetColdStartRouteHandledForTesting() {
    _coldStartRouteHandled = false;
  }

  PushNotificationService({
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    required UserRepository userRepository,
    required GoRouter router,
  })  : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _userRepository = userRepository,
        _router = router,
        _logger = Logger();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Request permission
      // Handles denial gracefully (no loop, no error thrown).
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        _logger.i('Push notification permission denied by user.');
        // User denied permission; we continue without push notifications.
        _isInitialized = true;
        return;
      }

      // 2. Setup Local Notifications (for foreground + background display)
      await _localNotifications.initialize(
        settings: _initializationSettings(),
        onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      );

      // 3. Get initial token and listen for refresh
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _userRepository.savePushToken(token);
      }
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _userRepository.savePushToken(newToken);
      });

      // 4. Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // 5. Listen to background taps
      FirebaseMessaging.onMessageOpenedApp.listen(_routeMessage);

      // 6. Handle cold start. Two distinct origins, since this app only ever
      // sends data-only messages:
      //
      //   A) FirebaseMessaging.getInitialMessage() — the app was launched by
      //      tapping an OS-auto-displayed notification. Never actually
      //      happens with this payload contract today (that requires a
      //      `notification` field), but costs nothing to keep as a defensive
      //      fallback in case that ever changes.
      //   B) _localNotifications.getNotificationAppLaunchDetails() — the app
      //      was launched by tapping a notification *we* displayed manually
      //      (via the background handler above, or _onForegroundMessage).
      //      This is what actually fires today. FCM's own getInitialMessage
      //      has no visibility into a locally-shown notification at all.
      if (!_coldStartRouteHandled) {
        _coldStartRouteHandled = true;
        final initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          // Defer routing slightly to allow app to fully mount
          Future.delayed(const Duration(milliseconds: 500), () {
            _routeMessage(initialMessage);
          });
        } else {
          final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
          final payload = launchDetails?.notificationResponse?.payload;
          if (launchDetails?.didNotificationLaunchApp == true && payload != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _routeFromPayload(payload);
            });
          }
        }
      }

      _isInitialized = true;
    } catch (e) {
      _logger.e('Failed to initialize push notifications: $e');
    }
  }

  /// `FirebaseMessaging.onMessage` is a static stream, which Mockito cannot
  /// intercept — this exists purely so a test can drive the same logic
  /// `_onForegroundMessage` runs with a synthetic [RemoteMessage], without
  /// needing the real stream.
  @visibleForTesting
  void handleForegroundMessageForTesting(RemoteMessage message) => _onForegroundMessage(message);

  void _onForegroundMessage(RemoteMessage message) {
    // The backend never sets `notification` (see the payload contract at the
    // top of this file) — content is always built from `data`. Reading
    // `message.notification` first is kept only as a defensive fallback for
    // a manually-sent test message (e.g. Firebase Console), which does
    // attach one; production alerts never take that branch.
    final notification = message.notification;
    final content = notification != null
        ? NotificationContent(title: notification.title ?? '', body: notification.body ?? '')
        : buildNotificationContent(message.data);

    if (content == null) return;

    _localNotifications.show(
      id: message.hashCode,
      title: content.title,
      body: content.body,
      notificationDetails: _notificationDetails(),
      payload: jsonEncode(message.data),
    );
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      _routeFromPayload(response.payload!);
    }
  }

  void _routeFromPayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _routeData(data);
    } catch (e) {
      _logger.e('Error parsing local notification payload: $e');
    }
  }

  void _routeMessage(RemoteMessage message) {
    _routeData(message.data);
  }

  void _routeData(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String?;
      final ticker = data['ticker'] as String?;

      if ((type == 'sell' || type == 'buy') && ticker != null && ticker.isNotEmpty) {
        _router.push('/stock/$ticker');
      } else {
        // Unknown or malformed payload -> fallback to dashboard
        _router.go('/');
      }
    } catch (e) {
      _logger.e('Error routing push notification: $e');
      _router.go('/');
    }
  }
}
