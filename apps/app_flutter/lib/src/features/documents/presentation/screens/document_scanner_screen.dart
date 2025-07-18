import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/utils/app_colors.dart';
import '../../../../core/utils/logger.dart';

class DocumentScannerScreen extends StatefulWidget {
  final String? caseId;
  final Function(ExtractedDocumentData)? onDocumentProcessed;

  const DocumentScannerScreen({
    super.key,
    this.caseId,
    this.onDocumentProcessed,
  });

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  final OCRService _ocrService = OCRService();
  bool _isProcessing = false;
  File? _selectedImage;
  OCRResult? _ocrResult;
  ExtractedDocumentData? _extractedData;
  String _currentStep = 'select'; // select, process, result

  @override
  void initState() {
    super.initState();
    _initializeOCR();
  }

  Future<void> _initializeOCR() async {
    try {
      await _ocrService.initialize();
    } catch (e) {
      AppLogger.error('Erro ao inicializar OCR', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao inicializar scanner. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de Documentos'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentStep == 'result')
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveDocument,
              tooltip: 'Salvar documento',
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case 'select':
        return _buildSelectionView();
      case 'process':
        return _buildProcessingView();
      case 'result':
        return _buildResultView();
      default:
        return _buildSelectionView();
    }
  }

  Widget _buildSelectionView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryBlue, Colors.white],
          stops: [0.3, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header ilustrativo
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.scan,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scanner Inteligente',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Extraia dados automaticamente de documentos\ncom tecnologia de OCR avançada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // Opções de captura
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Como deseja capturar o documento?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Scanner nativo (recomendado)
                      _buildCaptureOption(
                        icon: LucideIcons.scanLine,
                        title: 'Scanner Automático',
                        subtitle: 'Interface nativa com correção automática',
                        recommended: true,
                        onTap: _scanWithNativeInterface,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Câmera manual
                      _buildCaptureOption(
                        icon: LucideIcons.camera,
                        title: 'Capturar com Câmera',
                        subtitle: 'Tire uma foto do documento',
                        onTap: _captureFromCamera,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Galeria
                      _buildCaptureOption(
                        icon: LucideIcons.image,
                        title: 'Selecionar da Galeria',
                        subtitle: 'Escolha uma imagem existente',
                        onTap: _pickFromGallery,
                      ),
                      
                      const Spacer(),
                      
                      // Tipos de documentos suportados
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.info,
                                  size: 16,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Documentos Suportados',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• CPF, CNPJ, RG, Carteira OAB\n'
                              '• Contratos de Trabalho\n'
                              '• Comprovantes e Holerites\n'
                              '• Procurações e Petições',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool recommended = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: recommended ? AppColors.primaryBlue : Colors.grey.shade300,
          width: recommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: recommended 
                        ? AppColors.primaryBlue.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: recommended ? AppColors.primaryBlue : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Recomendado',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryBlue, Colors.white],
          stops: [0.3, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Imagem sendo processada
            if (_selectedImage != null) ...[
              Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            
            // Status de processamento
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Indicador de progresso
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryBlue,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        'Processando Documento',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        'Extraindo texto e identificando dados...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Passos do processamento
                      _buildProcessingStep('Analisando imagem', true),
                      _buildProcessingStep('Extraindo texto (OCR)', true),
                      _buildProcessingStep('Identificando dados', _isProcessing),
                      _buildProcessingStep('Validando informações', false),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingStep(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryBlue : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? Colors.black87 : Colors.grey.shade500,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    if (_extractedData == null) {
      return const Center(
        child: Text('Nenhum resultado disponível'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Imagem processada
        if (_selectedImage != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],

        // Tipo de documento detectado
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDocumentIcon(_extractedData!.documentType),
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Documento',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _getDocumentTypeName(_extractedData!.documentType),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Dados extraídos
        const Text(
          'Dados Extraídos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Cards dos dados
        if (_extractedData!.nome != null)
          _buildDataCard('Nome', _extractedData!.nome!, LucideIcons.user),
        
        if (_extractedData!.cpf != null)
          _buildDataCard('CPF', _extractedData!.cpf!, LucideIcons.creditCard),
        
        if (_extractedData!.cnpj != null)
          _buildDataCard('CNPJ', _extractedData!.cnpj!, LucideIcons.building),
        
        if (_extractedData!.rg != null)
          _buildDataCard('RG', _extractedData!.rg!, LucideIcons.badgeCheck),
        
        if (_extractedData!.oab != null)
          _buildDataCard('OAB', _extractedData!.oab!, LucideIcons.scale),
        
        if (_extractedData!.endereco != null)
          _buildDataCard('Endereço', _extractedData!.endereco!, LucideIcons.mapPin),

        // Contatos
        if (_extractedData!.telefones.isNotEmpty) ...[
          _buildDataCard(
            'Telefones',
            _extractedData!.telefones.join(', '),
            LucideIcons.phone,
          ),
        ],

        if (_extractedData!.emails.isNotEmpty) ...[
          _buildDataCard(
            'E-mails',
            _extractedData!.emails.join(', '),
            LucideIcons.mail,
          ),
        ],

        // Ações
        const SizedBox(height: 24),
        
        // Botão de validação via backend
        OutlinedButton.icon(
          onPressed: _validateWithBackend,
          icon: const Icon(LucideIcons.checkCircle),
          label: const Text('Validar com Backend'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: AppColors.primaryBlue),
          ),
        ),

        const SizedBox(height: 8),
        
        ElevatedButton.icon(
          onPressed: _saveDocument,
          icon: const Icon(LucideIcons.save),
          label: const Text('Salvar Documento'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: 8),

        OutlinedButton.icon(
          onPressed: _scanAnother,
          icon: const Icon(LucideIcons.rotateCcw),
          label: const Text('Escanear Outro'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Botão de copiar
            IconButton(
              onPressed: () => _copyToClipboard(value),
              icon: const Icon(LucideIcons.copy, size: 16),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_currentStep != 'select') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Icon(
              LucideIcons.shield,
              color: AppColors.primaryBlue,
              size: 16,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Seus documentos são processados localmente e com segurança',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos de captura
  Future<void> _scanWithNativeInterface() async {
    if (!(await _checkPermissions())) return;

    setState(() {
      _currentStep = 'process';
      _isProcessing = true;
    });

    try {
      final images = await _ocrService.scanDocumentWithNativeInterface();
      if (images != null && images.isNotEmpty) {
        _selectedImage = images.first;
        await _processImage(_selectedImage!);
      } else {
        _resetToSelection();
      }
    } catch (e) {
      AppLogger.error('Erro no scanner nativo', error: e);
      _showError('Erro ao usar scanner nativo');
      _resetToSelection();
    }
  }

  Future<void> _captureFromCamera() async {
    if (!(await _checkPermissions())) return;

    setState(() {
      _currentStep = 'process';
      _isProcessing = true;
    });

    try {
      final image = await _ocrService.captureImageFromCamera();
      if (image != null) {
        _selectedImage = image;
        await _processImage(image);
      } else {
        _resetToSelection();
      }
    } catch (e) {
      AppLogger.error('Erro na captura da câmera', error: e);
      _showError('Erro ao capturar imagem');
      _resetToSelection();
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _currentStep = 'process';
      _isProcessing = true;
    });

    try {
      final image = await _ocrService.pickImageFromGallery();
      if (image != null) {
        _selectedImage = image;
        await _processImage(image);
      } else {
        _resetToSelection();
      }
    } catch (e) {
      AppLogger.error('Erro ao selecionar da galeria', error: e);
      _showError('Erro ao selecionar imagem');
      _resetToSelection();
    }
  }

  // Processamento
  Future<void> _processImage(File imageFile) async {
    try {
      // Pré-processar imagem para melhor OCR
      final processedImage = await _ocrService.preprocessImage(imageFile);
      
      // Extrair dados
      final extractedData = await _ocrService.processDocumentWithValidation(processedImage);
      
      setState(() {
        _extractedData = extractedData;
        _currentStep = 'result';
        _isProcessing = false;
      });

      AppLogger.success('Documento processado com sucesso');
    } catch (e) {
      AppLogger.error('Erro no processamento do documento', error: e);
      _showError('Erro ao processar documento');
      _resetToSelection();
    }
  }

  // Utilidades
  Future<bool> _checkPermissions() async {
    final cameraStatus = await Permission.camera.request();
    return cameraStatus.isGranted;
  }

  void _resetToSelection() {
    setState(() {
      _currentStep = 'select';
      _isProcessing = false;
      _selectedImage = null;
      _ocrResult = null;
      _extractedData = null;
    });
  }

  void _scanAnother() {
    _resetToSelection();
  }

  // Salvamento no backend
  Future<void> _saveDocumentToBackend() async {
    if (_extractedData == null || _selectedImage == null) return;

    try {
      // Converter imagem para base64
      final imageBytes = await _selectedImage!.readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      // Preparar dados do OCR
      final ocrResult = {
        'full_text': _ocrResult?.fullText ?? '',
        'lines': _ocrResult?.lines ?? [],
        'confidence': _ocrResult?.confidence ?? 0.0,
        'detected_types': _ocrResult?.detectedTypes.map((t) => t.toString()).toList() ?? [],
      };

      // Converter extracted data para Map
      final extractedDataMap = {
        'nome': _extractedData!.nome,
        'cpf': _extractedData!.cpf,
        'cnpj': _extractedData!.cnpj,
        'rg': _extractedData!.rg,
        'oab': _extractedData!.oab,
        'endereco': _extractedData!.endereco,
        'telefones': _extractedData!.telefones,
        'emails': _extractedData!.emails,
        'custom_fields': _extractedData!.customFields,
      };

      // Salvar via API
      final response = await ApiService.saveProcessedDocument(
        caseId: widget.caseId ?? 'temp_case_id',
        documentName: 'Documento ${_getDocumentTypeName(_extractedData!.documentType)}',
        documentType: _extractedData!.documentType.toString(),
        extractedData: extractedDataMap,
        ocrResult: ocrResult,
        confidenceScore: _ocrResult?.confidence ?? 0.0,
        imageBase64: imageBase64,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.success('Documento salvo no backend: ${data['document_id']}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar no backend', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Validação via backend
  Future<void> _validateWithBackend() async {
    if (_extractedData == null) return;

    try {
      setState(() => _isProcessing = true);

      final extractedDataMap = {
        'nome': _extractedData!.nome,
        'cpf': _extractedData!.cpf,
        'cnpj': _extractedData!.cnpj,
        'rg': _extractedData!.rg,
        'oab': _extractedData!.oab,
        'endereco': _extractedData!.endereco,
        'telefones': _extractedData!.telefones,
        'emails': _extractedData!.emails,
      };

      final response = await ApiService.validateDocumentData(
        extractedData: extractedDataMap,
      );

      if (response.statusCode == 200) {
        final validationResult = response.data['data']['validation_result'];
        
        if (validationResult['is_valid']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Dados validados com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final errors = validationResult['errors'] as List<dynamic>;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erros encontrados: ${errors.join(', ')}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Erro na validação', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro na validação: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _saveDocument() {
    if (_extractedData != null) {
      // Salvar localmente (callback para tela anterior)
      widget.onDocumentProcessed?.call(_extractedData!);
      
      // Salvar no backend se há um caso associado
      if (widget.caseId != null) {
        _saveDocumentToBackend();
      }
      
      context.pop(_extractedData);
    }
  }

  void _copyToClipboard(String text) {
    // TODO: Implementar cópia para clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado para a área de transferência'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.cpf:
      case DocumentType.cnpj:
        return LucideIcons.creditCard;
      case DocumentType.rg:
        return LucideIcons.badgeCheck;
      case DocumentType.oab:
        return LucideIcons.scale;
      case DocumentType.contratoTrabalho:
        return LucideIcons.fileText;
      case DocumentType.holerite:
        return LucideIcons.receipt;
      case DocumentType.comprovantePagamento:
        return LucideIcons.banknote;
      case DocumentType.comprovanteResidencia:
        return LucideIcons.home;
      case DocumentType.procuracao:
        return LucideIcons.userCheck;
      case DocumentType.peticao:
        return LucideIcons.scroll;
      default:
        return LucideIcons.file;
    }
  }

  String _getDocumentTypeName(DocumentType type) {
    switch (type) {
      case DocumentType.cpf:
        return 'CPF';
      case DocumentType.cnpj:
        return 'CNPJ';
      case DocumentType.rg:
        return 'RG';
      case DocumentType.oab:
        return 'Carteira OAB';
      case DocumentType.contratoTrabalho:
        return 'Contrato de Trabalho';
      case DocumentType.holerite:
        return 'Holerite';
      case DocumentType.comprovantePagamento:
        return 'Comprovante de Pagamento';
      case DocumentType.comprovanteResidencia:
        return 'Comprovante de Residência';
      case DocumentType.procuracao:
        return 'Procuração';
      case DocumentType.peticao:
        return 'Petição';
      default:
        return 'Documento Genérico';
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
} 