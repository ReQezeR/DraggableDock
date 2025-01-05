import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:draggable_dock/widgets/dock_item.dart';
import 'package:flutter/material.dart';

class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
    this.itemHeight = 64,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T, double) builder;

  /// DockItem height
  final double itemHeight;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  late final List<T> _items = widget.items.toList();
  late final ValueNotifier<List<T>> _itemsNotifier;

  late final double itemHeight = widget.itemHeight;

  int? hoveredIndex;
  T? draggedItem;
  bool get isAnyDragged => draggedItem != null;
  bool isDragOutside = false;

  @override
  void initState() {
    super.initState();
    _itemsNotifier = ValueNotifier<List<T>>(widget.items.toList());
  }

  @override
  void dispose() {
    _itemsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setIsDragOutside(false),
      onExit: (_) => _setIsDragOutside(true),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black12,
        ),
        height: itemHeight,
        child: ValueListenableBuilder(
          valueListenable: _itemsNotifier,
          builder: (context, List<T> items, child) {
            return AnimatedReorderableListView(
              items: items,
              shrinkWrap: true,
              longPressDraggable: false,
              buildDefaultDragHandles: false,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              isSameItem: (T a, T b) => a.toString() == b.toString(),
              onReorder: (int oldIndex, int newIndex) {
                _moveItem(oldIndex, newIndex);
              },
              onReorderStart: (p0) {
                draggedItem = items.elementAtOrNull(p0);
                hoveredIndex = null;
              },
              onReorderEnd: (p0) {
                hoveredIndex = null;
                draggedItem = null;
              },
              itemBuilder: (context, index) => Draggable<T>(
                key: ValueKey(_items[index].toString()),
                data: _items[index],
                feedback: _getFeedbackItem(_items[index], itemHeight),
                child: _getItem(_items[index], index, itemHeight),
                onDragStarted: () {
                  draggedItem = _items[index];
                },
                onDragEnd: (details) {
                  setState(() {
                    draggedItem = null;
                    hoveredIndex = null;
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Helper to change item order
  void _moveItem(int oldIndex, int newIndex) {
    final T item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
  }

  /// Helper to update flag if the item is being dragged outside the dock
  void _setIsDragOutside(bool value) {
    if (isAnyDragged) {
      setState(() {
        if (!value) {
          hoveredIndex = null;
        }
        isDragOutside = value;
      });
    }
  }

  /// Helper to calculate distance from hovered item
  int _calculateHoverDistance(int index) =>
      hoveredIndex == null ? -69 : (index - hoveredIndex!).abs();

  /// Helper to determine if the item is being dragged
  bool _isItemDragged(T item) => draggedItem?.toString() == item.toString();

  /// Helper to determine if the item should be compacted
  bool _isCompacted(bool isItemDragged) => isItemDragged && isDragOutside;

  /// FeedbackItem widget
  Widget _getFeedbackItem(T item, double size) {
    return Transform.scale(
      scale: 1.2,
      child: SizedBox(
        height: size,
        width: size,
        child: widget.builder(item, size),
      ),
    );
  }

  /// DockItem widget
  Widget _getItem(T item, int index, double height) {
    return DockItem<T>(
      index: index,
      item: item,
      height: height,
      builder: widget.builder,
      distance: _calculateHoverDistance(index),
      isCompacted: _isCompacted(_isItemDragged(item)),
      isDragged: _isItemDragged(item),
      isAnyDragged: isAnyDragged,
      onAcceptWithDetails: (T data) {
        draggedItem = null;
        final int fromIndex = _items.indexOf(data);
        _moveItem(fromIndex, index);
        _itemsNotifier.value = List.from(_items);
      },
      onWillAcceptWithDetails: (T data) {
        setState(() {
          hoveredIndex = index;
        });

        final int fromIndex = _items.indexOf(data);
        _moveItem(fromIndex, index);
        _itemsNotifier.value = List.from(_items);
        return true;
      },
      onHover: (int? i) {
        setState(() {
          hoveredIndex = i;
        });
      },
    );
  }
}
