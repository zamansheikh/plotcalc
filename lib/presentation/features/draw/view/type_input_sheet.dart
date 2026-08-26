import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/geometry/presets.dart';
import '../../../../core/geometry/vertex.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/length_unit.dart';
import '../../../../l10n/l10n.dart';

const _errPositive = 'err.positive';
const _errTriangle = 'err.triangle';
const _errMinSides = 'err.minSides';

Future<List<Vertex>?> showTypeInputSheet(
  BuildContext context, {
  required ShapePreset preset,
  required LengthUnit lengthUnit,
  required Color accent,
}) {
  return showModalBottomSheet<List<Vertex>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _TypeInputSheet(
        preset: preset,
        lengthUnit: lengthUnit,
        accent: accent,
      ),
    ),
  );
}

class _TypeInputSheet extends StatefulWidget {
  final ShapePreset preset;
  final LengthUnit lengthUnit;
  final Color accent;
  const _TypeInputSheet({
    required this.preset,
    required this.lengthUnit,
    required this.accent,
  });

  @override
  State<_TypeInputSheet> createState() => _TypeInputSheetState();
}

class _TypeInputSheetState extends State<_TypeInputSheet> {
  // Per-shape values, in the user's selected length unit.
  late final Map<String, TextEditingController> _ctrls;
  int _sideCount = 5; // for freeform
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrls = _initialFields(widget.preset, widget.lengthUnit);
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Returns sensible defaults in the user's length unit (round numbers).
  static Map<String, TextEditingController> _initialFields(
    ShapePreset preset,
    LengthUnit unit,
  ) {
    String def(double meters) => unit.fromMeters(meters).toStringAsFixed(1);
    return switch (preset) {
      ShapePreset.rectangle => {
          'Width': TextEditingController(text: def(50)),
          'Height': TextEditingController(text: def(30)),
        },
      ShapePreset.square => {
          'Side': TextEditingController(text: def(40)),
        },
      ShapePreset.triangle => {
          'Side A': TextEditingController(text: def(40)),
          'Side B': TextEditingController(text: def(40)),
          'Side C': TextEditingController(text: def(40)),
        },
      ShapePreset.trapezoid => {
          'Top': TextEditingController(text: def(30)),
          'Bottom': TextEditingController(text: def(56)),
          'Height': TextEditingController(text: def(36)),
        },
      ShapePreset.pentagon => {
          'Side': TextEditingController(text: def(26)),
        },
      ShapePreset.freeform => {
          'Side length': TextEditingController(text: def(25)),
        },
    };
  }

  /// The geometry helpers below are static and have no BuildContext, so they
  /// throw one of these stable codes and [_errorText] translates it.
  static String _errorText(BuildContext context, String code) => switch (code) {
    _errPositive => context.l10n.typeErrPositive,
    _errTriangle => context.l10n.typeErrTriangle,
    _errMinSides => context.l10n.typeErrMinSides,
    _ => code,
  };

  /// Read all controller values, convert to meters, return as a map.
  Map<String, double> _readMeters() {
    final out = <String, double>{};
    for (final entry in _ctrls.entries) {
      final raw = entry.value.text.replaceAll(',', '').trim();
      final v = double.tryParse(raw);
      if (v == null || v <= 0) {
        throw const FormatException(_errPositive);
      }
      out[entry.key] = widget.lengthUnit.toMeters(v);
    }
    return out;
  }

