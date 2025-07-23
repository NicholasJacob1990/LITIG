import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_html/flutter_html.dart';
import 'package:meu_app/src/core/theme/app_colors.dart';

/// Widget de Rich Text Editor reutilizável usando Flutter Quill
/// Suporta formatação completa para emails, InMails e outros conteúdos
class RichTextEditorWidget extends StatefulWidget {
  final String? initialContent;
  final String? placeholder;
  final bool readOnly;
  final double? minHeight;
  final double? maxHeight;
  final Function(String htmlContent)? onChanged;
  final Function(String htmlContent)? onSubmitted;
  final bool showToolbar;
  final bool enableImages;
  final bool enableLinks;

  const RichTextEditorWidget({
    super.key,
    this.initialContent,
    this.placeholder,
    this.readOnly = false,
    this.minHeight = 150,
    this.maxHeight = 400,
    this.onChanged,
    this.onSubmitted,
    this.showToolbar = true,
    this.enableImages = false,
    this.enableLinks = true,
  });

  @override
  State<RichTextEditorWidget> createState() => _RichTextEditorWidgetState();
}

class _RichTextEditorWidgetState extends State<RichTextEditorWidget> {
  late quill.QuillController _controller;
  late ScrollController _scrollController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Inicializar com conteúdo
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      try {
        // Tentar converter HTML para Delta
        final delta = _htmlToDelta(widget.initialContent!);
        _controller = quill.QuillController(
          document: quill.Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // Se falhar, usar como texto simples
        _controller = quill.QuillController.basic();
        _controller.document.insert(0, widget.initialContent!);
      }
    } else {
      _controller = quill.QuillController.basic();
    }

    // Listener para mudanças
    _controller.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (widget.onChanged != null) {
      final htmlContent = _deltaToHtml(_controller.document.toDelta());
      widget.onChanged!(htmlContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (widget.showToolbar && !widget.readOnly)
            _buildToolbar(),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                minHeight: widget.minHeight ?? 150,
                maxHeight: widget.maxHeight ?? 400,
              ),
              child: quill.QuillEditor.basic(
                controller: _controller,
                scrollController: _scrollController,
                focusNode: _focusNode,
                configurations: quill.QuillEditorConfigurations(
                  readOnly: widget.readOnly,
                  placeholder: widget.placeholder ?? 'Digite aqui...',
                  padding: const EdgeInsets.all(16),
                  autoFocus: false,
                  expands: false,
                  showCursor: !widget.readOnly,
                  customStyles: _getCustomStyles(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outline.withOpacity(0.2)),
        ),
      ),
      child: quill.QuillSimpleToolbar(
        controller: _controller,
        configurations: quill.QuillSimpleToolbarConfigurations(
          toolbarSize: 40,
          multiRowsDisplay: false,
          color: AppColors.primaryBlue,
          showDividers: true,
          showFontFamily: false,
          showFontSize: false,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: false,
          showInlineCode: true,
          showColorButton: false,
          showBackgroundColorButton: false,
          showClearFormat: true,
          showAlignmentButtons: true,
          showLeftAlignment: true,
          showCenterAlignment: true,
          showRightAlignment: true,
          showJustifyAlignment: false,
          showHeaderStyle: true,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: false,
          showCodeBlock: false,
          showQuote: true,
          showIndent: true,
          showLink: widget.enableLinks,
          showUnLink: widget.enableLinks,
          showClipboardCut: false,
          showClipboardCopy: false,
          showClipboardPaste: false,
          showRedo: true,
          showUndo: true,
        ),
      ),
    );
  }

  quill.DefaultStyles _getCustomStyles() {
    return quill.DefaultStyles(
      paragraph: quill.DefaultTextBlockStyle(
        const TextStyle(
          fontSize: 16,
          height: 1.4,
          color: Colors.black87,
        ),
        const quill.VerticalSpacing(8, 8),
        const quill.VerticalSpacing(0, 0),
        null,
      ),
      h1: quill.DefaultTextBlockStyle(
        const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
          color: Colors.black87,
        ),
        const quill.VerticalSpacing(16, 8),
        const quill.VerticalSpacing(0, 0),
        null,
      ),
      h2: quill.DefaultTextBlockStyle(
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.3,
          color: Colors.black87,
        ),
        const quill.VerticalSpacing(12, 6),
        const quill.VerticalSpacing(0, 0),
        null,
      ),
      h3: quill.DefaultTextBlockStyle(
        const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: Colors.black87,
        ),
        const quill.VerticalSpacing(10, 4),
        const quill.VerticalSpacing(0, 0),
        null,
      ),
    );
  }

  /// Converte HTML simples para Delta (implementação básica)
  quill.Delta _htmlToDelta(String html) {
    // Implementação básica - pode ser expandida com biblioteca específica
    final delta = quill.Delta();
    
    // Remover tags HTML básicas e converter para texto simples
    final cleanText = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), ''); // Remove todas as outras tags HTML
    
    delta.insert(cleanText);
    return delta;
  }

  /// Converte Delta para HTML básico
  String _deltaToHtml(quill.Delta delta) {
    try {
      final buffer = StringBuffer();
      
      for (final op in delta.operations) {
        if (op.data is String) {
          String text = op.data as String;
          Map<String, dynamic>? attributes = op.attributes;
          
          if (attributes != null) {
            // Aplicar formatação
            if (attributes['bold'] == true) {
              text = '<strong>$text</strong>';
            }
            if (attributes['italic'] == true) {
              text = '<em>$text</em>';
            }
            if (attributes['underline'] == true) {
              text = '<u>$text</u>';
            }
            if (attributes['header'] != null) {
              final level = attributes['header'];
              text = '<h$level>$text</h$level>';
            }
            if (attributes['list'] == 'ordered') {
              text = '<li>$text</li>';
            }
            if (attributes['list'] == 'bullet') {
              text = '<li>$text</li>';
            }
            if (attributes['link'] != null) {
              final url = attributes['link'];
              text = '<a href="$url">$text</a>';
            }
          }
          
          // Converter quebras de linha
          text = text.replaceAll('\n', '<br>');
          buffer.write(text);
        }
      }
      
      return buffer.toString();
    } catch (e) {
      // Em caso de erro, retornar texto simples
      return _controller.document.toPlainText();
    }
  }

  /// Obtém o conteúdo como HTML
  String getHtmlContent() {
    return _deltaToHtml(_controller.document.toDelta());
  }

  /// Obtém o conteúdo como texto simples
  String getPlainTextContent() {
    return _controller.document.toPlainText();
  }

  /// Define novo conteúdo
  void setContent(String htmlContent) {
    try {
      final delta = _htmlToDelta(htmlContent);
      _controller.document = quill.Document.fromDelta(delta);
    } catch (e) {
      _controller.clear();
      _controller.document.insert(0, htmlContent);
    }
  }

  /// Limpa o conteúdo
  void clear() {
    _controller.clear();
  }

  /// Foca no editor
  void focus() {
    _focusNode.requestFocus();
  }
}