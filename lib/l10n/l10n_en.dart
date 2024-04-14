import 'l10n.dart';

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get loadingText => 'Now Loading';

  @override
  String get sayhello => 'Hello!';

  @override
  String get res_sayhello => 'nice to meet you!';

  @override
  String get saygoodbye => 'see you!';
}
