import 'package:flutter/material.dart';
import '../domain/mcdu_key.dart';

/// Representation of a single MCDU key event.
class MCDUKeyEvent {
  final String keyId;
  final DateTime timestamp;

  MCDUKeyEvent({
    required this.keyId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Normalized hitbox definition:
/// Coordinates (x, y, width, height) are relative to original image size (0.0 to 1.0)
class MCDUHitboxDefinition {
  final String keyId;
  final double x;
  final double y;
  final double width;
  final double height;

  const MCDUHitboxDefinition({
    required this.keyId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class MCDUKeypadOverlay extends StatelessWidget {
  final double containerWidth;
  final double containerHeight;
  final ValueChanged<MCDUKeyEvent> onKeyPressed;

  const MCDUKeypadOverlay({
    super.key,
    required this.containerWidth,
    required this.containerHeight,
    required this.onKeyPressed,
  });

  /// Normalized hitbox configurations accurately calibrated against MCDU UI.jpg (707 x 961 px).
  static const List<MCDUHitboxDefinition> allHitboxes = [
    // -------------------------------------------------------------
    // Line Select Keys (LSK): 1L-6L (Left) and 1R-6R (Right)
    // -------------------------------------------------------------
    // Left LSKs (1L - 6L)
    MCDUHitboxDefinition(keyId: '1L', x: 0.038, y: 0.150, width: 0.095, height: 0.038),
    MCDUHitboxDefinition(keyId: '2L', x: 0.038, y: 0.203, width: 0.095, height: 0.038),
    MCDUHitboxDefinition(keyId: '3L', x: 0.038, y: 0.256, width: 0.095, height: 0.038),
    MCDUHitboxDefinition(keyId: '4L', x: 0.038, y: 0.309, width: 0.095, height: 0.038),
    MCDUHitboxDefinition(keyId: '5L', x: 0.038, y: 0.362, width: 0.095, height: 0.038),
    MCDUHitboxDefinition(keyId: '6L', x: 0.038, y: 0.415, width: 0.095, height: 0.038),

    // Right LSKs (1R - 6R)
    MCDUHitboxDefinition(keyId: '1R', x: 0.865, y: 0.150, width: 0.095, height: 0.038),
    MCDUHitboxDefinition(keyId: '2R', x: 0.865, y: 0.203, width: 0.095, height: 0.038),
    MCDUHitboxDefinition(keyId: '3R', x: 0.865, y: 0.256, width: 0.095, height: 0.038),
    MCDUHitboxDefinition(keyId: '4R', x: 0.865, y: 0.309, width: 0.095, height: 0.038),
    MCDUHitboxDefinition(keyId: '5R', x: 0.865, y: 0.362, width: 0.095, height: 0.038),
    MCDUHitboxDefinition(keyId: '6R', x: 0.865, y: 0.415, width: 0.095, height: 0.038),

    // -------------------------------------------------------------
    // Function / Mode Keys (Physical layout in MCDU UI.jpg)
    // Row 1: PERF, NAV, PREV, FPL, PROG, DIR
    // -------------------------------------------------------------
    MCDUHitboxDefinition(keyId: MCDUKey.perf, x: 0.040, y: 0.528, width: 0.105, height: 0.048),
    MCDUHitboxDefinition(keyId: MCDUKey.nav,  x: 0.160, y: 0.528, width: 0.105, height: 0.048),
    MCDUHitboxDefinition(keyId: MCDUKey.prev, x: 0.280, y: 0.528, width: 0.105, height: 0.048),
    MCDUHitboxDefinition(keyId: MCDUKey.fpl,  x: 0.400, y: 0.528, width: 0.105, height: 0.048),
    MCDUHitboxDefinition(keyId: MCDUKey.prog, x: 0.520, y: 0.528, width: 0.105, height: 0.048),
    MCDUHitboxDefinition(keyId: MCDUKey.dir,  x: 0.635, y: 0.528, width: 0.105, height: 0.048),

    // Row 2: MENU, NEXT, RADIO
    MCDUHitboxDefinition(keyId: MCDUKey.menu,  x: 0.040, y: 0.592, width: 0.105, height: 0.048),
    MCDUHitboxDefinition(keyId: MCDUKey.next,  x: 0.280, y: 0.592, width: 0.105, height: 0.048),
    MCDUHitboxDefinition(keyId: MCDUKey.radio, x: 0.635, y: 0.592, width: 0.105, height: 0.048),

    // Vertical Key right side: BRT/DIM
    MCDUHitboxDefinition(keyId: MCDUKey.brtDim, x: 0.885, y: 0.528, width: 0.082, height: 0.078),

    // -------------------------------------------------------------
    // Alpha Keypad (Left Block): 6 Columns x 5 Rows (A through Z, DEL, CLR)
    // Columns: 0.040, 0.130, 0.220, 0.310, 0.400, 0.490 (w: 0.082, h: 0.046)
    // -------------------------------------------------------------
    // Row 1: A, B, C, D, E, F
    MCDUHitboxDefinition(keyId: 'A', x: 0.040, y: 0.668, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'B', x: 0.130, y: 0.668, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'C', x: 0.220, y: 0.668, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'D', x: 0.310, y: 0.668, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'E', x: 0.400, y: 0.668, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'F', x: 0.490, y: 0.668, width: 0.082, height: 0.046),

    // Row 2: G, H, I, J, K, L
    MCDUHitboxDefinition(keyId: 'G', x: 0.040, y: 0.732, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'H', x: 0.130, y: 0.732, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'I', x: 0.220, y: 0.732, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'J', x: 0.310, y: 0.732, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'K', x: 0.400, y: 0.732, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'L', x: 0.490, y: 0.732, width: 0.082, height: 0.046),

    // Row 3: M, N, O, P, Q, R
    MCDUHitboxDefinition(keyId: 'M', x: 0.040, y: 0.796, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'N', x: 0.130, y: 0.796, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'O', x: 0.220, y: 0.796, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'P', x: 0.310, y: 0.796, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'Q', x: 0.400, y: 0.796, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'R', x: 0.490, y: 0.796, width: 0.082, height: 0.046),

    // Row 4: S, T, U, V, W
    MCDUHitboxDefinition(keyId: 'S', x: 0.130, y: 0.860, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'T', x: 0.220, y: 0.860, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'U', x: 0.310, y: 0.860, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'V', x: 0.400, y: 0.860, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'W', x: 0.490, y: 0.860, width: 0.082, height: 0.046),

    // Row 5: X, Y, Z, DEL, CLR
    MCDUHitboxDefinition(keyId: 'X', x: 0.130, y: 0.924, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'Y', x: 0.220, y: 0.924, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: 'Z', x: 0.310, y: 0.924, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.del, x: 0.400, y: 0.924, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.clr, x: 0.490, y: 0.924, width: 0.082, height: 0.046),

    // -------------------------------------------------------------
    // Numeric & Symbol Keypad (Right Block): 4 Columns x 4 Rows
    // Columns: 0.605, 0.700, 0.795, 0.885 (w: 0.082, h: 0.046)
    // -------------------------------------------------------------
    // Row 1: 1, 2, 3, +/-
    MCDUHitboxDefinition(keyId: MCDUKey.one, x: 0.605, y: 0.732, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.two, x: 0.700, y: 0.732, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.three, x: 0.795, y: 0.732, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.plusMinus, x: 0.885, y: 0.732, width: 0.082, height: 0.046),

    // Row 2: 4, 5, 6, /
    MCDUHitboxDefinition(keyId: MCDUKey.four, x: 0.605, y: 0.796, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.five, x: 0.700, y: 0.796, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.six, x: 0.795, y: 0.796, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.slash, x: 0.885, y: 0.796, width: 0.082, height: 0.046),

    // Row 3: 7, 8, 9
    MCDUHitboxDefinition(keyId: MCDUKey.seven, x: 0.605, y: 0.860, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.eight, x: 0.700, y: 0.860, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.nine, x: 0.795, y: 0.860, width: 0.082, height: 0.046),

    // Row 4: SP, 0, .
    MCDUHitboxDefinition(keyId: MCDUKey.space, x: 0.605, y: 0.924, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.zero, x: 0.700, y: 0.924, width: 0.082, height: 0.046),
    MCDUHitboxDefinition(keyId: MCDUKey.dot, x: 0.795, y: 0.924, width: 0.082, height: 0.046),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: allHitboxes.map((hitbox) {
        final left = hitbox.x * containerWidth;
        final top = hitbox.y * containerHeight;
        final width = hitbox.width * containerWidth;
        final height = hitbox.height * containerHeight;

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(width * 0.2),
              splashColor: Colors.amber.withValues(alpha: 0.35),
              highlightColor: Colors.amber.withValues(alpha: 0.2),
              onTap: () {
                onKeyPressed(MCDUKeyEvent(keyId: hitbox.keyId));
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(width * 0.2),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
