// lib/features/mcdu_core/domain/mcdu_key.dart
// Identifier definitions for MCDU keys verified against MCDU UI.jpg.
class MCDUKey {
  // Function / Mode keys (Top function keypad area)
  static const String perf = 'PERF';
  static const String nav = 'NAV';
  static const String prev = 'PREV';
  static const String fpl = 'FPL';
  static const String prog = 'PROG';
  static const String dir = 'DIR';
  static const String menu = 'MENU';
  static const String next = 'NEXT';
  static const String radio = 'RADIO';
  static const String brtDim = 'BRT/DIM';

  // Alpha keys (A‑Z)
  static const List<String> alpha = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'
  ];

  // Numeric / Symbol keys
  static const String zero = '0';
  static const String one = '1';
  static const String two = '2';
  static const String three = '3';
  static const String four = '4';
  static const String five = '5';
  static const String six = '6';
  static const String seven = '7';
  static const String eight = '8';
  static const String nine = '9';
  static const String slash = 'SLASH';
  static const String space = 'SP';
  static const String dot = 'DOT';
  static const String plusMinus = '+/-';

  // Editing / Action keys
  static const String clr = 'CLR';
  static const String del = 'DEL';
}
