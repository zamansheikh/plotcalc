import 'package:flutter/material.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key});

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  final TextEditingController _inputController = TextEditingController();
  String _fromUnit = 'squareMeters';
  String _toUnit = 'squareFeet';
  double? _result;

  final Map<String, Map<String, dynamic>> units = {
    'squareMeters': {
      'label': 'Square Meters (m²)',
      'symbol': 'm²',
      'factor': 1.0,
    },
    'squareFeet': {
      'label': 'Square Feet (ft²)',
      'symbol': 'ft²',
      'factor': 0.092903,
    },
    'hectares': {'label': 'Hectares (ha)', 'symbol': 'ha', 'factor': 10000.0},
    'acres': {'label': 'Acres (ac)', 'symbol': 'ac', 'factor': 4046.86},
    'bigha': {'label': 'Bigha', 'symbol': 'Bigha', 'factor': 1348.95},
    'katha': {'label': 'Katha', 'symbol': 'Katha', 'factor': 67.026},
    'shatak': {'label': 'Shatak', 'symbol': 'Shatak', 'factor': 40.4686},
    'chotak': {'label': 'Chotak', 'symbol': 'Chotak', 'factor': 4.189},
    'bighaMymensingh': {
      'label': 'Bigha (Mymensingh)',
      'symbol': 'Bigha (Mym)',
      'factor': 5260.91,
    },
    'kathaMymensingh': {
      'label': 'Katha (Mymensingh)',
      'symbol': 'Katha (Mym)',
      'factor': 263.046,
    },
  };

  String _getLocalizedUnitName(BuildContext context, String unitId) {
    final loc = AppLocalizations.of(context);
    switch (unitId) {
      case 'squareMeters':
        return loc.metersTitle;
      case 'squareFeet':
        return loc.squareFeet;
      case 'hectares':
        return loc.hectares;
      case 'acres':
        return loc.acres;
      case 'bigha':
        return loc.bighaStandard;
      case 'katha':
        return loc.kathaStandard;
      case 'shatak':
        return loc.shatak;
      case 'chotak':
        return loc.chotak;
      case 'bighaMymensingh':
        return loc.bighaMymensingh;
      case 'kathaMymensingh':
        return loc.kathaMymensingh;
      default:
        return unitId;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _convert() {
    final input = double.tryParse(_inputController.text);
    final loc = AppLocalizations.of(context);

    if (input == null || input < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.enterAreaValue)));
      return;
    }

    setState(() {
      // Convert to square meters
      double inSquareMeters = input * units[_fromUnit]!['factor'];
      // Convert to target unit
      _result = inSquareMeters / units[_toUnit]!['factor'];
    });
  }

  String _formatResult(double value) {
    if (value >= 1) {
      return value.toStringAsFixed(2);
    }
    return value.toStringAsFixed(6);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(loc.unitConverter)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              color: isDarkTheme
                  ? AppTheme.primaryColor.withValues(alpha: 0.28)
                  : AppTheme.primaryColor.withValues(alpha: 0.13),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      size: 48,
                      color: isDarkTheme
                          ? Colors.lightGreen.shade300
                          : AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.unitConverter,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDarkTheme
                            ? Colors.lightGreen.shade300
                            : AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.convertInstantly,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkTheme
                            ? Colors.grey.shade200
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Input Value
            Text(
              loc.enterAreaValue,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inputController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _convert(),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: const Icon(Icons.input),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // From Unit
            Text(
              loc.convertFrom,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _fromUnit,
              items: units.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(_getLocalizedUnitName(context, e.key)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _fromUnit = value!);
                _convert();
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Swap Button
            Center(
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  setState(() {
                    final temp = _fromUnit;
                    _fromUnit = _toUnit;
                    _toUnit = temp;
                  });
                  _convert();
                },
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.swap_vert),
              ),
            ),
            const SizedBox(height: 16),

            // To Unit
            Text(
              loc.convertTo,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _toUnit,
              items: units.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(_getLocalizedUnitName(context, e.key)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _toUnit = value!);
                _convert();
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Result Display
            if (_result != null)
              Card(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkTheme
                          ? [
                              AppTheme.primaryColor.withValues(alpha: 0.2),
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                            ]
                          : [
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                              AppTheme.primaryColor.withValues(alpha: 0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        loc.result,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isDarkTheme
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatResult(_result!),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme
                                  ? Colors.lightGreen.shade300
                                  : AppTheme.primaryColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLocalizedUnitName(context, _toUnit),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkTheme
                              ? Colors.grey.shade400
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDarkTheme
                        ? Colors.grey.shade600
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Enter a value to see the result',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkTheme
                        ? Colors.grey.shade400
                        : Colors.grey.shade500,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Quick Reference
            _buildQuickReference(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReference() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Reference',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickRefChip('1 m² = 10.76 ft²'),
            _buildQuickRefChip('1 acre = 4,047 m²'),
            _buildQuickRefChip('1 ha = 10,000 m²'),
            _buildQuickRefChip('1 bigha ≈ 1,338 m²'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickRefChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
