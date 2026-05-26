import 'package:flutter/material.dart';
import 'package:lumina/shared/widgets/lumina_placeholder_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LuminaPlaceholderScreen(
      title: 'Dashboard',
      subtitle: 'Your daily growth companion begins here.',
      icon: PhosphorIcons.house(PhosphorIconsStyle.fill),
    );
  }
}
