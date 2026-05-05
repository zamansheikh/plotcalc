import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../core/utils/land_unit_system.dart';

class KhotiyanCalculatorPage extends StatefulWidget {
  const KhotiyanCalculatorPage({super.key});

  @override
  State<KhotiyanCalculatorPage> createState() =>
      _KhotiyanCalculatorPageState();
}

class _KhotiyanCalculatorPageState extends State<KhotiyanCalculatorPage> {
  static const _primary = Color(0xFFEF6C00);
  static const _bg = Color(0xFFF6F8FA);

  // Hierarchy: 16 Ana = 1; 20 Gonda = 1 Ana; 4 Kora = 1 Gonda;
  // 3 Kranti = 1 Kora; 20 Til = 1 Kranti.
  static const int tilPerKranti = 20;
  static const int krantiPerKora = 3;
  static const int koraPerGonda = 4;
  static const int gondaPerAna = 20;
  static const int anaPerWhole = 16;
  static const int totalTilInWhole =
      anaPerWhole * gondaPerAna * koraPerGonda * krantiPerKora * tilPerKranti;

  int _selectedAna = 0;
  int _selectedGonda = 0;
  int _selectedKora = 0;
  int _selectedKranti = 0;
  int _selectedTil = 0;

  final TextEditingController _totalLandController = TextEditingController();
  LandUnitId _selectedLandUnit = LandUnitId.shatak;

  @override
  void initState() {
    super.initState();
    _totalLandController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _totalLandController.dispose();
    super.dispose();
  }

  int get _totalTil {
    int t = _selectedTil;
    t += _selectedKranti * tilPerKranti;
    t += _selectedKora * krantiPerKora * tilPerKranti;
    t += _selectedGonda * koraPerGonda * krantiPerKora * tilPerKranti;
    t +=
        _selectedAna *
        gondaPerAna *
        koraPerGonda *
        krantiPerKora *
        tilPerKranti;
    return t;
  }

  double get _share => _totalTil / totalTilInWhole;

  double get _totalLandSqft {
    final v = double.tryParse(_totalLandController.text);
    if (v == null || v <= 0) return 0;
    return LandUnitSystem.toSqft(v, _selectedLandUnit);
  }

  double get _userLandSqft => _totalLandSqft * _share;

  void _reset() {
    setState(() {
      _selectedAna = 0;
      _selectedGonda = 0;
      _selectedKora = 0;
      _selectedKranti = 0;
      _selectedTil = 0;
      _totalLandController.clear();
    });
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
                    _buildShareCard(loc),
                    const SizedBox(height: 14),
                    _buildSelectorCard(loc),
                    const SizedBox(height: 14),
                    _buildTotalLandCard(loc),
                    if (_share > 0 && _userLandSqft > 0) ...[
                      const SizedBox(height: 14),
                      _buildResultsCard(loc),
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

  Widget _buildHeader(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE65100), Color(0xFFEF6C00), Color(0xFFFB8C00)],
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
              Icons.grid_view_rounded,
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
                  loc.khotiyanCalculator,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  loc.khotiyanSubtitle,
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
            tooltip: loc.clear,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _reset,
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(AppLocalizations loc) {
    final share = _share;
    final pct = (share * 100).toStringAsFixed(4);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFB8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                loc.hissya,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                share.toStringAsFixed(6),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: share.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$_totalTil / $totalTilInWhole ${loc.til}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: _primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                loc.selectUnits,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _stepperRow(
            label: loc.ana,
            sub: '/16',
            value: _selectedAna,
            max: 16,
            onChanged: (v) => setState(() => _selectedAna = v),
          ),
          _stepperRow(
            label: loc.gonda,
            sub: '/20',
            value: _selectedGonda,
            max: 19,
            onChanged: (v) => setState(() => _selectedGonda = v),
          ),
          _stepperRow(
            label: loc.kora,
            sub: '/4',
            value: _selectedKora,
            max: 3,
            onChanged: (v) => setState(() => _selectedKora = v),
          ),
          _stepperRow(
            label: loc.kranti,
            sub: '/3',
            value: _selectedKranti,
            max: 2,
            onChanged: (v) => setState(() => _selectedKranti = v),
          ),
          _stepperRow(
            label: loc.til,
            sub: '/20',
            value: _selectedTil,
            max: 19,
            onChanged: (v) => setState(() => _selectedTil = v),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _stepperRow({
    required String label,
    required String sub,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: Colors.grey.shade100))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          _stepperBtn(
            icon: Icons.remove_rounded,
            enabled: value > 0,
            onTap: () => onChanged(value - 1),
          ),
          Container(
            width: 56,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
          ),
          _stepperBtn(
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? _primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? _primary : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildTotalLandCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.landscape_rounded,
                color: _primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                loc.totalLand,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
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
                  controller: _totalLandController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LandUnitId>(
                      value: _selectedLandUnit,
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
                          setState(() => _selectedLandUnit = v);
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
    );
  }

  Widget _buildResultsCard(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.yourLand,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          ..._buildResultRows(),
        ],
      ),
    );
  }

  List<Widget> _buildResultRows() {
    final units = LandUnitSystem.allConversionUnits;
    return List.generate(units.length, (i) {
      final unit = units[i];
      final value = LandUnitSystem.fromSqft(_userLandSqft, unit);
      return Container(
        decoration: BoxDecoration(
          border: i < units.length - 1
              ? Border(bottom: BorderSide(color: Colors.grey.shade100))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                LandUnitSystem.name(context, unit),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Text(
              LandUnitSystem.formatNumber(value),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
          ],
        ),
      );
    });
  }
}
