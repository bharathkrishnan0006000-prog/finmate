import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR (Google ML Kit) for photographed/scanned paper
/// statements. Runs entirely on-device — no image ever leaves the phone.
/// Only invoked when the user explicitly taps "Scan with Camera" on the
/// Upload Statement screen; never runs automatically.
class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  void dispose() => _recognizer.close();
}
