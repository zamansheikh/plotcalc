import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/geometry/presets.dart';
import '../../../../core/input_method.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/settings/settings_state.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/phone_chrome.dart';

class PickerScreen extends StatefulWidget {
  const PickerScreen({super.key});

  @override
  State<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends State<PickerScreen> {
  InputMethod _method = InputMethod.draw;
  ShapePreset _preset = ShapePreset.freeform;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _TopBar(),
            _Title(accent: accent),
            _Methods(
              selected: _method,
              accent: accent,
              onChanged: (m) => setState(() => _method = m),
            ),
            const SizedBox(height: 14),
            if (_method == InputMethod.tap)
              Expanded(
                child: _TapHintCard(accent: accent),
              )
            else ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _LabelMono('SHAPE PRESETS'),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    itemCount: ShapePreset.values.length,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (_, i) {
                      final p = ShapePreset.values[i];
                      final selected = p == _preset;
                      return _PresetTile(
                        preset: p,
                        selected: selected,
                        accent: accent,
                        onTap: () => setState(() => _preset = p),
                      );
                    },
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => context.push(
                    AppRoutes.draw,
                    extra: DrawArgs(method: _method, preset: _preset),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        switch (_method) {
                          InputMethod.draw => 'Start drawing',
                          InputMethod.tap => 'Place vertices',
                          InputMethod.type => 'Enter dimensions',
                        },
                        style: AppTypography.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward,
                          size: 14, color: AppColors.ink),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SmallIconButton(
            icon: Icons.chevron_left,
            onTap: () => context.pop(),
          ),
          Text(
            'STEP 1 / 3',
            style: AppTypography.mono(
              size: 11,
              color: AppColors.textFaint,
              letterSpacing: 1.32,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final Color accent;
  const _Title({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: AppTypography.sectionTitle,
              children: [
                const TextSpan(text: 'How do you want to '),
                TextSpan(
                  text: 'start',
                  style: AppTypography.sectionTitle.copyWith(color: accent),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a method, then a shape.',
            style: AppTypography.bodyDim,
          ),
        ],
      ),
    );
  }
}

class _Methods extends StatelessWidget {
  final InputMethod selected;
  final Color accent;
  final ValueChanged<InputMethod> onChanged;
  const _Methods({
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _MethodSpec(InputMethod.draw, Icons.brush_outlined, 'Draw', 'Tap & drag'),
      _MethodSpec(InputMethod.tap, Icons.touch_app_outlined, 'Tap',
          'Place vertices'),
      _MethodSpec(
          InputMethod.type, Icons.keyboard_outlined, 'Type', 'Sides + angles'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _MethodTile(
                spec: tiles[i],
                active: tiles[i].method == selected,
                accent: accent,
                onTap: () => onChanged(tiles[i].method),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MethodSpec {
  final InputMethod method;
  final IconData icon;
  final String label;
  final String sub;
  _MethodSpec(this.method, this.icon, this.label, this.sub);
}

class _MethodTile extends StatelessWidget {
  final _MethodSpec spec;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _MethodTile({
    required this.spec,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? accent : AppColors.surface,
          border: active ? null : Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  spec.icon,
                  size: 16,
                  color: active ? AppColors.ink : AppColors.text,
                ),
                if (active)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.ink,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              spec.label,
              style: AppTypography.sans(
                size: 12,
                weight: FontWeight.w600,
                color: active ? AppColors.ink : AppColors.text,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              spec.sub,
              style: AppTypography.mono(
                size: 9,
                color: active
                    ? AppColors.ink.withValues(alpha: 0.65)
                    : AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final ShapePreset preset;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : AppColors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: selected ? accent : AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const GridBackground(style: GridStyle.dots),
                    CustomPaint(
                      painter: _PresetShapePainter(
                        verts: preset.vertices,
                        color: color,
                        filled: selected,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              preset.label,
              style: AppTypography.sans(
                size: 11,
                weight: FontWeight.w500,
                color: color,
              ),
            ),
            Text(
              '${preset.vertices.length}–N sides',
              style: AppTypography.mono(
                size: 8,
                color: AppColors.textFaint,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetShapePainter extends CustomPainter {
  final List verts;
  final Color color;
  final bool filled;
  _PresetShapePainter({
    required this.verts,
    required this.color,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (verts.length < 3) return;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final v in verts) {
      if (v.x < minX) minX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.x > maxX) maxX = v.x;
      if (v.y > maxY) maxY = v.y;
    }
    final w = maxX - minX, h = maxY - minY;
    const padding = 6.0;
    final scale = ((size.width - padding * 2) / w)
        .clamp(0.0, double.infinity)
        .toDouble();
    final scaleY =
        ((size.height - padding * 2) / h).clamp(0.0, double.infinity).toDouble();
    final s = scale < scaleY ? scale : scaleY;
    final ox = (size.width - w * s) / 2 - minX * s;
    final oy = (size.height - h * s) / 2 - minY * s;

    final path = Path();
    for (var i = 0; i < verts.length; i++) {
      final p = Offset(verts[i].x * s + ox, verts[i].y * s + oy);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    if (filled) {
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: 0.18),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = filled ? color : color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    final dotPaint = Paint()..color = color;
    for (final v in verts) {
      canvas.drawCircle(
        Offset(v.x * s + ox, v.y * s + oy),
        1.6,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PresetShapePainter old) =>
      old.color != color || old.filled != filled || old.verts != verts;
}

class _LabelMono extends StatelessWidget {
  final String text;
  const _LabelMono(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.monoLabel);
  }
}

class _TapHintCard extends StatelessWidget {
  final Color accent;
  const _TapHintCard({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.lineMid),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.limeDim,
                border: Border.all(color: accent),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.touch_app_outlined, size: 26, color: accent),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap each corner on the canvas',
              textAlign: TextAlign.center,
              style: AppTypography.sans(size: 15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'You decide the number of vertices.\nDrop them in any order, then tap "Done".',
              textAlign: TextAlign.center,
              style: AppTypography.mono(
                size: 11,
                color: AppColors.textDim,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
