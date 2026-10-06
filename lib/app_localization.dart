import 'package:flutter/widgets.dart';

import 'l10n/app_localizations.dart';

export 'l10n/app_localizations.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

const studyLanguages = [
  'ko-KR',
  'vi-VN',
  'en-US',
  'ja-JP',
  'zh-CN',
  'fr-FR',
  'de-DE',
  'es-ES',
];

String studyLanguageName(BuildContext context, String code) {
  final l = context.l10n;
  return switch (code) {
    'ko-KR' => l.korean,
    'vi-VN' => l.vietnamese,
    'en-US' => l.english,
    'ja-JP' => l.japanese,
    'zh-CN' => l.chinese,
    'fr-FR' => l.french,
    'de-DE' => l.german,
    'es-ES' => l.spanish,
    _ => code,
  };
}
