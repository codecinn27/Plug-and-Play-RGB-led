import 'package:flutter/material.dart';
import 'package:p9_rgbridge/share/theme.dart';
import 'package:p9_rgbridge/widget/bottom_nav.dart';


void main() {
  runApp(MaterialApp(
    theme: AppTheme.lightTheme,
    home: const NavBar(),
    debugShowCheckedModeBanner: false,
  ));
}
