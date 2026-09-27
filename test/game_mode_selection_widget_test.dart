// test/game_mode_selection_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/game/domain/game_modes.dart';
import 'package:mcdu_app/features/game/presentation/game_mode_selection_screen.dart';
import 'package:mcdu_app/features/game/typing_test/presentation/typing_test_screen.dart';

void main() {
  group('Phase 15B GameModeSelectionScreen Widget Tests', () {
    // 1. GameModeSelectionScreen renders successfully
    testWidgets('1. GameModeSelectionScreen renders successfully', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameModeSelectionScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(GameModeSelectionScreen), findsOneWidget);
      expect(find.text('GAME MODES'), findsOneWidget);
      expect(find.text('Select a training game'), findsOneWidget);
    });

    // 2. Displays all 5 modes from GameModes.all
    testWidgets('2. Displays all 5 modes from GameModes.all', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameModeSelectionScreen()));
      await tester.pumpAndSettle();

      for (final mode in GameModes.all) {
        expect(find.text(mode.title), findsOneWidget);
      }
    });

    // 3. typing_test is visible, enabled, and shows PLAY
    testWidgets('3. typing_test is visible, enabled, and shows PLAY', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameModeSelectionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Typing Test'), findsOneWidget);
      final playButton = find.byKey(const Key('play_typing_test_button'));
      expect(playButton, findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
    });

    // 4. Other 4 modes are visible, disabled, and show COMING SOON
    testWidgets('4. Other 4 modes are visible, disabled, and show COMING SOON', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameModeSelectionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Word Rain'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Speed Run'), findsOneWidget);
      expect(find.text('MCDU Flow'), findsOneWidget);

      // Exactly 4 "COMING SOON" badges
      expect(find.text('COMING SOON'), findsNWidgets(4));
    });

    // 5. Tapping Typing Test navigates to TypingTestScreen showing READY and ABC123
    testWidgets('5. Tapping Typing Test navigates to TypingTestScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameModeSelectionScreen()));
      await tester.pumpAndSettle();

      final playButton = find.byKey(const Key('play_typing_test_button'));
      await tester.tap(playButton);
      await tester.pumpAndSettle();

      expect(find.byType(TypingTestScreen), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.text('ABC123'), findsOneWidget);
    });

    // 6. Back navigation returns to GameModeSelectionScreen
    testWidgets('6. Back navigation returns to GameModeSelectionScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameModeSelectionScreen()));
      await tester.pumpAndSettle();

      // Navigate to TypingTestScreen
      await tester.tap(find.byKey(const Key('play_typing_test_button')));
      await tester.pumpAndSettle();
      expect(find.byType(TypingTestScreen), findsOneWidget);

      // Pop back using Navigator
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.byType(GameModeSelectionScreen), findsOneWidget);
      expect(find.text('GAME MODES'), findsOneWidget);
    });

    // 7. Portrait layout has no overflow
    testWidgets('7. Portrait layout renders without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: GameModeSelectionScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GameModeSelectionScreen), findsOneWidget);
    });

    // 8. Landscape layout has no overflow
    testWidgets('8. Landscape layout renders without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1180, 820);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: GameModeSelectionScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GameModeSelectionScreen), findsOneWidget);
    });
  });
}
