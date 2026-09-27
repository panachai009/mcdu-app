// test/mcdu_operating_mode_test.dart
// Unit and Widget tests for MCDUOperatingMode foundation and transitions.

import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/domain/mcdu_operating_mode.dart';
import 'package:mcdu_app/features/mcdu_core/engine/mcdu_page_engine.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';

void main() {
  group('Phase 19B MCDUOperatingMode Foundation Tests', () {
    test('1. Enum contains realistic and game modes', () {
      expect(MCDUOperatingMode.values, contains(MCDUOperatingMode.realistic));
      expect(MCDUOperatingMode.values, contains(MCDUOperatingMode.game));
      expect(MCDUOperatingMode.values.length, 2);
    });

    test('2. MCDUPageEngine catalog contains MENU, GAME, and REALISTIC placeholder', () {
      expect(MCDUPageEngine.catalog.containsKey('MENU'), isTrue);
      expect(MCDUPageEngine.catalog.containsKey('GAME'), isTrue);
      expect(MCDUPageEngine.catalog.containsKey('REALISTIC'), isTrue);

      final menu = MCDUPageEngine.catalog['MENU']!;
      expect(menu.leftLabels[3], '<GAMES');
      expect(menu.leftLabels[4], '<REALISTIC');

      final realistic = MCDUPageEngine.catalog['REALISTIC']!;
      expect(realistic.title, 'REALISTIC MCDU');
      expect(realistic.lines, contains('AW139 FMS SIMULATION'));
      expect(realistic.leftLabels[5], '<MENU');
    });

    testWidgets('3. Default operating mode on startup is realistic, navigating to GAME sets game mode', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      expect(screenState.operatingMode, MCDUOperatingMode.realistic);
      expect(screenState.activeGameMode, isNull);

      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));

      // 4L navigates to GAME page
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      expect(screenState.operatingMode, MCDUOperatingMode.game);
      expect(screenState.activeGameMode, isNull);
      expect(find.text('MCDU GAME MENU'), findsOneWidget);

      // 6L RETURN navigates back to MENU
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(screenState.operatingMode, MCDUOperatingMode.realistic);
      expect(find.text('MCDU MENU'), findsOneWidget);
    });

    testWidgets('4. 5L from MENU enters REALISTIC placeholder page and 6L returns to MENU', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));

      // 5L enters REALISTIC
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '5L'));
      await tester.pumpAndSettle();

      expect(screenState.operatingMode, MCDUOperatingMode.realistic);
      expect(find.text('REALISTIC MCDU'), findsOneWidget);
      expect(find.text('AW139 FMS SIMULATION'), findsOneWidget);
      expect(find.text('PLACEHOLDER MODE'), findsOneWidget);
      expect(find.text('<MENU'), findsOneWidget);

      // 6L returns to MENU
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(find.text('MCDU MENU'), findsOneWidget);
      expect(screenState.operatingMode, MCDUOperatingMode.realistic);
    });

    testWidgets('5. Operating mode is game when minigame is active, returning to GAME retains game mode', (WidgetTester tester) async {
      await tester.pumpWidget(const MCDUApp(home: MCDUScreen()));
      await tester.pumpAndSettle();

      final screenState = tester.state<MCDUScreenState>(find.byType(MCDUScreen));
      final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));

      // 4L to GAME
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      // 4L on GAME page to SPEED RUN
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '4L'));
      await tester.pumpAndSettle();

      expect(screenState.operatingMode, MCDUOperatingMode.game);
      expect(screenState.activeGameMode, 'speed_run');

      // 6L ABORT returns to GAME menu
      overlay.onKeyPressed(MCDUKeyEvent(keyId: '6L'));
      await tester.pumpAndSettle();

      expect(screenState.operatingMode, MCDUOperatingMode.game);
      expect(screenState.activeGameMode, isNull);
      expect(find.text('MCDU GAME MENU'), findsOneWidget);
    });
  });
}
