import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primColor = Colors.cyan;
  static const Color _secColor = Color.fromRGBO(220, 118, 81, 1);
  static const Color _terColor = Colors.blueGrey;

  static ThemeData light = ThemeData.light().copyWith(
    typography: Typography.material2018(),
    textTheme: const TextTheme(
      titleSmall: TextStyle(fontSize: 16.0),
      titleMedium: TextStyle(fontSize: 18.0),
      titleLarge: TextStyle(fontSize: 24.0),
      bodySmall: TextStyle(fontSize: 14.0),
      bodyMedium: TextStyle(fontSize: 18.0),
      bodyLarge: TextStyle(fontSize: 20.0),
    ).apply(
      bodyColor: Colors.black,
      displayColor: _terColor,
    ),
    appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[300],
        actionsIconTheme: const IconThemeData(color: _primColor)),
    cardTheme: CardThemeData(
      color: Colors.grey[300],
    ),
    colorScheme: const ColorScheme.light(
      primary: _primColor,
      secondary: _secColor,
      tertiary: _terColor,
    ),
    dividerTheme: const DividerThemeData(color: _terColor),
  );

  static ThemeData dark = ThemeData.dark(useMaterial3: true).copyWith(
    typography: Typography.material2018(),
    textTheme: const TextTheme(
      titleSmall: TextStyle(fontSize: 16.0),
      titleMedium: TextStyle(fontSize: 18.0),
      titleLarge: TextStyle(fontSize: 24.0),
      bodySmall: TextStyle(fontSize: 14.0),
      bodyMedium: TextStyle(fontSize: 18.0),
      bodyLarge: TextStyle(fontSize: 20.0),
    ).apply(
      bodyColor: Colors.white,
      displayColor: _terColor,
    ),
    appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
        actionsIconTheme: const IconThemeData(color: _primColor)),
    cardTheme: CardThemeData(color: Colors.grey[850]),
    colorScheme: const ColorScheme.dark(
      primary: _primColor,
      secondary: _secColor,
      tertiary: _terColor,
    ),
    dividerTheme: const DividerThemeData(color: _terColor),
  );
}
