import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/geometry/map_scale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';

/// Pieces shared by the screens that work on a photo of a map: the mouza
/// tracer and the two-map comparison.

/// Reads a photo from the camera or the gallery. A seam, so tests can hand
/// the screen an image without a platform picker.
typedef PickMapPhoto = Future<Uint8List?> Function(ImageSource source);

Future<Uint8List?> pickMapPhotoWithPlugin(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    // Plenty for tracing, and keeps a 50-megapixel photo out of memory.
    maxWidth: 4096,
    maxHeight: 4096,
    imageQuality: 92,
  );
  return file?.readAsBytes();
}

String mapDistanceUnitLabel(AppLocalizations t, MapDistanceUnit u) =>
    switch (u) {
      MapDistanceUnit.foot => t.mouzaUnitFoot,
      MapDistanceUnit.meter => t.mouzaUnitMeter,
      MapDistanceUnit.chain => t.mouzaUnitChain,
      MapDistanceUnit.link => t.mouzaUnitLink,
    };

/// Holds a step's controls under the map. It never takes more than its share
/// of the room left over by the keyboard, and scrolls past that: the map must stay
/// big enough to see the line being measured, even on a small phone with a
/// large font.
class MapPanelBox extends StatelessWidget {
  final double maxHeight;
  final Widget child;
  const MapPanelBox({super.key, required this.maxHeight, required this.child});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxHeight: maxHeight),
    child: SingleChildScrollView(child: child),
  );
}

/// Lays its child out normally, but never gets shorter than the tallest it
/// has been. Hints change length as the user taps; if the panel holding
/// them shrank, the map above would grow and slide under the next tap.
/// Unlike a fixed height, this still fits any font size.
class NoShrink extends SingleChildRenderObjectWidget {
  const NoShrink({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => RenderNoShrink();
}

class RenderNoShrink extends RenderProxyBox {
  double _tallest = 0;

  @override
  void performLayout() {
    final c = child!;
    c.layout(constraints, parentUsesSize: true);
    _tallest = math.max(_tallest, c.size.height);
    size = constraints.constrain(Size(c.size.width, _tallest));
  }
}

class MapZoomButtons extends StatelessWidget {
  final VoidCallback onIn;
  final VoidCallback onOut;
  const MapZoomButtons({super.key, required this.onIn, required this.onOut});

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback onTap, Key key) => Material(
      color: AppColors.ink.withValues(alpha: 0.85),
      shape: const CircleBorder(side: BorderSide(color: AppColors.lineMid)),
      child: InkWell(
        key: key,
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.text),
        ),
      ),
    );
    return Column(
      children: [
        button(Icons.add, onIn, const ValueKey('mouza-zoom-in')),
        const SizedBox(height: 8),
        button(Icons.remove, onOut, const ValueKey('mouza-zoom-out')),
      ],
    );
  }
}

class MapHint extends StatelessWidget {
  final String text;
  final Color accent;
  const MapHint(this.text, {super.key, required this.accent});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.touch_app_outlined, size: 16, color: accent),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: AppTypography.sans(size: 13, color: AppColors.text),
        ),
      ),
    ],
  );
}

ButtonStyle mapPrimaryButtonStyle(Color accent) => FilledButton.styleFrom(
  backgroundColor: accent,
  foregroundColor: AppColors.ink,
  disabledBackgroundColor: AppColors.surface,
  disabledForegroundColor: AppColors.textDim,
  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

ButtonStyle get mapSecondaryButtonStyle => OutlinedButton.styleFrom(
  foregroundColor: AppColors.text,
  disabledForegroundColor: AppColors.textFaint,
  side: const BorderSide(color: AppColors.lineMid),
  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

/// Step for setting a map's scale: two points, then their real distance.
class MapScalePanel extends StatelessWidget {
  final int points;
  final TextEditingController controller;
  final MapDistanceUnit unit;
  final Color accent;
  final bool ready;
  final ValueChanged<MapDistanceUnit> onUnit;
  final VoidCallback onChanged;
  final VoidCallback onStartOver;
  final VoidCallback onNext;
  const MapScalePanel({
    super.key,
    required this.points,
    required this.controller,
    required this.unit,
    required this.accent,
    required this.ready,
    required this.onUnit,
    required this.onChanged,
    required this.onStartOver,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The hint changes between the two taps; a panel that shrinks
          // would move the map under the second tap. Once both points are
          // in there is nothing left to tap, so it may size naturally again.
          NoShrink(
            key: ValueKey(points == 2),
            child: MapHint(switch (points) {
              0 => t.mouzaScaleHintFirst,
              1 => t.mouzaScaleHintSecond,
              _ => t.mouzaDragTip,
            }, accent: accent),
          ),
          if (points == 2) ...[
            const SizedBox(height: 12),
            Text(t.mouzaScaleDistance, style: AppTypography.monoLabel),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.lineMid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      key: const ValueKey('mouza-distance'),
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9০-৯.,]'),
                        ),
                      ],
                      cursorColor: accent,
                      textAlignVertical: TextAlignVertical.center,
                      style: AppTypography.mono(
                        size: 18,
                        weight: FontWeight.w600,
                        color: accent,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: AppTypography.mono(
                          size: 18,
                          color: AppColors.textFaint,
                        ),
                      ),
                      onChanged: (_) => onChanged(),
                      // The keyboard's tick goes on, so the Next button
                      // does not have to be found under the keyboard.
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        if (ready) onNext();
                      },
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final u in MapDistanceUnit.values) ...[
                    if (u != MapDistanceUnit.values.first)
                      const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(mapDistanceUnitLabel(t, u)),
                      selected: u == unit,
                      onSelected: (_) => onUnit(u),
                      showCheckmark: false,
                      labelStyle: AppTypography.sans(
                        size: 13,
                        weight: FontWeight.w600,
                        color: u == unit ? AppColors.ink : AppColors.text,
                      ),
                      selectedColor: accent,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: u == unit ? accent : AppColors.lineMid,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.mouzaScaleNoBar,
              style: AppTypography.sans(size: 12, color: AppColors.textDim),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (points > 0) ...[
                OutlinedButton(
                  onPressed: onStartOver,
                  style: mapSecondaryButtonStyle,
                  child: Text(
                    t.mouzaStartOver,
                    style: AppTypography.sans(size: 13),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: ready ? onNext : null,
                  style: mapPrimaryButtonStyle(accent),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.mouzaNext,
                        style: AppTypography.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: ready ? AppColors.ink : AppColors.textDim,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: ready ? AppColors.ink : AppColors.textDim,
                      ),
                    ],
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
