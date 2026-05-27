import 'package:flutter/material.dart';
import 'package:lumina/shared/widgets/custom_bottom_nav_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  int get _currentIndex {
    final index = luminaDestinations.indexWhere(
      (item) => location.startsWith(item.path),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavBar(currentIndex: _currentIndex),
    );
  }
}
