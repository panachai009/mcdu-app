import 'package:flutter_test/flutter_test.dart';
import 'package:mcdu_app/features/game/falling_code/domain/reporting_point.dart';
import 'package:mcdu_app/features/game/falling_code/domain/reporting_points_catalog.dart';

void main() {
  group('ReportingPointsCatalog Tests', () {
    test('1. Total count is exactly 72 points', () {
      expect(ReportingPointsCatalog.all.length, 72);
    });

    test('2. Bangkok Zone count is exactly 38 points', () {
      expect(ReportingPointsCatalog.bangkokZone.length, 38);
      for (final p in ReportingPointsCatalog.bangkokZone) {
        expect(p.category, ReportingPointCategory.bangkokZone);
      }
    });

    test('3. Military/Provincial count is exactly 34 points', () {
      expect(ReportingPointsCatalog.militaryProvincial.length, 34);
      for (final p in ReportingPointsCatalog.militaryProvincial) {
        expect(p.category, ReportingPointCategory.militaryProvincial);
      }
    });

    test('4. All codes are unique and uppercase alphanumeric', () {
      final codePattern = RegExp(r'^[A-Z0-9]+$');
      final seenCodes = <String>{};

      for (final p in ReportingPointsCatalog.all) {
        expect(p.code, isNotEmpty);
        expect(codePattern.hasMatch(p.code), isTrue,
            reason: 'Code ${p.code} must be alphanumeric uppercase');
        expect(seenCodes.contains(p.code), isFalse,
            reason: 'Code ${p.code} must be unique');
        seenCodes.add(p.code);
      }
      expect(seenCodes.length, 72);
    });

    test('5. Specific Bangkok Zone checkpoints match PDF source', () {
      final bngkn = ReportingPointsCatalog.findByCode('BNGKN');
      expect(bngkn, isNotNull);
      expect(bngkn!.name, '11TH INFANTRY');
      expect(bngkn.category, ReportingPointCategory.bangkokZone);

      final tpad = ReportingPointsCatalog.findByCode('TPAD');
      expect(tpad, isNotNull);
      expect(tpad!.name, 'TPAD');
      expect(tpad.category, ReportingPointCategory.bangkokZone);

      final wbk10 = ReportingPointsCatalog.findByCode('10WBK');
      expect(wbk10, isNotNull);
      expect(wbk10!.name, '10 NM WEST');
    });

    test('6. Specific Military checkpoints match PDF source', () {
      final spf01 = ReportingPointsCatalog.findByCode('SPF01');
      expect(spf01, isNotNull);
      expect(spf01!.name, 'พล.รพศ.1');
      expect(spf01.category, ReportingPointCategory.militaryProvincial);

      final knsus = ReportingPointsCatalog.findByCode('KNSUS');
      expect(knsus, isNotNull);
      expect(knsus!.name, 'กรมการสัตว์ทหารบก');
      expect(knsus.category, ReportingPointCategory.militaryProvincial);

      final crma = ReportingPointsCatalog.findByCode('CRMA');
      expect(crma, isNotNull);
      expect(crma!.name, 'รร.นายร้อย จปร.');
    });

    test('7. findByCode is case-insensitive and trims whitespace', () {
      final lower = ReportingPointsCatalog.findByCode('bngkn ');
      expect(lower, isNotNull);
      expect(lower!.code, 'BNGKN');

      final unknown = ReportingPointsCatalog.findByCode('NONEXISTENT');
      expect(unknown, isNull);
    });

    test('8. ReportingPoint equality and hashCode work correctly', () {
      const p1 = ReportingPoint(
        code: 'TEST1',
        name: 'Test Name',
        category: ReportingPointCategory.bangkokZone,
        rawCoordinates: 'COORD1',
      );
      const p2 = ReportingPoint(
        code: 'TEST1',
        name: 'Test Name',
        category: ReportingPointCategory.bangkokZone,
        rawCoordinates: 'COORD1',
      );
      const p3 = ReportingPoint(
        code: 'TEST2',
        name: 'Test Name',
        category: ReportingPointCategory.bangkokZone,
        rawCoordinates: 'COORD1',
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1 == p3, isFalse);
    });

    test('9. All reporting points have non-empty names and coordinates', () {
      for (final p in ReportingPointsCatalog.all) {
        expect(p.name, isNotEmpty);
        expect(p.rawCoordinates, isNotNull);
        expect(p.rawCoordinates, isNotEmpty);
      }
    });

    test('10. Bangkok and Military lists are strictly disjoint subsets of all', () {
      final bkk = ReportingPointsCatalog.bangkokZone;
      final mil = ReportingPointsCatalog.militaryProvincial;

      expect(bkk.length + mil.length, ReportingPointsCatalog.all.length);
      final bkkCodes = bkk.map((p) => p.code).toSet();
      final milCodes = mil.map((p) => p.code).toSet();
      expect(bkkCodes.intersection(milCodes), isEmpty);
    });
  });
}
