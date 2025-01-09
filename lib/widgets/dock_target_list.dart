import 'package:flutter/material.dart';

/// [Widget] building list of drag targets.
class DockTargetList<T extends Object> extends StatelessWidget {
  const DockTargetList({
    super.key,
    required this.isIgnored,
    required this.onAccept,
    required this.onWillAccept,
    required this.itemSize,
    required this.itemCount,
  });

  final bool isIgnored;
  final double itemSize;
  final int itemCount;

  final Function(T data, int index) onAccept;
  final bool Function(T data, int index) onWillAccept;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isIgnored,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return SizedBox(
            width: itemSize,
            height: itemSize,
            child: DragTarget<T>(
              hitTestBehavior: HitTestBehavior.translucent,
              onAcceptWithDetails: (details) => onAccept(details.data, index),
              onWillAcceptWithDetails: (details) =>
                  onWillAccept(details.data, index),
              builder: (context, candidateData, rejectedData) {
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
  }
}
