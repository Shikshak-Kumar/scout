import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scout_mobile/core/theme/theme.dart';

void main() {
  test('theme uses Material 3', () {
    expect(ScoutTheme.light.useMaterial3, isTrue);
    expect(ScoutTheme.dark.brightness, Brightness.dark);
  });
}
