import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';

class KhotiyanCalculatorPage extends StatefulWidget {
  const KhotiyanCalculatorPage({super.key});

  @override
  State<KhotiyanCalculatorPage> createState() => _KhotiyanCalculatorPageState();
}

class _KhotiyanCalculatorPageState extends State<KhotiyanCalculatorPage> {
  // Selected values
  int _selectedAna = 0;
  int _selectedGonda = 0;
  int _selectedKora = 0;
  int _selectedKranti = 0;
  int _selectedTil = 0;

  final TextEditingController _totalLandController = TextEditingController();
  String _selectedLandUnit = 'shatak'; // Default unit

  double _calculatedShare = 0.0;
  Map<String, double> _results = {};

  // Constants for conversion
  static const int tilPerKranti = 20;
  static const int krantiPerKora = 3;
  static const int koraPerGonda = 4;
  static const int gondaPerAna = 20;
  static const int anaPerWhole = 16;

  // Total Til in 1 unit (16 Ana)
  // 16 * 20 * 4 * 3 * 20 = 76800
  static const int totalTilInWhole =
      anaPerWhole * gondaPerAna * koraPerGonda * krantiPerKora * tilPerKranti;

  @override
  void initState() {
    super.initState();
    _totalLandController.addListener(_calculate);
  }

