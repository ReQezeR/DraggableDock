import 'package:draggable_dock/widgets/hoverable_wrapper.dart';
import 'package:flutter/material.dart';

class DockItem<T extends Object> extends StatefulWidget {
  const DockItem({
    super.key,
    required this.index,
    required this.item,
    required this.height,
    required this.distance,
    required this.isVisible,
    required this.isCompacted,
    required this.isDragged,
    required this.isAnyDragged,
    required this.onHover,
    required this.builder,
  });
  final int index;
  final T item;
  final double height;
  final int distance;
  final bool isVisible;
  final bool isCompacted;
  final bool isDragged;
  final bool isAnyDragged;
  final Widget Function(T, double) builder;
  final Function(int?) onHover;

  @override
  State<DockItem<T>> createState() => _DockItemState<T>();
}

class _DockItemState<T extends Object> extends State<DockItem<T>> {
  bool _isCompacted = false;
  bool _showChild = false;

  @override
  void initState() {
    _isCompacted = widget.isCompacted;
    _showChild = widget.isVisible;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _isCompacted = widget.isCompacted;

    if (_isCompacted) {
      _showChild = false;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: widget.height,
      width: _isCompacted ? 0 : widget.height,
      onEnd: () {
        setState(() {
          _showChild = !_isCompacted;
        });
      },
      child: Opacity(
        opacity: _showChild ? 1.0 : 0,
        child: HoverableWrapper(
          index: widget.index,
          distance: widget.distance,
          onHover: (int? i) => widget.onHover(i),
          isAnyDragged: widget.isAnyDragged,
          child: widget.isDragged
              ? Container()
              : widget.builder(widget.item, widget.height),
        ),
      ),
    );
  }
}
