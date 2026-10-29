import 'dart:math' as math;

import '../units/area_unit.dart';
import 'geometry.dart';
import 'lot_division.dart';
import 'vertex.dart';

/// A share as people write it, read into a number.
///
/// [absolute] shares are parts of the whole — "১/৩", "৬ আনা", "৩৩%", "০.২৫"
/// — and must add up to at most one. Plain counts — "২" for a son and "১"
/// for a daughter — are only weights against each other.
class ShareValue {
  final double value;
  final bool absolute;
  const ShareValue(this.value, {required this.absolute});
}

/// Reads typed shares and areas. Bengali and ASCII digits both work.
class ShareParser {
  ShareParser._();

  static const _bengaliDigits = '০১২৩৪৫৬৭৮৯';

  static String _ascii(String s) {
    var out = s.trim();
    for (var i = 0; i < _bengaliDigits.length; i++) {
      out = out.replaceAll(_bengaliDigits[i], '$i');
    }
    return out.replaceAll('٫', '.').replaceAll(',', '');
  }

  /// A plain number, for areas. Null when it is not one.
  static double? number(String raw) {
    final s = _ascii(raw);
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  /// Land shares in the old money reckoning: a whole is 16 আনা, an আনা is
  /// 20 গণ্ডা, a গণ্ডা 4 কড়া, a কড়া 3 ক্রান্তি.
  static const _anna = {
    'আনা': 1 / 16,
    'anna': 1 / 16,
    'গণ্ডা': 1 / 320,
    'গন্ডা': 1 / 320,
    'ganda': 1 / 320,
    // কড়া written with ড় as one letter, and as ড plus its dot.
    '\u0995\u09dc\u09be': 1 / 1280,
    '\u0995\u09a1\u09bc\u09be': 1 / 1280,
    'করা': 1 / 1280,
    'kora': 1 / 1280,
    'ক্রান্তি': 1 / 3840,
    'kranti': 1 / 3840,
  };

  /// Reads one share. Null when it cannot be read; blank is null too.
  static ShareValue? parse(String raw) {
    final s = _ascii(raw).toLowerCase();
    if (s.isEmpty) return null;

    // "33%"
    final pct = RegExp(r'^(\d+(?:\.\d+)?)\s*%$').firstMatch(s);
    if (pct != null) {
      return ShareValue(double.parse(pct.group(1)!) / 100, absolute: true);
    }

    // "1/3"
    final frac = RegExp(
      r'^(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)$',
    ).firstMatch(s);
    if (frac != null) {
      final d = double.parse(frac.group(2)!);
      if (d == 0) return null;
      return ShareValue(double.parse(frac.group(1)!) / d, absolute: true);
    }

    // "৬ আনা ১০ গণ্ডা"
    final units = RegExp(r'(\d+(?:\.\d+)?)\s*([^\d\s.]+)');
    final matches = units.allMatches(s).toList();
    if (matches.isNotEmpty &&
        s.replaceAll(units, '').trim().isEmpty &&
        matches.every((m) => _anna.containsKey(m.group(2)))) {
      var v = 0.0;
      for (final m in matches) {
        v += double.parse(m.group(1)!) * _anna[m.group(2)]!;
      }
      return ShareValue(v, absolute: true);
    }

    // "2", "1.5" are weights; "0.25", ".৩৩৩৩" are parts of the whole, as
    // the records write a share.
    final n = double.tryParse(s);
    if (n == null || n < 0) return null;
    return ShareValue(n, absolute: n < 1);
  }
}

enum DivisionMode {
  /// Everyone the same.
  equal,

  /// By share: fractions, আনা-গণ্ডা, percentages, or counts.
  shares,

  /// By area; owners left blank share what is left equally.
  areas,
}

class DivisionOwner {
  final String name;

  /// What was typed: a share in [DivisionMode.shares], an area in
  /// [DivisionMode.areas]. Ignored in [DivisionMode.equal].
  final String amount;

  const DivisionOwner({this.name = '', this.amount = ''});

  DivisionOwner copyWith({String? name, String? amount}) =>
      DivisionOwner(name: name ?? this.name, amount: amount ?? this.amount);

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  factory DivisionOwner.fromJson(Map<String, dynamic> j) => DivisionOwner(
    name: j['name'] as String? ?? '',
    amount: j['amount'] as String? ?? '',
  );
}

/// Everything that decides how a plot is divided, kept so a division can be
/// opened again and changed.
class DivisionSpec {
  final String parentPlotId;
  final List<DivisionOwner> owners;
  final DivisionMode mode;

