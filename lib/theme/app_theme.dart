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
const heartActive = Color(0xFFE91E63);
const heartInactive = Color(0xFF9E9E9E);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: mediumPink,
    primary: darkPink,
    secondary: mediumPink,
    surface: colorBackground,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colorBackground,
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
