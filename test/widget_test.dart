// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:raco/main.dart';
import 'package:raco/core/services/settings_service.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Create a mock SettingsService for testing
    final settingsService = SettingsService();
    await settingsService.init();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(settingsService: settingsService));

    // Verify that the app loads with the home view
    // The app should show the "Pendientes" title in the app bar
    expect(find.text('Pendientes'), findsOneWidget);
  });
}
