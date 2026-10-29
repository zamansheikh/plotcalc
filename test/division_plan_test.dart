import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/core/geometry/division_plan.dart';
import 'package:plotcalc/core/geometry/geometry.dart';
import 'package:plotcalc/core/geometry/vertex.dart';
import 'package:plotcalc/core/units/area_unit.dart';

/// 60 × 40 m, 2400 m². Side 0 runs along the top (north) edge.
const field = [Vertex(0, 0), Vertex(60, 0), Vertex(60, 40), Vertex(0, 40)];

DivisionSpec spec(
  List<String> amounts, {
  DivisionMode mode = DivisionMode.shares,
  int? front,
  double road = 0,
  AreaUnit unit = AreaUnit.sqm,
}) => DivisionSpec(
  parentPlotId: 'p',
  owners: [
    for (var i = 0; i < amounts.length; i++)
      DivisionOwner(name: 'O$i', amount: amounts[i]),
  ],
  mode: mode,
  frontSide: front,
  roadWidthM: road,
  areaUnit: unit,
);

double areaOf(DivisionResult r, int owner) => r.ofOwner(owner)!.areaSqm;

void main() {
  group('reading shares', () {
    double? v(String s) => ShareParser.parse(s)?.value;
    bool? abs(String s) => ShareParser.parse(s)?.absolute;

    test('fractions, Bengali or not', () {
      expect(v('1/3'), closeTo(1 / 3, 1e-12));
      expect(v('১/৩'), closeTo(1 / 3, 1e-12));
      expect(abs('১/৩'), isTrue);
      expect(v('1/0'), isNull);
    });

    test('আনা, গণ্ডা, কড়া', () {
      expect(v('৬ আনা'), closeTo(6 / 16, 1e-12));
      expect(v('৮ আনা'), closeTo(0.5, 1e-12));
      expect(v('৬ আনা ১০ গণ্ডা'), closeTo(6 / 16 + 10 / 320, 1e-12));
      expect(v('১ গণ্ডা ২ কড়া'), closeTo(1 / 320 + 2 / 1280, 1e-12));
      expect(abs('৬ আনা'), isTrue);
      expect(v('৬ বিঘা'), isNull, reason: 'not a share');
    });

    test('percent and decimals', () {
      expect(v('৩৩%'), closeTo(0.33, 1e-12));
      expect(v('.৩৩৩৩'), closeTo(0.3333, 1e-12));
      expect(abs('0.25'), isTrue);
    });

    test('counts are weights', () {
      expect(v('২'), 2);
      expect(abs('২'), isFalse);
      expect(abs('1.5'), isFalse);
      expect(v('abc'), isNull);
    });
  });

  group('sizes', () {
    test('equal', () {
      final r = DivisionPlan.compute(
        spec(['', '', ''], mode: DivisionMode.equal),
        field,
      );
      expect(r.ok, isTrue);
      for (var i = 0; i < 3; i++) {
        expect(areaOf(r, i), closeTo(800, 1e-4));
      }
      expect(r.cuts.length, 2);
    });

    test('counts: two sons and a daughter', () {
      final r = DivisionPlan.compute(spec(['২', '২', '১']), field);
      expect(areaOf(r, 0), closeTo(960, 1e-4));
      expect(areaOf(r, 2), closeTo(480, 1e-4));
    });

    test('আনা adding up to the whole', () {
      final r = DivisionPlan.compute(spec(['১০ আনা', '৬ আনা']), field);
      expect(r.ok, isTrue);
      expect(r.rest, isNull);
      expect(areaOf(r, 0), closeTo(1500, 1e-4));
    });

    test('fractions short of the whole leave an unassigned piece', () {
      final r = DivisionPlan.compute(spec(['১/২', '১/৩']), field);
      expect(r.ok, isTrue);
      expect(areaOf(r, 0), closeTo(1200, 1e-4));
      expect(areaOf(r, 1), closeTo(800, 1e-4));
      expect(r.rest!.areaSqm, closeTo(400, 1e-4));
    });

    test('blanks share what typed parts leave', () {
      // Half to the eldest; the other two split the rest.
      final r = DivisionPlan.compute(spec(['১/২', '', '']), field);
      expect(r.ok, isTrue);
      expect(areaOf(r, 0), closeTo(1200, 1e-4));
      expect(areaOf(r, 1), closeTo(600, 1e-4));
      expect(areaOf(r, 2), closeTo(600, 1e-4));
      expect(r.rest, isNull);
    });

    test('blanks among counts count as one', () {
      final r = DivisionPlan.compute(spec(['২', '', '']), field);
      expect(areaOf(r, 0), closeTo(1200, 1e-4));
      expect(areaOf(r, 1), closeTo(600, 1e-4));
    });

    test('over the whole, or mixed, is refused', () {
      expect(DivisionPlan.compute(spec(['১/২', '২/৩']), field).issues, [
        DivisionIssue.sharesOver,
      ]);
      expect(DivisionPlan.compute(spec(['১/২', '২']), field).issues, [
        DivisionIssue.sharesMixed,
      ]);
      expect(DivisionPlan.compute(spec(['১/২', 'x']), field).issues, [
        DivisionIssue.shareUnreadable,
      ]);
    });

    test('a fixed piece first, the rest equally', () {
      // A mosque gets 5 shotok; three brothers share the rest.
      final r = DivisionPlan.compute(
        spec(
          ['৫', '', '', ''],
          mode: DivisionMode.areas,
          unit: AreaUnit.shotok,
        ),
        field,
      );
      expect(r.ok, isTrue);
      final mosque = AreaUnit.shotok.toSqm(5);
      expect(areaOf(r, 0), closeTo(mosque, 1e-4));
      for (var i = 1; i < 4; i++) {
        expect(areaOf(r, i), closeTo((2400 - mosque) / 3, 1e-4));
      }
    });

    test('areas over the land are refused', () {
      final r = DivisionPlan.compute(
        spec(['2000', '1000'], mode: DivisionMode.areas),
        field,
      );
      expect(r.issues, [DivisionIssue.areasOver]);
    });
  });

  group('front side and road', () {
    test('every lot touches the front side', () {
      // Front: side 2, the bottom (south) edge.
      final r = DivisionPlan.compute(spec(['১', '১', '১'], front: 2), field);
      for (final lot in r.lots) {
        final ys = [for (final v in lot.vertices) v.y];
        expect(
          ys.reduce(math.max),
          closeTo(40, 1e-4),
          reason: 'reaches the south edge',
        );
      }
    });

    test('a road strip along the front, and lots behind it', () {
      // 6 m road along the top; every lot reaches the road's edge.
      final r = DivisionPlan.compute(
        spec(['১', '১'], front: 0, road: 6),
        field,
      );
      expect(r.road!.areaSqm, closeTo(60 * 6, 1e-4));
      expect(Geometry.polygonArea(r.land), closeTo(2400 - 360, 1e-4));
      for (final lot in r.lots) {
        final ys = [for (final v in lot.vertices) v.y];
        expect(ys.reduce(math.min), closeTo(6, 1e-4));
        expect(lot.areaSqm, closeTo((2400 - 360) / 2, 1e-4));
      }
    });

    test('a road as deep as the plot is refused', () {
      final r = DivisionPlan.compute(spec(['১'], front: 0, road: 50), field);
      expect(r.issues, [DivisionIssue.roadTooWide]);
    });

    test('owners run left to right as seen from the front', () {
      // Front along the bottom (south): standing there looking north, the
      // first owner is on the left — the west, low x.
      final south = DivisionPlan.compute(spec(['১', '৩'], front: 2), field);
      final xs = [for (final v in south.ofOwner(0)!.vertices) v.x];
      expect(xs.reduce(math.min), closeTo(0, 1e-4));
      expect(xs.reduce(math.max), closeTo(15, 1e-4));
      // Front along the top (north): looking south, left is the east.
      final north = DivisionPlan.compute(spec(['১', '৩'], front: 0), field);
      final xn = [for (final v in north.ofOwner(0)!.vertices) v.x];
      expect(xn.reduce(math.min), closeTo(45, 1e-4));
      expect(xn.reduce(math.max), closeTo(60, 1e-4));
    });

    test('the corners\' drawing order does not change the result', () {
      const reversed = [
        Vertex(0, 40),
        Vertex(60, 40),
        Vertex(60, 0),
        Vertex(0, 0),
      ];
      // In this order side 0 is the south edge.
      final r = DivisionPlan.compute(spec(['১', '৩'], front: 0), reversed);
      final xs = [for (final v in r.ofOwner(0)!.vertices) v.x];
      expect(xs.reduce(math.max), closeTo(15, 1e-4));
    });
  });

  group('slide to resize', () {
    test('turns the division into areas, the last owner taking the rest', () {
      final s = spec(['', ''], mode: DivisionMode.equal);
      final r = DivisionPlan.compute(s, field);
      // Divider starts at x = 30; slide it to x = 20.
      final amounts = DivisionPlan.areasAfterSlide(
        s,
        r,
        0,
        const Vertex(20, 20),
      );
      expect(double.parse(amounts[0]), closeTo(800, 0.01));
      expect(amounts[1], '');
      final after = DivisionPlan.compute(
        s.copyWith(
          mode: DivisionMode.areas,
          owners: [
            for (var i = 0; i < 2; i++)
              s.owners[i].copyWith(amount: amounts[i]),
          ],
        ),
        field,
      );
      expect(after.ok, isTrue);
      expect(areaOf(after, 1), closeTo(1600, 0.01));
    });
  });

  group('চৌহদ্দি', () {
    test('neighbours on each side', () {
      // Road along the north, two lots side by side behind it.
      final r = DivisionPlan.compute(
        spec(['১', '১'], front: 0, road: 6),
        field,
      );
      final pieces = [for (final p in r.pieces) p.vertices];
      final roadIndex = r.pieces.indexWhere((p) => p.kind == PieceKind.road);
      // Front along the north: looking south from it, owner 0 is on the
      // left — the east.
      final east = r.pieces.indexWhere((p) => p.owner == 0);
      final west = r.pieces.indexWhere((p) => p.owner == 1);
      final b = Chouhoddi.of(pieces, west);
      BoundaryStretch on(Cardinal c) => b.firstWhere((s) => s.side == c);
      expect(on(Cardinal.north).neighbour, roadIndex);
      expect(on(Cardinal.north).lengthM, closeTo(30, 1e-4));
      expect(on(Cardinal.east).neighbour, east);
      expect(on(Cardinal.east).lengthM, closeTo(34, 1e-4));
      expect(on(Cardinal.south).neighbour, isNull, reason: 'plot edge');
      expect(on(Cardinal.west).neighbour, isNull);
      expect(b.length, 4, reason: 'a rectangle has four stretches');
    });
  });

  test('a saved spec reads back', () {
    final s = spec(
      ['৬ আনা', '১০ আনা'],
      front: 2,
      road: 2.4,
    ).copyWith(angles: [0.3], ownerPlotIds: ['x', 'y'], roadPlotId: 'r');
    final back = DivisionSpec.fromJson(s.toJson());
    expect(back.owners.map((o) => o.amount), ['৬ আনা', '১০ আনা']);
    expect(back.frontSide, 2);
    expect(back.roadWidthM, 2.4);
    expect(back.angles, [0.3]);
    expect(back.ownerPlotIds, ['x', 'y']);
    expect(back.roadPlotId, 'r');
    expect(back.mode, DivisionMode.shares);
  });
}
