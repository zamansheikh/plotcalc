import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'geometry.dart';
import 'vertex.dart';

/// Where one plot sits on a sheet's canvas: its centre, in metres, and how
/// far it is turned, in radians. The plot's own shape is never changed.
class PlotPlacement extends Equatable {
  final double x;
  final double y;
  final double angle;

  const PlotPlacement(this.x, this.y, [this.angle = 0]);

  PlotPlacement moved(double dx, double dy) =>
      PlotPlacement(x + dx, y + dy, angle);

  PlotPlacement turned(double by) {
    // Kept in (-π, π] so a stored angle never drifts into large numbers.
    var a = (angle + by) % (2 * math.pi);
    if (a > math.pi) a -= 2 * math.pi;
    return PlotPlacement(x, y, a);
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'a': angle};

  factory PlotPlacement.fromJson(Map<String, dynamic> j) => PlotPlacement(
    (j['x'] as num).toDouble(),
    (j['y'] as num).toDouble(),
    (j['a'] as num?)?.toDouble() ?? 0,
  );

  @override
  List<Object?> get props => [x, y, angle];
}

/// Placing plots side by side at true scale, so a sheet can show how the
/// pieces of land sit next to each other.
class SheetLayout {
  SheetLayout._();

  /// Gap left between plots that are placed automatically, in metres.
  static const double gap = 4;

  /// Area centroid. Falls back to the vertex average for a degenerate
  /// polygon, where the area formula divides by zero.
  static Vertex centroid(List<Vertex> v) {
    if (v.isEmpty) return const Vertex(0, 0);
    var a = 0.0, cx = 0.0, cy = 0.0;
    for (var i = 0; i < v.length; i++) {
      final p = v[i], q = v[(i + 1) % v.length];
      final cross = p.x * q.y - q.x * p.y;
      a += cross;
      cx += (p.x + q.x) * cross;
      cy += (p.y + q.y) * cross;
    }
    if (a.abs() < 1e-9) {
      final sx = v.fold<double>(0, (s, p) => s + p.x);
      final sy = v.fold<double>(0, (s, p) => s + p.y);
      return Vertex(sx / v.length, sy / v.length);
    }
    return Vertex(cx / (3 * a), cy / (3 * a));
  }

  /// The plot's outline where [p] puts it: turned about its centroid, then
  /// moved so the centroid lands on (p.x, p.y).
  static List<Vertex> place(List<Vertex> v, PlotPlacement p) {
    final c = centroid(v);
    final cos = math.cos(p.angle), sin = math.sin(p.angle);
    return [
      for (final q in v)
        Vertex(
          p.x + (q.x - c.x) * cos - (q.y - c.y) * sin,
          p.y + (q.x - c.x) * sin + (q.y - c.y) * cos,
        ),
    ];
  }

  /// Even-odd point-in-polygon test.
  static bool contains(List<Vertex> poly, Vertex pt) {
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

  /// Keeps every placement in [existing] and gives the other plots a spot:
  /// left to right in rows, below anything already placed.
  static Map<String, PlotPlacement> fill(
    List<(String, List<Vertex>)> plots,
    Map<String, PlotPlacement> existing,
  ) {
    final out = <String, PlotPlacement>{
      for (final (id, _) in plots)
        if (existing[id] != null) id: existing[id]!,
    };
    final todo = [
      for (final p in plots)
        if (!out.containsKey(p.$1)) p,
    ];
    if (todo.isEmpty) return out;

    // Start below whatever is already on the canvas.
    var top = 0.0, left = 0.0;
    if (out.isNotEmpty) {
      final placed = [
        for (final (id, v) in plots)
          if (out[id] != null) ...place(v, out[id]!),
      ];
      final (minX, _, _, maxY) = Geometry.bbox(placed);
      left = minX;
      top = maxY + gap * 2;
    }

    // Rows about as wide as a square holding everything would be.
    var area = 0.0;
    for (final (_, v) in todo) {
      final (x0, y0, x1, y1) = Geometry.bbox(v);
      area += (x1 - x0 + gap) * (y1 - y0 + gap);
    }
    final rowWidth = math.max(math.sqrt(area) * 1.3, 1.0);

    var x = left, y = top, rowHeight = 0.0;
    for (final (id, v) in todo) {
      final (x0, y0, x1, y1) = Geometry.bbox(v);
      final w = x1 - x0, h = y1 - y0;
      if (x > left && x - left + w > rowWidth) {
        x = left;
        y += rowHeight + gap;
        rowHeight = 0;
      }
      // The placement is the centroid; offset it to put the box at (x, y).
      final c = centroid(v);
      out[id] = PlotPlacement(x + (c.x - x0), y + (c.y - y0));
      x += w + gap;
      rowHeight = math.max(rowHeight, h);
    }
    return out;
  }

  /// Lets go of plot [id] cleanly against its neighbours: when one of its
  /// corners is within [threshold] metres of another plot's corner, the plot
  /// moves so the two meet exactly. Failing that, a corner near another
  /// plot's side moves onto that side. Otherwise nothing changes.
  ///
  /// This is what makes two plots that share a boundary on the ground share
  /// it on the canvas too, which a finger alone can't do precisely.
  static PlotPlacement snap(
    String id,
    List<(String, List<Vertex>)> plots,
    Map<String, PlotPlacement> layout,
    double threshold,
  ) {
    final p = layout[id]!;
    final me = plots.firstWhere((e) => e.$1 == id).$2;
    final mine = place(me, p);
    final others = [
      for (final (oid, v) in plots)
        if (oid != id && layout[oid] != null) place(v, layout[oid]!),
    ];

    // Corners meet: always both ways, the shift just changes sign.
    double best = threshold;
    Vertex? shift;
    for (final v in mine) {
      for (final o in others) {
        for (final w in o) {
          final d = _dist(v, w);
          if (d < best) {
            best = d;
            shift = Vertex(w.x - v.x, w.y - v.y);
          }
        }
      }
    }
    if (shift != null) return p.moved(shift.x, shift.y);

    // A corner lands on a side: mine on theirs, or theirs on mine.
    best = threshold;
    void tryEdges(List<Vertex> corners, List<Vertex> poly, double sign) {
      for (final v in corners) {
        for (var i = 0; i < poly.length; i++) {
          final q = _closest(v, poly[i], poly[(i + 1) % poly.length]);
          final d = _dist(v, q);
          if (d < best) {
            best = d;
            shift = Vertex((q.x - v.x) * sign, (q.y - v.y) * sign);
          }
        }
      }
    }

    for (final o in others) {
      tryEdges(mine, o, 1);
      tryEdges(o, mine, -1);
    }
    final s = shift;
    return s == null ? p : p.moved(s.x, s.y);
  }

  static double _dist(Vertex a, Vertex b) =>
      math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));

  /// Point on segment ab nearest to p.
  static Vertex _closest(Vertex p, Vertex a, Vertex b) {
    final dx = b.x - a.x, dy = b.y - a.y;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) return a;
    final t = (((p.x - a.x) * dx + (p.y - a.y) * dy) / len2).clamp(0.0, 1.0);
    return Vertex(a.x + dx * t, a.y + dy * t);
  }

  /// Bounding box of every placed plot, or null when there are none.
  static (double, double, double, double)? bounds(
    List<(String, List<Vertex>)> plots,
    Map<String, PlotPlacement> layout,
  ) {
    final all = [
      for (final (id, v) in plots)
        if (layout[id] != null) ...place(v, layout[id]!),
    ];
    return all.isEmpty ? null : Geometry.bbox(all);
  }
}
