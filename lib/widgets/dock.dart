import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:draggable_dock/widgets/hoverable_wrapper.dart';
import 'package:flutter/material.dart';

class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T, double) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();
  late final ValueNotifier<List<T>> _itemsNotifier;
  final double itemHeight = 64;
  int? hoveredIndex;
  T? draggedItem;
  bool get isDragged => draggedItem != null;
  bool isDragOutside = false;

  void _updateItems(int oldIndex, int newIndex) {
    final T item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
  }

  int _calculateHoverDistance(int index) =>
      hoveredIndex == null ? -69 : (index - hoveredIndex!).abs();

  void _setIsDragOutside(bool value) {
    if (isDragged) {
      setState(() {
        if (!value) {
          hoveredIndex = null;
        }
        isDragOutside = value;
      });
    }
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              items: items,
              longPressDraggable: false,
              onReorder: (int oldIndex, int newIndex) {
                _updateItems(oldIndex, newIndex);
              }, //TODO
              onReorderStart: (p0) {
                draggedItem = items.elementAtOrNull(p0);
                hoveredIndex = null;
              },
              onReorderEnd: (p0) {
                hoveredIndex = null;
                draggedItem = null;
              },
              isSameItem: (T a, T b) => a.toString() == b.toString(),
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                return Draggable<T>(
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
                );
              },
            );
          },
        ),
      ),
    );
  }

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

  Widget _getItem(T item, int index, double height) {
    bool isItemDragged = draggedItem.toString() == item.toString();
    bool isCompacted = isItemDragged && isDragOutside;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: height,
      width: isCompacted ? 0 : height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DragTarget<T>(
            onAcceptWithDetails: (details) {
              draggedItem = null;
              final int fromIndex = _items.indexOf(details.data);
              _updateItems(fromIndex, index);
              _itemsNotifier.value = List.from(_items);
            },
            onWillAcceptWithDetails: (details) {
              setState(() {
                hoveredIndex = index;
              });

              final int fromIndex = _items.indexOf(details.data);
              _updateItems(fromIndex, index);
              _itemsNotifier.value = List.from(_items);
              return true;
            },
            builder: (context, candidateData, rejectedData) {
              return Container();
            },
          ),
          HoverableWrapper(
            index: index,
            distance: _calculateHoverDistance(index),
            onHover: (int? i) {
              setState(() {
                hoveredIndex = i;
              });
            },
            isAnyDragged: isDragged,
            child: isItemDragged ? Container() : widget.builder(item, height),
          ),
        ],
      ),
    );
  }
}
