import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/main.dart';
import 'package:lumina/shared/widgets/custom_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    final hiveDir = Directory('C:/tmp/lumina_hive_test')
      ..createSync(recursive: true);
    Hive.init(hiveDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('Lumina app shell renders dashboard and navigation', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: AppRoot()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.byType(CustomBottomNavBar), findsOneWidget);
  });
}
