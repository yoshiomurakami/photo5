import 'package:flutter/material.dart';

enum ErrorDialogType {
  RETRY_DIALOG,
  CLOSE_DIALOG,
  YES_NO_DIALOG,
  // ... その他の種類
}

class ErrorDialogData {
  final String description;
  final Future<bool> Function(BuildContext context) actionInDialog;
  final ErrorDialogType dialogType;
  final List<Widget> actions;

  ErrorDialogData({
    required this.description,
    required this.actionInDialog,
    required this.dialogType,
    required BuildContext context,
  }) : actions = _generateActions(dialogType, actionInDialog, context);

  static List<Widget> _generateActions(ErrorDialogType dialogType, Future<bool> Function(BuildContext context) actionInDialog, BuildContext context) {
    switch(dialogType) {
      case ErrorDialogType.RETRY_DIALOG:
        return [
          TextButton(
            child: Text('Retry'),
            onPressed: () async {
              Navigator.of(context).pop();
              await actionInDialog(context);
            },
          ),
        ];
      case ErrorDialogType.CLOSE_DIALOG:
        return [
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ];
      case ErrorDialogType.YES_NO_DIALOG:
        return [
          TextButton(
            child: Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Yes'),
            onPressed: () async {
              Navigator.of(context).pop();
              await actionInDialog(context);
            },
          ),
        ];
    }
  }
}
