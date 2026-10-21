import 'package:flutter/material.dart';

class AppRadius {
  static const double xs = 6.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double button = 14.0;
  static const double card = 18.0;
  static const double modal = 22.0;
  static const double pill = 999.0;

  // BorderRadius helpers
  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius buttonRadius = BorderRadius.circular(button);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
  static final BorderRadius modalRadius = BorderRadius.circular(modal);
}