  /// Unit of the areas typed in [DivisionMode.areas].
  final AreaUnit areaUnit;

  /// The side every lot must touch: side `i` runs from corner `i` to
  /// `i + 1` of the parent. Null leaves the dividers free.
  final int? frontSide;

  /// Width of a common road along [frontSide], in metres. 0 for none.
  final double roadWidthM;

  /// Per divider, a direction the user turned it to (see [LotDivision]);
  /// null follows the front side.
  final List<double?> angles;

  /// Plots this division was saved as, for saving it again in place.
  final List<String> ownerPlotIds;
  final String? roadPlotId;
  final String? restPlotId;

  const DivisionSpec({
    required this.parentPlotId,
    required this.owners,
    this.mode = DivisionMode.equal,
    this.areaUnit = AreaUnit.shotok,
    this.frontSide,
    this.roadWidthM = 0,
    this.angles = const [],
    this.ownerPlotIds = const [],
    this.roadPlotId,
    this.restPlotId,
  });

  DivisionSpec copyWith({
    List<DivisionOwner>? owners,
    DivisionMode? mode,
    AreaUnit? areaUnit,
    int? frontSide,
    bool clearFront = false,
    double? roadWidthM,
    List<double?>? angles,
    List<String>? ownerPlotIds,
    String? roadPlotId,
    bool clearRoadPlot = false,
    String? restPlotId,
    bool clearRestPlot = false,
  }) => DivisionSpec(
    parentPlotId: parentPlotId,
    owners: owners ?? this.owners,
    mode: mode ?? this.mode,
    areaUnit: areaUnit ?? this.areaUnit,
    frontSide: clearFront ? null : (frontSide ?? this.frontSide),
    roadWidthM: roadWidthM ?? this.roadWidthM,
    angles: angles ?? this.angles,
    ownerPlotIds: ownerPlotIds ?? this.ownerPlotIds,
    roadPlotId: clearRoadPlot ? null : (roadPlotId ?? this.roadPlotId),
    restPlotId: clearRestPlot ? null : (restPlotId ?? this.restPlotId),
  );

  Map<String, dynamic> toJson() => {
    'parent': parentPlotId,
    'owners': [for (final o in owners) o.toJson()],
    'mode': mode.name,
    'unit': areaUnit.name,
    if (frontSide != null) 'front': frontSide,
    if (roadWidthM > 0) 'road': roadWidthM,
    if (angles.any((a) => a != null)) 'angles': angles,
    if (ownerPlotIds.isNotEmpty) 'ownerPlots': ownerPlotIds,
    if (roadPlotId != null) 'roadPlot': roadPlotId,
    if (restPlotId != null) 'restPlot': restPlotId,
  };

  factory DivisionSpec.fromJson(Map<String, dynamic> j) => DivisionSpec(
    parentPlotId: j['parent'] as String,
    owners: [
      for (final o in (j['owners'] as List? ?? const []))
        DivisionOwner.fromJson((o as Map).cast<String, dynamic>()),
    ],
    mode: DivisionMode.values.firstWhere(
      (m) => m.name == j['mode'],
      orElse: () => DivisionMode.equal,
    ),
    areaUnit: AreaUnit.values.firstWhere(
      (u) => u.name == j['unit'],
      orElse: () => AreaUnit.shotok,
    ),
    frontSide: j['front'] as int?,
    roadWidthM: (j['road'] as num?)?.toDouble() ?? 0,
    angles: [
      for (final a in (j['angles'] as List? ?? const []))
        (a as num?)?.toDouble(),
    ],
    ownerPlotIds: [
      for (final id in (j['ownerPlots'] as List? ?? const [])) id as String,
    ],
    roadPlotId: j['roadPlot'] as String?,
    restPlotId: j['restPlot'] as String?,
  );
}

enum PieceKind { owner, road, rest }

/// One piece of the divided plot.
class DivisionPiece {
  final PieceKind kind;

  /// Index into the spec's owners, for [PieceKind.owner].
  final int? owner;
  final List<Vertex> vertices;

  /// The area this piece was meant to have.
  final double targetSqm;

  const DivisionPiece({
    required this.kind,
    required this.vertices,
    required this.targetSqm,
    this.owner,
  });

  double get areaSqm => Geometry.polygonArea(vertices);
}

enum DivisionIssue {
  /// Shares add up to more than the whole.
  sharesOver,

  /// Parts of the whole and plain counts typed together.
  sharesMixed,

  /// A share could not be read.
  shareUnreadable,

  /// Areas add up to more than the land.
  areasOver,

  /// A typed area could not be read.
  areaUnreadable,

