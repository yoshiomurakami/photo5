import 'l10n.dart';

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get next => 'next';

  @override
  String get skip => 'skip';

  @override
  String get agree => 'agree';

  @override
  String get intro1Title => 'First Screen';

  @override
  String get intro1Body => 'The explanation for the first page will be displayed here.';

  @override
  String get intro2Title => 'Second Screen';

  @override
  String get intro2Body => 'The second explanation will be slightly longer than the previous one.';

  @override
  String get intro3Title => 'Let\'s make the title of the third photo longer.';

  @override
  String get intro3Body => 'Now, when we display an even longer sentence than before, what will happen to the line breaks?';

  @override
  String get termsAndPrivacyPolicy => 'TermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicy';

  @override
  String get latestVersion => 'Latest version from server:';

  @override
  String get loadingText => 'Now Loading';

  @override
  String get errorNoInternetConnection => 'No internet connection or server unreachable. Please check your internet connection.';

  @override
  String get errorGetAppVersion => 'Could not fetch the app version. Please check if the application is properly installed.';

  @override
  String get errorFetchAppVersion => 'Failed to load version info from the server.';

  @override
  String get errorGetUserId => 'The UserID is corrupted. Please initialize the application.';

  @override
  String get errorFetchUserId => 'Could not fetch valid UserID. Please check your network connection and try again.';

  @override
  String get errorAccessAppdata => 'Could not access app data. Please restart the application.';

  @override
  String get errorCompleteTutorial => 'Could not complete the tutorial. Please check your network connection and try again.';

  @override
  String get errorInitializeApp => 'Could not initialize app status. Please restart the application.';

  @override
  String get permissionLocation => 'permission_location';

  @override
  String get permissionCamera => 'permission_camera';

  @override
  String get permissionAllowButton => 'allow';

  @override
  String get permissionErrorDialogTitle => 'Permission error';

  @override
  String get permissionErrorDialogText => 'Permission is needed.';

  @override
  String get permissionErrorDialogButton => 'Retry';

  @override
  String get sayHello => 'Hello! A test to see how far a long sentence can be displayed. 35 characters so far.';

  @override
  String get resSayHello => 'What’s up?';

  @override
  String get sayGoodbye => 'see you!';

  @override
  String get shotTogether => 'Shot together!📸';
}
