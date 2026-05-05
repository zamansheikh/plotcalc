import 'package:equatable/equatable.dart';

/// 2D point in meters.
class Vertex extends Equatable {
  final double x;
  final double y;

  const Vertex(this.x, this.y);

  Vertex copyWith({double? x, double? y}) => Vertex(x ?? this.x, y ?? this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory Vertex.fromJson(Map<String, dynamic> j) =>
      Vertex((j['x'] as num).toDouble(), (j['y'] as num).toDouble());

  @override
  List<Object?> get props => [x, y];
}
