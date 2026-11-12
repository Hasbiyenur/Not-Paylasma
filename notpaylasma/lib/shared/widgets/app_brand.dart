import 'package:flutter/material.dart';

/// Ortak marka imzası; font uygulamayla birlikte gelir ve çevrimdışı çalışır.
class AppBrand extends StatelessWidget {
  const AppBrand({this.large = false, super.key});
  final bool large;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Not',
            style: TextStyle(
              color: dark ? Colors.white : const Color(0xFF202B4B),
            ),
          ),
          TextSpan(
            text: 'Paylaş',
            style: TextStyle(
              color: dark ? const Color(0xFFC9B8FF) : const Color(0xFF7254B3),
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: large ? 38 : 25,
        fontWeight: FontWeight.w800,
        letterSpacing: large ? -1.5 : -.8,
        height: 1.2,
      ),
    );
    return Semantics(
      label: 'NotPaylaş',
      child: ExcludeSemantics(
        child: large
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 94),
                  const SizedBox(height: 20),
                  name,
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 38),
                  const SizedBox(width: 10),
                  Flexible(child: name),
                ],
              ),
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 48, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: const CustomPaint(painter: AppLogoPainter()),
  );
}

/// Vektör kaynak; başlık ve dışa aktarılan uygulama ikonları aynı çizimi kullanır.
class AppLogoPainter extends CustomPainter {
  const AppLogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final tile = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 100, 100),
      const Radius.circular(25),
    );
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF34467A), Color(0xFF202C50)],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    final left = Path()
      ..moveTo(20, 29)
      ..quadraticBezierTo(35, 24, 49, 35)
      ..lineTo(49, 76)
      ..quadraticBezierTo(35, 65, 20, 70)
      ..close();
    final right = Path()
      ..moveTo(53, 35)
      ..quadraticBezierTo(66, 24, 81, 29)
      ..lineTo(81, 70)
      ..quadraticBezierTo(66, 65, 53, 76)
      ..close();
    canvas.drawPath(left, Paint()..color = const Color(0xFFF5F0FF));
    canvas.drawPath(right, Paint()..color = const Color(0xFFBEA8F0));
    final line = Paint()
      ..color = const Color(0xFF8D7CB8)
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(28, 40)
        ..quadraticBezierTo(35, 39, 41, 43)
        ..moveTo(28, 49)
        ..quadraticBezierTo(35, 48, 41, 52),
      line,
    );
    // Yukarı uzanan ok: notu başkalarıyla paylaşma.
    final arrow = Paint()
      ..color = const Color(0xFF202C50)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(62, 57)
        ..lineTo(73, 44)
        ..moveTo(63, 44)
        ..lineTo(73, 44)
        ..lineTo(73, 54),
      arrow,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AppLogoPainter oldDelegate) => false;
}
