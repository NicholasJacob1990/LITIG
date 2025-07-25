import 'package:flutter/material.dart';

/// Widget simples de editor de texto rico (versão simplificada para resolver problemas de compilação)
class RichTextEditorWidget extends StatefulWidget {
  final String? initialText;
  final String? initialContent;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final double? minHeight;
  final bool? enableLinks;
  final bool? enableImages;

  const RichTextEditorWidget({
    super.key,
    this.initialText,
    this.initialContent,
    this.onChanged,
    this.placeholder,
    this.minHeight,
    this.enableLinks,
    this.enableImages,
  });

  @override
  State<RichTextEditorWidget> createState() => RichTextEditorWidgetState();
}

class RichTextEditorWidgetState extends State<RichTextEditorWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? widget.initialContent ?? '');
    _controller.addListener(() {
      widget.onChanged?.call(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String getHtmlContent() {
    return _controller.text.replaceAll('\n', '<br>');
  }

  void setHtmlContent(String html) {
    final text = html.replaceAll('<br>', '\n').replaceAll(RegExp(r'<[^>]*>'), '');
    _controller.text = text;
  }
  
  String getPlainTextContent() {
    return _controller.text;
  }
  
  void setContent(String content) {
    _controller.text = content;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: widget.minHeight != null 
          ? BoxConstraints(minHeight: widget.minHeight!)
          : null,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Toolbar simples
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.format_bold, size: 20),
                  onPressed: () {
                    // Funcionalidade básica de formatação pode ser implementada aqui
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.format_italic, size: 20),
                  onPressed: () {
                    // Funcionalidade básica de formatação pode ser implementada aqui
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.format_underlined, size: 20),
                  onPressed: () {
                    // Funcionalidade básica de formatação pode ser implementada aqui
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Editor de texto
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: widget.placeholder ?? 'Digite aqui...',
                  border: InputBorder.none,
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
        ],
      ),
    );
  }
}