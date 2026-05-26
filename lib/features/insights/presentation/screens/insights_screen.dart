import 'package:flutter/material.dart';
import 'package:lumina/shared/widgets/lumina_placeholder_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LuminaPlaceholderScreen(
      title: 'Insights',
      subtitle: 'Patterns and signals will gather here.',
      icon: PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
    );
  }
}
