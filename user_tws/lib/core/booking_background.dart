import 'package:flutter/material.dart';

/// Shared booking-flow backdrop — `images/home/4.png` (fade + white base in [BookingBackgroundLayer]).
abstract final class BookingBackground {
  static const String assetPath = 'images/home/4.png';
  static const Color washColor = Color(0xFFFFFBF0);
}

/// Top scenic strip: photo **fades to transparency** (ShaderMask) over a white base — soft edge like the reference, no hard cut.
class BookingBackgroundLayer extends StatelessWidget {
  const BookingBackgroundLayer({
    super.key,
    required this.child,

    /// Viewport fraction for the image layer height (fade happens inside this band).
    this.imageHeightFraction = 0.42,
  });

  final Widget child;

  final double imageHeightFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final band = (h * imageHeightFraction).clamp(160.0, h);

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.white),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: band,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [
                      0.0,
                      0.18,
                      0.38,
                      0.58,
                      0.78,
                      1.0,
                    ],
                    colors: [
                      Colors.white,
                      Colors.white,
                      Colors.white.withValues(alpha: 0.92),
                      Colors.white.withValues(alpha: 0.45),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ).createShader(bounds);
                },
                child: Image.asset(
                  BookingBackground.assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: band,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: BookingBackground.washColor),
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}