  /// The road takes the whole plot.
  roadTooWide,
}

/// The worked-out division: road, lots, and the lines between them.
class DivisionResult {
  final List<DivisionPiece> pieces;
  final List<CutLine> cuts;

  /// The plot minus the road: what the lots are cut from.
  final List<Vertex> land;
  final List<DivisionIssue> issues;

  /// The direction each divider was cut at (see [LotDivision]).
  final List<double> angles;

  const DivisionResult({
    required this.pieces,
    required this.cuts,
    required this.land,
    required this.issues,
    this.angles = const [],
  });

  bool get ok => issues.isEmpty;

  DivisionPiece? get road =>
      pieces.where((p) => p.kind == PieceKind.road).firstOrNull;

  DivisionPiece? get rest =>
      pieces.where((p) => p.kind == PieceKind.rest).firstOrNull;

  /// Owners' lots and the unassigned rest, in cutting order: what the
  /// dividers separate.
  List<DivisionPiece> get lots => [
    for (final p in pieces)
      if (p.kind != PieceKind.road) p,
  ];

  DivisionPiece? ofOwner(int i) => pieces
      .where((p) => p.kind == PieceKind.owner && p.owner == i)
      .firstOrNull;
}

class DivisionPlan {
  DivisionPlan._();

  /// Unassigned land below this share of the plot is rounding, not land.
  static const _restEpsilon = 1e-6;

  /// The direction dividers face so they cut straight back from [side],
  /// each lot getting its own stretch of it — and pointing left to right
  /// as seen standing at that side looking in, so the first owner's lot is
  /// on the left whichever way the plot's corners were drawn.
  static double frontAngle(List<Vertex> poly, int side) {
    final n = _inward(poly, side);
    // Facing n on screen (y down), the right hand points (-n.y, n.x).
    return math.atan2(n.x, -n.y);
  }

  /// Unit normal of [side] pointing into the plot.
  static Vertex _inward(List<Vertex> poly, int side) {
    final a = poly[side], b = poly[(side + 1) % poly.length];
    final dx = b.x - a.x, dy = b.y - a.y;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return const Vertex(0, -1);
    var nx = -dy / len, ny = dx / len;
    final c = _centroid(poly);
    if ((c.x - a.x) * nx + (c.y - a.y) * ny < 0) {
      nx = -nx;
      ny = -ny;
    }
    return Vertex(nx, ny);
  }

  /// Splits off a strip [widthM] deep along [side]: the road, and the land
  /// behind it.
  static (List<Vertex> road, List<Vertex> land) roadStrip(
    List<Vertex> poly,
    int side,
    double widthM,
  ) {
    final a = poly[side];
    if (widthM <= 0) return (const [], poly);
    final n = _inward(poly, side);
    final nx = n.x, ny = n.y;
    final angle = math.atan2(ny, nx);
    final edge = a.x * nx + a.y * ny;
    final road = LotDivision.clip(poly, angle, edge + widthM, keepNear: true);
    final land = LotDivision.clip(poly, angle, edge + widthM, keepNear: false);
    return (road, land);
  }

