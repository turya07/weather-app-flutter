import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData appTheme() {
  return ThemeData(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      color: Colors.deepPurpleAccent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.deepPurpleAccent,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.deepPurple,
    ).copyWith(secondary: Colors.deepPurpleAccent),
  );
}
