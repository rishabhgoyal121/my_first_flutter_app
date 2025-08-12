import 'package:flutter/material.dart';

class AddToCartAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onAnimationComplete;
  final GlobalKey cartIconKey;

  const AddToCartAnimation({
    super.key,
    required this.child,
    required this.onAnimationComplete,
    required this.cartIconKey,
  });

  @override
  State<StatefulWidget> createState() => AddToCartAnimationState();
}

class AddToCartAnimationState extends State<AddToCartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );
  }

  void startAnimation() async {
    final overlay = Overlay.of(context);
    final renderbox = context.findRenderObject() as RenderBox;
    final start = renderbox.localToGlobal(Offset.zero);
    final size = renderbox.size;
    final cartBox =
        widget.cartIconKey.currentContext?.findRenderObject() as RenderBox;

    final end = cartBox.localToGlobal(Offset.zero);
    final cartSize = cartBox.size;

    const double animImgSize = 48.0;

    final entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final startCenter = Offset(
              start.dx + size.width / 2,
              start.dy + size.height / 2,
            );
            final endCenter = Offset(
              end.dx + cartSize.width / 2,
              end.dy + cartSize.height / 2,
            );
            final dx =
                startCenter.dx +
                (endCenter.dx - startCenter.dx) * _controller.value -
                size.width / 2;
            final dy =
                startCenter.dy +
                (endCenter.dy - startCenter.dy) * _controller.value -
                size.height / 2;
            final currentCenter = Offset(dx, dy);
            return Positioned(
              left: currentCenter.dx - animImgSize/2,
              top: currentCenter.dy - animImgSize/2,
              child: Opacity(
                opacity: 1.0 - _controller.value,
                child: SizedBox(
                  width: animImgSize,
                  height: animImgSize,
                  child: widget.child,
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    await _controller.forward();
    entry.remove();
    widget.onAnimationComplete();
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
