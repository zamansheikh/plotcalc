import 'package:equatable/equatable.dart';

import '../../core/geometry/division_plan.dart';
import '../../core/geometry/sheet_layout.dart';
import '../../core/units/area_unit.dart';

/// A named group of saved plots, read together: "my father's land",
/// "plots for sale".
///
/// Holds plot ids, not copies. Editing a plot later changes the sheet's
/// totals too, and a deleted plot simply drops out of the sheet.
class PlotSheet extends Equatable {
  final String id;
  final String name;

  /// In the order the sheet lists them.
  final List<String> plotIds;

  /// Unit the sheet is read in. `null` means "follow the app setting".
  final AreaUnit? unit;

  /// Land price per one [priceUnit], in taka. `null` until someone enters a
  /// price, in which case the sheet shows no value at all.
  final double? pricePerUnit;

  /// Unit the price is quoted in. Land is usually priced per shotok
  /// (decimal), so that is the default.
  final AreaUnit priceUnit;

  final DateTime createdAt;

  /// Where each plot sits on the sheet's canvas, by plot id. Plots without
  /// an entry are laid out automatically until someone arranges them.
  final Map<String, PlotPlacement> layout;

  /// How the plots were made, when this sheet is a saved division of one
  /// plot: kept so the division can be opened and changed again.
  final DivisionSpec? division;

  const PlotSheet({
    required this.id,
    required this.name,
    required this.plotIds,
    required this.createdAt,
    this.unit,
    this.pricePerUnit,
    this.priceUnit = AreaUnit.shotok,
    this.layout = const {},
    this.division,
  });

  PlotSheet copyWith({
    String? name,
    List<String>? plotIds,
    AreaUnit? unit,
    bool clearUnit = false,
    double? pricePerUnit,
    bool clearPrice = false,
    AreaUnit? priceUnit,
    Map<String, PlotPlacement>? layout,
    DivisionSpec? division,
  }) => PlotSheet(
    id: id,
    name: name ?? this.name,
    plotIds: plotIds ?? this.plotIds,
    createdAt: createdAt,
    unit: clearUnit ? null : (unit ?? this.unit),
    pricePerUnit: clearPrice ? null : (pricePerUnit ?? this.pricePerUnit),
    priceUnit: priceUnit ?? this.priceUnit,
    layout: layout ?? this.layout,
    division: division ?? this.division,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'plotIds': plotIds,
    'createdAt': createdAt.toIso8601String(),
    if (unit != null) 'unit': unit!.name,
    if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
    'priceUnit': priceUnit.name,
    if (layout.isNotEmpty)
      'layout': {for (final e in layout.entries) e.key: e.value.toJson()},
    if (division != null) 'division': division!.toJson(),
  };

  factory PlotSheet.fromJson(Map<String, dynamic> j) => PlotSheet(
    id: j['id'] as String,
    name: j['name'] as String,
    plotIds: (j['plotIds'] as List).cast<String>(),
    createdAt: DateTime.parse(j['createdAt'] as String),
    unit: _unitOrNull(j['unit']),
    pricePerUnit: (j['pricePerUnit'] as num?)?.toDouble(),
    priceUnit: _unitOrNull(j['priceUnit']) ?? AreaUnit.shotok,
    layout: {
      for (final e in ((j['layout'] as Map?) ?? const {}).entries)
        e.key as String: PlotPlacement.fromJson(
          (e.value as Map).cast<String, dynamic>(),
        ),
    },
    division: j['division'] == null
        ? null
        : DivisionSpec.fromJson((j['division'] as Map).cast<String, dynamic>()),
  );

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
    plotIds,
    unit,
    pricePerUnit,
    priceUnit,
    createdAt,
    layout,
    division?.toJson().toString(),
  ];
}
