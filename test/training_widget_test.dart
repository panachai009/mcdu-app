import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_screen.dart';
import 'package:mcdu_app/features/training/presentation/training_screen.dart';
import 'package:mcdu_app/features/training/presentation/training_status_panel.dart';

void main() {
  // 1. Default: Basic MCDU Flow, Step 1 / 8, Press MENU, READY
  testWidgets('1. TrainingScreen renders default Basic MCDU Flow at Step 1/8 with Press MENU', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(TrainingScreen), findsOneWidget);
    expect(find.byType(TrainingStatusPanel), findsOneWidget);
    expect(find.byType(MCDUScreen), findsOneWidget);

    expect(find.text('BASIC MCDU TRAINING'), findsOneWidget);
    expect(find.text('Basic MCDU Flow'), findsOneWidget);
    expect(find.text('Step 1 / 8'), findsOneWidget);
    expect(find.text('Press MENU key'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
  });

  // 2. Selector: Scenario selector displays all 4 options
  testWidgets('2. Scenario selector displays all 4 catalog scenarios', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
    await tester.pumpAndSettle();

    // Tap dropdown selector
    final dropdown = find.byType(DropdownButton<String>);
    expect(dropdown, findsOneWidget);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    // Verify all 4 scenario titles are visible in dropdown menu items
    expect(find.text('Basic MCDU Flow').hitTestable(), findsWidgets);
    expect(find.text('Scratchpad Input').hitTestable(), findsOneWidget);
    expect(find.text('LSK Data Entry').hitTestable(), findsOneWidget);
    expect(find.text('Page Navigation').hitTestable(), findsOneWidget);
  });

  // 3. Switch to Scratchpad: Step 1 / 7, Press A, Correct: 0, Errors: 0, READY
  testWidgets('3. Switch to Scratchpad Input initializes Step 1/7, Press A, counts 0, READY', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
    await tester.pumpAndSettle();

    // Tap dropdown and select Scratchpad Input
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scratchpad Input').hitTestable().last);
    await tester.pumpAndSettle();

    expect(find.text('Scratchpad Input'), findsOneWidget);
    expect(find.text('Step 1 / 7'), findsOneWidget);
    expect(find.text('Type A'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Errors'), findsOneWidget);
    expect(find.text('0'), findsWidgets); // Correct: 0, Errors: 0
    expect(find.text('READY'), findsOneWidget);
  });

  // 4. Switch to LSK: Step 1 / 6, Press M
  testWidgets('4. Switch to LSK Data Entry initializes Step 1/6, Press M', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LSK Data Entry').hitTestable().last);
    await tester.pumpAndSettle();

    expect(find.text('LSK Data Entry'), findsOneWidget);
    expect(find.text('Step 1 / 6'), findsOneWidget);
    expect(find.text('Type M'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
  });

  // 5. Switch to Page Navigation: Step 1 / 9, Press MENU
  testWidgets('5. Switch to Page Navigation initializes Step 1/9, Press MENU', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Page Navigation').hitTestable().last);
    await tester.pumpAndSettle();

    expect(find.text('Page Navigation'), findsOneWidget);
    expect(find.text('Step 1 / 9'), findsOneWidget);
    expect(find.text('Press MENU key'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
  });

  // 6 & 7. State Reset & MCDU Reset: In-progress state is cleared, MCDU returns to MENU, scratchpad empty
  testWidgets('6-7. Switching scenario resets in-progress counters and resets MCDU core to MENU', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
    await tester.pumpAndSettle();

    final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));

    // Progress in Basic MCDU Flow: press MENU (Step 1 -> 2), then press wrong key (error)
    overlay.onKeyPressed(MCDUKeyEvent(keyId: 'MENU'));
    await tester.pumpAndSettle();
    overlay.onKeyPressed(MCDUKeyEvent(keyId: 'DIR')); // Wrong key (expected FPL)
    await tester.pumpAndSettle();

    expect(find.text('Step 2 / 8'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // Correct: 1, Errors: 1

    // Switch to Scratchpad Input via selector
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scratchpad Input').hitTestable().last);
    await tester.pumpAndSettle();

    // Verify completely fresh training state
    expect(find.text('Step 1 / 7'), findsOneWidget);
    expect(find.text('Type A'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('MCDU MENU'), findsOneWidget); // MCDU core is at MENU page
  });

  // 8. Real Keypad: evaluate newly selected scenario via actual MCDU touch overlay
  testWidgets('8. Real MCDU keypad drives training evaluation in selected scenario', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
    await tester.pumpAndSettle();

    // Switch to Scratchpad Input (Step 1 expects A)
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scratchpad Input').hitTestable().last);
    await tester.pumpAndSettle();

    final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));

    // Press wrong key 'Z'
    overlay.onKeyPressed(MCDUKeyEvent(keyId: 'Z'));
    await tester.pumpAndSettle();
    expect(find.textContaining('INCORRECT'), findsOneWidget);
    expect(find.textContaining('Expected: A'), findsOneWidget);
    expect(find.textContaining('Pressed: Z'), findsOneWidget);
    expect(find.text('Step 1 / 7'), findsOneWidget);

    // Press correct key 'A'
    overlay.onKeyPressed(MCDUKeyEvent(keyId: 'A'));
    await tester.pumpAndSettle();
    expect(find.text('CORRECT'), findsOneWidget);
    expect(find.text('Step 2 / 7'), findsOneWidget);
  });

  // 9. Completion: Completing selected scenario displays TRAINING COMPLETE
  testWidgets('9. Completing newly selected scenario displays TRAINING COMPLETE', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
    await tester.pumpAndSettle();

    // Switch to LSK Data Entry (6 steps: M, O, D, 1, L, 1L)
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LSK Data Entry').hitTestable().last);
    await tester.pumpAndSettle();

    final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
    final sequence = ['M', 'O', 'D', '1', 'L', '1L'];
    for (final keyId in sequence) {
      overlay.onKeyPressed(MCDUKeyEvent(keyId: keyId));
      await tester.pumpAndSettle();
    }

    expect(find.text('TRAINING COMPLETE'), findsWidgets);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('Step 6 / 6'), findsOneWidget);
  });

  // 10. Existing flow still completes and resets
  testWidgets('10. Basic MCDU Flow completes and RESET restores default state', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
    await tester.pumpAndSettle();

    final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));
    final sequence = ['MENU', 'FPL', 'V', 'T', 'B', 'D', '1L', 'CLR'];
    for (final keyId in sequence) {
      overlay.onKeyPressed(MCDUKeyEvent(keyId: keyId));
      await tester.pumpAndSettle();
    }

    expect(find.text('TRAINING COMPLETE'), findsWidgets);
    expect(find.text('COMPLETED'), findsOneWidget);

    final resetButton = find.widgetWithText(ElevatedButton, 'RESET');
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    expect(find.text('Step 1 / 8'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('Press MENU key'), findsOneWidget);
    expect(find.text('MCDU MENU'), findsOneWidget);
  });

  testWidgets('Portrait and Landscape layout preserve 707:961 MCDU aspect ratio without overflow', (WidgetTester tester) async {
    // Portrait (820 x 1180)
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
    await tester.pumpAndSettle();

    final aspectRatios = tester.widgetList<AspectRatio>(find.byType(AspectRatio));
    for (final ar in aspectRatios) {
      expect(ar.aspectRatio, closeTo(707 / 961, 0.001));
    }

    // Landscape (1180 x 820)
    tester.view.physicalSize = const Size(1180, 820);
    await tester.pumpWidget(const MaterialApp(home: TrainingScreen()));
    await tester.pumpAndSettle();

    final landscapeAspectRatios = tester.widgetList<AspectRatio>(find.byType(AspectRatio));
    for (final ar in landscapeAspectRatios) {
      expect(ar.aspectRatio, closeTo(707 / 961, 0.001));
    }
  });
}
