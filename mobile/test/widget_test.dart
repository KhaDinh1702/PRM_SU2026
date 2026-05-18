import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/main.dart';

void main() {
  testWidgets('Timer App initial state and presets test', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // 2. Verify that our initial timer is set to '25:00' (Focus Mode default).
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('TẠM DỪNG'), findsOneWidget);
    expect(find.text('FOCUS'), findsOneWidget);

    // 3. Tap the 'Short Break' preset button.
    await tester.tap(find.text('Short Break'));
    await tester.pumpAndSettle();

    // 4. Verify that the timer time changes to '05:00' and mode becomes 'SHORT BREAK'.
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('SHORT BREAK'), findsOneWidget);

    // 5. Tap the 'Long Break' preset button.
    await tester.tap(find.text('Long Break'));
    await tester.pumpAndSettle();

    // 6. Verify that the timer time changes to '15:00' and mode becomes 'LONG BREAK'.
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('LONG BREAK'), findsOneWidget);

    // 7. Test starting the timer by tapping the Play button.
    final playButton = find.byIcon(Icons.play_arrow_rounded);
    await tester.ensureVisible(playButton);
    await tester.tap(playButton);
    await tester.pump();

    // Verify it changed status text to 'TIẾN TRÌNH'
    expect(find.text('TIẾN TRÌNH'), findsOneWidget);
  });
}
