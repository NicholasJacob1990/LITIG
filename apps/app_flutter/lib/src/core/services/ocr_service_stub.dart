// Stubs para MLKit quando não disponível
class InputImage {
  final dynamic file;
  InputImage.fromFile(this.file);
}

class RecognizedText {
  final String text;
  final List<TextBlock> blocks;
  RecognizedText({required this.text, required this.blocks});
}

class TextBlock {
  final List<TextLine> lines;
  final List<TextElement> elements = [];
  TextBlock({required this.lines});
}

class TextLine {
  final String text;
  final List<TextElement> elements;
  TextLine({required this.text, required this.elements});
}

class TextElement {
  final String text;
  TextElement({required this.text});
}

class TextRecognizer {
  Future<RecognizedText> processImage(InputImage inputImage) async {
    // Stub implementation
    return RecognizedText(
      text: 'OCR temporariamente desabilitado',
      blocks: [],
    );
  }
  
  Future<void> close() async {}
}

class DocumentScannerResult {
  final List<String> images;
  DocumentScannerResult({required this.images});
}

class DocumentScanner {
  Future<DocumentScannerResult> scanDocument() async {
    return DocumentScannerResult(images: []);
  }
}