import 'package:flutter/material.dart';

class GlobalColor {
  GlobalColor._();
 
  static const Color _primary = Color(0xff12CDD9);
  static const Color _second = Colors.orange;
  static const Color container = Colors.white;
  static const Color backgroundColor = Color(0xff1F1D2B);

 

  static MaterialColor primary = MaterialColor(
    _primary.value,
    <int, Color>{
      50: Color(_primary.value - (0xcc000000)),
      100: Color(_primary.value - (0xaa000000)),
      200: Color(_primary.value - (0x99000000)),
      300: Color(_primary.value - (0x55000000)),
      400: Color(_primary.value - (0x11000000)),
      500: _primary,
      600: Color(_primary.value + (0x11000000)),
      700: Color(_primary.value + (0x55000000)),
      800: Color(_primary.value + (0x99000000)),
      900: Color(_primary.value + (0xff000000)),
    },
  );

}