  static DivisionResult compute(DivisionSpec spec, List<Vertex> parent) {
    final issues = <DivisionIssue>[];
    if (parent.length < 3 || spec.owners.isEmpty) {
      return DivisionResult(
        pieces: const [],
        cuts: const [],
        land: parent,
        issues: issues,
      );
    }

    final pieces = <DivisionPiece>[];
    var land = parent;
    final front = spec.frontSide;
    final hasFront = front != null && front >= 0 && front < parent.length;
    if (hasFront && spec.roadWidthM > 0) {
      final (road, rest) = roadStrip(parent, front, spec.roadWidthM);
      if (Geometry.polygonArea(rest) <= 0) {
        issues.add(DivisionIssue.roadTooWide);
      } else {
        land = rest;
        if (Geometry.polygonArea(road) > 0) {
          pieces.add(
            DivisionPiece(
              kind: PieceKind.road,
              vertices: road,
              targetSqm: Geometry.polygonArea(road),
            ),
          );
        }
      }
    }
    final landSqm = Geometry.polygonArea(land);

    // How much land each owner gets, and what is left unassigned.
    final n = spec.owners.length;
    final targets = List<double>.filled(n, 0);
    var rest = 0.0;
    switch (spec.mode) {
      case DivisionMode.equal:
        for (var i = 0; i < n; i++) {
          targets[i] = landSqm / n;
        }
      case DivisionMode.shares:
        // Blank shares: with parts of the whole typed (১/২, ৬ আনা) they
        // split what those leave; with counts (২, ১) each counts as one.
        final blanks = <int>[];
        final typed = <int, ShareValue>{};
        for (var i = 0; i < n; i++) {
          final raw = spec.owners[i].amount;
          if (raw.trim().isEmpty) {
            blanks.add(i);
            continue;
          }
          final v = ShareParser.parse(raw);
          if (v == null) {
            issues.add(DivisionIssue.shareUnreadable);
            break;
          }
          typed[i] = v;
        }
        if (issues.isNotEmpty) break;
        final anyAbs = typed.values.any((s) => s.absolute);
        final allAbs = typed.values.every((s) => s.absolute);
        if (anyAbs && !allAbs) {
          issues.add(DivisionIssue.sharesMixed);
          break;
        }
        if (anyAbs) {
          final sum = typed.values.fold<double>(0, (t, s) => t + s.value);
          if (sum > 1 + 1e-6) {
            issues.add(DivisionIssue.sharesOver);
            break;
          }
          for (final e in typed.entries) {
            targets[e.key] = landSqm * e.value.value;
          }
          final left = landSqm * math.max(0.0, 1 - sum);
          if (blanks.isEmpty) {
            rest = left;
          } else {
            for (final i in blanks) {
              targets[i] = left / blanks.length;
            }
          }
        } else {
          final weights = [for (var i = 0; i < n; i++) typed[i]?.value ?? 1.0];
          final sum = weights.fold<double>(0, (t, w) => t + w);
          if (sum <= 0) {
            issues.add(DivisionIssue.shareUnreadable);
            break;
          }
          for (var i = 0; i < n; i++) {
            targets[i] = landSqm * weights[i] / sum;
          }
        }
      case DivisionMode.areas:
        final blanks = <int>[];
        var fixed = 0.0;
        for (var i = 0; i < n; i++) {
          final raw = spec.owners[i].amount;
          if (raw.trim().isEmpty) {
            blanks.add(i);
            continue;
          }
          final v = ShareParser.number(raw);
          if (v == null || v < 0) {
            issues.add(DivisionIssue.areaUnreadable);
            break;
          }
          targets[i] = spec.areaUnit.toSqm(v);
          fixed += targets[i];
        }
        if (issues.isNotEmpty) break;
        // A typed area is rounded; a thousandth over is rounding, not a
        // mistake.
        if (fixed > landSqm * 1.001) {
          issues.add(DivisionIssue.areasOver);
          break;
        }
        final left = math.max(0.0, landSqm - fixed);
        if (blanks.isEmpty) {
          rest = left;
        } else {
          for (final i in blanks) {
            targets[i] = left / blanks.length;
          }
        }
    }

    if (issues.isNotEmpty) {
      return DivisionResult(
        pieces: pieces,
        cuts: const [],
        land: land,
        issues: issues,
      );
    }

    // Cut in owner order, the unassigned rest last.
    final order = [
      for (var i = 0; i < n; i++) (PieceKind.owner, i, targets[i]),
      if (rest > landSqm * _restEpsilon) (PieceKind.rest, null, rest),
    ];
    // An owner given nothing gets no piece and no divider.
    final cutting = [
      for (final o in order)
        if (o.$3 > landSqm * _restEpsilon) o,
    ];
    if (cutting.isEmpty || landSqm <= 0) {
      return DivisionResult(
        pieces: pieces,
        cuts: const [],
        land: land,
        issues: issues,
      );
    }

    final base = hasFront
        ? frontAngle(parent, front)
        : LotDivision.defaultAngle;
    final angles = [
      for (var i = 0; i < cutting.length - 1; i++)
        i < spec.angles.length && spec.angles[i] != null
            ? spec.angles[i]!
            : base,
    ];
    final fractions = [for (final c in cutting) c.$3 / landSqm];
    final lots = LotDivision.divide(land, fractions, angles: angles);
    for (var i = 0; i < lots.length && i < cutting.length; i++) {
      pieces.add(
        DivisionPiece(
          kind: cutting[i].$1,
          owner: cutting[i].$2,
          vertices: lots[i].vertices,
          targetSqm: cutting[i].$3,
        ),
      );
    }
    return DivisionResult(
      pieces: pieces,
      cuts: LotDivision.cutLines(land, fractions, angles: angles),
      land: land,
      issues: issues,
      angles: angles,
    );
  }

