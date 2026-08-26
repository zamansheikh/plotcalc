import 'package:equatable/equatable.dart';

import '../../core/geometry/geometry.dart';
import '../../core/geometry/vertex.dart';
import '../../core/units/area_unit.dart';

enum PlotTag { agricultural, residential, commercial, forest, other }

extension PlotTagX on PlotTag {
  // Display names are locale-dependent — see PlotTagL10n.labelOf in l10n.dart.

  static PlotTag fromKey(String key) {
    return PlotTag.values.firstWhere(
      (t) => t.name == key,
      orElse: () => PlotTag.other,
    );
  }
}

class Plot extends Equatable {
  final String id;
  final String name;
  final List<Vertex> vertices;
  final PlotTag tag;
  final DateTime createdAt;
  final int colorValue; // ARGB

  /// Unit this plot is read in. `null` means "follow the app setting" —
  /// which is what every plot saved before this field existed does.
  final AreaUnit? preferredUnit;

  /// Set when this plot is a circle. [vertices] still holds a fine polygon
  /// so painters and hit tests are unchanged, but area and perimeter come
  /// from the exact formulae, and the UI says "circle" rather than "72 sides".
  final double? circleRadiusM;

  bool get isCircle => circleRadiusM != null && circleRadiusM! > 0;

  /// Area as the user should see it. For a circle this is exact rather than
  /// the drawn polygon's slightly smaller area.
  double get areaSqm => isCircle
      ? Geometry.circleArea(circleRadiusM!)
      : Geometry.polygonArea(vertices);

  /// Likewise the boundary length: a circumference for circles.
  double get perimeterM => isCircle
      ? Geometry.circleCircumference(circleRadiusM!)
      : Geometry.polygonPerimeter(vertices);

  const Plot({
    required this.id,
    required this.name,
    required this.vertices,
    required this.tag,
    required this.createdAt,
    required this.colorValue,
    this.preferredUnit,
    this.circleRadiusM,
  });

  Plot copyWith({
    String? id,
    String? name,
    List<Vertex>? vertices,
    PlotTag? tag,
    DateTime? createdAt,
    int? colorValue,
    AreaUnit? preferredUnit,
    double? circleRadiusM,

    /// Explicitly drop the override and go back to the app setting;
    /// passing `preferredUnit: null` can't express that on its own.
    bool clearPreferredUnit = false,

    /// Editing a circle's outline turns it into an ordinary polygon.
    bool clearCircle = false,
  }) =>
      Plot(
        id: id ?? this.id,
        name: name ?? this.name,
        vertices: vertices ?? this.vertices,
        tag: tag ?? this.tag,
        createdAt: createdAt ?? this.createdAt,
        colorValue: colorValue ?? this.colorValue,
        preferredUnit: clearPreferredUnit
            ? null
            : (preferredUnit ?? this.preferredUnit),
        circleRadiusM: clearCircle
            ? null
            : (circleRadiusM ?? this.circleRadiusM),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'vertices': vertices.map((v) => v.toJson()).toList(),
        'tag': tag.name,
        'createdAt': createdAt.toIso8601String(),
        'colorValue': colorValue,
        // Omitted entirely when unset, so the stored shape is unchanged for
        // plots that follow the app setting.
        if (preferredUnit != null) 'preferredUnit': preferredUnit!.name,
        if (circleRadiusM != null) 'circleRadiusM': circleRadiusM,
      };

  factory Plot.fromJson(Map<String, dynamic> j) => Plot(
        id: j['id'] as String,
        name: j['name'] as String,
        vertices: (j['vertices'] as List)
            .map((e) => Vertex.fromJson(e as Map<String, dynamic>))
            .toList(),
        tag: PlotTagX.fromKey(j['tag'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        colorValue: j['colorValue'] as int,
        preferredUnit: _unitOrNull(j['preferredUnit']),
        circleRadiusM: switch (j['circleRadiusM']) {
          final num r when r > 0 => r.toDouble(),
          _ => null,
        },
      );

  /// Unlike [AreaUnit.fromKey] this does not fall back to a real unit: an
  /// unreadable value must mean "follow the app setting", not "square feet".
  static AreaUnit? _unitOrNull(Object? key) {
    if (key is! String) return null;
    for (final u in AreaUnit.values) {
      if (u.name == key) return u;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    vertices,
    tag,
    createdAt,
    colorValue,
    preferredUnit,
    circleRadiusM,
  ];
}
