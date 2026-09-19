import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// Localized Text Widget
/// Automatically rebuilds when language changes
class LocalizedText extends StatelessWidget {
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Map<String, String>? params;

  const LocalizedText(
    this.translationKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.params,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final text = languageProvider.translate(translationKey, params: params);
        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Localized Button Text Widget
class LocalizedButton extends StatelessWidget {
  final String translationKey;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final Map<String, String>? params;

  const LocalizedButton(
    this.translationKey, {
    super.key,
    required this.onPressed,
    this.style,
    this.params,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final text = languageProvider.translate(translationKey, params: params);
        return ElevatedButton(
          onPressed: onPressed,
          style: style,
          child: Text(text),
        );
      },
    );
  }
}

/// Localized Text Button Widget
class LocalizedTextButton extends StatelessWidget {
  final String translationKey;
  final VoidCallback onPressed;
  final TextStyle? style;
  final Map<String, String>? params;

  const LocalizedTextButton(
    this.translationKey, {
    super.key,
    required this.onPressed,
    this.style,
    this.params,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final text = languageProvider.translate(translationKey, params: params);
        return TextButton(
          onPressed: onPressed,
          child: Text(
            text,
            style: style,
          ),
        );
      },
    );
  }
}

/// Localized Outlined Button Widget
class LocalizedOutlinedButton extends StatelessWidget {
  final String translationKey;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final Map<String, String>? params;

  const LocalizedOutlinedButton(
    this.translationKey, {
    super.key,
    required this.onPressed,
    this.style,
    this.params,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final text = languageProvider.translate(translationKey, params: params);
        return OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: Text(text),
        );
      },
    );
  }
}

/// Localized App Bar Title
class LocalizedAppBarTitle extends StatelessWidget {
  final String translationKey;
  final TextStyle? style;
  final Map<String, String>? params;

  const LocalizedAppBarTitle(
    this.translationKey, {
    super.key,
    this.style,
    this.params,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final text = languageProvider.translate(translationKey, params: params);
        return Text(
          text,
          style: style ?? const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}

/// Localized Tooltip
class LocalizedTooltip extends StatelessWidget {
  final String translationKey;
  final Widget child;
  final Map<String, String>? params;

  const LocalizedTooltip(
    this.translationKey, {
    super.key,
    required this.child,
    this.params,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final text = languageProvider.translate(translationKey, params: params);
        return Tooltip(
          message: text,
          child: child,
        );
      },
    );
  }
}