  @override
  void dispose() {
    _totalLandController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      // Calculate total selected Til
      int currentTil = _selectedTil;
      currentTil += _selectedKranti * tilPerKranti;
      currentTil += _selectedKora * krantiPerKora * tilPerKranti;
      currentTil +=
          _selectedGonda * koraPerGonda * krantiPerKora * tilPerKranti;
      currentTil +=
          _selectedAna *
          gondaPerAna *
          koraPerGonda *
          krantiPerKora *
          tilPerKranti;

      // Calculate share fraction
      _calculatedShare = currentTil / totalTilInWhole;

      // Calculate land share
      double totalLandInput = double.tryParse(_totalLandController.text) ?? 0.0;

      if (totalLandInput > 0) {
        // 1. Convert input to Square Meters
        double totalLandSqMeters = _convertToSqMeters(
          totalLandInput,
          _selectedLandUnit,
        );

        // 2. Calculate user's share in Square Meters
        double userLandSqMeters = totalLandSqMeters * _calculatedShare;

        // 3. Convert user's share to all units
        _results = {
          'squareMeters': userLandSqMeters,
          'squareFeet': userLandSqMeters / 0.092903,
          'hectares': userLandSqMeters / 10000,
          'acres': userLandSqMeters / 4046.86,
          'bigha': userLandSqMeters / 1335.46,
          'katha': userLandSqMeters / 66.773,
          'shatak': userLandSqMeters / 40.4686,
          'bighaMymensingh': userLandSqMeters / 5260.91,
          'kathaMymensingh': userLandSqMeters / 263.046,
          'chotak': userLandSqMeters / 4.173,
        };
      } else {
        _results = {};
      }
    });
  }

  double _convertToSqMeters(double value, String unit) {
    switch (unit) {
      case 'squareMeters':
        return value;
      case 'squareFeet':
        return value * 0.092903;
      case 'hectares':
        return value * 10000;
      case 'acres':
        return value * 4046.86;
      case 'bigha':
        return value * 1335.46;
      case 'katha':
        return value * 66.773;
      case 'shatak':
        return value * 40.4686;
      case 'bighaMymensingh':
        return value * 5260.91;
      case 'kathaMymensingh':
        return value * 263.046;
      case 'chotak':
        return value * 4.173;
      default:
        return 0;
    }
  }

  String _getAnaSymbol(int value, AppLocalizations loc) {
    if (value == 0) return "0 ${loc.ana}";
    const symbols = [
      "",
      "⁄",
      "৵",
      "৶",
      "৷",
      "৷⁄",
      "৷৵",
      "৷৶",
      "৷৷",
      "৷৷⁄",
      "৷৷৵",
      "৷৷৶",
      "৸",
      "৸ ⁄",
      "৸৵",
      "৸৶",
      "১",
    ];
    if (value > 0 && value < symbols.length) {
      return "$value ${loc.ana}  ${symbols[value]}";
    }
    return "$value ${loc.ana}";
  }

  String _getGondaSymbol(int value, AppLocalizations loc) {
    if (value == 0) return "0 ${loc.gonda}";
    return "$value ${loc.gonda}";
  }

  String _getKoraSymbol(int value, AppLocalizations loc) {
    if (value == 0) return "0 ${loc.kora}";
    const symbols = ["", "৷", "৷৷", "৸"];
    if (value > 0 && value < symbols.length) {
      return "$value ${loc.kora}  ${symbols[value]}";
    }
    return "$value ${loc.kora}";
  }

  String _getKrantiSymbol(int value, AppLocalizations loc) {
    if (value == 0) return "0 ${loc.kranti}";
    const symbols = ["", "৴", "৴৴"];
    if (value > 0 && value < symbols.length) {
      return "$value ${loc.kranti}  ${symbols[value]}";
    }
    return "$value ${loc.kranti}";
  }

  String _getTilSymbol(int value, AppLocalizations loc) {
    if (value == 0) return "0 ${loc.til}";
    return "$value ${loc.til}";
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);
    final loc = AppLocalizations.of(context);
    final shareText =
        "${_calculatedShare.toStringAsFixed(6)} ( ${loc.hissya} )";

    final Map<String, String> unitLabels = {
      'squareMeters': loc.squareMeters,
      'squareFeet': loc.squareFeet,
      'hectares': loc.hectares,
      'acres': loc.acres,
      'bigha': loc.bigha,
      'katha': loc.katha,
      'shatak': loc.shatak,
      'bighaMymensingh': loc.bighaMymensingh,
      'kathaMymensingh': loc.kathaMymensingh,
      'chotak': loc.chotak,
    };

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Green gradient header
            Container(
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
                      Icons.account_balance_rounded,
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
                          loc.khotiyanCalculator,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.selectUnitsSubtitle,
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
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Unit Selection Card
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
                            loc.selectUnits,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Ana
                          _buildDropdownField(
                            label: loc.ana,
                            value: _selectedAna,
                            itemCount: 17,
                            symbolGetter: (i) => _getAnaSymbol(i, loc),
                            onChanged: (val) {
                              setState(() => _selectedAna = val);
                              _calculate();
                            },
                          ),
                          const SizedBox(height: 12),

                          // Gonda
                          _buildDropdownField(
                            label: loc.gonda,
                            value: _selectedGonda,
                            itemCount: 20,
                            symbolGetter: (i) => _getGondaSymbol(i, loc),
                            onChanged: (val) {
                              setState(() => _selectedGonda = val);
                              _calculate();
                            },
                          ),
                          const SizedBox(height: 12),

                          // Kora
                          _buildDropdownField(
                            label: loc.kora,
                            value: _selectedKora,
                            itemCount: 4,
                            symbolGetter: (i) => _getKoraSymbol(i, loc),
                            onChanged: (val) {
                              setState(() => _selectedKora = val);
                              _calculate();
                            },
                          ),
                          const SizedBox(height: 12),

                          // Kranti
                          _buildDropdownField(
                            label: loc.kranti,
                            value: _selectedKranti,
                            itemCount: 3,
                            symbolGetter: (i) => _getKrantiSymbol(i, loc),
                            onChanged: (val) {
                              setState(() => _selectedKranti = val);
                              _calculate();
                            },
                          ),
                          const SizedBox(height: 12),

                          // Til
                          _buildDropdownField(
                            label: loc.til,
                            value: _selectedTil,
                            itemCount: 20,
                            symbolGetter: (i) => _getTilSymbol(i, loc),
                            onChanged: (val) {
                              setState(() => _selectedTil = val);
                              _calculate();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Total Land Input
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
                            loc.totalLand,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _totalLandController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: loc.amount,
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedLandUnit,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                      ),
                                      items: unitLabels.entries.map((entry) {
                                        return DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(
                                            entry.value,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                            () => _selectedLandUnit = val,
                                          );
                                          _calculate();
                                        }
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
                    const SizedBox(height: 20),

                    // Results
                    if (_calculatedShare > 0)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              loc.results,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Hissya Result
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2E7D32,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${loc.hissya}:",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    shareText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (_results.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Divider(height: 1, color: Colors.grey.shade200),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "${loc.yourLand}:",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              ..._results.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        unitLabels[entry.key] ?? entry.key,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        entry.value.toStringAsFixed(4),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required int value,
    required int itemCount,
    required String Function(int) symbolGetter,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: List.generate(itemCount, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text(symbolGetter(index)),
                );
              }),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
