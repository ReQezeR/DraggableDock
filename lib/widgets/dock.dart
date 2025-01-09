import 'package:draggable_dock/widgets/dock_dragable_list.dart';
import 'package:draggable_dock/widgets/dock_item.dart';
import 'package:draggable_dock/widgets/dock_target_list.dart';
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
class _DockState<T extends Object> extends State<Dock<T>>
    with SingleTickerProviderStateMixin {
  ///List of [T] items
  late final List<T> _items = widget.items.toList();

  ///ValueNotifier connected to [_items] list
  late final ValueNotifier<List<T>> _itemsNotifier;

  late final double itemSize = widget.itemHeight;

  ///Global dock posiotion.
  Offset? dockOffset;

  ///Index of hovered item.
  int? hoveredIndex;

  ///Index of dragged item.
  int? invisibleIndex;

  ///Dragged item.
  T? draggedItem;

  ///Is item dragged outside dock
  bool isDragOutside = false;

  ///Was item dragged outside dock
  bool wasDragOutside = false;

  ///Is swapping animation enabled
  bool enableSwap = true;

  //Overlay related variables
  OverlayEntry? overlayEntry;
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;

  bool get isAnyDragged => draggedItem != null;

  @override
  void initState() {
    super.initState();
    _itemsNotifier = ValueNotifier<List<T>>(widget.items.toList());
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initScaleAnimation();
  }

  @override
  void dispose() {
    removeOverlay();
    _controller.dispose();
    _itemsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setIsDragOutside(false),
      onExit: (_) => _setIsDragOutside(true),
      child: SizedBox(
        height: itemSize,
        child: ValueListenableBuilder(
          valueListenable: _itemsNotifier,
          builder: (context, List<T> items, child) {
            return Stack(
              fit: StackFit.loose,
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                DockDragableList(
                  items: items,
                  itemSize: itemSize,
                  enableSwap: enableSwap,
                  itemBuilder: (item, index, size) =>
                      _getItem(item, index, size),
                  feedbackBuilder: (item, size) => _getFeedbackItem(item, size),
                  onDragStarted: (index) => _onItemDragStarted(index),
                  onDraggableCanceled: (index, offset) =>
                      _onItemDragCanceled(index, offset),
                ),
                DockTargetList(
                  isIgnored: !isAnyDragged,
                  itemCount: items.length,
                  itemSize: itemSize,
                  onAccept: (T data, index) => _onDragAccept(data, index),
                  onWillAccept: (T data, index) =>
                      _onDragWillAccept(data, index),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// On drag start set draggedItem and invisibleIndex based on index.
  void _onItemDragStarted(int index) {
    setState(() {
      draggedItem = _items[index];
      invisibleIndex = index;
    });
  }

  /// On drag cancel set animation offset, play animation and reset selected variables values.
  void _onItemDragCanceled(int index, Offset offset) {
    _setPositionAnimation(index, offset);

    _showOverlayAndAnimate(
      _getFeedbackItem(_items[index], itemSize),
    );
    setState(() {
      enableSwap = true;
      isDragOutside = false;
      draggedItem = null;
      hoveredIndex = null;
    });
  }

  /// On drag accept change item position and reset selected variables values.
  void _onDragAccept(T data, int index) {
    final int fromIndex = _items.indexOf(data);
    _moveItem(fromIndex, index);
    draggedItem = null;
    invisibleIndex = null;
  }

  /// On will drag accept update variables and change item position.
  bool _onDragWillAccept(T data, int index) {
    final int fromIndex = _items.indexOf(data);

    setState(() {
      // False when swapping items order in reverse direction and item was outside dock.
      if (index + 1 == fromIndex && wasDragOutside) {
        enableSwap = false;
      } else {
        enableSwap = true;
      }
      wasDragOutside = false;
      hoveredIndex = index;
    });
    _moveItem(fromIndex, index);

    return true;
  }

  ///Setup scale animation.
  void _initScaleAnimation() {
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  ///Setup position animation with given offset.
  void _setPositionAnimation(int index, Offset offset) {
    double leftPadding = 8;
    double itemWidth = widget.itemHeight;
    double endX = (dockOffset?.dx ?? 0) + leftPadding + (index * itemWidth);
    double endY = dockOffset?.dy ?? 0;

    _positionAnimation = Tween<Offset>(
      begin: Offset(offset.dx, offset.dy),
      end: Offset(endX, endY),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  ///Show and animate feedback item on overlay.
  void _showOverlayAndAnimate(Widget item, {bool animateScale = true}) {
    overlayEntry?.remove();

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Transform.scale(
            scale: animateScale ? _scaleAnimation.value : 1.0,
            child: item,
          ),
        );
      },
    );

    Overlay.of(context).insert(overlayEntry!);
    _controller.forward(from: 0).whenComplete(() {
      removeOverlay();
      setState(() {
        invisibleIndex = null;
      });
    });

    _controller.addListener(() {
      overlayEntry?.markNeedsBuild();
    });
  }

  ///Cleanup overlay.
  void removeOverlay() {
    overlayEntry?.remove();
    overlayEntry?.dispose();
    overlayEntry = null;
  }

  /// Change items order, move item from oldIndex to newIndex.
  void _moveItem(int oldIndex, int newIndex) {
    if (oldIndex != newIndex) {
      final T item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    }
    _itemsNotifier.value = List.from(_items);
  }

  /// Helper to determine and update dockOffset.
  void _setDockOffset() {
    Offset raw =
        (context.findRenderObject() as RenderBox).globalToLocal(Offset.zero);
    dockOffset = Offset(raw.dx.abs(), raw.dy.abs());
  }

  /// Helper to update flag if the item is being dragged outside the dock.
  void _setIsDragOutside(bool value) {
    _setDockOffset();

    if (isAnyDragged) {
      setState(() {
        if (!value) {
          hoveredIndex = null;
        } else {
          wasDragOutside = true;
        }
        isDragOutside = value;
      });
    }
  }

  /// Helper to calculate distance from hovered item.
  int _calculateHoverDistance(int index) =>
      hoveredIndex == null || isDragOutside
          ? -69
          : (index - hoveredIndex!).abs();

  /// Helper to determine if the item is being dragged.
  bool _isItemDragged(T item) => draggedItem?.toString() == item.toString();

  /// Helper to determine if the item should be compacted.
  bool _isCompacted(int index, bool isItemDragged) {
    return isItemDragged && isDragOutside;
  }

  /// FeedbackItem widget builder.
  Widget _getFeedbackItem(T item, double size, {double scale = 1.2}) {
    return Transform.scale(
      scale: scale,
      child: SizedBox(
        height: size,
        width: size,
        child: widget.builder(item, size),
      ),
    );
  }

  /// DockItem widget builder.
  Widget _getItem(T item, int index, double size) {
    return DockItem<T>(
      index: index,
      item: item,
      height: size,
      builder: widget.builder,
      distance: _calculateHoverDistance(index),
      isVisible: invisibleIndex != index,
      isCompacted: _isCompacted(index, _isItemDragged(item)),
      isDragged: _isItemDragged(item),
      isAnyDragged: isAnyDragged,
      onHover: (int? i) {
        setState(() {
          hoveredIndex = i;
        });
      },
    );
  }
}
