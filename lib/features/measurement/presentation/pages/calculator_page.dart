import 'package:flutter/material.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final TextEditingController _areaController = TextEditingController();
  String _selectedUnit = 'squareMeters';
  Map<String, double> _results = {};

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  void _calculateConversions() {
    final loc = AppLocalizations.of(context);
    final input = double.tryParse(_areaController.text);

    if (input == null || input <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.enterAreaValue)));
      return;
    }

    setState(() {
      _results = {};

      // Convert from selected unit to square meters first
      double areaInSqMeters = 0;
      switch (_selectedUnit) {
        case 'squareMeters':
          areaInSqMeters = input;
          break;
        case 'squareFeet':
          areaInSqMeters = input * 0.092903;
          break;
        case 'hectares':
          areaInSqMeters = input * 10000;
          break;
        case 'acres':
          areaInSqMeters = input * 4046.86;
          break;
        case 'bigha':
          areaInSqMeters = input * 1348.95;
          break;
        case 'katha':
          areaInSqMeters = input * 67.026;
          break;
        case 'shatak':
          areaInSqMeters = input * 40.4686;
          break;
        case 'bighaMymensingh':
          areaInSqMeters = input * 5260.91;
          break;
        case 'kathaMymensingh':
          areaInSqMeters = input * 263.046;
          break;
        case 'chotak':
          areaInSqMeters = input * 4.189;
          break;
      }

      // Convert to all units
      _results = {
        'squareMeters': areaInSqMeters,
        'squareFeet': areaInSqMeters / 0.092903,
        'hectares': areaInSqMeters / 10000,
        'acres': areaInSqMeters / 4046.86,
        'bigha': areaInSqMeters / 1348.95,
        'katha': areaInSqMeters / 67.026,
        'shatak': areaInSqMeters / 40.4686,
        'bighaMymensingh': areaInSqMeters / 5260.91,
        'kathaMymensingh': areaInSqMeters / 263.046,
        'chotak': areaInSqMeters / 4.189,
      };
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
      appBar: AppBar(title: Text(loc.calculator)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                      Icons.calculate,
                      size: 48,
                      color: isDarkTheme
                          ? Colors.lightGreen.shade300
                          : AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.calculator,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDarkTheme
                            ? Colors.lightGreen.shade300
                            : AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Convert between different area units',
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

            // Input Section
            Text(
              loc.enterAreaValue,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _areaController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter value...',
                prefixIcon: const Icon(Icons.input),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Unit Selection
            Text(
              loc.convertFrom,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _selectedUnit,
              items: [
                DropdownMenuItem(
                  value: 'squareMeters',
                  child: Text(loc.squareMeters),
                ),
                DropdownMenuItem(
                  value: 'squareFeet',
                  child: Text(loc.squareFeet),
                ),
                DropdownMenuItem(value: 'hectares', child: Text(loc.hectares)),
                DropdownMenuItem(value: 'acres', child: Text(loc.acres)),
                DropdownMenuItem(value: 'bigha', child: Text(loc.bigha)),
                DropdownMenuItem(value: 'katha', child: Text(loc.katha)),
                DropdownMenuItem(value: 'shatak', child: Text(loc.shatak)),
                DropdownMenuItem(
                  value: 'bighaMymensingh',
                  child: Text('Bigha (Mymensingh)'),
                ),
                DropdownMenuItem(
                  value: 'kathaMymensingh',
                  child: Text('Katha (Mymensingh)'),
                ),
                DropdownMenuItem(value: 'chotak', child: Text('Chotak')),
              ],
              onChanged: (value) {
                setState(() => _selectedUnit = value!);
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
            const SizedBox(height: 24),

            // Calculate Button
            ElevatedButton.icon(
              onPressed: _calculateConversions,
              icon: const Icon(Icons.calculate),
              label: Text(loc.calculate),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Results Section
            if (_results.isNotEmpty) ...[
              Text(
                loc.result,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Results Grid
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildResultTile(
                      'Square Meters (m²)',
                      _results['squareMeters']!,
                      0,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildResultTile(
                      'Square Feet (ft²)',
                      _results['squareFeet']!,
                      1,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildResultTile('Hectares (ha)', _results['hectares']!, 2),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildResultTile('Acres (ac)', _results['acres']!, 3),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildResultTile('Bigha', _results['bigha']!, 4),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildResultTile('Katha', _results['katha']!, 5),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildResultTile('Shatak', _results['shatak']!, 6),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildResultTile(
                      'Bigha (Mymensingh)',
                      _results['bighaMymensingh']!,
                      7,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildResultTile(
                      'Katha (Mymensingh)',
                      _results['kathaMymensingh']!,
                      8,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildResultTile('Chotak', _results['chotak']!, 9),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(String label, double value, int index) {
    final color = index % 2 == 0 ? Colors.transparent : Colors.grey.shade50;
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            _formatResult(value),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
