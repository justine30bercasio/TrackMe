import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptOcr {
  static bool get isAvailable {
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  static Future<String> recognize(String imagePath) async {
    TextRecognizer? recognizer;
    try {
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final input = InputImage.fromFile(File(imagePath));
      final result = await recognizer.processImage(input);
      return result.text;
    } catch (_) {
      return '';
    } finally {
      await recognizer?.close();
    }
  }
}