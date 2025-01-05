import 'package:draggable_dock/widgets/hoverable_wrapper.dart';
import 'package:flutter/material.dart';

class DockItem<T extends Object> extends StatefulWidget {
  const DockItem({
    super.key,
    required this.index,
    required this.item,
    required this.height,
    required this.distance,
    required this.isCompacted,
    required this.isDragged,
    required this.isAnyDragged,
    required this.onAcceptWithDetails,
    required this.onWillAcceptWithDetails,
    required this.onHover,
    required this.builder,
  });
  final int index;
  final T item;
  final double height;
  final int distance;
  final bool isCompacted;
  final bool isDragged;
  final bool isAnyDragged;
  final Widget Function(T, double) builder;
  final Function(T) onAcceptWithDetails;
  final Function(T) onWillAcceptWithDetails;
  final Function(int?) onHover;

  @override
  State<DockItem<T>> createState() => _DockItemState<T>();
}

class _DockItemState<T extends Object> extends State<DockItem<T>> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: widget.height,
      width: widget.isCompacted ? 0 : widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DragTarget<T>(
            onAcceptWithDetails: (details) =>
                widget.onAcceptWithDetails(details.data),
            onWillAcceptWithDetails: (details) =>
                widget.onWillAcceptWithDetails(details.data),
            builder: (context, candidateData, rejectedData) {
              return Container();
            },
          ),
          HoverableWrapper(
            index: widget.index,
            distance: widget.distance,
            onHover: (int? i) => widget.onHover(i),
            isAnyDragged: widget.isAnyDragged,
            child: widget.isDragged
                ? Container()
                : widget.builder(widget.item, widget.height),
          ),
        ],
      ),
    );
  }
}
