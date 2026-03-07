import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../core/utils/land_area_breakdown.dart';
import '../widgets/land_area_breakdown_widget.dart';

class LandCalculatorPage extends StatefulWidget {
  const LandCalculatorPage({super.key});

  @override
  State<LandCalculatorPage> createState() => _LandCalculatorPageState();
}

class _LandCalculatorPageState extends State<LandCalculatorPage> {
  final TextEditingController _inputController = TextEditingController();
  String _inputUnit = 'squareFeet';

  // Initial default units
  late List<LandUnitDef> _units;

  List<String> _breakdown = [];
  Map<String, int> _unitValues = {};
  double _remainderSqFt = 0;
  String? _lastUnitDecimal;

  @override
  void initState() {
    super.initState();
    _resetUnits();
  }

  void _resetUnits() {
    setState(() {
      _units = LandAreaCalculator.getDefaultUnits();
      _calculate();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _calculate() {
    final input = double.tryParse(_inputController.text);
    if (input == null || input < 0) {
      setState(() {
        _breakdown = [];
        _unitValues = {};
        _remainderSqFt = 0;
        _lastUnitDecimal = null;
      });
      return;
    }

    // Convert input to Square Feet first
    double totalSqFt = 0;
    switch (_inputUnit) {
      case 'squareMeters':
        totalSqFt = input * 10.7639;
        break;
      case 'squareFeet':
        totalSqFt = input;
        break;
      case 'acres':
        totalSqFt = input * 43560.0;
        break;
      case 'bigha':
        totalSqFt = input * 14520.0;
        break;
      case 'katha':
        totalSqFt = input * 721.46;
        break;
      case 'shatak':
        totalSqFt = input * 435.6;
        break;
      case 'bighaMymensingh':
        totalSqFt = input * 56628.0;
        break;
      case 'kathaMymensingh':
        totalSqFt = input * 2831.4;
        break;
      case 'chotak':
        totalSqFt = input * 45.09;
        break;
    }

    final result = LandAreaCalculator.calculate(totalSqFt, _units);

    setState(() {
      _breakdown = result.breakdown;
      _unitValues = result.unitValues;
      _remainderSqFt = result.remainderSqFt;
      _lastUnitDecimal = result.lastUnitDecimal;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final LandUnitDef item = _units.removeAt(oldIndex);
      _units.insert(newIndex, item);
      _calculate();
    });
  }

  String _getLocalizedUnitName(BuildContext context, String unitId) {
    final loc = AppLocalizations.of(context);
    switch (unitId) {
      case 'squareFeet':
        return loc.squareFeet;
      case 'squareMeters':
        return loc.metersTitle; // Using full title for dropdown
      case 'acres':
      case 'acre':
        return loc.acres;
      case 'bigha':
        return loc.bighaStandard;
      case 'katha':
        return loc.kathaStandard;
      case 'shatak':
        return loc.shatak;
      case 'bighaMymensingh':
        return loc.bighaMymensingh;
      case 'kathaMymensingh':
        return loc.kathaMymensingh;
      case 'chotak':
        return loc.chotak;
      default:
        return unitId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const primaryColor = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Green gradient header
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.landscape_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.landCalculator,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.dragToReorder,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    tooltip: loc.resetUnits,
                    onPressed: _resetUnits,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Input Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.totalArea,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _inputController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0.0',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  onChanged: (_) => _calculate(),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _inputUnit,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'squareFeet',
                                          child: Text(loc.squareFeet),
                                        ),
                                        DropdownMenuItem(
                                          value: 'squareMeters',
                                          child: Text(loc.metersTitle),
                                        ),
                                        DropdownMenuItem(
                                          value: 'acres',
                                          child: Text(loc.acres),
                                        ),
                                        DropdownMenuItem(
                                          value: 'bigha',
                                          child: Text(loc.bighaStandard),
                                        ),
                                        DropdownMenuItem(
                                          value: 'katha',
                                          child: Text(loc.kathaStandard),
                                        ),
                                        DropdownMenuItem(
                                          value: 'shatak',
                                          child: Text(loc.shatak),
                                        ),
                                        DropdownMenuItem(
                                          value: 'bighaMymensingh',
                                          child: Text(loc.bighaMymensingh),
                                        ),
                                        DropdownMenuItem(
                                          value: 'kathaMymensingh',
                                          child: Text(loc.kathaMymensingh),
                                        ),
                                        DropdownMenuItem(
                                          value: 'chotak',
                                          child: Text(loc.chotak),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _inputUnit = value!;
                                          _calculate();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Results Section
                    if (_breakdown.isNotEmpty || _remainderSqFt > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: LandAreaBreakdownWidget(
                          result: LandAreaResult(
                            breakdown: _breakdown,
                            unitValues: _unitValues,
                            remainderSqFt: _remainderSqFt,
                            lastUnitDecimal: _lastUnitDecimal,
                          ),
                        ),
                      ),

                    // Unit Configuration Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.tune, size: 20, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            loc.unitConfiguration,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reorderable List
                    Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _units.length,
                        onReorder: _onReorder,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 4,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final unit = _units[index];
                          return Container(
                            key: ValueKey(unit.id),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                _getLocalizedUnitName(context, unit.id),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '1 ${_getLocalizedUnitName(context, unit.id)} ≈ ${unit.sqftFactor.toStringAsFixed(1)} sq.ft',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              value: unit.isEnabled,
                              activeColor: primaryColor,
                              secondary: ReorderableDragStartListener(
                                index: index,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.drag_handle_rounded,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              onChanged: (bool? value) {
                                setState(() {
                                  unit.isEnabled = value ?? false;

                                  // Auto-uncheck logic
                                  if (unit.isEnabled) {
                                    if (unit.id == 'bighaMymensingh') {
                                      // Uncheck Standard Bigha
                                      final standard = _units.firstWhere(
                                        (u) => u.id == 'bigha',
                                        orElse: () => unit,
                                      );
                                      if (standard != unit) {
                                        standard.isEnabled = false;
                                      }
                                    } else if (unit.id == 'kathaMymensingh') {
                                      // Uncheck Standard Katha
                                      final standard = _units.firstWhere(
                                        (u) => u.id == 'katha',
                                        orElse: () => unit,
                                      );
                                      if (standard != unit) {
                                        standard.isEnabled = false;
                                      }
                                    }
                                  }

                                  _calculate();
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
