import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/plot.dart';
import '../../domain/repositories/plot_repository.dart';

class PlotRepositoryImpl implements PlotRepository {
  static const _key = 'plotcalc.plots.v1';

  final SharedPreferences _prefs;
  final _controller = StreamController<List<Plot>>.broadcast();
  List<Plot>? _cache;

  PlotRepositoryImpl(this._prefs);

  Future<List<Plot>> _load() async {
    if (_cache != null) return _cache!;
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _cache = const [];
      return _cache!;
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Plot.fromJson(e as Map<String, dynamic>))
          .toList();
      _cache = list;
    } catch (_) {
      _cache = const [];
    }
    return _cache!;
  }

  Future<void> _persist() async {
    final raw = jsonEncode(_cache!.map((p) => p.toJson()).toList());
    await _prefs.setString(_key, raw);
    _controller.add(List.unmodifiable(_cache!));
  }

  @override
  Future<List<Plot>> getAll() async {
    final all = await _load();
    return List.unmodifiable(all);
  }

  @override
  Future<Plot?> getById(String id) async {
    final all = await _load();
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<void> save(Plot plot) async {
    final all = [...await _load()];
    final i = all.indexWhere((p) => p.id == plot.id);
    if (i >= 0) {
      all[i] = plot;
    } else {
      all.insert(0, plot);
    }
    _cache = all;
    await _persist();
  }

  @override
  Future<void> delete(String id) async {
    final all = [...await _load()];
    all.removeWhere((p) => p.id == id);
    _cache = all;
    await _persist();
  }

  @override
  Future<void> deleteAll() async {
    _cache = const [];
    await _persist();
  }

  @override
  Stream<List<Plot>> watchAll() async* {
    yield await getAll();
    yield* _controller.stream;
  }
}
