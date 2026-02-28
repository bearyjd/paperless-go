import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paperless_go/features/scanner/processing/filters/deskew.dart';

void main() {
  test('deskew corrects 7-degree synthetic page', () {
    final page = _createTextPage(600, 800);
    final tilted = img.copyRotate(page, angle: 7);
    final result = applyDeskew(tilted);
    expect(identical(result, tilted), isFalse,
        reason: 'Should correct 7-degree tilt');
  });

  test('deskew corrects 3-degree synthetic page', () {
    final page = _createTextPage(600, 800);
    final tilted = img.copyRotate(page, angle: 3);
    final result = applyDeskew(tilted);
    expect(identical(result, tilted), isFalse,
        reason: 'Should correct 3-degree tilt');
  });

  test('deskew on real skewed photo', () {
    final file = File('/var/home/user/Downloads/PXL_20260228_161727776.jpg');
    if (!file.existsSync()) return;
    var image = img.decodeImage(file.readAsBytesSync())!;
    image = img.bakeOrientation(image);

    // Simulate scanner crop: just the page area
    final pageX = (image.width * 0.05).round();
    final pageY = (image.height * 0.03).round();
    final pageW = (image.width * 0.85).round();
    final pageH = (image.height * 0.90).round();
    var page = img.copyCrop(image, x: pageX, y: pageY, width: pageW, height: pageH);
    page = img.copyResize(page, width: 800);

    final result = applyDeskew(page);
    final rotated = !identical(result, page);
    print('Rotated: $rotated, ${page.width}x${page.height} -> ${result.width}x${result.height}');
    expect(rotated, isTrue, reason: 'Should detect skew in document photo');
  });

  test('blank page returns unchanged', () {
    final blank = img.Image(width: 200, height: 200);
    img.fill(blank, color: img.ColorRgb8(255, 255, 255));
    expect(identical(applyDeskew(blank), blank), isTrue);
  });
}

img.Image _createTextPage(int width, int height) {
  final page = img.Image(width: width, height: height);
  img.fill(page, color: img.ColorRgb8(245, 245, 245));
  for (var lineY = 60; lineY < height - 50; lineY += 25) {
    for (var x = 50; x < width - 80; x++) {
      for (var dy = 0; dy < 2; dy++) {
        if (lineY + dy < height) {
          page.setPixel(x, lineY + dy, img.ColorRgb8(30, 30, 30));
        }
      }
    }
  }
  return page;
}
