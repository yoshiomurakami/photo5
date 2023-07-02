import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'error_dialog.dart';
import 'error_dialog_data.dart';
import 'main_screen.dart';
import 'dart:ui' as ui;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overboard/flutter_overboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: Startup(),
      home:IntroductionScreen(),
    );
  }
}

class IntroductionScreen extends StatefulWidget {
  @override
  _IntroductionScreenState createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  @override
  void initState() {
    super.initState();
    _checkIntroStatus();
  }

  Future<void> _checkIntroStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int introStatus = prefs.getInt('intro') ?? 0;
    if (introStatus == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => Startup()),
      );
    }
  }

  Widget _introduction(BuildContext context) {
    return Scaffold(
      body: OverBoard(
        nextText: 'next',
        skipText: 'skip',
        finishText: 'agree',
        allowScroll: true,
        pages: pages,
        showBullets: true,
        inactiveBulletColor: Colors.blue,
        finishCallback: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('intro', 1);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Startup()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _introduction(context);
  }
}

  final pages = [
    PageModel(
        color: const Color(0xFF0097A7),
        imageAssetPath: 'assets/01.png',
        title: 'Screen 1',
        body: 'Share your ideas with the team',
        doAnimateImage: true),
    PageModel(
        color: const Color(0xFF536DFE),
        imageAssetPath: 'assets/02.png',
        title: 'Screen 2',
        body: 'See the increase in productivity & output',
        doAnimateImage: true),
    PageModel(
        color: const Color(0xFF9B90BC),
        imageAssetPath: 'assets/03.png',
        title: 'Screen 3',
        body: 'Connect with the people from different places',
        doAnimateImage: true),
    PageModel.withChild(
        child: TermsAndPrivacyPolicyPage(),
        color: const Color(0xFF5886d6),
        doAnimateChild: true)

  ];

class TermsAndPrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        color: Colors.white,
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー利用規約とプライバシーポリシー", // Replace this with your actual terms and privacy policy
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class Startup extends StatefulWidget {
  @override
  _StartupState createState() => _StartupState();
}

class _StartupState extends State<Startup> {
  late StreamController<bool> _startupController;
  String loadingText = 'Now Loading';
  // late Timer loadingTextTimer;
  // int loadingDots = 1; // Add this line
  String latestVersion = "";

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



  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _startupController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError && snapshot.error is ErrorDialogData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorDialog(snapshot.error as ErrorDialogData);
          });
          return _buildLoadingScreen();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasData && snapshot.data == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          });
        }

        return _buildLoadingScreen();

      },
    );
  }

  @override
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Color(0xFFFFCC4D),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.width * 0.2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "🤚",
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    "Latest version from server: $latestVersion", // Display the latest version here
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                    ),
                  ),
                  SizedBox(height: 16.0),  // Add spacing between the two text widgets
                  Text(
                    loadingText,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkConnectivity(BuildContext context) async {
    // await Future.delayed(Duration(seconds: 5));
    debugPrint("Connectivity check starting");
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("No internet connection");

      StreamSubscription<ConnectivityResult>? subscription;
      subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        if (result != ConnectivityResult.none) {
          subscription?.cancel();
          debugPrint("Connectivity established");
          // Resume startup procedures
          _startupProcedures(context);
        }
      });
      throw createErrorDialogData('No internet connection', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
    } else {
      debugPrint("Connectivity OK");
    }
    return;
  }

  Future<void> _checkVersion() async {
    debugPrint("Version check starting");

    String currentVersion;

    // Fetch package info
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
      debugPrint("Current app version: $currentVersion");
    } catch (e) {
      // Handle error from package info fetching
      throw createErrorDialogData('Could not fetch the app version. Please check if the application is properly installed.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
    }

    // Fetch latest version from server
    try {
      final response = await http.get(Uri.parse('https://photo5.world/api/startup/version'));
      if (response.statusCode == 200) {
        latestVersion = jsonDecode(response.body)['version'];
        debugPrint("Latest version from server: $latestVersion");
        if (currentVersion != latestVersion) {
          debugPrint("Need to update to the latest version");
        }
      } else {
        throw createErrorDialogData('Failed to load version info from the server', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
      }
    } catch (e) {
      // Handle error from server response
      throw createErrorDialogData('No internet connection or server unreachable. Please check your internet connection.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
    }

    debugPrint("Version check completed");
    return;
  }

  Future<void> _checkUserId() async {
    debugPrint("UserId check starting");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userID') ?? "";
    debugPrint("userId in SharedPreferences = $userId");

    if (userId.length == 8) {
      // save value to a variable accessible globally
      // globalUserId = userId; // Assume that globalUserId is a global variable.
      return;
    } else if (userId.isNotEmpty) {
      throw createErrorDialogData('The UserID is corrupted. Please initialize the application.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
    }

    try {
      // Assuming that http package is imported and API_URI is defined.
      var response = await http.post(
        Uri.parse('https://photo5.world/api/express/regist'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        String newUserId = jsonDecode(response.body)['userID'];
        debugPrint("New userID: $newUserId");
        if (newUserId.length == 8) {
          prefs.setString('userID', newUserId);
        } else {
          throw createErrorDialogData('Could not fetch valid UserID. Please check your network connection and try again.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
        }
      } else {
        throw createErrorDialogData('Could not fetch UserID from server. Please check your network connection and try again.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
      }
    } catch (e) {
      throw createErrorDialogData('Unexpected error occurred while fetching UserID. Please check your network connection and try again.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
    }
    debugPrint("UserId check completed");
    return;
  }

  Future<void> _checkStatus() async {
    debugPrint("Status check starting");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String status = prefs.getString('status') ?? "";

    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      throw createErrorDialogData('Could not access app data. Please restart the application.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
    }

    try {
      status = prefs.getString('status') ?? "";
      debugPrint('Current status value: $status');
    } catch (e) {
      throw createErrorDialogData('Could not read app status. Please restart the application.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
    }

    if (status == '0') {
      try {
        await _showTutorial();
        //便宜上0に上書き。本当は1にする。
        prefs.setString('status', '0');
      } catch (e) {
        throw createErrorDialogData('Could not complete the tutorial. Please check your network connection and try again.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
      }
    } else if (status.isEmpty) {
      try {
        await _showTutorial();
        //便宜上0に上書き。本当は1にする。
        prefs.setString('status', '0');
      } catch (e) {
        throw createErrorDialogData('Could not initialize app status. Please restart the application.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
      }
    } else {
      // status is not '0', so just return
      //便宜上0に上書き。本当は1にする。
      prefs.setString('status', '0');
      debugPrint("Status check completed");
      return;
    }

    debugPrint("Status check completed");
    return;
  }

  Future<void> _showTutorial() async {
    debugPrint("Start _showTutorial()");
    // Implementation of the tutorial goes here.
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            child: PageView(
              children: <Widget>[
                _tutorialPage('assets/tutorial1.png', 'Tutorial text 1'),
                _tutorialPage('assets/tutorial2.png', 'Tutorial text 2'),
                _tutorialPage('assets/tutorial3.png', 'Tutorial text 3', showButton: true),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _tutorialPage(String imagePath, String text, {bool showButton = false}) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.width * 0.8, // or another value to match the width of your SizedBox
          child: Image.asset(imagePath, fit: BoxFit.contain),
        ),
        Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (showButton)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Start'),
          ),
      ],
    );
  }





  Future<bool> _startupProcedures(BuildContext context) async {
    debugPrint("Startup procedures starting");
    try {
      // Wait for both _checkConnectivity(context) and Duration(seconds: 5) to complete
      await Future.wait([
        _checkConnectivity(context),
        Future.delayed(Duration(seconds: 5)),
      ]);
      await _checkVersion();
      await _checkUserId();
      await _checkStatus();

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

  void _showErrorDialog(ErrorDialogData errorDialogData) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,  // This line is added
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