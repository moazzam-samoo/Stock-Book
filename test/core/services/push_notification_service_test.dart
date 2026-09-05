import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_investment_tracker/core/services/push_notification_service.dart';
import 'package:stock_investment_tracker/domain/repositories/user_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';
import 'package:stock_investment_tracker/presentation/routing/app_router.dart';
import 'package:stock_investment_tracker/providers/push_notification_providers.dart';

import 'push_notification_service_test.mocks.dart';

@GenerateMocks([
  FirebaseMessaging,
  UserRepository,
  GoRouter,
  FlutterLocalNotificationsPlugin,
])
void main() {
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockUserRepository mockUserRepository;
  late MockGoRouter mockGoRouter;
  late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
  late PushNotificationService service;

  setUp(() {
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockUserRepository = MockUserRepository();
    mockGoRouter = MockGoRouter();
    mockLocalNotifications = MockFlutterLocalNotificationsPlugin();

    // Default mock setups
    when(mockFirebaseMessaging.requestPermission(
      alert: anyNamed('alert'),
      announcement: anyNamed('announcement'),
      badge: anyNamed('badge'),
      carPlay: anyNamed('carPlay'),
      criticalAlert: anyNamed('criticalAlert'),
      provisional: anyNamed('provisional'),
      sound: anyNamed('sound'),
    )).thenAnswer((_) async => const NotificationSettings(
          authorizationStatus: AuthorizationStatus.authorized,
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.disabled,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.disabled,
          criticalAlert: AppleNotificationSetting.disabled,
          sound: AppleNotificationSetting.enabled,
          timeSensitive: AppleNotificationSetting.disabled,
          providesAppNotificationSettings: AppleNotificationSetting.disabled,
          lockScreen: AppleNotificationSetting.enabled,
          notificationCenter: AppleNotificationSetting.enabled,
          showPreviews: AppleShowPreviewSetting.always,
        ));

    when(mockLocalNotifications.initialize(
      settings: anyNamed('settings'),
      onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse'),
      onDidReceiveBackgroundNotificationResponse: anyNamed('onDidReceiveBackgroundNotificationResponse'),
    )).thenAnswer((_) async => true);

    when(mockFirebaseMessaging.getToken()).thenAnswer((_) async => 'fake_token_123');
    when(mockFirebaseMessaging.onTokenRefresh).thenAnswer((_) => const Stream.empty());
    
    when(mockFirebaseMessaging.getInitialMessage()).thenAnswer((_) async => null);

    when(mockUserRepository.savePushToken(any)).thenAnswer((_) async => {});

    // Without this, an unstubbed push() throws MissingStubError inside
    // _routeData's try/catch, which silently falls back to go('/') — the
    // routing tests below would still pass (Mockito records a call as "made"
    // even when its stub throws), just for the wrong reason: verifying push
    // was attempted, not that routing actually succeeded without also
    // triggering the error-fallback path.
    when(mockGoRouter.push(any)).thenAnswer((_) async => null);

    service = PushNotificationService(
      firebaseMessaging: mockFirebaseMessaging,
      localNotifications: mockLocalNotifications,
      userRepository: mockUserRepository,
      router: mockGoRouter,
    );
  });

  test('1. Token persisted on init', () async {
    await service.initialize();
    verify(mockUserRepository.savePushToken('fake_token_123')).called(1);
  });

  test('2. onTokenRefresh re-persists', () async {
    when(mockFirebaseMessaging.onTokenRefresh).thenAnswer((_) => Stream.value('refreshed_token_456'));
    await service.initialize();
    // Flush microtasks
    await Future.delayed(Duration.zero);
    
    verify(mockUserRepository.savePushToken('fake_token_123')).called(1);
    verify(mockUserRepository.savePushToken('refreshed_token_456')).called(1);
  });

  test('3. Permission denied leaves app usable', () async {
    when(mockFirebaseMessaging.requestPermission(
      alert: anyNamed('alert'),
      announcement: anyNamed('announcement'),
      badge: anyNamed('badge'),
      carPlay: anyNamed('carPlay'),
      criticalAlert: anyNamed('criticalAlert'),
      provisional: anyNamed('provisional'),
      sound: anyNamed('sound'),
    )).thenAnswer((_) async => const NotificationSettings(
          authorizationStatus: AuthorizationStatus.denied,
          alert: AppleNotificationSetting.disabled,
          announcement: AppleNotificationSetting.disabled,
          badge: AppleNotificationSetting.disabled,
          carPlay: AppleNotificationSetting.disabled,
          criticalAlert: AppleNotificationSetting.disabled,
          sound: AppleNotificationSetting.disabled,
          timeSensitive: AppleNotificationSetting.disabled,
          providesAppNotificationSettings: AppleNotificationSetting.disabled,
          lockScreen: AppleNotificationSetting.disabled,
          notificationCenter: AppleNotificationSetting.disabled,
          showPreviews: AppleShowPreviewSetting.never,
        ));

    await service.initialize();
    // It should exit early, getToken should not be called
    verifyNever(mockFirebaseMessaging.getToken());
    verifyNever(mockUserRepository.savePushToken(any));
  });

  test('4. Route type: "sell" navigates to /stock/{ticker}', () {
    // We can test this by exposing the routing logic or by triggering the callback directly.
    // Let's invoke _routeData directly or simulate initial message.
    // We'll simulate getInitialMessage.
    final msg = RemoteMessage(data: {'type': 'sell', 'ticker': 'ENGRO'});
    when(mockFirebaseMessaging.getInitialMessage()).thenAnswer((_) async => msg);
    
    service.initialize();

    // We need a small delay since getInitialMessage routing is delayed by 500ms
    return Future.delayed(const Duration(milliseconds: 600), () {
      verify(mockGoRouter.push('/stock/ENGRO')).called(1);
      // Proves the success path was actually taken, not the error-fallback
      // path that a caught MissingStubError would silently trigger.
      verifyNever(mockGoRouter.go(any));
    });
  });

  test('5. Route type: "buy" navigates to /stock/{ticker}', () {
    final msg = RemoteMessage(data: {'type': 'buy', 'ticker': 'HUBC'});
    when(mockFirebaseMessaging.getInitialMessage()).thenAnswer((_) async => msg);
    
    service.initialize();

    return Future.delayed(const Duration(milliseconds: 600), () {
      verify(mockGoRouter.push('/stock/HUBC')).called(1);
      verifyNever(mockGoRouter.go(any));
    });
  });

  test('6. Malformed payload lands on dashboard', () {
    final msg = RemoteMessage(data: {'type': 'unknown', 'ticker': 'ENGRO'});
    when(mockFirebaseMessaging.getInitialMessage()).thenAnswer((_) async => msg);
    
    service.initialize();
    
    return Future.delayed(const Duration(milliseconds: 600), () {
      verify(mockGoRouter.go('/')).called(1);
    });
  });

  test('7. getInitialMessage cold start routes correctly', () {
    final msg = RemoteMessage(data: {'type': 'sell', 'ticker': 'LUCK'});
    when(mockFirebaseMessaging.getInitialMessage()).thenAnswer((_) async => msg);
    
    service.initialize();

    return Future.delayed(const Duration(milliseconds: 600), () {
      verify(mockGoRouter.push('/stock/LUCK')).called(1);
      verifyNever(mockGoRouter.go(any));
    });
  });

  test('calling initialize() twice only requests permission once', () async {
    // Not required test 8 (see below) — this is the double-init idempotency
    // guard (`_isInitialized`), a real behavior worth covering in its own
    // right, just not what "no uid" means.
    await service.initialize();
    await service.initialize();
    verify(mockFirebaseMessaging.requestPermission(
      alert: anyNamed('alert'),
      badge: anyNamed('badge'),
      sound: anyNamed('sound'),
    )).called(1);
  });

  test('8. No uid: pushNotificationServiceProvider resolves to null, a safe no-op', () {
    // This is a provider-level guarantee (userRepositoryProvider requires a
    // uid; pushNotificationServiceProvider requires a non-null repository),
    // not something the PushNotificationService class itself can be asked
    // about — so it's tested through a ProviderContainer, not through the
    // `service` instance the other tests above use.
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => null),
        // appRouterProvider's real definition needs Firebase Auth (via
        // authStateProvider) and Hive (via onboardingControllerProvider) —
        // neither is initialized in this plain Dart test, and this test
        // doesn't care about routing anyway, only about the "no uid" guard.
        appRouterProvider.overrideWith(
          (ref) => GoRouter(routes: [GoRoute(path: '/', builder: (context, state) => const SizedBox())]),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(pushNotificationServiceProvider), isNull);
  });
}
