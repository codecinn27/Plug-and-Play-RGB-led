import 'package:flutter/material.dart';

BoxDecoration buildCustomGradient() {
  return const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFFADA996), // #ada996
        Color(0xFFF2F2F2), // #f2f2f2
        Color(0xFFDBDBDB), // #dbdbdb
        Color(0xFFEAEAEA), // #eaeaea
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  );
}

BoxDecoration buildWarmGradient() {
  return const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFFF9D423), // #F9D423 - warm yellow
        Color(0xFFFF4E50), // #FF4E50 - red
      ],
      begin: Alignment.centerLeft,  // "to right" direction
      end: Alignment.centerRight,
    ),
  );
}

BoxDecoration buildGreenGradient() {
  return const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFFB5AC49), // #B5AC49
        Color(0xFF3CA55C), // #3CA55C
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  );
}

BoxDecoration buildSoftGradient() {
  return const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFFDECBA4), // #DECBA4
        Color(0xFF3E5151), // #3E5151
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  );
}
