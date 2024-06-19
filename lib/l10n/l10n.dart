import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_ja.dart';

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n? of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n);
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja')
  ];

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'skip'**
  String get skip;

  /// No description provided for @agree.
  ///
  /// In en, this message translates to:
  /// **'agree'**
  String get agree;

  /// No description provided for @intro1Title.
  ///
  /// In en, this message translates to:
  /// **'First Screen'**
  String get intro1Title;

  /// No description provided for @intro1Body.
  ///
  /// In en, this message translates to:
  /// **'The explanation for the first page will be displayed here.'**
  String get intro1Body;

  /// No description provided for @intro2Title.
  ///
  /// In en, this message translates to:
  /// **'Second Screen'**
  String get intro2Title;

  /// No description provided for @intro2Body.
  ///
  /// In en, this message translates to:
  /// **'The second explanation will be slightly longer than the previous one.'**
  String get intro2Body;

  /// No description provided for @intro3Title.
  ///
  /// In en, this message translates to:
  /// **'Let\'s make the title of the third photo longer.'**
  String get intro3Title;

  /// No description provided for @intro3Body.
  ///
  /// In en, this message translates to:
  /// **'Now, when we display an even longer sentence than before, what will happen to the line breaks?'**
  String get intro3Body;

  /// No description provided for @termsAndPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'TermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicyTermsAndPrivacyPolicy'**
  String get termsAndPrivacyPolicy;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest version from server:'**
  String get latestVersion;

  /// No description provided for @loadingText.
  ///
  /// In en, this message translates to:
  /// **'Now Loading'**
  String get loadingText;

  /// No description provided for @errorNoInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection or server unreachable. Please check your internet connection.'**
  String get errorNoInternetConnection;

  /// No description provided for @errorGetAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch the app version. Please check if the application is properly installed.'**
  String get errorGetAppVersion;

  /// No description provided for @errorFetchAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Failed to load version info from the server.'**
  String get errorFetchAppVersion;

  /// No description provided for @errorGetUserId.
  ///
  /// In en, this message translates to:
  /// **'The UserID is corrupted. Please initialize the application.'**
  String get errorGetUserId;

  /// No description provided for @errorFetchUserId.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch valid UserID. Please check your network connection and try again.'**
  String get errorFetchUserId;

  /// No description provided for @errorAccessAppdata.
  ///
  /// In en, this message translates to:
  /// **'Could not access app data. Please restart the application.'**
  String get errorAccessAppdata;

  /// No description provided for @errorCompleteTutorial.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the tutorial. Please check your network connection and try again.'**
  String get errorCompleteTutorial;

  /// No description provided for @errorInitializeApp.
  ///
  /// In en, this message translates to:
  /// **'Could not initialize app status. Please restart the application.'**
  String get errorInitializeApp;

  /// No description provided for @permissionLocation.
  ///
  /// In en, this message translates to:
  /// **'permission_location'**
  String get permissionLocation;

  /// No description provided for @permissionCamera.
  ///
  /// In en, this message translates to:
  /// **'permission_camera'**
  String get permissionCamera;

  /// No description provided for @permissionAllowButton.
  ///
  /// In en, this message translates to:
  /// **'allow'**
  String get permissionAllowButton;

  /// No description provided for @permissionErrorDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission error'**
  String get permissionErrorDialogTitle;

  /// No description provided for @permissionErrorDialogText.
  ///
  /// In en, this message translates to:
  /// **'Permission is needed.'**
  String get permissionErrorDialogText;

  /// No description provided for @permissionErrorDialogButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get permissionErrorDialogButton;

  /// No description provided for @sayHello.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get sayHello;

  /// No description provided for @resSayHello.
  ///
  /// In en, this message translates to:
  /// **'What’s up?'**
  String get resSayHello;

  /// No description provided for @sayGoodbye.
  ///
  /// In en, this message translates to:
  /// **'see you!'**
  String get sayGoodbye;

  /// No description provided for @shotTogether.
  ///
  /// In en, this message translates to:
  /// **'Shot together!📸'**
  String get shotTogether;

  /// No description provided for @newPhoto.
  ///
  /// In en, this message translates to:
  /// **'check new photo!'**
  String get newPhoto;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return L10nEn();
    case 'ja': return L10nJa();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
