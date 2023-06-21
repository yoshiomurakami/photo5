import 'package:flutter/material.dart';
import 'error_dialog_data.dart';

class ErrorDialog extends StatelessWidget {
  final ErrorDialogData errorDialogData;

  ErrorDialog({required this.errorDialogData});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(errorDialogData.description),
      actions: errorDialogData.actions,
    );
  }
}