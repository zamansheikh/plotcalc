import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/plot.dart';

class SavePlotResult {
  final String name;
  final PlotTag tag;
  const SavePlotResult({required this.name, required this.tag});
}

Future<SavePlotResult?> showSavePlotSheet(
  BuildContext context, {
  required String defaultName,
  required Color accent,
}) {
  return showModalBottomSheet<SavePlotResult>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _SavePlotSheet(defaultName: defaultName, accent: accent),
    ),
  );
}

class _SavePlotSheet extends StatefulWidget {
  final String defaultName;
  final Color accent;
  const _SavePlotSheet({required this.defaultName, required this.accent});

  @override
  State<_SavePlotSheet> createState() => _SavePlotSheetState();
}

class _SavePlotSheetState extends State<_SavePlotSheet> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.defaultName);
  PlotTag _tag = PlotTag.agricultural;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            'Save plot',
            style: AppTypography.sans(size: 18, weight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Text(
            'NAME',
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.ink,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _nameCtrl,
              cursorColor: widget.accent,
              textAlignVertical: TextAlignVertical.center,
              style: AppTypography.sans(size: 14),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Plot name',
              ),
              autofocus: false,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'CATEGORY',
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in PlotTag.values)
                _TagChip(
                  tag: t,
                  active: t == _tag,
                  accent: widget.accent,
                  onTap: () => setState(() => _tag = t),
                ),
            ],
          ),
          const SizedBox(height: 20),
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
                    'Cancel',
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
                  onPressed: () {
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(context).pop(
                      SavePlotResult(name: name, tag: _tag),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Save',
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
}

class _TagChip extends StatelessWidget {
  final PlotTag tag;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _TagChip({
    required this.tag,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? accent : AppColors.ink,
          border: Border.all(color: active ? accent : AppColors.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          tag.label,
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
