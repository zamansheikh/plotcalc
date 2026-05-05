import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../core/utils/land_area_breakdown.dart';
import '../../../../core/utils/land_unit_system.dart';
import '../widgets/land_area_breakdown_widget.dart';

class LandCalculatorPage extends StatefulWidget {
  const LandCalculatorPage({super.key});

  @override
  State<LandCalculatorPage> createState() => _LandCalculatorPageState();
}

class _LandCalculatorPageState extends State<LandCalculatorPage> {
  static const _primary = Color(0xFF2E7D32);
  static const _bg = Color(0xFFF6F8FA);

  final TextEditingController _inputController = TextEditingController();
  LandUnitId _inputUnit = LandUnitId.squareFeet;

  late List<LandUnitConfig> _units;

  LandAreaResult? _result;
  bool _showConfigure = false;
  bool _showCombine = false;
  bool _showAdjust = false;

  // Adjust state
  bool _adjustAdds = true;
  final TextEditingController _adjustController = TextEditingController();
  LandUnitId _adjustUnit = LandUnitId.shatak;

  // Combine multi-unit state
  final Map<LandUnitId, TextEditingController> _combineControllers = {};

  @override
  void initState() {
    super.initState();
    _units = LandUnitSystem.defaultBreakdownUnits()
        .map((c) => c.copy())
        .toList();
    for (final id in [
      LandUnitId.acre,
      LandUnitId.bigha,
      LandUnitId.katha,
      LandUnitId.shatak,
      LandUnitId.chotak,
    ]) {
      _combineControllers[id] = TextEditingController();
    }
    _calculate();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _adjustController.dispose();
    for (final c in _combineControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetUnits() {
    setState(() {
      _units = LandUnitSystem.defaultBreakdownUnits()
          .map((c) => c.copy())
          .toList();
    });
    _calculate();
  }

  List<LandUnitDef> _toLegacyUnits() {
    return _units.map((c) {
      return LandUnitDef(
        id: _legacyId(c.id),
        name: LandUnitSystem.name(context, c.id),
        sqftFactor: LandUnitSystem.sqftFactor(c.id),
        isEnabled: c.isEnabled,
      );
    }).toList();
  }

  String _legacyId(LandUnitId id) {
    switch (id) {
      case LandUnitId.bighaMymensingh:
        return 'bighaMymensingh';
      case LandUnitId.kathaMymensingh:
        return 'kathaMymensingh';
      case LandUnitId.acre:
        return 'acre';
      case LandUnitId.bigha:
        return 'bigha';
      case LandUnitId.katha:
        return 'katha';
      case LandUnitId.shatak:
        return 'shatak';
      case LandUnitId.chotak:
        return 'chotak';
      case LandUnitId.squareMeter:
        return 'squareMeters';
      case LandUnitId.squareFeet:
        return 'squareFeet';
      case LandUnitId.hectare:
        return 'hectares';
    }
  }

  double get _currentSqft {
    final v = double.tryParse(_inputController.text);
    if (v == null || v < 0) return 0;
    return LandUnitSystem.toSqft(v, _inputUnit);
  }

  void _calculate() {
    final sqft = _currentSqft;
    if (sqft <= 0) {
      setState(() => _result = null);
      return;
    }
    setState(() {
      _result = LandAreaCalculator.calculate(sqft, _toLegacyUnits());
    });
  }

  void _setInputFromSqft(double sqft) {
    final value = LandUnitSystem.fromSqft(sqft, _inputUnit);
    _inputController.text = _formatInput(value);
    _calculate();
  }

  String _formatInput(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e9) {
      return v.toStringAsFixed(0);
    }
    return v
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _units.removeAt(oldIndex);
      _units.insert(newIndex, item);
    });
    _calculate();
  }

  void _toggleUnit(LandUnitConfig u, bool? value) {
    setState(() {
      u.isEnabled = value ?? false;
      if (u.isEnabled) {
        const conflicts = <LandUnitId, LandUnitId>{
          LandUnitId.bighaMymensingh: LandUnitId.bigha,
          LandUnitId.bigha: LandUnitId.bighaMymensingh,
          LandUnitId.kathaMymensingh: LandUnitId.katha,
          LandUnitId.katha: LandUnitId.kathaMymensingh,
        };
        final conflictId = conflicts[u.id];
        if (conflictId != null) {
          for (final c in _units) {
            if (c.id == conflictId) c.isEnabled = false;
          }
        }
      }
    });
    _calculate();
  }

  double _sumCombineSqft() {
    double total = 0;
    _combineControllers.forEach((id, ctrl) {
      final v = double.tryParse(ctrl.text);
      if (v != null && v > 0) {
        total += LandUnitSystem.toSqft(v, id);
      }
    });
    return total;
  }

  void _applyCombined() {
    final sqft = _sumCombineSqft();
    if (sqft > 0) {
      _setInputFromSqft(sqft);
      setState(() => _showCombine = false);
    }
  }

  void _applyAdjustment() {
    final v = double.tryParse(_adjustController.text);
    if (v == null || v <= 0) return;
    final delta = LandUnitSystem.toSqft(v, _adjustUnit);
    final current = _currentSqft;
    final newTotal = _adjustAdds
        ? current + delta
        : (current - delta).clamp(0.0, double.infinity);
    _setInputFromSqft(newTotal);
    _adjustController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(loc),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputCard(loc),
                    const SizedBox(height: 16),
                    if (_result != null) ...[
                      LandAreaBreakdownWidget(result: _result!),
                      const SizedBox(height: 16),
                    ],
                    _buildAdjustCard(loc),
                    const SizedBox(height: 12),
                    _buildCombineCard(loc),
                    const SizedBox(height: 12),
                    _buildConfigCard(loc),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.landscape_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.landCalculator,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  loc.calculatorSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: loc.resetUnits,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _resetUnits,
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.input_rounded, color: _primary, size: 18),
              const SizedBox(width: 8),
              Text(
                loc.totalArea,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              if (_inputController.text.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _inputController.clear();
                    _calculate();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          loc.clearInput,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _inputController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _primary.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LandUnitId>(
                      value: _inputUnit,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _primary,
                      ),
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                      dropdownColor: Colors.white,
                      items: LandUnitSystem.allConversionUnits.map((id) {
                        return DropdownMenuItem(
                          value: id,
                          child: Text(
                            LandUnitSystem.shortName(context, id),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _inputUnit = v);
                          _calculate();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Text(
            loc.presets,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _preset('1 ${loc.acre}', LandUnitSystem.sqftPerAcre),
              _preset('1 ${loc.bigha}', LandUnitSystem.sqftPerBigha),
              _preset('1 ${loc.katha}', LandUnitSystem.sqftPerKatha),
              _preset('1 ${loc.shatak}', LandUnitSystem.sqftPerShatak),
              _preset('1000 ft²', 1000),
              _preset('1 ha', LandUnitSystem.sqftPerHectare),
            ],
          ),
        ],
      ),
    );
  }

  Widget _preset(String label, double sqft) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _setInputFromSqft(sqft),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primary.withValues(alpha: 0.18)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustCard(AppLocalizations loc) {
    return _ExpandableCard(
      icon: Icons.tune_rounded,
      iconColor: const Color(0xFF1976D2),
      title: loc.adjustArea,
      subtitle: loc.adjustAreaDesc,
      expanded: _showAdjust,
      onToggle: () => setState(() => _showAdjust = !_showAdjust),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _segment(
                  label: loc.add,
                  icon: Icons.add_rounded,
                  selected: _adjustAdds,
                  color: const Color(0xFF2E7D32),
                  onTap: () => setState(() => _adjustAdds = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _segment(
                  label: loc.subtract,
                  icon: Icons.remove_rounded,
                  selected: !_adjustAdds,
                  color: const Color(0xFFD32F2F),
                  onTap: () => setState(() => _adjustAdds = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _adjustController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    hintText: '0',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LandUnitId>(
                      value: _adjustUnit,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: LandUnitSystem.allConversionUnits.map((id) {
                        return DropdownMenuItem(
                          value: id,
                          child: Text(
                            LandUnitSystem.shortName(context, id),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _adjustUnit = v);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_adjustController.text.isNotEmpty) _buildAdjustPreview(loc),
          if (_adjustController.text.isNotEmpty) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _adjustController.text.isEmpty
                  ? null
                  : _applyAdjustment,
              icon: Icon(
                _adjustAdds ? Icons.add_rounded : Icons.remove_rounded,
              ),
              label: Text(loc.applyAdjustment),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustPreview(AppLocalizations loc) {
    final v = double.tryParse(_adjustController.text) ?? 0;
    final deltaSqft = LandUnitSystem.toSqft(v, _adjustUnit);
    final current = _currentSqft;
    final newSqft = _adjustAdds
        ? current + deltaSqft
        : (current - deltaSqft).clamp(0.0, double.infinity);
    final newInUnit = LandUnitSystem.fromSqft(newSqft, _inputUnit);
    final unitShort = LandUnitSystem.shortName(context, _inputUnit);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.currentTotal,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${LandUnitSystem.fromSqft(current, _inputUnit).toStringAsFixed(2)} $unitShort',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.newTotal,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${newInUnit.toStringAsFixed(2)} $unitShort',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombineCard(AppLocalizations loc) {
    final totalSqft = _sumCombineSqft();
    return _ExpandableCard(
      icon: Icons.calculate_rounded,
      iconColor: const Color(0xFF7B1FA2),
      title: loc.combineUnits,
      subtitle: loc.compoundTarget,
      expanded: _showCombine,
      onToggle: () => setState(() => _showCombine = !_showCombine),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._combineControllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      LandUnitSystem.shortName(context, entry.key),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: entry.value,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '0',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.summarize_rounded,
                  size: 16,
                  color: Color(0xFF7B1FA2),
                ),
                const SizedBox(width: 6),
                Text(
                  loc.total,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
                const Spacer(),
                Text(
                  '${totalSqft.toStringAsFixed(2)} ft²',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: totalSqft > 0 ? _applyCombined : null,
              icon: const Icon(Icons.check_rounded),
              label: Text(loc.useCombined),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(AppLocalizations loc) {
    return _ExpandableCard(
      icon: Icons.settings_rounded,
      iconColor: const Color(0xFF455A64),
      title: loc.configureUnits,
      subtitle: loc.dragToReorder,
      expanded: _showConfigure,
      onToggle: () => setState(() => _showConfigure = !_showConfigure),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _units.length,
          onReorder: _onReorder,
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) {
            return Material(
              elevation: 6,
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final u = _units[index];
            final factor = LandUnitSystem.sqftFactor(u.id);
            return Container(
              key: ValueKey(u.id),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: u.isEnabled
                    ? const Color(0xFFF1F8F4)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: u.isEnabled
                      ? _primary.withValues(alpha: 0.2)
                      : Colors.grey.shade200,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                leading: Checkbox(
                  value: u.isEnabled,
                  activeColor: _primary,
                  onChanged: (v) => _toggleUnit(u, v),
                ),
                title: Text(
                  LandUnitSystem.name(context, u.id),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                subtitle: Text(
                  '1 = ${factor.toStringAsFixed(2)} ft²',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: Colors.grey[500],
                      size: 18,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExpandableCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
