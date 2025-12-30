import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

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
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryColor;
    final loc = AppLocalizations.of(context);
    final shareText =
        "${_calculatedShare.toStringAsFixed(6)} ( ${loc.hissya} )";

    final Map<String, String> _unitLabels = {
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
      appBar: AppBar(title: Text(loc.khotiyanCalculator)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              color: isDarkTheme
                  ? primaryColor.withValues(alpha: 0.2)
                  : primaryColor.withValues(alpha: 0.1),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.calculate, size: 48, color: primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      loc.calculateShare,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Text(loc.selectUnitsSubtitle),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Unit Selection Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.selectUnits,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ana
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: loc.ana,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      value: _selectedAna,
                      items: List.generate(17, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text(_getAnaSymbol(index, loc)),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedAna = val);
                          _calculate();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Gonda
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: loc.gonda,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      value: _selectedGonda,
                      items: List.generate(20, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text(_getGondaSymbol(index, loc)),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedGonda = val);
                          _calculate();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Kora
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: loc.kora,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      value: _selectedKora,
                      items: List.generate(4, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text(_getKoraSymbol(index, loc)),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedKora = val);
                          _calculate();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Kranti
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: loc.kranti,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      value: _selectedKranti,
                      items: List.generate(3, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text(_getKrantiSymbol(index, loc)),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedKranti = val);
                          _calculate();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Til
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: loc.til,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      value: _selectedTil,
                      items: List.generate(20, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text(_getTilSymbol(index, loc)),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedTil = val);
                          _calculate();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Total Land Input
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.totalLand,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _totalLandController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: loc.amount,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: loc.unit,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                            value: _selectedLandUnit,
                            isExpanded: true,
                            items: _unitLabels.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedLandUnit = val);
                                _calculate();
                              }
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

            // Results
            if (_calculatedShare > 0)
              Card(
                color: isDarkTheme ? Colors.grey[800] : Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: primaryColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        loc.results,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Hissya Result
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${loc.hissya}:",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              shareText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_results.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${loc.yourLand}:",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Detailed Results Grid
                        ..._results.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _unitLabels[entry.key] ?? entry.key,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  "${entry.value.toStringAsFixed(4)}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
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
              ),
          ],
        ),
      ),
    );
  }
}
