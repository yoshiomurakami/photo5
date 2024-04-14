import 'l10n.dart';

/// The translations for Japanese (`ja`).
class L10nJa extends L10n {
  L10nJa([String locale = 'ja']) : super(locale);

  @override
  String get loadingText => 'ローディング中';

  @override
  String get sayhello => 'こんにちは！長い文章はどこまで表示されるのかテスト。ここまでで３５文字。';

  @override
  String get res_sayHello => 'よろしく！';

  @override
  String get saygoodbye => 'またね！';

  @override
  String get shotTogether => '一緒に撮ろう！';
}
