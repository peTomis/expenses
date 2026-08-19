import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/category_provider.dart';
import '../../../providers/color_provider.dart';

class ColorPicker extends StatelessWidget {
  const ColorPicker({super.key, required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  void _onSVPan(HSVColor hsv, Offset local, Size size) {
    final s = (local.dx / size.width).clamp(0.0, 1.0);
    final v = (1.0 - local.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(s).withValue(v).toColor());
  }

  void _onHuePan(HSVColor hsv, Offset local, Size size) {
    final hue = (local.dx / size.width * 360.0).clamp(0.0, 360.0);
    onChanged(hsv.withHue(hue).toColor());
  }

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(color);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const h = 160.0;
            final size = Size(constraints.maxWidth, h);
            return GestureDetector(
              onPanStart: (d) => _onSVPan(hsv, d.localPosition, size),
              onPanUpdate: (d) => _onSVPan(hsv, d.localPosition, size),
              onTapDown: (d) => _onSVPan(hsv, d.localPosition, size),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  size: size,
                  painter: _SVPickerPainter(
                    hue: hsv.hue,
                    saturation: hsv.saturation,
                    value: hsv.value,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const h = 20.0;
            final size = Size(constraints.maxWidth, h);
            return GestureDetector(
              onPanStart: (d) => _onHuePan(hsv, d.localPosition, size),
              onPanUpdate: (d) => _onHuePan(hsv, d.localPosition, size),
              onTapDown: (d) => _onHuePan(hsv, d.localPosition, size),
              child: CustomPaint(
                size: size,
                painter: _HuePickerPainter(hue: hsv.hue),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SVPickerPainter extends CustomPainter {
  const _SVPickerPainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  final double hue;
  final double saturation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    final cx = saturation * size.width;
    final cy = (1.0 - value) * size.height;
    canvas.drawCircle(
      Offset(cx, cy),
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      8,
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant _SVPickerPainter old) =>
      old.hue != hue || old.saturation != saturation || old.value != value;
}

class _HuePickerPainter extends CustomPainter {
  const _HuePickerPainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            for (var i = 0; i <= 6; i++)
              HSVColor.fromAHSV(1.0, i * 60.0, 1.0, 1.0).toColor(),
          ],
        ).createShader(rect),
    );

    final tx = (hue / 360.0) * size.width;
    final ty = size.height / 2;
    final r = size.height / 2 + 2;

    canvas.drawCircle(
      Offset(tx, ty),
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(tx, ty),
      r - 2,
      Paint()..color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _HuePickerPainter old) => old.hue != hue;
}

class CategoryIconGrid extends ConsumerWidget {
  const CategoryIconGrid({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onChanged,
  });

  final IconData selectedIcon;
  final Color selectedColor;
  final ValueChanged<IconData> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final inputBackground = ref
        .watch(appPrimary500ColorProvider)
        .withValues(alpha: 0.5);

    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (final icon in _categoryIconChoices)
          _CategoryIconButton(
            icon: icon,
            selected: icon == selectedIcon,
            textColor: textColor,
            selectedColor: selectedColor,
            backgroundColor: inputBackground,
            onTap: () => onChanged(icon),
          ),
      ],
    );
  }
}

class _CategoryIconButton extends StatelessWidget {
  const _CategoryIconButton({
    required this.icon,
    required this.selected,
    required this.textColor,
    required this.selectedColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final Color textColor;
  final Color selectedColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 42,
        child: Material(
          color: selected ? selectedColor : backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Icon(
              icon,
              color: selected ? Colors.white : textColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

final _categoryIconChoices = [Icons.label_outline, ...categoryIcons];
