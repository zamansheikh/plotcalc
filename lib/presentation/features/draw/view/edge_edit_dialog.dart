import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/length_unit.dart';

sealed class EdgeEditResult {
  const EdgeEditResult();
}

class EdgeLengthChanged extends EdgeEditResult {
  final double newLengthMeters;
  final bool moveTo; // true = move toIndex, false = move fromIndex
  const EdgeLengthChanged({
    required this.newLengthMeters,
    required this.moveTo,
  });
}

class EdgeInsertMidpoint extends EdgeEditResult {
  const EdgeInsertMidpoint();
}

/// Generic length-adjust dialog for both sides and diagonals. Set
/// [canInsertMidpoint] to true (sides only) to expose an "Insert midpoint
/// vertex" secondary action that splits the edge in two.
Future<EdgeEditResult?> showEdgeEditDialog(
  BuildContext context, {
  required int fromIndex,
  required int toIndex,
  required double currentLengthMeters,
  required LengthUnit lengthUnit,
  required Color accent,
  required bool isDiagonal,
  bool canInsertMidpoint = false,
}) {
  return showDialog<EdgeEditResult>(
    context: context,
    builder: (dialogContext) => _EdgeEditDialog(
      fromIndex: fromIndex,
      toIndex: toIndex,
      currentLengthMeters: currentLengthMeters,
      lengthUnit: lengthUnit,
      accent: accent,
      isDiagonal: isDiagonal,
      canInsertMidpoint: canInsertMidpoint,
    ),
  );
}

class _EdgeEditDialog extends StatefulWidget {
  final int fromIndex;
  final int toIndex;
  final double currentLengthMeters;
  final LengthUnit lengthUnit;
  final Color accent;
  final bool isDiagonal;
  final bool canInsertMidpoint;
  const _EdgeEditDialog({
    required this.fromIndex,
    required this.toIndex,
    required this.currentLengthMeters,
    required this.lengthUnit,
    required this.accent,
    required this.isDiagonal,
    required this.canInsertMidpoint,
  });

  @override
  State<_EdgeEditDialog> createState() => _EdgeEditDialogState();
}

class _EdgeEditDialogState extends State<_EdgeEditDialog> {
  late final TextEditingController _ctrl;
  bool _moveTo = true;

  @override
  void initState() {
    super.initState();
    final v = widget.lengthUnit.fromMeters(widget.currentLengthMeters);
    _ctrl = TextEditingController(text: v.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _applyLength() {
    final raw = _ctrl.text.replaceAll(',', '').trim();
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return;
    final meters = widget.lengthUnit.toMeters(v);
    Navigator.of(context).pop(
      EdgeLengthChanged(newLengthMeters: meters, moveTo: _moveTo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromLabel = 'V${widget.fromIndex + 1}';
    final toLabel = 'V${widget.toIndex + 1}';
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        widget.isDiagonal ? 'Adjust diagonal' : 'Adjust side',
        style: AppTypography.sans(size: 16, weight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(label: fromLabel, accent: widget.accent),
              const SizedBox(width: 8),
              const Icon(Icons.swap_horiz,
                  size: 16, color: AppColors.textDim),
              const SizedBox(width: 8),
              _Chip(label: toLabel, accent: widget.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'now ${widget.lengthUnit.format(widget.currentLengthMeters)} ${widget.lengthUnit.label}',
                  style: AppTypography.mono(
                    size: 11,
                    color: AppColors.textDim,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'NEW LENGTH',
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.ink,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    cursorColor: widget.accent,
                    textAlignVertical: TextAlignVertical.center,
                    style: AppTypography.mono(
                      size: 16,
                      weight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _applyLength(),
                  ),
                ),
                Text(
                  widget.lengthUnit.label,
                  style: AppTypography.mono(
                    size: 11,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'WHICH ENDPOINT MOVES?',
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _MoveOption(
                  label: 'Move $fromLabel',
                  active: !_moveTo,
                  accent: widget.accent,
                  onTap: () => setState(() => _moveTo = false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MoveOption(
                  label: 'Move $toLabel',
                  active: _moveTo,
                  accent: widget.accent,
                  onTap: () => setState(() => _moveTo = true),
                ),
              ),
            ],
          ),
          if (widget.canInsertMidpoint) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.line,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'OR',
                    style: AppTypography.mono(
                      size: 10,
                      color: AppColors.textFaint,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.line,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(
                  const EdgeInsertMidpoint(),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  backgroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.line),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Insert vertex at midpoint',
                  style: AppTypography.sans(
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTypography.sans(size: 13, color: AppColors.textDim),
          ),
        ),
        FilledButton(
          onPressed: _applyLength,
          style: FilledButton.styleFrom(
            backgroundColor: widget.accent,
            foregroundColor: AppColors.ink,
          ),
          child: Text(
            'Apply',
            style: AppTypography.sans(
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color accent;
  const _Chip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.limeDim,
        border: Border.all(color: accent),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.mono(
          size: 11,
          weight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}

class _MoveOption extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _MoveOption({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? accent : AppColors.ink,
          border: Border.all(color: active ? accent : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTypography.sans(
            size: 12,
            weight: FontWeight.w500,
            color: active ? AppColors.ink : AppColors.text,
          ),
        ),
      ),
    );
  }
}
