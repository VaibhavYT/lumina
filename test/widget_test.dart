import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/main.dart';
import 'package:lumina/shared/widgets/custom_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Lumina app shell renders dashboard and navigation', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: AppRoot()));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(
      find.text('Your daily growth companion begins here.'),
      findsOneWidget,
    );
    expect(find.byType(CustomBottomNavBar), findsOneWidget);
  });
}