  /// The areas each owner's lot would have after sliding divider [index]
  /// to [point], as typed areas in the spec's unit: dragging a divider says
  /// "this big", so the division becomes one by area. Only the two lots
  /// beside the divider change.
  static List<String> areasAfterSlide(
    DivisionSpec spec,
    DivisionResult result,
    int index,
    Vertex point,
  ) {
    final lots = result.lots;
    final landSqm = Geometry.polygonArea(result.land);
    final out = [for (final o in spec.owners) o.amount];
    if (landSqm <= 0 || lots.length < 2) return out;
    final shares = [for (final l in lots) l.targetSqm / landSqm];
    final next = LotDivision.sharesAfterMove(
      result.land,
      shares,
      result.angles,
      index,
      point,
    );
    for (var i = 0; i < lots.length; i++) {
      final o = lots[i].owner;
      if (o == null) continue;
      out[o] = _plain(spec.areaUnit.fromSqm(next[i] * landSqm));
    }
    // The owner cut last takes what is left, so rounding each typed area
    // can never add up to more than the land.
    final last = lots.last.owner;
    if (last != null) out[last] = '';
    return out;
  }

  static String _plain(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static Vertex _centroid(List<Vertex> p) {
    var x = 0.0, y = 0.0;
    for (final v in p) {
      x += v.x;
      y += v.y;
    }
    return Vertex(x / p.length, y / p.length);
  }
}

/// Compass direction of a boundary, with the top of the drawing as north.
enum Cardinal { north, east, south, west }

/// One stretch of a lot's boundary and what lies beyond it.
class BoundaryStretch {
  final Cardinal side;
  final double lengthM;

  /// Index of the neighbouring piece in the list given to [Chouhoddi.of];
  /// null where the lot meets the edge of the original plot.
  final int? neighbour;

  const BoundaryStretch(this.side, this.lengthM, this.neighbour);
}

/// চৌহদ্দি: what bounds each lot on each side.
class Chouhoddi {
  Chouhoddi._();

  /// The boundary of [pieces][index], stretch by stretch, with what lies
  /// beyond each. Neighbouring stretches facing the same way and bordering
  /// the same thing are joined.
  static List<BoundaryStretch> of(List<List<Vertex>> pieces, int index) {
    final poly = pieces[index];
    if (poly.length < 3) return const [];
    final area = _signedArea(poly);
    final sign = area >= 0 ? 1.0 : -1.0;
    var size = 0.0;
    for (final p in pieces) {
      for (final v in p) {
        size = math.max(size, math.max(v.x.abs(), v.y.abs()));
      }
    }
    final probe = math.max(0.02, size * 1e-4);

    final raw = <BoundaryStretch>[];
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i], b = poly[(i + 1) % poly.length];
      final dx = b.x - a.x, dy = b.y - a.y;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len < 1e-6) continue;
      final nx = sign * dy / len, ny = sign * -dx / len;
      final m = Vertex(
        (a.x + b.x) / 2 + nx * probe,
        (a.y + b.y) / 2 + ny * probe,
      );
      int? neighbour;
      for (var j = 0; j < pieces.length; j++) {
        if (j == index || pieces[j].length < 3) continue;
        if (_contains(pieces[j], m)) {
          neighbour = j;
          break;
        }
      }
      // Screen y grows downward, so "up" — north — is negative y.
      final side = nx.abs() >= ny.abs()
          ? (nx > 0 ? Cardinal.east : Cardinal.west)
          : (ny < 0 ? Cardinal.north : Cardinal.south);
      raw.add(BoundaryStretch(side, len, neighbour));
    }
    if (raw.isEmpty) return raw;

    bool same(BoundaryStretch x, BoundaryStretch y) =>
        x.side == y.side && x.neighbour == y.neighbour;
    final out = <BoundaryStretch>[];
    for (final s in raw) {
      if (out.isNotEmpty && same(out.last, s)) {
        out.last = BoundaryStretch(
          s.side,
          out.last.lengthM + s.lengthM,
          s.neighbour,
        );
      } else {
        out.add(s);
      }
    }
    if (out.length > 1 && same(out.first, out.last)) {
      final f = out.removeAt(0);
      out.last = BoundaryStretch(
        f.side,
        f.lengthM + out.last.lengthM,
        f.neighbour,
      );
    }
    return out;
  }

  static double _signedArea(List<Vertex> p) {
    var s = 0.0;
    for (var i = 0; i < p.length; i++) {
      final a = p[i], b = p[(i + 1) % p.length];
      s += a.x * b.y - b.x * a.y;
    }
    return s / 2;
  }

  static bool _contains(List<Vertex> poly, Vertex pt) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final a = poly[i], b = poly[j];
      if ((a.y > pt.y) != (b.y > pt.y) &&
          pt.x < (b.x - a.x) * (pt.y - a.y) / (b.y - a.y) + a.x) {
        inside = !inside;
      }
    }
    return inside;
  }
}
