import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/constants/app_constants.dart';

class OnboardingRepository {
  const OnboardingRepository();

  static const _completedKey = 'onboarding.completed.v1';

  bool get hasCompleted {
    return Hive.box<dynamic>(AppConstants.settingsBox).get(
          _completedKey,
          defaultValue: false,
        ) ==
        true;
  }

  Future<void> complete() {
    return Hive.box<dynamic>(
      AppConstants.settingsBox,
    ).put(_completedKey, true);
  }
}
