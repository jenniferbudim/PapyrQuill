import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

// Colors ported from ui/theme/Color.kt.
const colorBackground = Color(0xFFFFFAEE);
const lighterPink = Color(0xFFEEB0D1);
const mediumPink = Color(0xFFE185BA);
const lightPink = Color(0xFFFBF0F6);
const searchTextColor = Color(0xFF3D1A22);
const cardBeige = Color(0xFFDDD0B4);
const cardTitleColor = Color(0xFF2C1810);
const cardBodyColor = Color(0xFF6B5040);
const darkPink = Color(0xFF7E0049);
// Story header card on the Document screen.
const headerCardPink = Color(0xFFF4C9E2);
const headerTitleColor = Color(0xFF3F143B);
const headerBodyColor = Color(0xFF7A4872);
// Timeline screen.
const timelineTitleColor = Color(0xFF7F4279);
const timelineFrameNameColor = Color(0xFF8D5286);
const timelineChipTextColor = Color(0xFF4A1F45);
const timelineScrollThumb = Color(0xFFC3A1B5);
// Windows (desktop) layouts.
const sidebarSelected = Color(0xFFCBC0A7);
const sidebarDivider = Color(0xFF765766);
const desktopPreviewColor = Color(0xFFA58E9E);
const desktopSearchText = Color(0xFF860B52);
const desktopSearchIcon = Color(0xFF70425D);
const desktopScrollThumb = Color(0xFFCCC8BE);
const bookCream = Color(0xFFFFF4D7);
const bookShade = Color(0xFFF8E5EF);
const heartActive = Color(0xFFE91E63);
const heartInactive = Color(0xFF9E9E9E);

bool get _isDesktop =>
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS;

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: mediumPink,
    primary: darkPink,
    secondary: mediumPink,
    surface: colorBackground,
  );
  return ThemeData(
    useMaterial3: true,
    // The Windows app uses the Handlee handwriting font everywhere; Android
    // keeps its normal font.
    fontFamily: _isDesktop ? 'Handlee' : null,
    colorScheme: scheme,
    scaffoldBackgroundColor: colorBackground,
    // Screens slide in from the right and the old one shifts left slightly,
    // on every platform (instead of Android's fade/zoom). Swiping from the
    // left edge goes back.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: colorBackground,
      foregroundColor: cardTitleColor,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: mediumPink,
      foregroundColor: Colors.white,
    ),
  );
}

/// Pink outlined text field used in the dialogs (Kotlin: dialogFieldColors()).
InputDecoration fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: mediumPink),
    floatingLabelStyle: const TextStyle(color: darkPink),
    border: const OutlineInputBorder(),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: mediumPink),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: darkPink, width: 2),
    ),
  );
}
