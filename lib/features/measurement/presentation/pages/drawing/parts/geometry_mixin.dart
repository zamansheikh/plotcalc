part of '../drawing_page.dart';

mixin GeometryMixin on State<DrawingPage> {
  List<Point> get _points;

  void _fixShapeGeometry(
    Map<int, double> sides,
    Map<String, double> diagonals,
  ) {
    if (_points.length < 3) return;

    // We need all sides to be measured
    if (sides.length != _points.length) return;

    // For N > 3, we need N-3 diagonals.
    // We assume diagonals are from point 0 to i (i=2..N-2)
    // If the user hasn't provided enough diagonals, we can't fix the shape fully.
    // But we can try to fix what we can.
    // For a triangle (N=3), we don't need diagonals.

    try {
      // 1. Establish coordinate system based on P0 and P1
      // P0 is at (0,0) in our local metric space
      // P1 is at (Side0, 0)
      final List<Offset> vPoints = [];
      vPoints.add(const Offset(0, 0)); // V0

      final double side0 = sides[0]!;
      vPoints.add(Offset(side0, 0)); // V1

      // 2. Calculate subsequent points V2, V3...
      for (int i = 2; i < _points.length; i++) {
        // To find Vi, we need distance from Vi-1 (which is Side(i-1))
        // and distance from V0 (which is Diagonal(0-i) OR Side(N-1) if i is last point)

        final double rPrev = sides[i - 1]!; // Distance from V(i-1)
        double rZero;

        if (i == _points.length - 1) {
          // Last point connects back to V0 via the last side
          rZero = sides[_points.length - 1]!;
        } else {
          // Intermediate point needs a diagonal from V0
          final diagKey = '0-$i';
          if (!diagonals.containsKey(diagKey)) {
            // Cannot triangulate further without this diagonal
            return;
          }
          rZero = diagonals[diagKey]!;
        }

        // Find intersection of Circle(V(i-1), rPrev) and Circle(V0, rZero)
        final intersection = _findIntersection(
          vPoints[i - 1],
          rPrev,
          const Offset(0, 0),
          rZero,
          i,
        );

        if (intersection == null) {
          // Impossible geometry
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible geometry! Check your measurements.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        vPoints.add(intersection);
      }

      // 3. Transform V points back to screen space
      // We want to map V0 -> P0 and V1 -> P1 (preserving P0->P1 direction)
      // Scale S = dist(P0, P1) / dist(V0, V1)
      // But dist(V0, V1) is side0.
      // So S = dist(P0, P1) / side0.
      // Actually, we want to KEEP the screen scale roughly what it is.
      // So we use the drawn length of the first side to determine scale.

      final p0 = Offset(_points[0].x, _points[0].y);
      final p1 = Offset(_points[1].x, _points[1].y);
      final currentDist = (p1 - p0).distance;
      final scale = currentDist / side0;

      final rotation = math.atan2(p1.dy - p0.dy, p1.dx - p0.dx);

      setState(() {
        for (int i = 0; i < _points.length; i++) {
          final v = vPoints[i];
          // Rotate
          final xRot = v.dx * math.cos(rotation) - v.dy * math.sin(rotation);
          final yRot = v.dx * math.sin(rotation) + v.dy * math.cos(rotation);
          // Scale and Translate
          final xFinal = p0.dx + xRot * scale;
          final yFinal = p0.dy + yRot * scale;

          // Update point
          // We create a new list to trigger state change if needed, but here we modify _points
          // Since we are inside setState, it's fine.
          _points[i] = Point(xFinal, yFinal);
        }
      });
    } catch (e) {
      debugPrint('Error fixing shape: $e');
    }
  }

  Offset? _findIntersection(
    Offset center1,
    double r1,
    Offset center2,
    double r2,
    int pointIndex,
  ) {
    // Find intersection of two circles
    // d = distance between centers
    final d = (center1 - center2).distance;

    // Check for solvability
    // Using a small epsilon for float comparison
    if (d > r1 + r2 + 0.001 || d < (r1 - r2).abs() - 0.001 || d == 0) {
      return null;
    }

    // a = distance from center1 to the line joining intersection points
    final a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);

    // h = distance from the line joining centers to the intersection points
    final h = math.sqrt(math.max(0, r1 * r1 - a * a));

    // P2 = point on the line joining centers
    final x2 = center1.dx + a * (center2.dx - center1.dx) / d;
    final y2 = center1.dy + a * (center2.dy - center1.dy) / d;

    // Two intersection points
    final sol1 = Offset(
      x2 + h * (center2.dy - center1.dy) / d,
      y2 - h * (center2.dx - center1.dx) / d,
    );
    final sol2 = Offset(
      x2 - h * (center2.dy - center1.dy) / d,
      y2 + h * (center2.dx - center1.dx) / d,
    );

    // To pick the correct solution, we compare with the original drawing.
    // We transform both solutions to screen space (using current P0, P1 alignment)
    // and see which one is closer to the user's drawn point P[pointIndex].

    // Note: In _fixShapeGeometry we calculated scale based on measured side0.
    // Here we just need a relative comparison, so using current screen P0-P1 is fine
    // assuming V0=(0,0) and V1=(side0,0) maps to P0, P1.
    // Wait, we need the scale relative to the V coordinates we are using.
    // V1.dx is the measured length.
    // So scale = (P1-P0).distance / V1.dx.
    // But we don't have V1.dx passed here easily.
    // Let's just use the calculated scale from _fixShapeGeometry logic:
    // We can pass P0, P1, and V1.dx to this function, or just do the check in _fixShapeGeometry.
    // But _fixShapeGeometry calls this.
    // Let's return both and let caller decide? No, simpler to decide here if we have context.

    // Let's approximate:
    // The "winding" or "side" of the line P0-P(i-1) should be preserved.
    // Or simply, closest to original point.

    // We need to reconstruct the transform to check.
    // Let's assume the caller handles the selection?
    // No, let's do a simple heuristic:
    // Check cross product (signed area) of (Vi-1 - V0) x (Vi - V0).
    // Compare with (Pi-1 - P0) x (Pi - P0).
    // They should have the same sign.

    final v0 = center2; // center2 is V0 (0,0) passed from caller
    final vPrev = center1; // center1 is V(i-1)

    // Original points
    final pOriginal = Offset(_points[pointIndex].x, _points[pointIndex].y);
    final pPrev = Offset(_points[pointIndex - 1].x, _points[pointIndex - 1].y);
    final pZero = Offset(_points[0].x, _points[0].y);

    // Cross product of solution 2
    // final cp2 = (vPrev.dx - v0.dx) * (sol2.dy - v0.dy) - (vPrev.dy - v0.dy) * (sol2.dx - v0.dx);

    // If signs match, pick sol1, else sol2
    // Note: Screen Y is down, Math Y is up usually, but cross product sign consistency holds.
    // However, if the points are collinear, CP is 0.
    // Also, if the user drew it "inside out" or "twisted", this might be tricky.
    // But "closest to original" is usually the best UX for "snapping".

    // Let's try "closest to original" approach by roughly transforming sol1/sol2.
    // We need scale and rotation.
    // Scale ~ (pPrev - pZero).distance / (vPrev - v0).distance
    // Rotation ~ angle(pPrev - pZero) - angle(vPrev - v0)
    // This is local transformation based on the previous segment.

    final distV = (vPrev - v0).distance;
    if (distV < 0.001) return sol1; // Should not happen

    final distP = (pPrev - pZero).distance;
    final scale = distP / distV;
    final angleP = math.atan2(pPrev.dy - pZero.dy, pPrev.dx - pZero.dx);
    final angleV = math.atan2(vPrev.dy - v0.dy, vPrev.dx - v0.dx);
    final rotation = angleP - angleV;

    Offset transform(Offset v) {
      final dx = v.dx - v0.dx;
      final dy = v.dy - v0.dy;
      final xRot = dx * math.cos(rotation) - dy * math.sin(rotation);
      final yRot = dx * math.sin(rotation) + dy * math.cos(rotation);
      return Offset(pZero.dx + xRot * scale, pZero.dy + yRot * scale);
    }

    final tSol1 = transform(sol1);
    final tSol2 = transform(sol2);

    if ((tSol1 - pOriginal).distance < (tSol2 - pOriginal).distance) {
      return sol1;
    } else {
      return sol2;
    }
  }
}
