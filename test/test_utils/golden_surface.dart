import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixes the test surface to [size] logical pixels so goldens render at a
/// deterministic size regardless of the default test window. Call
/// [addTearDown] cleanup is registered automatically.
void setGoldenSurfaceSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}
