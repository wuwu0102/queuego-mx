import 'dart:typed_data';

import 'image_picker_io.dart' if (dart.library.html) 'image_picker_web.dart';

Future<Uint8List?> pickImageBytes() => pickImageBytesImpl();
