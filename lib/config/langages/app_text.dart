import 'package:flutter/material.dart' as material;

import 'messages.dart';

/// Localized text widget. UI literals should be stable `MCODE-XXXXX` keys;
/// Japanese source text is accepted as a compatibility path for dynamic values.
class AppText extends material.StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.parameters = const <String, Object?>{},
    this.localizedParameters = const <String>{},
  });

  final String? data;
  final material.TextStyle? style;
  final material.StrutStyle? strutStyle;
  final material.TextAlign? textAlign;
  final material.TextDirection? textDirection;
  final material.Locale? locale;
  final bool? softWrap;
  final material.TextOverflow? overflow;
  final material.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final material.TextWidthBasis? textWidthBasis;
  final material.TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;
  final Map<String, Object?> parameters;
  final Set<String> localizedParameters;

  @override
  material.Widget build(material.BuildContext context) {
    return material.Text(
      AppStrings.translate(
        context,
        data,
        parameters: parameters,
        localizedParameters: localizedParameters,
      ),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

abstract final class AppStrings {
  static String translate(
    material.BuildContext context,
    String? source, {
    Map<String, Object?> parameters = const <String, Object?>{},
    Set<String> localizedParameters = const <String>{},
  }) {
    if (source == null) return '';
    final english =
        material.Localizations.localeOf(context).languageCode == 'en';
    final byCode = appMessageCatalog[source];
    if (byCode != null) {
      return _format(
        context,
        english ? byCode.en : byCode.ja,
        parameters,
        localizedParameters,
      );
    }

    final code = appMessageCodeByJapanese[source];
    if (code != null) {
      final message = appMessageCatalog[code]!;
      return _format(
        context,
        english ? message.en : message.ja,
        parameters,
        localizedParameters,
      );
    }
    if (!english) return source;

    final dynamicTranslation = _translateDynamic(source);
    if (dynamicTranslation != null) return dynamicTranslation;

    // Dynamic messages may combine a catalog phrase with a server/user value.
    // Keep those values intact while translating only catalogued phrases.
    final separator = source.indexOf(': ');
    if (separator > 0) {
      final title = translate(context, source.substring(0, separator));
      final message = translate(context, source.substring(separator + 2));
      if (title != source.substring(0, separator) ||
          message != source.substring(separator + 2)) {
        return '$title: $message';
      }
    }

    var translated = source;
    final messages = appMessageCatalog.values.toList()
      ..sort((a, b) => b.ja.length.compareTo(a.ja.length));
    for (final message in messages) {
      if (message.ja.length >= 4 && !message.ja.contains('{{')) {
        translated = translated.replaceAll(message.ja, message.en);
      }
    }
    return translated;
  }

  static String _format(
    material.BuildContext context,
    String source,
    Map<String, Object?> parameters,
    Set<String> localizedParameters,
  ) {
    var result = source;
    for (final entry in parameters.entries) {
      final value = entry.value;
      final renderedValue = value is String ? value : '$value';
      final localizedValue = localizedParameters.contains(entry.key)
          ? translate(context, renderedValue)
          : renderedValue;
      result = result.replaceAll('{{${entry.key}}}', localizedValue);
    }
    return result;
  }

  static String? _translateDynamic(String source) {
    final templates = <(String, RegExp, List<String>)>[
      ('MCODE-00425', RegExp(r'^(\d+) 台$'), ['count']),
      ('MCODE-00426', RegExp(r'^(\d+) 件$'), ['count']),
      ('MCODE-00444', RegExp(r'^すべて表示（(\d+) 件）$'), ['count']),
      ('MCODE-00427', RegExp(r'^ほか (\d+) 台（デバイスタブで確認）$'), ['count']),
      ('MCODE-00428', RegExp(r'^プロジェクト「(.+)」$'), ['name']),
      ('MCODE-00429', RegExp(r'^グループ「(.+)」$'), ['name']),
      ('MCODE-00430', RegExp(r'^プロジェクト「(.+)」のロール$'), ['name']),
      ('MCODE-00431', RegExp(r'^グループ「(.+)」のロール$'), ['name']),
      ('MCODE-00432', RegExp(r'^グループ「(.+)」を作成しました。$'), ['name']),
      ('MCODE-00433', RegExp(r'^「(.+)」を削除します。元に戻せません。$'), ['name']),
      (
        'MCODE-00434',
        RegExp(r'^(.+) をGorape側でrevokedにします。元に戻せません。$'),
        ['name'],
      ),
      ('MCODE-00435', RegExp(r'^保存に失敗しました: (.*)$'), ['message']),
      ('MCODE-00436', RegExp(r'^応答: (.*)$'), ['message']),
      (
        'MCODE-00437',
        RegExp(r'^この端末: (.+)。Keycloakログインはflutter_appauthで対応します。$'),
        ['name'],
      ),
      ('MCODE-00438', RegExp(r'^(.+)のロール$'), ['scope']),
      ('MCODE-00439', RegExp(r'^(.+)のロールがありません$'), ['scope']),
      ('MCODE-00440', RegExp(r'^(.+) をグループから外しました。$'), ['name']),
    ];
    for (final (code, pattern, names) in templates) {
      final match = pattern.firstMatch(source);
      if (match == null) continue;
      final message = appMessageCatalog[code];
      if (message == null) return null;
      var translated = message.en;
      for (var i = 0; i < names.length; i++) {
        translated = translated.replaceAll(
          '{{${names[i]}}}',
          match.group(i + 1)!,
        );
      }
      return translated;
    }
    return null;
  }
}

String tr(material.BuildContext context, String source) =>
    AppStrings.translate(context, source);
