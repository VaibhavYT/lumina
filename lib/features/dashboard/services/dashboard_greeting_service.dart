import 'package:intl/intl.dart';
import 'package:lumina/core/constants/app_constants.dart';
import 'package:lumina/core/data/lumina_models.dart';

class DashboardGreetingService {
  const DashboardGreetingService();

  String greeting({String name = AppConstants.defaultDisplayName}) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    }
    if (hour >= 12 && hour < 18) {
      return 'Good Afternoon';
    }
    if (hour >= 18 && hour < 22) {
      return 'Good Evening';
    }
    return 'Late Night, $name';
  }

  String subtitle({
    MoodEntry? moodEntry,
    required int completedTasks,
    required int totalTasks,
  }) {
    if (totalTasks > 0 && completedTasks == totalTasks) {
      return 'All tasks done. Strong day.';
    }
    if (moodEntry != null) {
      return "You're feeling ${moodEntry.label} today. Let's make it count.";
    }
    return "How's your day shaping up?";
  }

  String formattedDate() {
    return DateFormat('EEEE, d MMMM').format(DateTime.now());
  }
}
