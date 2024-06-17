/*
 * Copyright (c) 2021 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:math';

import 'package:flutter/material.dart';

import 'enum.dart';
import 'get_position.dart';
import 'measure_size.dart';
import 'widget/tooltip_slide_transition.dart';

const _kDefaultPaddingFromParent = 14.0;

class ShowcaseTooltip extends StatefulWidget {
  final GetPosition? position;
  final Offset? offset;
  final Size screenSize;
  final Color? tooltipBackgroundColor;
  final Color? tooltipBorderColor;
  final Color? textColor;
  final bool showArrow;
  final VoidCallback? onTooltipTap;
  final EdgeInsets? tooltipPadding;
  final Duration movingAnimationDuration;
  final bool disableMovingAnimation;
  final bool disableScaleAnimation;
  final BorderRadius? tooltipBorderRadius;
  final Duration scaleAnimationDuration;
  final Curve scaleAnimationCurve;
  final Alignment? scaleAnimationAlignment;
  final bool isTooltipDismissed;
  final TooltipPosition? tooltipPosition;
  final double toolTipSlideEndDistance;
  final Widget tooltip;
  final EdgeInsets screenEdgeInsets;
  final Rect targetRect;

  const ShowcaseTooltip({
    super.key,
    required this.position,
    required this.offset,
    required this.screenSize,
    required this.tooltipBackgroundColor,
    required this.tooltipBorderColor,
    required this.textColor,
    required this.showArrow,
    required this.onTooltipTap,
    required this.movingAnimationDuration,
    this.tooltipPadding = const EdgeInsets.symmetric(vertical: 8),
    required this.disableMovingAnimation,
    required this.disableScaleAnimation,
    required this.tooltipBorderRadius,
    required this.scaleAnimationDuration,
    required this.scaleAnimationCurve,
    this.scaleAnimationAlignment,
    this.isTooltipDismissed = false,
    this.tooltipPosition,
    this.toolTipSlideEndDistance = 7,
    required this.tooltip,
    this.screenEdgeInsets = const EdgeInsets.all(16),
    required this.targetRect,
  });

  @override
  State<ShowcaseTooltip> createState() => _ToolTipWidgetState();
}

class _ToolTipWidgetState extends State<ShowcaseTooltip>
    with TickerProviderStateMixin {
  TooltipPosition get tooltipPosition {
    return widget.tooltipPosition ?? TooltipPosition.top;
  }

  late final AnimationController _movingAnimationController;
  late final Animation<double> _movingAnimation;
  late final AnimationController _scaleAnimationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _movingAnimationController = AnimationController(
      duration: widget.movingAnimationDuration,
      vsync: this,
    );
    _movingAnimation = CurvedAnimation(
      parent: _movingAnimationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimationController = AnimationController(
      duration: widget.scaleAnimationDuration,
      vsync: this,
      lowerBound: widget.disableScaleAnimation ? 1 : 0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleAnimationController,
      curve: widget.scaleAnimationCurve,
    );
    if (widget.disableScaleAnimation) {
      movingAnimationListener();
    } else {
      _scaleAnimationController
        ..addStatusListener((scaleAnimationStatus) {
          if (scaleAnimationStatus == AnimationStatus.completed) {
            movingAnimationListener();
          }
        })
        ..forward();
    }
    if (!widget.disableMovingAnimation) {
      _movingAnimationController.forward();
    }
  }

  void movingAnimationListener() {
    _movingAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _movingAnimationController.reverse();
      }
      if (_movingAnimationController.isDismissed) {
        if (!widget.disableMovingAnimation) {
          _movingAnimationController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _movingAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ShowcaseTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tooltipPosition != widget.tooltipPosition) {
      setState(() {
        tooltipSize = null;
        contentTop = null;
        contentBottom = null;
        contentLeft = null;
        contentRight = null;
      });
    }
  }

  double arrowWidth = 18.0;
  double arrowHeight = 9.0;

  Size? tooltipSize;
  double? contentTop;
  double? contentBottom;
  double? contentLeft;
  double? contentRight;
  Offset tooltipOffset = Offset.zero;

  void onTooltipSizeChanged(Size? size, BuildContext context) {
    if (size == null) return;

    final screenSize = MediaQuery.sizeOf(context);
    final double horizontalPadding = widget.tooltipPadding?.horizontal ?? 0;
    final double verticalPadding = widget.tooltipPadding?.vertical ?? 0;

    double left = 0.0;
    double top = 0.0;
    double? right;
    double? bottom;

    void calculateOffsets() {
      final offset = Offset(
          screenSize.width -
              (left +
                  size.width +
                  horizontalPadding +
                  widget.screenEdgeInsets.right),
          0);

      left += offset.dx;
      top += offset.dy;

      if (left < widget.screenEdgeInsets.left) {
        left = widget.screenEdgeInsets.left;
        right = widget.screenEdgeInsets.right;
      }
      if (top < widget.screenEdgeInsets.top) {
        top = widget.screenEdgeInsets.top;
        bottom = widget.screenEdgeInsets.bottom;
      }

      if (screenSize.width ==
          (size.width +
              horizontalPadding +
              widget.screenEdgeInsets.horizontal)) {
        left = widget.screenEdgeInsets.left;
        right = widget.screenEdgeInsets.right;
      }
      if (screenSize.height ==
          (size.height + verticalPadding + widget.screenEdgeInsets.vertical)) {
        top = widget.screenEdgeInsets.top;
        bottom = widget.screenEdgeInsets.bottom;
      }

      setState(() {
        tooltipOffset = offset;
        contentTop = top;
        contentLeft = left;
        contentRight = right;
        contentBottom = bottom;
        if (screenSize.width >=
                (size.width +
                    horizontalPadding +
                    widget.screenEdgeInsets.horizontal) &&
            screenSize.height >=
                (size.height +
                    verticalPadding +
                    widget.screenEdgeInsets.vertical)) {
          tooltipSize = size;
        }
      });
    }

    switch (tooltipPosition) {
      case TooltipPosition.top:
        top = widget.position!.getTop() -
            size.height -
            arrowHeight -
            _kDefaultPaddingFromParent -
            (widget.tooltipPadding?.vertical ?? 0);
        left = widget.position!.getCenter() -
            size.width / 2 -
            (widget.tooltipPadding?.left ?? 0);
        calculateOffsets();
        break;

      case TooltipPosition.bottom:
        top = widget.position!.getBottom() +
            arrowHeight +
            _kDefaultPaddingFromParent;
        left = widget.position!.getCenter() -
            size.width / 2 -
            (widget.tooltipPadding?.left ?? 0);
        calculateOffsets();
        break;

      case TooltipPosition.left:
        right = screenSize.width -
            widget.position!.getLeft() -
            arrowWidth -
            _kDefaultPaddingFromParent;
        left = widget.position!.getLeft() -
            size.width -
            arrowWidth -
            _kDefaultPaddingFromParent;
        top = widget.position!.getCenter() -
            size.height / 2 -
            (widget.tooltipPadding?.top ?? 0);
        calculateOffsets();
        break;

      case TooltipPosition.right:
        left = widget.position!.getRight() +
            arrowWidth +
            _kDefaultPaddingFromParent;
        top = widget.position!.getCenter() -
            size.height / 2 -
            (widget.tooltipPadding?.top ?? 0);
        calculateOffsets();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.disableScaleAnimation && widget.isTooltipDismissed) {
      _scaleAnimationController.reverse();
    }

    return Positioned(
      top: contentTop,
      bottom: contentBottom,
      left: contentLeft,
      right: contentRight,
      child: Opacity(
        opacity: tooltipSize == null ? 0 : 1,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: widget.scaleAnimationAlignment ?? const Alignment(0, 0),
          child: ToolTipSlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: Offset(
                  0,
                  tooltipPosition == TooltipPosition.bottom
                      ? widget.toolTipSlideEndDistance
                      : -widget.toolTipSlideEndDistance),
            ).animate(_movingAnimation),
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                onTap: widget.onTooltipTap,
                child: CustomPaint(
                  painter: _TooltipPainter(
                    targetCenter: widget.targetRect.center,
                    arrowWidth: arrowWidth,
                    arrowHeight: arrowHeight,
                    backgroundColor:
                        widget.tooltipBackgroundColor ?? Colors.black,
                    borderColor: widget.tooltipBorderColor,
                    borderRadius:
                        widget.tooltipBorderRadius ?? BorderRadius.circular(8),
                    screenSize: MediaQuery.sizeOf(context),
                    tooltipPosition: tooltipPosition,
                    arrowOffset: -tooltipOffset,
                  ),
                  child: Padding(
                    padding: (widget.tooltipPadding ?? EdgeInsets.zero).add(
                      EdgeInsets.only(
                        top: tooltipPosition == TooltipPosition.bottom
                            ? arrowHeight
                            : 0,
                        bottom: tooltipPosition == TooltipPosition.top
                            ? arrowHeight
                            : 0,
                        left: tooltipPosition == TooltipPosition.right
                            ? arrowWidth
                            : 0,
                        right: tooltipPosition == TooltipPosition.left
                            ? arrowWidth
                            : 0,
                      ),
                    ),
                    child: Center(
                      child: MeasureSize(
                        onSizeChange: (size) =>
                            onTooltipSizeChanged(size, context),
                        child: widget.tooltip,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TooltipPainter extends CustomPainter {
  final double arrowWidth;
  final double arrowHeight;
  final Color backgroundColor;
  final Color? borderColor;
  final BorderRadius borderRadius;
  final Size screenSize;
  final Offset targetCenter;
  final TooltipPosition tooltipPosition;
  final Offset arrowOffset;

  const _TooltipPainter({
    required this.arrowWidth,
    required this.arrowHeight,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderRadius,
    required this.screenSize,
    required this.targetCenter,
    required this.tooltipPosition,
    required this.arrowOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (borderColor != null) {
      borderPaint.color = borderColor!;
    }

    final double tooltipWidth = min(screenSize.width, size.width);
    final double tooltipHeight = max(0, size.height - arrowHeight);

    double arrowX = max(0, size.width / 2 + arrowOffset.dx);
    double arrowY = max(0, size.height / 2 + arrowOffset.dy);

    final double arrowHalfWidth = arrowWidth / 2;
    arrowX = arrowX.clamp(
        borderRadius.topLeft.x + arrowHalfWidth,
        max(borderRadius.topLeft.x + arrowHalfWidth,
            tooltipWidth - borderRadius.topRight.x - arrowHalfWidth));
    arrowY = arrowY.clamp(
        borderRadius.topLeft.y + arrowHalfWidth,
        max(borderRadius.topLeft.y + arrowHalfWidth,
            tooltipHeight - borderRadius.bottomRight.y - arrowHalfWidth));

    final Path backgroundPath = Path();

    switch (tooltipPosition) {
      case TooltipPosition.top:
        final double arrowLeftX = arrowX - arrowHalfWidth;
        final double arrowRightX = arrowX + arrowHalfWidth;
        backgroundPath
          ..moveTo(arrowLeftX, tooltipHeight)
          ..lineTo(arrowX, tooltipHeight + arrowHeight)
          ..lineTo(arrowRightX, tooltipHeight)
          ..addRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(
                0,
                0,
                tooltipWidth,
                tooltipHeight,
              ),
              topLeft: borderRadius.topLeft,
              topRight: borderRadius.topRight,
              bottomLeft: borderRadius.bottomLeft,
              bottomRight: borderRadius.bottomRight,
            ),
          );
        break;

      case TooltipPosition.bottom:
        final double arrowLeftX = arrowX - arrowHalfWidth;
        final double arrowRightX = arrowX + arrowHalfWidth;
        backgroundPath
          ..moveTo(arrowLeftX, arrowHeight)
          ..lineTo(arrowX, 0)
          ..lineTo(arrowRightX, arrowHeight)
          ..addRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(
                0,
                arrowHeight,
                tooltipWidth,
                tooltipHeight,
              ),
              topLeft: borderRadius.topLeft,
              topRight: borderRadius.topRight,
              bottomLeft: borderRadius.bottomLeft,
              bottomRight: borderRadius.bottomRight,
            ),
          );
        break;

      case TooltipPosition.left:
        final double arrowTopY = arrowY - arrowHalfWidth;
        final double arrowBottomY = arrowY + arrowHalfWidth;
        backgroundPath
          ..moveTo(arrowWidth, arrowTopY)
          ..lineTo(0, arrowY)
          ..lineTo(arrowWidth, arrowBottomY)
          ..addRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(
                arrowWidth,
                0,
                tooltipWidth - arrowWidth,
                tooltipHeight + arrowHeight,
              ),
              topLeft: borderRadius.topLeft,
              topRight: borderRadius.topRight,
              bottomLeft: borderRadius.bottomLeft,
              bottomRight: borderRadius.bottomRight,
            ),
          );
        break;

      case TooltipPosition.right:
        final double arrowTopY = arrowY - arrowHalfWidth;
        final double arrowBottomY = arrowY + arrowHalfWidth;
        backgroundPath
          ..moveTo(tooltipWidth - arrowWidth, arrowTopY)
          ..lineTo(tooltipWidth, arrowY)
          ..lineTo(tooltipWidth - arrowWidth, arrowBottomY)
          ..addRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(
                0,
                0,
                tooltipWidth - arrowWidth,
                tooltipHeight + arrowHeight,
              ),
              topLeft: borderRadius.topLeft,
              topRight: borderRadius.topRight,
              bottomLeft: borderRadius.bottomLeft,
              bottomRight: borderRadius.bottomRight,
            ),
          );
        break;
    }

    canvas.drawPath(backgroundPath, borderPaint);
    canvas.drawPath(backgroundPath, paint);
  }

  @override
  bool shouldRepaint(covariant _TooltipPainter oldDelegate) {
    return arrowWidth != oldDelegate.arrowWidth ||
        arrowHeight != oldDelegate.arrowHeight ||
        backgroundColor != oldDelegate.backgroundColor ||
        borderColor != oldDelegate.borderColor ||
        borderRadius != oldDelegate.borderRadius ||
        screenSize != oldDelegate.screenSize ||
        targetCenter != oldDelegate.targetCenter ||
        tooltipPosition != oldDelegate.tooltipPosition ||
        arrowOffset != oldDelegate.arrowOffset;
  }
}
