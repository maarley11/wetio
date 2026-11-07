import 'dart:typed_data';
import 'image_compressor_stub.dart'
    if (dart.library.html) 'image_compressor_web.dart';

Future<Uint8List> compressImageBytesPlatform(
  Uint8List bytes, {
  int maxDimension = 900,
  num quality = 0.78,
}) =>
    compressImageBytesImpl(bytes, maxDimension: maxDimension, quality: quality);
