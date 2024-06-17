import 'package:flutter/material.dart';

class TargetWidget extends StatefulWidget {
  final Offset offset;
  final Size size;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final ShapeBorder? shapeBorder;
  final BorderRadius? radius;
  final bool disableDefaultChildGestures;
  final EdgeInsets margin;
  final List<BoxShadow>? shadows;

  const TargetWidget({
    required this.offset,
    required this.size,
    required this.shapeBorder,
    required this.margin,
    this.onTap,
    this.radius,
    this.onDoubleTap,
    this.onLongPress,
    this.disableDefaultChildGestures = false,
    this.shadows,
  }) : assert((shapeBorder != null ? 1 : 0) + (radius != null ? 1 : 0) <= 1,
            'Invalid combination of decoration, shapeBorder, and radius.');

  @override
  State<TargetWidget> createState() => _TargetWidgetState();
}

class _TargetWidgetState extends State<TargetWidget>
    with SingleTickerProviderStateMixin {
  late final DecorationTween _decorationTween = DecorationTween(
    begin: containerDecoration,
    end: ShapeDecoration(
      shape: RoundedRectangleBorder(
        borderRadius: widget.radius ?? BorderRadius.zero,
      ),
    ),
  );

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  late final _decorationAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  Decoration? get containerDecoration {
    if (widget.shapeBorder == null && widget.radius == null) {
      return const ShapeDecoration(
        shape: RoundedRectangleBorder(),
      );
    }
    return ShapeDecoration(
      shape: widget.radius == null
          ? widget.shapeBorder!
          : RoundedRectangleBorder(borderRadius: widget.radius!),
      shadows: widget.shadows,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.offset.dy - widget.margin.top,
      left: widget.offset.dx - widget.margin.left,
      child: widget.disableDefaultChildGestures
          ? IgnorePointer(
              child: targetWidgetContent(),
            )
          : targetWidgetContent(),
    );
  }

  Widget targetWidgetContent() {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onDoubleTap: widget.onDoubleTap,
      behavior: HitTestBehavior.translucent,
      child: DecoratedBoxTransition(
        decoration: _decorationTween.animate(_decorationAnimation),
        child: Container(
          height: widget.size.height,
          width: widget.size.width,
          margin: widget.margin,
        ),
      ),
    );
  }
}
