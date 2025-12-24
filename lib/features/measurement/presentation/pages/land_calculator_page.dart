import 'package:flutter/material.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

class LandUnitDef {
  final String id;
  final String name;
  final double sqftFactor;
  bool isEnabled;

  LandUnitDef({
    required this.id,
    required this.name,
    required this.sqftFactor,
    this.isEnabled = true,
  });
}

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
  double _remainderSqFt = 0;

  @override
  void initState() {
    super.initState();
    _resetUnits();
  }

  void _resetUnits() {
    setState(() {
      _units = [
        LandUnitDef(
          id: 'bighaMymensingh',
          name: 'Bigha (Mymensingh)',
          sqftFactor: 56628.0,
        ),
        LandUnitDef(id: 'acre', name: 'Acre', sqftFactor: 43560.0),
        LandUnitDef(id: 'bigha', name: 'Bigha (Standard)', sqftFactor: 14520.0),
        LandUnitDef(
          id: 'kathaMymensingh',
          name: 'Katha (Mymensingh)',
          sqftFactor: 2831.4,
        ),
        LandUnitDef(id: 'katha', name: 'Katha (Standard)', sqftFactor: 721.46),
        LandUnitDef(id: 'shatak', name: 'Shatak', sqftFactor: 435.6),
        LandUnitDef(id: 'chotak', name: 'Chotak', sqftFactor: 45.09),
      ];
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
        _remainderSqFt = 0;
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

    List<String> results = [];
    double currentArea = totalSqFt;

    // Calculate based on the current order of units
    for (var unit in _units) {
      if (unit.isEnabled && currentArea >= unit.sqftFactor) {
        // Avoid tiny floating point errors by using a small epsilon if needed,
        // but floor() usually handles it.
        int count = (currentArea / unit.sqftFactor).floor();
        if (count > 0) {
          results.add('$count ${unit.name}');
          currentArea -= count * unit.sqftFactor;
        }
      }
    }

    setState(() {
      _breakdown = results;
      _remainderSqFt = currentArea;
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

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryColor;
    final backgroundColor = isDarkTheme
        ? Colors.grey.shade900
        : Colors.grey.shade50;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Land Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Units',
            onPressed: _resetUnits,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Input Section
                  Card(
                    elevation: 0,
                    color: isDarkTheme ? Colors.grey.shade800 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Area',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkTheme
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: TextField(
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
                                    fillColor: isDarkTheme
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade50,
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
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkTheme
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _inputUnit,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'squareFeet',
                                          child: Text('Square Feet'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'squareMeters',
                                          child: Text('Square Meters'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'acres',
                                          child: Text('Acres'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'bigha',
                                          child: Text('Bigha (Std)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'katha',
                                          child: Text('Katha (Std)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'shatak',
                                          child: Text('Shatak'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'bighaMymensingh',
                                          child: Text('Bigha (Mym)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'kathaMymensingh',
                                          child: Text('Katha (Mym)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'chotak',
                                          child: Text('Chotak'),
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkTheme
                              ? [Colors.green.shade900, Colors.teal.shade900]
                              : [Colors.green.shade50, Colors.teal.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkTheme
                              ? Colors.green.shade800
                              : Colors.green.shade100,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Calculation Result',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme
                                  ? Colors.green.shade100
                                  : Colors.green.shade800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_breakdown.isNotEmpty)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: _breakdown.map((part) {
                                return Chip(
                                  label: Text(
                                    part,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkTheme
                                          ? Colors.white
                                          : Colors.green.shade900,
                                    ),
                                  ),
                                  backgroundColor: isDarkTheme
                                      ? Colors.green.shade800
                                      : Colors.white,
                                  elevation: 0,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              }).toList(),
                            ),
                          if (_remainderSqFt > 0.01) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkTheme
                                    ? Colors.black26
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '+ ${_remainderSqFt.toStringAsFixed(2)} sq.ft remainder',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkTheme
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Unit Configuration Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.tune, size: 20, color: primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Unit Configuration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drag to reorder priority. Uncheck to skip unit.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                          color: isDarkTheme
                              ? Colors.grey.shade800
                              : Colors.white,
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
                            color: isDarkTheme
                                ? Colors.grey.shade800
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkTheme
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              unit.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '1 ${unit.name} ≈ ${unit.sqftFactor.toStringAsFixed(1)} sq.ft',
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
                                  color: isDarkTheme
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade100,
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
    );
  }
}
