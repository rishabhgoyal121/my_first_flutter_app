import 'package:flutter/material.dart';

class CartItemDeleteAnimation extends StatefulWidget {
  final Widget child;
  final bool isDeleting;
  final VoidCallback? onAnimationEnd;

  const CartItemDeleteAnimation({
    super.key,
    required this.child,
    required this.isDeleting,
    this.onAnimationEnd,
  });

  @override
  State<StatefulWidget> createState() => _CartItemDeleteAnimationState();
}

class _CartItemDeleteAnimationState extends State<CartItemDeleteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _fade = Tween<double>(begin: 1, end: 0).animate(_controller);
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(1, 0),
    ).animate(_controller);

    if (widget.isDeleting) {
      _controller.forward().then((_) {
        widget.onAnimationEnd?.call();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CartItemDeleteAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDeleting && !oldWidget.isDeleting) {
      _controller.forward().then((_) {
        widget.onAnimationEnd?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
