import 'package:flutter/material.dart';
import 'package:lumina/shared/widgets/lumina_placeholder_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DailyLogScreen extends StatelessWidget {
  const DailyLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LuminaPlaceholderScreen(
      title: 'Daily Log',
      subtitle: 'A calm place to capture mood, energy, tasks, and notes.',
      icon: PhosphorIcons.pencilLine(PhosphorIconsStyle.fill),
    );
  }
}
