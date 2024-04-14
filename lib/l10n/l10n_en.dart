import 'l10n.dart';

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get loadingText => 'Now Loading';

  @override
  String get sayhello => 'Hello! A test to see how far a long sentence can be displayed. 35 characters so far.';

  @override
  String get res_sayHello => 'What’s up?';

  @override
  String get saygoodbye => 'see you!';

  @override
  String get shotTogether => 'Shot together!';
}
