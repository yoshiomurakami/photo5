import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // StreamControllerを使用するために必要
import 'error_dialog.dart';
import 'error_dialog_data.dart';
import 'main_screen.dart';
import 'dart:ui' as ui;

class Startup extends StatefulWidget {
  @override
  _StartupState createState() => _StartupState();
}

class _StartupState extends State<Startup> {
  late StreamController<bool> _startupController;

  @override
  void initState() {
    super.initState();
    _startupController = StreamController<bool>();
    _startupProcedures(context);
  }

  @override
  void dispose() {
    _startupController.close();
    super.dispose();
  }

  Widget _splashScreen() {
    return Scaffold(
      body: Container(
        color: Colors.blue,  // これで全画面が青になります
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _startupController.stream,
      builder: (context, snapshot) {
        // Startup logic is still running
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _splashScreen();
        }

        // Startup logic has completed with an error
        if (snapshot.hasError && snapshot.error is ErrorDialogData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorDialog(snapshot.error as ErrorDialogData);
          });
        }

        // Startup logic has completed successfully
        if (snapshot.hasData && snapshot.data == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          });
        }

        // While waiting for the navigator to finish, keep showing the splash screen
        return _splashScreen();
      },
    );
  }

  Future<bool> _startupProcedures(BuildContext context) async {
    debugPrint("Startup procedures starting");
    try {
      await _checkLanguageSetting();

      await _checkConnectivity(context);

      await _checkVersion();

      await _checkUserId();
      // Continue with other startup checks as needed

      debugPrint("Startup procedures completed");
      _startupController.add(true);
      return true;
    } catch (e) {
      if (e is ErrorDialogData) {
        _showErrorDialog(e);
      }
      // Add other error handling code as needed
      _startupController.addError(e);
      return false;
    }
  }

  Future<void> _checkLanguageSetting() async {
    debugPrint("Checking language setting");
    Locale myLocale = ui.PlatformDispatcher.instance.locale;
    String languageCode = myLocale.languageCode; // en, ja, etc.
    debugPrint(languageCode);
    return;
  }

  Future<void> _checkConnectivity(BuildContext context) async {
    debugPrint("Connectivity check starting");
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      throw createErrorDialogData('No internet connection', (ctx) => _startupProcedures(context), ErrorDialogType.RETRY_DIALOG, context);
    } else {
      debugPrint("Connectivity OK");
    }
    return;
  }

  Future<void> _checkVersion() async {
    debugPrint("Version check starting");
    // await Future.delayed(Duration(seconds: 3));
    debugPrint("Version check completed");
    return;
  }

  Future<void> _checkUserId() async {
    debugPrint("UserId check starting");
    // await Future.delayed(Duration(seconds: 3));
    debugPrint("UserId check completed");
    return;
  }

  void _showErrorDialog(ErrorDialogData errorDialogData) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ErrorDialog(errorDialogData: errorDialogData);
      },
    );
  }

  ErrorDialogData createErrorDialogData(String description, Future<bool> Function(BuildContext) dialogFunction, ErrorDialogType dialogType, BuildContext context) {
    return ErrorDialogData(
      description: description,
      actionInDialog: dialogFunction,
      dialogType: dialogType,
      context: context,
    );
  }
}
