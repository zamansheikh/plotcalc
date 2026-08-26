import 'package:equatable/equatable.dart';

import '../../core/geometry/vertex.dart';

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

  const Plot({
    required this.id,
    required this.name,
    required this.vertices,
    required this.tag,
    required this.createdAt,
    required this.colorValue,
  });

  Plot copyWith({
    String? id,
    String? name,
    List<Vertex>? vertices,
    PlotTag? tag,
    DateTime? createdAt,
    int? colorValue,
  }) =>
      Plot(
        id: id ?? this.id,
        name: name ?? this.name,
        vertices: vertices ?? this.vertices,
        tag: tag ?? this.tag,
        createdAt: createdAt ?? this.createdAt,
        colorValue: colorValue ?? this.colorValue,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'vertices': vertices.map((v) => v.toJson()).toList(),
        'tag': tag.name,
        'createdAt': createdAt.toIso8601String(),
        'colorValue': colorValue,
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
      );

  @override
  List<Object?> get props => [id, name, vertices, tag, createdAt, colorValue];
}
