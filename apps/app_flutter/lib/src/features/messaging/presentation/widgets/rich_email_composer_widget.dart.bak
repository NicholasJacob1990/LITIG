import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/app_colors.dart';
import 'package:meu_app/src/shared/widgets/rich_text_editor_widget.dart';
import 'package:meu_app/src/features/messaging/presentation/bloc/unified_messaging_bloc.dart';

/// Widget para composição de emails com Rich Text Editor
/// Inclui campos completos: To, CC, BCC, Subject, Body formatado
class RichEmailComposerWidget extends StatefulWidget {
  final String? initialTo;
  final String? initialSubject;
  final String? initialBody;
  final String? replyToEmailId;
  final bool isReply;
  final bool isReplyAll;
  final VoidCallback? onCancel;
  final Function(Map<String, dynamic>)? onSent;

  const RichEmailComposerWidget({
    super.key,
    this.initialTo,
    this.initialSubject,
    this.initialBody,
    this.replyToEmailId,
    this.isReply = false,
    this.isReplyAll = false,
    this.onCancel,
    this.onSent,
  });

  @override
  State<RichEmailComposerWidget> createState() => _RichEmailComposerWidgetState();
}

class _RichEmailComposerWidgetState extends State<RichEmailComposerWidget> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyEditorKey = GlobalKey<RichTextEditorWidgetState>();
  
  bool _showCcBcc = false;
  bool _isSending = false;
  String _bodyContent = '';

  @override
  void initState() {
    super.initState();
    
    // Preencher campos iniciais
    if (widget.initialTo != null) {
      _toController.text = widget.initialTo!;
    }
    
    if (widget.initialSubject != null) {
      _subjectController.text = widget.initialSubject!;
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UnifiedMessagingBloc, UnifiedMessagingState>(
      listener: (context, state) {
        if (state is UnifiedMessagingSent) {
          setState(() => _isSending = false);
          widget.onSent?.call({'success': true, 'message': state.successMessage});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is UnifiedMessagingError) {
          setState(() => _isSending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is UnifiedMessagingSending) {
          setState(() => _isSending = true);
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildRecipientFields(),
                    _buildSubjectField(),
                    const Divider(height: 1),
                    Expanded(child: _buildBodyEditor()),
                    _buildBottomActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            widget.isReply ? LucideIcons.reply : LucideIcons.mail,
            color: AppColors.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isReply 
                  ? (widget.isReplyAll ? 'Responder a Todos' : 'Responder')
                  : 'Novo Email',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isSending)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              onPressed: widget.onCancel ?? () => Navigator.pop(context),
              icon: const Icon(LucideIcons.x),
              tooltip: 'Fechar',
            ),
        ],
      ),
    );
  }

  Widget _buildRecipientFields() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Campo Para
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Para:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _toController,
                  decoration: const InputDecoration(
                    hintText: 'destinatario@email.com',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite o destinatário';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _showCcBcc = !_showCcBcc),
                child: Text(_showCcBcc ? 'Ocultar' : 'CC/BCC'),
              ),
            ],
          ),
          
          // Campos CC e BCC
          if (_showCcBcc) ...[
            const Divider(height: 1),
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'CC:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _ccController,
                    decoration: const InputDecoration(
                      hintText: 'copia@email.com (opcional)',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'BCC:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _bccController,
                    decoration: const InputDecoration(
                      hintText: 'copia-oculta@email.com (opcional)',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Assunto:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'Assunto do email',
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o assunto';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: RichTextEditorWidget(
        key: _bodyEditorKey,
        initialContent: widget.initialBody,
        placeholder: 'Digite sua mensagem...',
        minHeight: 200,
        onChanged: (htmlContent) {
          _bodyContent = htmlContent;
        },
        enableLinks: true,
        enableImages: false,
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Botões de ação secundária
          IconButton(
            onPressed: _isSending ? null : _saveDraft,
            icon: const Icon(LucideIcons.save),
            tooltip: 'Salvar rascunho',
          ),
          IconButton(
            onPressed: _isSending ? null : _showAttachmentOptions,
            icon: const Icon(LucideIcons.paperclip),
            tooltip: 'Anexar arquivo',
          ),
          IconButton(
            onPressed: _isSending ? null : _scheduleEmail,
            icon: const Icon(LucideIcons.clock),
            tooltip: 'Agendar envio',
          ),
          
          const Spacer(),
          
          // Botões principais
          TextButton(
            onPressed: _isSending ? null : (widget.onCancel ?? () => Navigator.pop(context)),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _isSending ? null : _sendEmail,
            icon: _isSending 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.send, size: 16),
            label: Text(_isSending ? 'Enviando...' : 'Enviar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _sendEmail() {
    if (!_formKey.currentState!.validate()) return;
    
    final to = _toController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyContent.isNotEmpty ? _bodyContent : _bodyEditorKey.currentState?.getPlainTextContent() ?? '';
    
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o conteúdo do email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Preparar lista de destinatários
    final recipients = [to];
    if (_ccController.text.isNotEmpty) {
      recipients.addAll(_ccController.text.split(',').map((e) => e.trim()));
    }

    if (widget.isReply && widget.replyToEmailId != null) {
      // Enviar resposta
      context.read<UnifiedMessagingBloc>().add(
        ReplyToEmail(
          emailId: widget.replyToEmailId!,
          accountId: '', // Será preenchido pelo bloc
          replyBody: body,
          replyAll: widget.isReplyAll,
        ),
      );
    } else {
      // Enviar novo email
      context.read<UnifiedMessagingBloc>().add(
        SendEmailMessage(
          to: to,
          subject: subject,
          body: body,
          cc: _ccController.text.isNotEmpty 
              ? _ccController.text.split(',').map((e) => e.trim()).toList()
              : null,
        ),
      );
    }
  }

  void _saveDraft() {
    final to = _toController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyContent.isNotEmpty ? _bodyContent : _bodyEditorKey.currentState?.getPlainTextContent() ?? '';
    
    if (to.isEmpty && subject.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nada para salvar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<UnifiedMessagingBloc>().add(
      CreateEmailDraft(
        accountId: '', // Será preenchido pelo bloc
        to: to,
        subject: subject,
        body: body,
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.file),
            title: const Text('Arquivo'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implementar seleção de arquivo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
              );
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.image),
            title: const Text('Imagem'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implementar seleção de imagem
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
              );
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.camera),
            title: const Text('Câmera'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implementar captura de foto
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _scheduleEmail() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agendar Envio'),
        content: const Text('Funcionalidade de agendamento em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}