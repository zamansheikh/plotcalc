import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/land_unit_system.dart';

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key});

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

enum _UnitGroup { all, metric, standard, mymensingh }

class _UnitConverterPageState extends State<UnitConverterPage> {
  static const _primary = Color(0xFF00838F);
  static const _bg = Color(0xFFF6F8FA);

  final TextEditingController _controller = TextEditingController();
  LandUnitId _selectedUnit = LandUnitId.shatak;
  _UnitGroup _filter = _UnitGroup.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _inputSqft {
    final v = double.tryParse(_controller.text);
    if (v == null || v <= 0) return 0;
    return LandUnitSystem.toSqft(v, _selectedUnit);
  }

  List<LandUnitId> get _filteredUnits {
    const metric = [
      LandUnitId.squareMeter,
      LandUnitId.squareFeet,
      LandUnitId.hectare,
      LandUnitId.acre,
    ];
    const standard = [
      LandUnitId.bigha,
      LandUnitId.katha,
      LandUnitId.shatak,
      LandUnitId.chotak,
    ];
    const mymensingh = [
      LandUnitId.bighaMymensingh,
      LandUnitId.kathaMymensingh,
    ];
    switch (_filter) {
      case _UnitGroup.all:
        return LandUnitSystem.allConversionUnits;
      case _UnitGroup.metric:
        return metric;
      case _UnitGroup.standard:
        return standard;
      case _UnitGroup.mymensingh:
        return mymensingh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final hasInput = _inputSqft > 0;

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
                    const SizedBox(height: 14),
                    _buildFilterChips(loc),
                    const SizedBox(height: 14),
                    _buildResultsCard(loc, hasInput),
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
          colors: [Color(0xFF006064), Color(0xFF00838F), Color(0xFF00ACC1)],
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
              Icons.swap_horiz_rounded,
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
                  loc.unitConverter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  loc.convertSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
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
              const Icon(
                Icons.input_rounded,
                color: _primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                loc.from,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              if (_controller.text.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() => _controller.clear());
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
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _controller,
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
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LandUnitId>(
                      value: _selectedUnit,
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
                        if (v != null) setState(() => _selectedUnit = v);
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

  Widget _buildFilterChips(AppLocalizations loc) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(loc.all, _UnitGroup.all),
          const SizedBox(width: 8),
          _filterChip(loc.metric, _UnitGroup.metric),
          const SizedBox(width: 8),
          _filterChip(loc.standard, _UnitGroup.standard),
          const SizedBox(width: 8),
          _filterChip(loc.mymensingh, _UnitGroup.mymensingh),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _UnitGroup group) {
    final selected = _filter == group;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _filter = group),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard(AppLocalizations loc, bool hasInput) {
    final units = _filteredUnits;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.list_alt_rounded,
                  color: _primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.result,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                if (hasInput)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _copyAllResults(loc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: _primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            loc.copy,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!hasInput)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
              child: Column(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    size: 40,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.enterAreaValue,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: List.generate(units.length, (i) {
                final unit = units[i];
                final value = LandUnitSystem.fromSqft(_inputSqft, unit);
                final isSource = unit == _selectedUnit;
                return _ResultRow(
                  label: LandUnitSystem.name(context, unit),
                  value: LandUnitSystem.formatNumber(value),
                  highlighted: isSource,
                  isLast: i == units.length - 1,
                  onCopy: () => _copyOne(unit, value),
                );
              }),
            ),
        ],
      ),
    );
  }

  void _copyOne(LandUnitId unit, double value) {
    final text =
        '${LandUnitSystem.formatNumber(value)} ${LandUnitSystem.shortName(context, unit)}';
    Clipboard.setData(ClipboardData(text: text));
    _showSnack(AppLocalizations.of(context).copied);
  }

  void _copyAllResults(AppLocalizations loc) {
    final lines = <String>[];
    for (final unit in _filteredUnits) {
      final v = LandUnitSystem.fromSqft(_inputSqft, unit);
      lines.add(
        '${LandUnitSystem.name(context, unit)}: ${LandUnitSystem.formatNumber(v)}',
      );
    }
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    _showSnack(loc.copied);
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;
  final bool isLast;
  final VoidCallback onCopy;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.highlighted,
    required this.isLast,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCopy,
      child: Container(
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFE0F7FA) : null,
          border: !isLast
              ? Border(bottom: BorderSide(color: Colors.grey.shade100))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (highlighted)
              Container(
                width: 4,
                height: 18,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00838F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: highlighted ? const Color(0xFF006064) : Colors.grey[800],
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: highlighted
                    ? const Color(0xFF006064)
                    : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.copy_rounded,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
