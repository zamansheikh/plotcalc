import 'package:uuid/uuid.dart';

import '../../../core/di/injection.dart';
import '../../../core/geometry/division_plan.dart';
import '../../../core/geometry/sheet_layout.dart';
import '../../../domain/entities/plot.dart';
import '../../../domain/entities/plot_sheet.dart';
import '../../../domain/usecases/delete_plot.dart';
import '../../../domain/usecases/get_plots.dart';
import '../../../domain/usecases/save_plot.dart';
import '../../../domain/usecases/save_sheet.dart';
import '../../../l10n/l10n.dart';
import 'view/division_canvas.dart';

/// Names for a division's pieces, as shown on screen and in the PDF.
class DivisionNames {
  final DivisionSpec spec;
  final AppLocalizations t;
  const DivisionNames(this.spec, this.t);

  String owner(int i) {
    final n = spec.owners[i].name.trim();
    return n.isEmpty ? t.subdivideLot(i + 1) : n;
  }

  String of(DivisionPiece p) => switch (p.kind) {
    PieceKind.owner => owner(p.owner!),
    PieceKind.road => t.divisionRoad,
    PieceKind.rest => t.divisionRest,
  };
}

/// Saves a division as a sheet: one plot per owner (and for the road and
/// any unassigned land), laid out exactly as on the ground, with the
/// division kept so it can be opened and changed again.
class DivisionStore {
  DivisionStore._();

  static Future<PlotSheet> save({
    required Plot parent,
    required DivisionSpec spec,
    required DivisionResult result,
    required AppLocalizations t,
    PlotSheet? existing,
  }) async {
    final names = DivisionNames(spec, t);
    final old = existing?.division;
    final known = {for (final p in await sl<GetPlots>()()) p.id: p};
    String idFor(String? previous) =>
        previous != null && previous.isNotEmpty ? previous : const Uuid().v4();

    final ownerIds = <String>[];
    final plotIds = <String>[];
    final layout = <String, PlotPlacement>{};
    String? roadId, restId;

    Future<void> write(DivisionPiece piece, String id, String name) async {
      final previous = known[id];
      await sl<SavePlot>()(
        Plot(
          id: id,
          name: '${parent.name} · $name',
          vertices: piece.vertices,
          tag: piece.kind == PieceKind.road ? PlotTag.other : parent.tag,
          createdAt: previous?.createdAt ?? DateTime.now(),
          colorValue: pieceColour(piece).toARGB32(),
          preferredUnit: parent.preferredUnit,
        ),
      );
      plotIds.add(id);
      final c = SheetLayout.centroid(piece.vertices);
      layout[id] = PlotPlacement(c.x, c.y);
    }

    for (var i = 0; i < spec.owners.length; i++) {
      final piece = result.ofOwner(i);
      final previous = old != null && i < old.ownerPlotIds.length
          ? old.ownerPlotIds[i]
          : null;
      if (piece == null || piece.vertices.length < 3) {
        ownerIds.add('');
        continue;
      }
      final id = idFor(previous);
      ownerIds.add(id);
      await write(piece, id, names.owner(i));
    }
    final rest = result.rest;
    if (rest != null && rest.vertices.length >= 3) {
      restId = idFor(old?.restPlotId);
      await write(rest, restId, t.divisionRest);
    }
    final road = result.road;
    if (road != null && road.vertices.length >= 3) {
      roadId = idFor(old?.roadPlotId);
      await write(road, roadId, t.divisionRoad);
    }

    // Plots an earlier save made that this one no longer has.
    final kept = plotIds.toSet();
    for (final id in [
      ...?old?.ownerPlotIds,
      old?.roadPlotId,
      old?.restPlotId,
    ]) {
      if (id != null && id.isNotEmpty && !kept.contains(id)) {
        await sl<DeletePlot>()(id);
      }
    }

    final saved = spec.copyWith(
      ownerPlotIds: ownerIds,
      roadPlotId: roadId,
      clearRoadPlot: roadId == null,
      restPlotId: restId,
      clearRestPlot: restId == null,
    );
    final sheet = existing == null
        ? PlotSheet(
            id: const Uuid().v4(),
            name: t.divisionSheetName(parent.name),
            plotIds: plotIds,
            createdAt: DateTime.now(),
            layout: layout,
            division: saved,
          )
        : existing.copyWith(plotIds: plotIds, layout: layout, division: saved);
    await sl<SaveSheet>()(sheet);
    return sheet;
  }
}
