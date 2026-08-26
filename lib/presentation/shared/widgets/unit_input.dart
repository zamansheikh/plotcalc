import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/units/area_unit.dart';
import '../../../l10n/l10n.dart';
import 'phone_chrome.dart';

/// The numeric-entry vocabulary shared by the converter and the calculator:
/// a borderless mono numeral and a row of unit pills. Extracted so the two
/// screens can't drift apart visually.

/// Large borderless numeral. The card around it supplies the framing, which
/// is why there is no border or padding here.
class BigNumberField extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;
  final ValueChanged<String> onChanged;
  final double size;
  final String? suffix;
  final bool autofocus;

  const BigNumberField({
    super.key,
    required this.controller,
    required this.accent,
    required this.onChanged,
    this.size = 36,
    this.suffix,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            cursorColor: accent,
            style: AppTypography.mono(
              size: size,
              weight: FontWeight.w500,
              color: accent,
              letterSpacing: -0.7,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: '0',
              hintStyle: AppTypography.mono(
                size: size,
                weight: FontWeight.w500,
                color: AppColors.textFaint,
                letterSpacing: -0.7,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 8),
          Text(
            suffix!,
            style: AppTypography.mono(size: 14, color: AppColors.textDim),
          ),
        ],
      ],
    );
  }
}

class UnitChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const UnitChip({
    super.key,
    required this.label,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accent : AppColors.ink,
          border: Border.all(color: active ? accent : AppColors.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTypography.mono(
            size: 11,
            color: active ? AppColors.ink : AppColors.text,
          ),
        ),
      ),
    );
  }
}

/// Wrapping row of area-unit pills.
class UnitChipRow extends StatelessWidget {
  final List<AreaUnit> units;
  final AreaUnit selected;
  final Color accent;
  final ValueChanged<AreaUnit> onChanged;

  const UnitChipRow({
    super.key,
    required this.units,
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final u in units)
          UnitChip(
            label: u.labelOf(context.l10n),
            active: u == selected,
            accent: accent,
            onTap: () => onChanged(u),
          ),
      ],
    );
  }
}

/// Full-width action button in the app's filled-accent style.
class WideButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color accent;
  final VoidCallback? onTap;

  /// Filled reads as the primary action; outlined as the secondary one.
  final bool filled;

  const WideButton({
    super.key,
    required this.label,
    required this.accent,
    this.icon,
    this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    final bg = !on
        ? AppColors.ink
        : filled
        ? accent
        : AppColors.ink;
    final fg = !on
        ? AppColors.textFaint
        : filled
        ? AppColors.ink
        : accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: on ? accent : AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The screen header used by every pushed tool: back chevron, hero title,
/// mono subtitle.
class ToolHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget? trailing;

  const ToolHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SmallIconButton(icon: Icons.chevron_left, onTap: onBack),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.heroTitle),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.mono(size: 11, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
