import 'package:flutter/material.dart';

class DismissableTile extends StatelessWidget {
  final Key key;
  final Widget child;
  final Function() onDismissed;
  final Function() cancelDismiss;

  const DismissableTile({
    required this.key,
    required this.child,
    required this.onDismissed,
    required this.cancelDismiss
  }) : super(key: key);

  Widget deleteBackground(MainAxisAlignment alignment) {
    return Container(
      color: Colors.red,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: alignment,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            Text("Remove product", style: TextStyle(color: Colors.white),),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key,
      background: deleteBackground(MainAxisAlignment.start),
      secondaryBackground: deleteBackground(MainAxisAlignment.end),
      onDismissed: (DismissDirection dismissDirection) async {
        // Execute on Dismissed function
        onDismissed();
        // Show snackbar to undo the delete operation
        Scaffold.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: const Text('Product removed!'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: cancelDismiss
          )
        ));
      },
      child: child
    );
  }
}
