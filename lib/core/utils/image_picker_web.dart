import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

Future<Uint8List?> pickImageBytesImpl() {
  final completer = Completer<Uint8List?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  uploadInput.click();

  uploadInput.onChange.listen((_) {
    final file = uploadInput.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is! String) {
        completer.complete(null);
        return;
      }
      final commaIndex = result.indexOf(',');
      if (commaIndex < 0) {
        completer.complete(null);
        return;
      }
      final encoded = result.substring(commaIndex + 1);
      completer.complete(base64Decode(encoded));
    });
  });

  return completer.future;
}
