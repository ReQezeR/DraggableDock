import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';

/// [Widget] building animated and reorderable list of draggable items.
class DockDragableList<T extends Object> extends StatelessWidget {
  const DockDragableList({
    super.key,
    required this.items,
    required this.itemSize,
    required this.enableSwap,
    required this.onDragStarted,
    required this.onDraggableCanceled,
    required this.itemBuilder,
    required this.feedbackBuilder,
  });

  final List<T> items;
  final double itemSize;
  final bool enableSwap;

  final Function(int index) onDragStarted;
  final Function(int index, Offset offset) onDraggableCanceled;
  final Widget Function(T item, double size) feedbackBuilder;
  final Widget Function(T item, int index, double size) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      height: itemSize,
      child: AnimatedReorderableListView(
        items: items,
        nonDraggableItems: items,
        enableSwap: enableSwap,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        longPressDraggable: false,
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        isSameItem: (a, b) => a == b,
        onReorder: (oldIndex, newIndex) {},
        itemBuilder: (context, index) => Draggable<T>(
          key: ValueKey(items[index].toString()),
          hitTestBehavior: HitTestBehavior.translucent,
          data: items[index],
          feedback: Transform.translate(
            offset: const Offset(0, -6),
            child: feedbackBuilder(items[index], itemSize),
          ),
          child: itemBuilder(items[index], index, itemSize),
          onDragStarted: () => onDragStarted(index),
          onDraggableCanceled: (velocity, offset) =>
              onDraggableCanceled(index, offset),
        ),
      ),
    );
  }
}
