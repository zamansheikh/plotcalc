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

  // Define units sorted by size (Largest to Smallest)
  // Note: Bigha (Mymensingh) is ~56628 sqft, which is larger than Acre (43560 sqft)
  final List<LandUnitDef> _units = [
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

  List<String> _breakdown = [];
  double _remainderSqFt = 0;

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
    }

    List<String> results = [];
    double currentArea = totalSqFt;

    for (var unit in _units) {
      if (unit.isEnabled && currentArea >= unit.sqftFactor) {
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

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Land Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Area',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _inputController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter value',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _inputUnit,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
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
                            ],
                            onChanged: (value) {
                              setState(() {
                                _inputUnit = value!;
                                _calculate();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Unit Toggles
            const Text(
              'Active Units (Drag to reorder or toggle)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _units.map((unit) {
                  return CheckboxListTile(
                    title: Text(unit.name),
                    subtitle: Text(
                      '1 ${unit.name} ≈ ${unit.sqftFactor.toStringAsFixed(2)} sq.ft',
                    ),
                    value: unit.isEnabled,
                    activeColor: primaryColor,
                    onChanged: (bool? value) {
                      setState(() {
                        unit.isEnabled = value ?? false;
                        _calculate();
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_breakdown.isNotEmpty || _remainderSqFt > 0)
              Card(
                color: isDarkTheme
                    ? Colors.grey.shade800
                    : Colors.green.shade50,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Breakdown Result',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_breakdown.isNotEmpty)
                        ..._breakdown.map(
                          (part) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              part,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_remainderSqFt > 0.01) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          '+ ${_remainderSqFt.toStringAsFixed(2)} sq.ft',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          '(approx. ${(_remainderSqFt / 10.7639).toStringAsFixed(2)} sq.m)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
