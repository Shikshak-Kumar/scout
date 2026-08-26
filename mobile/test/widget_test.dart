import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scout_mobile/core/theme/theme.dart';

void main() {
  test('themes use the unified Material 3 palette', () {
    expect(ScoutTheme.light.useMaterial3, isTrue);
    expect(ScoutTheme.dark.useMaterial3, isTrue);
    expect(ScoutTheme.dark.brightness, Brightness.light);
  });
}
