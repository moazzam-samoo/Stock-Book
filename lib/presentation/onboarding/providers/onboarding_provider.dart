import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/local/local_storage.dart';

part 'onboarding_provider.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  bool build() {
    final box = Hive.box(LocalStorage.authBox);
    return box.get('onboarding_seen', defaultValue: false) as bool;
  }

  Future<void> completeOnboarding() async {
    final box = Hive.box(LocalStorage.authBox);
    await box.put('onboarding_seen', true);
    state = true;
  }
}
