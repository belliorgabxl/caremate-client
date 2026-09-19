// Crops the square icon mark out of assets/images/caremate-logo.png
// (which also carries the "CareMate" wordmark below the mark), writing the
// result to assets/images/app_icon.png for flutter_launcher_icons.
//
// The mark and the wordmark are separated by a fully-transparent gap row;
// this scans for that gap to find the mark's bottom edge, then crops a
// square centered on the mark's horizontal content, so it stays correct if
// the source logo is ever re-exported at a different size/padding.
//
// The mark itself is already a rounded square (squircle), not a flat-edge
// square — cropping straight to its bounding box leaves transparent corner
// slivers inside the output. iOS/Android then mask *that* with their own
// rounded-corner shape, so the two roundings don't line up and a sliver of
// white (remove_alpha_ios fills transparency with white) shows at the
// corners — the "white edge inside the app icon frame" artifact. Fixed by
// inset-cropping past the squircle's own corner radius (detected by
// scanning inward from a corner until content starts) and scaling back up
// to full size, so the output is a flat-edge square that bleeds to every
// edge — the standard shape platform icon pipelines expect, since they do
// their own corner rounding on top.
//
// Run with: dart run tool/crop_icon.dart

import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const sourcePath = 'assets/images/caremate-logo.png';
  const outputPath = 'assets/images/app_icon.png';

  final source = img.decodePng(File(sourcePath).readAsBytesSync());
  if (source == null) {
    stderr.writeln('Could not decode $sourcePath');
    exit(1);
  }

  bool rowHasContent(int y) {
    for (int x = 0; x < source.width; x++) {
      if (source.getPixel(x, y).a > 10) return true;
    }
    return false;
  }

  int? markBottom;
  bool sawContent = false;
  for (int y = 0; y < source.height; y++) {
    final hasContent = rowHasContent(y);
    if (hasContent) {
      sawContent = true;
    } else if (sawContent) {
      markBottom = y;
      break;
    }
  }
  markBottom ??= source.height;

  int minX = source.width, maxX = 0;
  for (int y = 0; y < markBottom; y++) {
    for (int x = 0; x < source.width; x++) {
      if (source.getPixel(x, y).a > 10) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
      }
    }
  }

  final side = markBottom;
  final centerX = (minX + maxX) ~/ 2;
  var x = centerX - side ~/ 2;
  if (x < 0) x = 0;
  if (x + side > source.width) x = source.width - side;

  final cropped = img.copyCrop(source, x: x, y: 0, width: side, height: side);

  // Detect the squircle's corner radius by scanning inward from the
  // top-left corner of the crop until a pixel actually has content.
  int inset = 0;
  while (inset < side ~/ 2 &&
      cropped.getPixel(inset, inset).a <= 10) {
    inset++;
  }

  final bled = inset == 0
      ? cropped
      : img.copyResize(
          img.copyCrop(
            cropped,
            x: inset,
            y: inset,
            width: side - inset * 2,
            height: side - inset * 2,
          ),
          width: side,
          height: side,
        );

  File(outputPath).writeAsBytesSync(img.encodePng(bled));
  stdout.writeln(
    'Wrote $outputPath (${bled.width}x${bled.height}, corner inset $inset px)',
  );
}
