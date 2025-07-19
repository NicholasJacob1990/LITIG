import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:cpf_cnpj_validator/cpf_validator.dart';
import 'package:cpf_cnpj_validator/cnpj_validator.dart';
import '../utils/logger.dart';

/// Resultado da extração de texto OCR
class OCRResult {
  final String fullText;
  final List<String> lines;
  final Map<String, String> extractedData;
  final double confidence;
  final List<DocumentType> detectedTypes;

  const OCRResult({
    required this.fullText,
    required this.lines,
    required this.extractedData,
    required this.confidence,
    required this.detectedTypes,
  });
}

/// Tipos de documentos detectáveis
enum DocumentType {
  cpf,
  cnpj,
  rg,
  oab,
  contratoTrabalho,
  holerite,
  comprovantePagamento,
  comprovanteResidencia,
  procuracao,
  peticao,
  outros
}

/// Dados estruturados extraídos de documentos
class ExtractedDocumentData {
  final String? cpf;
  final String? cnpj;
  final String? rg;
  final String? oab;
  final String? nome;
  final String? endereco;
  final List<String> telefones;
  final List<String> emails;
  final Map<String, String> customFields;
  final DocumentType documentType;

  const ExtractedDocumentData({
    this.cpf,
    this.cnpj,
    this.rg,
    this.oab,
    this.nome,
    this.endereco,
    this.telefones = const [],
    this.emails = const [],
    this.customFields = const {},
    required this.documentType,
  });
}

