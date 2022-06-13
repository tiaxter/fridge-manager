import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SlidableTile extends StatelessWidget {
  @override
  final Key key;
  final Widget child;
  final Function() delete;
  final Function() edit;
  final Function() remove;
  final Function() removeDismiss;
  final Function() deleteDismiss;

  const SlidableTile({
    required this.key,
    required this.child,
    required this.delete,
    required this.edit,
    required this.remove,
    required this.removeDismiss,
    required this.deleteDismiss
  }) : super(key: key);

  void undoableSnackbar(BuildContext context, Function() undo) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.red,
      content: const Text('Product removed!'),
      action: SnackBarAction(
        label: 'Undo',
        textColor: Colors.white,
        onPressed: undo
      )
    ));

  }

  @override
  Widget build(BuildContext context) {
    ActionPane actionPane = ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.75,
        children: [
          SlidableAction(
            onPressed: (BuildContext? ctx) => edit(),
            label: 'Edit',
            icon: Icons.edit,
            foregroundColor: Colors.white,
            backgroundColor: Colors.lightBlue,
          ),
          SlidableAction(
            onPressed: (BuildContext? ctx) async {
              await remove();
              undoableSnackbar(context, removeDismiss);
            },
            label: 'Remove one',
            icon: Icons.exposure_neg_1,
            foregroundColor: Colors.white,
            backgroundColor: Colors.orange,
          ),
          SlidableAction(
            onPressed: (BuildContext? ctx) async {
              await delete();
              undoableSnackbar(context, removeDismiss);
            },
            label: 'Delete',
            icon: Icons.delete,
            backgroundColor: Colors.red,
          ),
        ],
      );
    return Slidable(
      key: key,
      endActionPane: actionPane,
      child: child,
    );
  }
}