  void _generate() {
    try {
      final m = _readMeters();
      final verts = switch (widget.preset) {
        ShapePreset.rectangle => _rectangle(m['Width']!, m['Height']!),
        ShapePreset.square => _square(m['Side']!),
        ShapePreset.triangle =>
          _triangle(m['Side A']!, m['Side B']!, m['Side C']!),
        ShapePreset.trapezoid =>
          _trapezoid(m['Top']!, m['Bottom']!, m['Height']!),
        ShapePreset.pentagon => _regularPolygon(5, m['Side']!),
        ShapePreset.freeform =>
          _regularPolygon(_sideCount, m['Side length']!),
      };
      Navigator.of(context).pop(verts);
    } on FormatException catch (e) {
      setState(() => _error = _errorText(context, e.message));
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.typeTitle,
            style: AppTypography.sans(size: 18, weight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.typeSubtitle(_subtitle(context, widget.preset), widget.lengthUnit.labelOf(context.l10n)),
            style: AppTypography.mono(
              size: 11,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.preset == ShapePreset.freeform) ...[
            _SideCountRow(
              count: _sideCount,
              accent: accent,
              onChanged: (n) => setState(() => _sideCount = n),
            ),
            const SizedBox(height: 12),
          ],
          for (final entry in _ctrls.entries) ...[
            _NumberField(
              label: _fieldLabel(context, entry.key),
              controller: entry.value,
              accent: accent,
              suffix: widget.lengthUnit.labelOf(context.l10n),
            ),
            const SizedBox(height: 10),
          ],
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: AppTypography.sans(
                  size: 12,
                  color: AppColors.danger,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    backgroundColor: AppColors.surfaceHi,
                    side: const BorderSide(color: AppColors.line),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.l10n.actionCancel,
                    style: AppTypography.sans(
                      size: 13,
                      weight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 14,
                child: FilledButton(
                  onPressed: _generate,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.l10n.actionGenerate,
                    style: AppTypography.sans(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
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

  static String _subtitle(BuildContext context, ShapePreset p) => switch (p) {
    ShapePreset.rectangle => context.l10n.presetRectangle,
    ShapePreset.square => context.l10n.presetSquare,
    ShapePreset.triangle => context.l10n.typeTriangle3,
    ShapePreset.trapezoid => context.l10n.presetTrapezoid,
    ShapePreset.pentagon => context.l10n.typeRegularPentagon,
    ShapePreset.freeform => context.l10n.typeRegularPolygon,
  };

  /// [_ctrls] is keyed by stable English identifiers that the geometry code
  /// looks fields up by; only the on-screen label follows the locale.
  static String _fieldLabel(BuildContext context, String key) => switch (key) {
    'Width' => context.l10n.typeWidth,
    'Height' => context.l10n.typeHeight,
    'Side' => context.l10n.typeSide,
    'Side A' => context.l10n.typeSideA,
    'Side B' => context.l10n.typeSideB,
    'Side C' => context.l10n.typeSideC,
    'Top' => context.l10n.typeTop,
    'Bottom' => context.l10n.typeBottom,
    'Side length' => context.l10n.typeSideLength,
    _ => key,
  };
}

class _NumberField extends StatelessWidget {
  final String label;
  final String suffix;
  final TextEditingController controller;
  final Color accent;
  const _NumberField({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: AppTypography.sans(size: 13, weight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.ink,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.]'),
                      ),
                    ],
                    cursorColor: accent,
                    textAlignVertical: TextAlignVertical.center,
                    style: AppTypography.mono(
                      size: 14,
                      weight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: '0',
                    ),
                  ),
                ),
                Text(
                  suffix,
                  style: AppTypography.mono(
                    size: 11,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SideCountRow extends StatelessWidget {
  final int count;
  final Color accent;
  final ValueChanged<int> onChanged;
  const _SideCountRow({
    required this.count,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            context.l10n.typeSidesCount,
            style: AppTypography.sans(size: 13, weight: FontWeight.w500),
          ),
        ),
        _Step(
          symbol: '−',
          onTap: count > 3 ? () => onChanged(count - 1) : null,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Center(
            child: Text(
              '$count',
              style: AppTypography.mono(
                size: 16,
                weight: FontWeight.w500,
                color: accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _Step(
          symbol: '+',
          onTap: count < 12 ? () => onChanged(count + 1) : null,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String symbol;
  final VoidCallback? onTap;
  const _Step({required this.symbol, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ink,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          symbol,
          style: AppTypography.mono(
            size: 16,
            color: disabled ? AppColors.textFaint : AppColors.text,
          ),
        ),
      ),
    );
  }
}

// ─── Shape generators (all values in meters, polygon centered at origin) ──

List<Vertex> _rectangle(double w, double h) {
  return [
    Vertex(-w / 2, -h / 2),
    Vertex(w / 2, -h / 2),
    Vertex(w / 2, h / 2),
    Vertex(-w / 2, h / 2),
  ];
}

List<Vertex> _square(double s) => _rectangle(s, s);

List<Vertex> _triangle(double a, double b, double c) {
  // Triangle inequality: each pair must sum > third side.
  if (a + b <= c || a + c <= b || b + c <= a) {
    throw const FormatException(_errTriangle);
  }
  // Place A at origin, B at (c, 0). Find C using law of cosines.
  final cosA = (b * b + c * c - a * a) / (2 * b * c);
  final clampedCos = cosA.clamp(-1.0, 1.0);
  final angleA = math.acos(clampedCos);
  final cx = b * math.cos(angleA);
  final cy = b * math.sin(angleA);
  final raw = [Vertex(0, 0), Vertex(c, 0), Vertex(cx, cy)];
  // Recenter on centroid.
  final ccx = (raw[0].x + raw[1].x + raw[2].x) / 3;
  final ccy = (raw[0].y + raw[1].y + raw[2].y) / 3;
  return raw.map((v) => Vertex(v.x - ccx, v.y - ccy)).toList();
}

List<Vertex> _trapezoid(double top, double bottom, double height) {
  final h = height / 2;
  return [
    Vertex(-bottom / 2, h),
    Vertex(bottom / 2, h),
    Vertex(top / 2, -h),
    Vertex(-top / 2, -h),
  ];
}

List<Vertex> _regularPolygon(int n, double side) {
  if (n < 3) {
    throw const FormatException(_errMinSides);
  }
  // Circumradius for a regular n-gon with given side length.
  final r = side / (2 * math.sin(math.pi / n));
  return [
    for (var i = 0; i < n; i++)
      Vertex(
        r * math.cos(-math.pi / 2 + i * 2 * math.pi / n),
        r * math.sin(-math.pi / 2 + i * 2 * math.pi / n),
      ),
  ];
}
