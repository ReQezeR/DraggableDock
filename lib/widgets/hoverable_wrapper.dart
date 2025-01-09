import 'package:flutter/material.dart';

/// [Widget] that scales it's child when hovered.
class HoverableWrapper extends StatefulWidget {
  const HoverableWrapper({
    super.key,
    required this.index,
    required this.child,
    required this.distance,
    required this.onHover,
    required this.isAnyDragged,
  });
  final Widget child;
  final int index;
  final int distance;
  final Function(int? index) onHover;
  final bool isAnyDragged;

  @override
  State<HoverableWrapper> createState() => _HoverableWrapperState();
}

class _HoverableWrapperState extends State<HoverableWrapper> {
  bool _isHovered = false;

  /// Helper to determine scale depending on distance from hovered item.
  double _getDistanceScale() {
    if (widget.distance == 0) {
      return 1.2;
    } else if (widget.distance == 1) {
      return 1.1;
    } else if (widget.distance == 2) {
      return 1.05;
    } else {
      return 1;
    }
  }

  /// Handles on hover logic
  void _onHover() {
    if (!widget.isAnyDragged) {
      _isHovered = true;
      widget.onHover(widget.index);
    } else {
      _isHovered = true;
    }
  }

  /// Handles on hover end logic
  void _onHoverEnd() {
    if (!widget.isAnyDragged) {
      _isHovered = false;
      widget.onHover(null);
    } else {
      _isHovered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      hitTestBehavior: HitTestBehavior.translucent,
      onEnter: (_) => _onHover(),
      onExit: (_) => _onHoverEnd(),
      child: AnimatedScale(
        alignment: Alignment.bottomCenter,
        duration: Duration(milliseconds: _isHovered ? 200 : 400),
        curve: _isHovered ? Curves.easeOut : Curves.ease,
        scale: _isHovered ? 1.2 : _getDistanceScale(),
        child: widget.child,
      ),
    );
  }
}
