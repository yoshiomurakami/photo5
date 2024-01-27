import 'package:flutter/material.dart';

enum ErrorDialogType {
  dependDialog,
  retryDialog,
  closeDialog,
  yesNoDialog,
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
      case ErrorDialogType.dependDialog:
        return [
        ];
      case ErrorDialogType.retryDialog:
        return [
          TextButton(
            child: const Text('Retry'),
            onPressed: () async {
              Navigator.of(context).pop();
              await actionInDialog(context);
            },
          ),
        ];
      case ErrorDialogType.closeDialog:
        return [
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ];
      case ErrorDialogType.yesNoDialog:
        return [
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () async {
              Navigator.of(context).pop();
              await actionInDialog(context);
            },
          ),
        ];
    }
  }
}
