import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool enabled;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.enabled = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty && widget.enabled) {
      widget.onSendMessage(message);
      _controller.clear();
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _onTextChanged(String value) {
    final wasTyping = _isTyping;
    final isTyping = value.trim().isNotEmpty;
    
    if (wasTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              onPressed: widget.enabled ? _showAttachmentOptions : null,
              icon: Icon(
                LucideIcons.paperclip,
                color: widget.enabled 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[400],
              ),
            ),
            
            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: _onTextChanged,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: widget.enabled 
                        ? 'Digite uma mensagem...'
                        : 'Chat não disponível',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                onPressed: (_isTyping && widget.enabled) ? _sendMessage : null,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (_isTyping && widget.enabled)
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    LucideIcons.send,
                    color: (_isTyping && widget.enabled)
                        ? Theme.of(context).colorScheme.onPrimary
                        : Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                'Anexar arquivo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    context,
                    icon: LucideIcons.camera,
                    label: 'Câmera',
                    onTap: () {
                      Navigator.pop(context);
                      _handleCameraAttachment();
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: LucideIcons.image,
                    label: 'Galeria',
                    onTap: () {
                      Navigator.pop(context);
                      _handleGalleryAttachment();
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: LucideIcons.file,
                    label: 'Documento',
                    onTap: () {
                      Navigator.pop(context);
                      _handleDocumentAttachment();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _handleCameraAttachment() {
    // TODO: Implement camera attachment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de câmera será implementada em breve'),
      ),
    );
  }

  void _handleGalleryAttachment() {
    // TODO: Implement gallery attachment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de galeria será implementada em breve'),
      ),
    );
  }

  void _handleDocumentAttachment() {
    // TODO: Implement document attachment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de documento será implementada em breve'),
      ),
    );
  }
}