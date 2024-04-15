import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void displayDeleteEntryDialog(BuildContext context,
    {required String message,
    String deleteWord = 'Delete',
    required Function deleteEntry}) async {
  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                GoRouter.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                GoRouter.of(context).pop();
                deleteEntry();
              },
              child: Text(deleteWord),
            ),
          ],
        );
      });
}
