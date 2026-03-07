import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key});

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  final TextEditingController _areaController = TextEditingController();
  String _selectedUnit = 'squareMeters';
  Map<String, double> _results = {};

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  void _calculateConversions() {
    final input = double.tryParse(_areaController.text);

    if (input == null || input <= 0) {
      setState(() => _results = {});
      return;
    }

    setState(() {
      _results = {};
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
          areaInSqMeters = input * 1335.46;
          break;
        case 'katha':
          areaInSqMeters = input * 66.773;
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
          areaInSqMeters = input * 4.173;
          break;
      }

      _results = {
        'squareMeters': areaInSqMeters,
        'squareFeet': areaInSqMeters / 0.092903,
        'hectares': areaInSqMeters / 10000,
        'acres': areaInSqMeters / 4046.86,
        'bigha': areaInSqMeters / 1335.46,
        'katha': areaInSqMeters / 66.773,
        'shatak': areaInSqMeters / 40.4686,
        'bighaMymensingh': areaInSqMeters / 5260.91,
        'kathaMymensingh': areaInSqMeters / 263.046,
        'chotak': areaInSqMeters / 4.173,
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, loc),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Input Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.enterAreaValue,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _areaController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: loc.enterValue,
                              prefixIcon: const Icon(
                                Icons.input_rounded,
                                color: Color(0xFF2E7D32),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => _calculateConversions(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.convertFrom,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedUnit,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                items: _buildDropdownItems(loc),
                                onChanged: (value) {
                                  setState(() => _selectedUnit = value!);
                                  _calculateConversions();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_results.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        loc.result,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildResultRow(
                              'Square Meters (m²)',
                              _results['squareMeters']!,
                              isFirst: true,
                            ),
                            _buildResultRow(
                              'Square Feet (ft²)',
                              _results['squareFeet']!,
                            ),
                            _buildResultRow(
                              'Hectares (ha)',
                              _results['hectares']!,
                            ),
                            _buildResultRow('Acres (ac)', _results['acres']!),
                            _buildResultRow('Bigha', _results['bigha']!),
                            _buildResultRow('Katha', _results['katha']!),
                            _buildResultRow('Shatak', _results['shatak']!),
                            _buildResultRow(
                              'Bigha (Mymensingh)',
                              _results['bighaMymensingh']!,
                            ),
                            _buildResultRow(
                              'Katha (Mymensingh)',
                              _results['kathaMymensingh']!,
                            ),
                            _buildResultRow(
                              'Chotak',
                              _results['chotak']!,
                              isLast: true,
                            ),
                          ],
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

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
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
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
              Icons.swap_horiz_rounded,
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
                  loc.unitConverter,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.convertBetweenUnits,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(AppLocalizations loc) {
    return [
      DropdownMenuItem(value: 'squareMeters', child: Text(loc.metersTitle)),
      DropdownMenuItem(value: 'squareFeet', child: Text(loc.squareFeet)),
      DropdownMenuItem(value: 'hectares', child: Text(loc.hectares)),
      DropdownMenuItem(value: 'acres', child: Text(loc.acres)),
      DropdownMenuItem(value: 'bigha', child: Text(loc.bighaStandard)),
      DropdownMenuItem(value: 'katha', child: Text(loc.kathaStandard)),
      DropdownMenuItem(value: 'shatak', child: Text(loc.shatak)),
      DropdownMenuItem(
        value: 'bighaMymensingh',
        child: Text(loc.bighaMymensingh),
      ),
      DropdownMenuItem(
        value: 'kathaMymensingh',
        child: Text(loc.kathaMymensingh),
      ),
      DropdownMenuItem(value: 'chotak', child: Text(loc.chotak)),
    ];
  }

  Widget _buildResultRow(
    String label,
    double value, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        if (!isFirst) Divider(height: 1, color: Colors.grey.shade100),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                _formatResult(value),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