/// Serviço completo de OCR e extração de dados
class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  late final TextRecognizer _textRecognizer;
  late final DocumentScanner _documentScanner;
  final ImagePicker _imagePicker = ImagePicker();

  /// Inicializa o serviço OCR
  Future<void> initialize() async {
    try {
      _textRecognizer = TextRecognizer();
      
      // Configurar scanner de documentos
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.all,
        mode: ScannerMode.full,
        isGalleryImport: true,
        pageLimit: 10,
        resultFormats: [ResultFormat.jpeg, ResultFormat.pdf],
      );
      _documentScanner = DocumentScanner(options: options);
      
      AppLogger.success('OCR Service inicializado com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao inicializar OCR Service', error: e);
      rethrow;
    }
  }

  /// Scanner completo de documento com interface nativa
  Future<List<File>?> scanDocumentWithNativeInterface() async {
    try {
      final result = await _documentScanner.scanDocument();
      if (result.images.isNotEmpty) {
        return result.images;
      }
      return null;
    } catch (e) {
      AppLogger.error('Erro no scanner de documentos', error: e);
      return null;
    }
  }

  /// Captura imagem via câmera para OCR
  Future<File?> captureImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      AppLogger.error('Erro ao capturar imagem', error: e);
      return null;
    }
  }

  /// Seleciona imagem da galeria
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      AppLogger.error('Erro ao selecionar imagem', error: e);
      return null;
    }
  }

  /// Extrai texto de uma imagem usando OCR
  Future<OCRResult> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final fullText = recognizedText.text;
      final lines = recognizedText.blocks
          .expand((block) => block.lines)
          .map((line) => line.text)
          .toList();
      
      // Extrair dados estruturados
      final extractedData = _extractStructuredData(fullText);
      final documentTypes = _detectDocumentTypes(fullText);
      final confidence = _calculateConfidence(recognizedText);
      
      AppLogger.info('OCR processado: ${lines.length} linhas extraídas');
      
      return OCRResult(
        fullText: fullText,
        lines: lines,
        extractedData: extractedData,
        confidence: confidence,
        detectedTypes: documentTypes,
      );
    } catch (e) {
      AppLogger.error('Erro na extração de texto OCR', error: e);
      rethrow;
    }
  }

  /// Processa documento completo com validação brasileira
  Future<ExtractedDocumentData> processDocumentWithValidation(File imageFile) async {
    try {
      final ocrResult = await extractTextFromImage(imageFile);
      
      // Detectar tipo principal do documento
      final primaryType = ocrResult.detectedTypes.isNotEmpty 
          ? ocrResult.detectedTypes.first 
          : DocumentType.outros;
      
      // Extrair e validar dados específicos do Brasil
      final cpf = _extractAndValidateCPF(ocrResult.fullText);
      final cnpj = _extractAndValidateCNPJ(ocrResult.fullText);
      final rg = _extractRG(ocrResult.fullText);
      final oab = _extractOAB(ocrResult.fullText);
      final nome = _extractName(ocrResult.fullText);
      final endereco = _extractAddress(ocrResult.fullText);
      final telefones = _extractPhones(ocrResult.fullText);
      final emails = _extractEmails(ocrResult.fullText);
      
      return ExtractedDocumentData(
        cpf: cpf,
        cnpj: cnpj,
        rg: rg,
        oab: oab,
        nome: nome,
        endereco: endereco,
        telefones: telefones,
        emails: emails,
        documentType: primaryType,
      );
    } catch (e) {
      AppLogger.error('Erro no processamento do documento', error: e);
      rethrow;
    }
  }

  /// Pré-processa imagem para melhorar OCR
  Future<File> preprocessImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Não foi possível decodificar a imagem');
      }
      
      // Aplicar melhorias na imagem
      image = img.adjustColor(image, brightness: 1.1, contrast: 1.2);
      image = img.grayscale(image);
      
      // Salvar imagem processada
      final tempDir = await getTemporaryDirectory();
      final processedFile = File('${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await processedFile.writeAsBytes(img.encodeJpg(image));
      
      AppLogger.info('Imagem pré-processada com sucesso');
      return processedFile;
    } catch (e) {
      AppLogger.error('Erro no pré-processamento da imagem', error: e);
      return imageFile; // Retorna original em caso de erro
    }
  }

  /// Extrai e valida CPF
  String? _extractAndValidateCPF(String text) {
    final cpfPattern = RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b');
    final matches = cpfPattern.allMatches(text);
    
    for (final match in matches) {
      final cpf = match.group(0)?.replaceAll(RegExp(r'[^\d]'), '');
      if (cpf != null && CPFValidator.isValid(cpf)) {
        return CPFValidator.format(cpf);
      }
    }
    return null;
  }

  /// Extrai e valida CNPJ
  String? _extractAndValidateCNPJ(String text) {
    final cnpjPattern = RegExp(r'\b\d{2}\.?\d{3}\.?\d{3}/?\d{4}-?\d{2}\b');
    final matches = cnpjPattern.allMatches(text);
    
    for (final match in matches) {
      final cnpj = match.group(0)?.replaceAll(RegExp(r'[^\d]'), '');
      if (cnpj != null && CNPJValidator.isValid(cnpj)) {
        return CNPJValidator.format(cnpj);
      }
    }
    return null;
  }

  /// Extrai número de RG
  String? _extractRG(String text) {
    final rgPatterns = [
      RegExp(r'rg[:\s]*(\d{1,2}\.?\d{3}\.?\d{3}-?\w?)', caseSensitive: false),
      RegExp(r'registro geral[:\s]*(\d{1,2}\.?\d{3}\.?\d{3}-?\w?)', caseSensitive: false),
      RegExp(r'\b\d{1,2}\.?\d{3}\.?\d{3}-?\w?\b'),
    ];
    
    for (final pattern in rgPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1) ?? match.group(0);
      }
    }
    return null;
  }

  /// Extrai número da OAB
  String? _extractOAB(String text) {
    final oabPatterns = [
      RegExp(r'oab[/\s]*([a-z]{2})[:\s]*(\d+)', caseSensitive: false),
      RegExp(r'ordem[^:]*advogados[^:]*(\w{2})[:\s]*(\d+)', caseSensitive: false),
      RegExp(r'\b(\d{4,6})/([a-z]{2})\b', caseSensitive: false),
    ];
    
    for (final pattern in oabPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 2) {
        final numero = match.group(2);
        final uf = match.group(1)?.toUpperCase();
        return '$numero/$uf';
      }
    }
    return null;
  }

  /// Extrai nome de pessoa
  String? _extractName(String text) {
    final namePatterns = [
      RegExp(r'nome[:\s]+([A-ZÁÉÍÓÚÂÊÎÔÛÀÈÌÒÙÃÕÇ\s]+)', caseSensitive: false),
      RegExp(r'nome completo[:\s]+([A-ZÁÉÍÓÚÂÊÎÔÛÀÈÌÒÙÃÕÇ\s]+)', caseSensitive: false),
      RegExp(r'^([A-ZÁÉÍÓÚÂÊÎÔÛÀÈÌÒÙÃÕÇ\s]{10,50})$', multiLine: true),
    ];
    
    for (final pattern in namePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.split(' ').length >= 2) {
          return name;
        }
      }
    }
    return null;
  }

  /// Extrai endereço
  String? _extractAddress(String text) {
    final addressPatterns = [
      RegExp(r'endereço[:\s]+([^,\n]{10,100})', caseSensitive: false),
      RegExp(r'rua[:\s]+([^,\n]{10,100})', caseSensitive: false),
      RegExp(r'avenida[:\s]+([^,\n]{10,100})', caseSensitive: false),
    ];
    
    for (final pattern in addressPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  /// Extrai telefones
  List<String> _extractPhones(String text) {
    final phonePattern = RegExp(r'\(?\d{2}\)?[\s-]?\d{4,5}[\s-]?\d{4}');
    return phonePattern.allMatches(text)
        .map((match) => match.group(0)!)
        .toSet()
        .toList();
  }

  /// Extrai emails
  List<String> _extractEmails(String text) {
    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    return emailPattern.allMatches(text)
        .map((match) => match.group(0)!)
        .toSet()
        .toList();
  }

  /// Extrai dados estruturados gerais
  Map<String, String> _extractStructuredData(String text) {
    final data = <String, String>{};
    
    // Padrões gerais
    final patterns = {
      'data_nascimento': RegExp(r'nascimento[:\s]*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
      'estado_civil': RegExp(r'estado civil[:\s]*(\w+)', caseSensitive: false),
      'profissao': RegExp(r'profissão[:\s]*([^\n]{5,30})', caseSensitive: false),
      'nacionalidade': RegExp(r'nacionalidade[:\s]*(\w+)', caseSensitive: false),
    };
    
    patterns.forEach((key, pattern) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        data[key] = match.group(1)!.trim();
      }
    });
    
    return data;
  }

  /// Detecta tipos de documentos
  List<DocumentType> _detectDocumentTypes(String text) {
    final types = <DocumentType>[];
    final lowerText = text.toLowerCase();
    
    // Mapeamento de palavras-chave para tipos
    final typeKeywords = {
      DocumentType.cpf: ['cpf', 'cadastro de pessoa física'],
      DocumentType.cnpj: ['cnpj', 'cadastro nacional'],
      DocumentType.rg: ['rg', 'registro geral', 'carteira de identidade'],
      DocumentType.oab: ['oab', 'ordem dos advogados', 'carteira advocacia'],
      DocumentType.contratoTrabalho: ['contrato de trabalho', 'clt', 'emprego'],
      DocumentType.holerite: ['holerite', 'contracheque', 'folha de pagamento'],
      DocumentType.comprovantePagamento: ['comprovante', 'pagamento', 'transferência'],
      DocumentType.comprovanteResidencia: ['comprovante residência', 'endereço', 'conta de luz'],
      DocumentType.procuracao: ['procuração', 'outorga', 'representação'],
      DocumentType.peticao: ['petição', 'excelentíssimo', 'meritíssimo'],
    };
    
    typeKeywords.forEach((type, keywords) {
      if (keywords.any((keyword) => lowerText.contains(keyword))) {
        types.add(type);
      }
    });
    
    return types.isEmpty ? [DocumentType.outros] : types;
  }

  /// Calcula confiança do OCR
  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int elementCount = 0;
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          // ML Kit não expõe confidence diretamente
          // Usamos heurísticas baseadas no texto
          final text = element.text;
          double confidence = 1.0;
          
          // Reduzir confiança para texto muito curto
          if (text.length < 3) confidence *= 0.5;
          
          // Reduzir confiança para caracteres especiais demais
          final specialChars = text.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '');
          if (specialChars.length > text.length * 0.3) confidence *= 0.7;
          
          totalConfidence += confidence;
          elementCount++;
        }
      }
    }
    
    return elementCount > 0 ? totalConfidence / elementCount : 0.0;
  }

  /// Libera recursos
  Future<void> dispose() async {
    try {
      await _textRecognizer.close();
      AppLogger.info('OCR Service finalizado');
    } catch (e) {
      AppLogger.error('Erro ao finalizar OCR Service', error: e);
    }
  }
} 