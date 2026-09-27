import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mcdu_app/app/app.dart';
import 'package:mcdu_app/features/mcdu_core/domain/mcdu_key.dart';
import 'package:mcdu_app/features/mcdu_core/presentation/mcdu_keypad_overlay.dart';

void main() {
  testWidgets('MCDU App builds and dynamic display reflects MENU default state', (WidgetTester tester) async {
    await tester.pumpWidget(const MCDUApp());
    await tester.pumpAndSettle();

    // Verify debug indicator presence
    expect(find.text('KEY: '), findsOneWidget);
    expect(find.text('NONE'), findsOneWidget);

    // Verify default Dynamic Display content on MENU page
    expect(find.text('MCDU MENU'), findsOneWidget);
    expect(find.text('<FPL'), findsOneWidget);
    expect(find.text('<DIR'), findsOneWidget);
    expect(find.text('<PROG'), findsOneWidget);
    expect(find.text('NAV>'), findsOneWidget);
    expect(find.text('RADIO>'), findsOneWidget);
    expect(find.text('DATA>'), findsOneWidget);

    // Verify overlay presence
    expect(find.byType(MCDUKeypadOverlay), findsOneWidget);
  });

  testWidgets('UI Test: Page navigation, Scratchpad typing, CLR, and LSK transfer on subpage', (WidgetTester tester) async {
    await tester.pumpWidget(const MCDUApp());
    await tester.pumpAndSettle();

    final overlay = tester.widget<MCDUKeypadOverlay>(find.byType(MCDUKeypadOverlay));

    // 1. In MENU, press 1L to navigate to FPL
    overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
    await tester.pumpAndSettle();
    expect(find.text('MCDU FPL'), findsOneWidget);
    expect(find.text('FPL PAGE'), findsOneWidget);

    // 2. Type VTBD in scratchpad
    overlay.onKeyPressed(MCDUKeyEvent(keyId: 'V'));
    overlay.onKeyPressed(MCDUKeyEvent(keyId: 'T'));
    overlay.onKeyPressed(MCDUKeyEvent(keyId: 'B'));
    overlay.onKeyPressed(MCDUKeyEvent(keyId: 'D'));
    await tester.pumpAndSettle();
    expect(find.text('VTBD'), findsOneWidget);

    // 3. Press CLR -> VTB
    overlay.onKeyPressed(MCDUKeyEvent(keyId: MCDUKey.clr));
    await tester.pumpAndSettle();
    expect(find.text('VTB'), findsOneWidget);

    // 4. Press D -> VTBD
    overlay.onKeyPressed(MCDUKeyEvent(keyId: 'D'));
    await tester.pumpAndSettle();
    expect(find.text('VTBD'), findsOneWidget);

    // 5. Transfer to LSK 1L on FPL page
    overlay.onKeyPressed(MCDUKeyEvent(keyId: '1L'));
    await tester.pumpAndSettle();
    expect(find.text('VTBD'), findsOneWidget);

    // 6. Test PREV returns to MENU
    overlay.onKeyPressed(MCDUKeyEvent(keyId: MCDUKey.prev));
    await tester.pumpAndSettle();
    expect(find.text('MCDU MENU'), findsOneWidget);

    // 7. Test NEXT returns forward to FPL
    overlay.onKeyPressed(MCDUKeyEvent(keyId: MCDUKey.next));
    await tester.pumpAndSettle();
    expect(find.text('MCDU FPL'), findsOneWidget);
  });

  testWidgets('18 & 19. MCDU Frame maintains 707:961 aspect ratio in portrait and landscape bounds', (WidgetTester tester) async {
    // Test Portrait (e.g. iPad portrait: 820 x 1180)
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MCDUApp());
    await tester.pumpAndSettle();
    expect(find.byType(AspectRatio), findsOneWidget);
    final portraitAspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(portraitAspectRatio.aspectRatio, closeTo(707 / 961, 0.001));

    // Test Landscape (e.g. iPad landscape: 1180 x 820)
    tester.view.physicalSize = const Size(1180, 820);
    await tester.pumpWidget(const MCDUApp());
    await tester.pumpAndSettle();
    final landscapeAspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(landscapeAspectRatio.aspectRatio, closeTo(707 / 961, 0.001));
  });
}
