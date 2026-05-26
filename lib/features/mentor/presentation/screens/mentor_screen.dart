import 'package:flutter/material.dart';
import 'package:lumina/shared/widgets/lumina_placeholder_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MentorScreen extends StatelessWidget {
  const MentorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LuminaPlaceholderScreen(
      title: 'Mentor',
      subtitle: 'Lumina will turn your logs into personal guidance.',
      icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
    );
  }
}
