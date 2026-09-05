import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/push_notification_service.dart';
import 'repository_providers.dart';
import '../presentation/routing/app_router.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService?>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final router = ref.watch(appRouterProvider);

  if (userRepository == null) return null;

  return PushNotificationService(
    userRepository: userRepository,
    router: router,
  );
});
