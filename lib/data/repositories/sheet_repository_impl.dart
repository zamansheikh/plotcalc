import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/plot_sheet.dart';
import '../../domain/repositories/sheet_repository.dart';

/// Stores sheets the same way plots are stored: one JSON list in
/// SharedPreferences, newest first.
class SheetRepositoryImpl implements SheetRepository {
  static const _key = 'plotcalc.sheets.v1';

  final SharedPreferences _prefs;
  final _controller = StreamController<List<PlotSheet>>.broadcast();
  List<PlotSheet>? _cache;

  SheetRepositoryImpl(this._prefs);

  Future<List<PlotSheet>> _load() async {
    if (_cache != null) return _cache!;
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _cache = const [];
      return _cache!;
    }
    try {
      _cache = (jsonDecode(raw) as List)
          .map((e) => PlotSheet.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _cache = const [];
    }
    return _cache!;
  }

  Future<void> _persist() async {
    final raw = jsonEncode(_cache!.map((s) => s.toJson()).toList());
    await _prefs.setString(_key, raw);
    _controller.add(List.unmodifiable(_cache!));
  }

  @override
  Future<List<PlotSheet>> getAll() async => List.unmodifiable(await _load());

  @override
  Future<PlotSheet?> getById(String id) async {
    for (final s in await _load()) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<void> save(PlotSheet sheet) async {
    final all = [...await _load()];
    final i = all.indexWhere((s) => s.id == sheet.id);
    if (i >= 0) {
      all[i] = sheet;
    } else {
      all.insert(0, sheet);
    }
    _cache = all;
    await _persist();
  }

  @override
  Future<void> delete(String id) async {
    final all = [...await _load()]..removeWhere((s) => s.id == id);
    _cache = all;
    await _persist();
  }

  @override
  Stream<List<PlotSheet>> watchAll() async* {
    yield await getAll();
    yield* _controller.stream;
  }
}
