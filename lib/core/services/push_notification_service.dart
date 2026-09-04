import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../../domain/repositories/user_repository.dart';
import 'package:logger/logger.dart';

/// Service responsible for handling Firebase Cloud Messaging (FCM) push notifications.
///
/// **Payload Contract (expected from backend):**
/// ```json
/// {
///   "type": "sell" | "buy",
///   "ticker": "ENGRO",
///   "positionId": "...",
///   "alertId": "..."
/// }
/// ```
class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging;
  final UserRepository _userRepository;
  final GoRouter _router;
  final Logger _logger;
  final FlutterLocalNotificationsPlugin _localNotifications;

  bool _isInitialized = false;

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

      // 2. Setup Local Notifications (for foreground display on Android)
      // 'ic_launcher' only exists as a mipmap resource (the adaptive launcher
      // icon) — flutter_local_notifications requires a drawable, which only
      // 'ic_launcher_foreground' (the adaptive icon's foreground layer) is.
      const androidInit = AndroidInitializationSettings('ic_launcher_foreground');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _localNotifications.initialize(
        settings: initSettings,
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

      // 6. Handle cold start from terminated state
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        // Defer routing slightly to allow app to fully mount
        Future.delayed(const Duration(milliseconds: 500), () {
          _routeMessage(initialMessage);
        });
      }

      _isInitialized = true;
    } catch (e) {
      _logger.e('Failed to initialize push notifications: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;

    if (notification != null) {
      // Use standard system sound or custom sound if provided
      const androidDetails = AndroidNotificationDetails(
        'stock_alerts', // Channel ID
        'Stock Alerts', // Channel Name
        channelDescription: 'Notifications for stock price alerts and updates',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('stock_alert'),
      );
      const iosDetails = DarwinNotificationDetails(
        sound: 'stock_alert.wav',
      );
      const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: notificationDetails,
        payload: jsonEncode(message.data),
      );
    }
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _routeData(data);
      } catch (e) {
        _logger.e('Error parsing local notification payload: $e');
      }
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
