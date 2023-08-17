import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overboard/flutter_overboard.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'error_dialog.dart';
import 'error_dialog_data.dart';
import 'main_screen.dart';
import 'timeline_providers.dart';
import 'chat_connection.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.getInstance().then((prefs) {
    final int? introStatus = prefs.getInt('intro') ?? 0;
    runApp(
      ProviderScope(
        child: MyApp(home: introStatus == 1 ? Startup() : IntroductionScreen()),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  final Widget home;

  MyApp({required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: this.home,
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
  late PageController pageController;
  late StreamController<bool> _startupController;
  String loadingText = 'Now Loading';
  String latestVersion = "";
  LatLng? _currentLocation;
  List<TimelineItem>? _timelineItems;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    _startupController = StreamController<bool>();
    _startupProcedures(context);
  }


  @override
  void dispose() {
    pageController.dispose();
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

  // @override
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
                        "✋",
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

  Future<bool> _startupProcedures(BuildContext context) async {
    debugPrint("Startup procedures starting");
    try {
      // Wait for both _checkConnectivity(context) and Duration(seconds: 5) to complete
      await Future.wait([
        _checkConnectivity(context),
        _checkDatabaseTable(), // Your new DB check function
        // Future.delayed(Duration(seconds: 5)),
      ]);
      await _checkVersion();
      await _checkUserId();
      await _checkStatus();
      await _checkPermission();

        _currentLocation = await determinePosition();
        _timelineItems = await getTimelineWithGeocoding();

      ChatConnection chatConnection = ChatConnection();
      chatConnection.connect(); // チャットサーバーへの接続を開始


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
        await _getPermission();
        //便宜上0に上書き。本当は1にする。
        prefs.setString('status', '1');
      } catch (e) {
        throw createErrorDialogData('Could not complete the tutorial. Please check your network connection and try again.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
      }
    } else if (status.isEmpty) {
      try {
        await _getPermission();
        //便宜上0に上書き。本当は1にする。
        prefs.setString('status', '1');
      } catch (e) {
        throw createErrorDialogData('Could not initialize app status. Please restart the application.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
      }
    } else {
      // status is not '0', so check permissions
      PermissionStatus cameraPermission = await Permission.camera.status;
      PermissionStatus locationPermission = await Permission.location.status;

      if (!cameraPermission.isGranted || !locationPermission.isGranted) {
        // One or both permissions are not granted, so show tutorial
        try {
          await _getPermission();
          // Set status to '1' after tutorial
          prefs.setString('status', '1');
        } catch (e) {
          // Handle error during tutorial as before
          throw createErrorDialogData('Could not complete the tutorial. Please check your network connection and try again.', (ctx) => _startupProcedures(context), ErrorDialogType.DEPEND_DIALOG, context);
        }
      } else {
        // Both permissions are granted, so just set status to '1'
        prefs.setString('status', '1');
      }
      debugPrint("Status check completed");
      return;
    }


    debugPrint("Status check completed");
    return;
  }

  Future<void> _checkPermission() async {
    debugPrint("Permission check starting");

    PermissionStatus cameraPermission = await Permission.camera.status;
    PermissionStatus locationPermission = await Permission.location.status;

    if (!cameraPermission.isGranted || !locationPermission.isGranted) {
      await _getPermission();
    }

    debugPrint("Permission check completed");
    return;
  }

  Future<void> _getPermission() async {
    debugPrint("Start _getPermission()");

    // Check for location and camera permissions.
    var locationStatus = await Permission.location.status;
    var cameraStatus = await Permission.camera.status;

    // Only show the tutorial if at least one permission is not granted.
    // if (locationStatus.isDenied || cameraStatus.isDenied) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.7,
              child: PageView(
                controller: pageController,
                children: <Widget>[
                  if (locationStatus.isDenied) _tutorialPage('assets/tutorial1.png', 'Tutorial text 1', Permission.location, showButton: true),
                  if (cameraStatus.isDenied) _tutorialPage('assets/tutorial2.png', 'Tutorial text 2', Permission.camera, showButton: true),
                ],
              ),
            ),
          );
        },
      );
    // } else {
    //   _navigateToMainScreen();
    // }
  }

  Widget _tutorialPage(String imagePath, String text, Permission permission, {bool showButton = false}) {
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
            onPressed: () async {
              // replace `Permission.camera` with the specific permission you need
              final granted = await _requestPermission(permission);
              if (granted) {
                pageController.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.ease,
                );
              }
            },
            child: Text('Request Permission'),
          ),
      ],
    );
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isDenied) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Permission error'),
            content: Text('Permission is needed.'),
            actions: <Widget>[
              TextButton(
                child: Text('Retry'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _requestPermission(permission);
                },
              ),
            ],
          );
        },
      );
      return false;
    }

    // After getting a permission, check if we have all needed permissions. If so, navigate to the main screen.
    var locationStatus = await Permission.location.status;
    var cameraStatus = await Permission.camera.status;
    if (locationStatus.isGranted && cameraStatus.isGranted) {
      Navigator.of(context).pop(); // This will close the tutorial dialog.
      // _navigateToMainScreen();
      return true;
    }


    return true;
  }



  Future<void> _checkDatabaseTable() async {
    final database = openDatabase(
      path.join(await getDatabasesPath(), 'images_database.db'),
      version: 1,
    );

    final db = await database;

    try {
      // Perform a query to check if the table exists
      await db.rawQuery('SELECT 1 FROM images LIMIT 1');
    } catch (e) {
      // If the table doesn't exist, create it
      await db.execute(
        "CREATE TABLE images(id INTEGER PRIMARY KEY, imagePath TEXT, thumbnailPath TEXT, userId TEXT, imageCountry TEXT, imageLat TEXT, imageLng TEXT)",
      );
    }
  }

  void _navigateToMainScreen() {
    _startupController.add(true);
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