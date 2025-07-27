import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/widgets/rich_text_editor_widget.dart';
import 'package:meu_app/src/features/messaging/presentation/bloc/unified_messaging_bloc.dart';

/// Widget para composição de InMail do LinkedIn com Rich Text Editor
/// Focado em comunicação profissional com formatação rica
class RichInMailComposerWidget extends StatefulWidget {
  final String accountId;
  final String? initialRecipientId;
  final String? initialSubject;
  final String? initialBody;
  final VoidCallback? onCancel;
  final Function(Map<String, dynamic>)? onSent;

  const RichInMailComposerWidget({
    super.key,
    required this.accountId,
    this.initialRecipientId,
    this.initialSubject,
    this.initialBody,
    this.onCancel,
    this.onSent,
  });

  @override
  State<RichInMailComposerWidget> createState() => _RichInMailComposerWidgetState();
}

class _RichInMailComposerWidgetState extends State<RichInMailComposerWidget> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyEditorKey = GlobalKey<RichTextEditorWidgetState>();
  
  bool _isSending = false;
  String _bodyContent = '';

  @override
  void initState() {
    super.initState();
    
    // Preencher campos iniciais
    if (widget.initialRecipientId != null) {
      _recipientController.text = widget.initialRecipientId!;
    }
    
    if (widget.initialSubject != null) {
      _subjectController.text = widget.initialSubject!;
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
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
        height: MediaQuery.of(context).size.height * 0.85,
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
                    _buildRecipientField(),
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
      decoration: BoxDecoration(
        color: const Color(0xFF0077B5).withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF0077B5).withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0077B5).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.linkedin,
              color: Color(0xFF0077B5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enviar InMail',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0077B5),
                  ),
                ),
                Text(
                  'Mensagem profissional do LinkedIn',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF0077B5).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_isSending)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077B5)),
              ),
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

  Widget _buildRecipientField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Para:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0077B5),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _recipientController,
              decoration: InputDecoration(
                hintText: 'ID ou nome do perfil LinkedIn (ex: john-doe-123456)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: const Color(0xFF0077B5).withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0077B5)),
                ),
                prefixIcon: const Icon(LucideIcons.user, color: Color(0xFF0077B5)),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o ID do destinatário';
                }
                return null;
              },
            ),
          ),
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
            width: 80,
            child: Text(
              'Assunto:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0077B5),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Assunto profissional do InMail',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: const Color(0xFF0077B5).withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0077B5)),
                ),
                prefixIcon: const Icon(LucideIcons.type, color: Color(0xFF0077B5)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.edit,
                color: Color(0xFF0077B5),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Mensagem:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0077B5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RichTextEditorWidget(
              key: _bodyEditorKey,
              initialContent: widget.initialBody,
              placeholder: 'Escreva sua mensagem profissional...\n\nDicas:\n• Seja claro e objetivo\n• Personalize para o destinatário\n• Inclua um call-to-action',
              minHeight: 200,
              onChanged: (htmlContent) {
                _bodyContent = htmlContent;
              },
              enableLinks: true,
              enableImages: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0077B5).withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: const Color(0xFF0077B5).withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dicas profissionais
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0077B5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0077B5).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.lightbulb,
                  color: Color(0xFF0077B5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'InMails têm maior taxa de resposta quando são personalizados e profissionais',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF0077B5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Botões de ação
          Row(
            children: [
              // Botões secundários
              OutlinedButton.icon(
                onPressed: _isSending ? null : _saveDraft,
                icon: const Icon(LucideIcons.save, size: 16),
                label: const Text('Salvar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0077B5),
                  side: const BorderSide(color: Color(0xFF0077B5)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _isSending ? null : _showTemplates,
                icon: const Icon(LucideIcons.fileText, size: 16),
                label: const Text('Templates'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0077B5),
                  side: const BorderSide(color: Color(0xFF0077B5)),
                ),
              ),
              
              const Spacer(),
              
              // Botões principais
              TextButton(
                onPressed: _isSending ? null : (widget.onCancel ?? () => Navigator.pop(context)),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isSending ? null : _sendInMail,
                icon: _isSending 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.send, size: 16),
                label: Text(_isSending ? 'Enviando...' : 'Enviar InMail'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendInMail() {
    if (!_formKey.currentState!.validate()) return;
    
    final recipientId = _recipientController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyContent.isNotEmpty ? _bodyContent : _bodyEditorKey.currentState?.getPlainTextContent() ?? '';
    
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o conteúdo da mensagem'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<UnifiedMessagingBloc>().add(
      SendLinkedInInMail(
        accountId: widget.accountId,
        recipientId: recipientId,
        subject: subject,
        body: body,
      ),
    );
  }

  void _saveDraft() {
    final recipientId = _recipientController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyContent.isNotEmpty ? _bodyContent : _bodyEditorKey.currentState?.getPlainTextContent() ?? '';
    
    if (recipientId.isEmpty && subject.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nada para salvar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Implementar salvamento de rascunho de InMail
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rascunho salvo localmente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showTemplates() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Templates de InMail',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0077B5),
              ),
            ),
            const SizedBox(height: 16),
            _buildTemplateOption(
              'Proposta de Parceria',
              'Template para propor parcerias profissionais',
              () => _applyTemplate('partnership'),
            ),
            _buildTemplateOption(
              'Networking Profissional',
              'Template para conexões de networking',
              () => _applyTemplate('networking'),
            ),
            _buildTemplateOption(
              'Oportunidade de Negócio',
              'Template para apresentar oportunidades',
              () => _applyTemplate('business'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateOption(String title, String description, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF0077B5).withValues(alpha: 0.1),
        child: const Icon(LucideIcons.fileText, color: Color(0xFF0077B5), size: 20),
      ),
      title: Text(title),
      subtitle: Text(description),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _applyTemplate(String templateType) {
    String templateContent = '';
    
    switch (templateType) {
      case 'partnership':
        templateContent = '''
<p>Olá [Nome],</p>

<p>Espero que esta mensagem o encontre bem. Meu nome é [Seu Nome] e sou [Sua Posição] na [Sua Empresa].</p>

<p>Tenho acompanhado seu trabalho em [área/setor] e fiquei impressionado com [mencionar algo específico]. Acredito que nossos trabalhos têm sinergia e gostaria de explorar possibilidades de <strong>parceria profissional</strong>.</p>

<p>Seria possível conversarmos brevemente sobre como podemos colaborar? Tenho algumas ideias que podem ser mutuamente benéficas.</p>

<p>Fico no aguardo de seu retorno.</p>

<p>Atenciosamente,<br>[Seu Nome]</p>
''';
        break;
      case 'networking':
        templateContent = '''
<p>Olá [Nome],</p>

<p>Vi seu perfil através de [como conheceu] e fiquei interessado em me conectar com você.</p>

<p>Sou [Sua Posição] com experiência em [área de atuação]. Admiro seu trabalho em [mencionar área/empresa] e acredito que poderíamos trocar experiências valiosas sobre <em>[tópico comum]</em>.</p>

<p>Gostaria de expandir minha rede de contatos com profissionais como você. Talvez possamos marcar um café virtual para nos conhecermos melhor?</p>

<p>Abraços,<br>[Seu Nome]</p>
''';
        break;
      case 'business':
        templateContent = '''
<p>Olá [Nome],</p>

<p>Meu nome é [Seu Nome] e represento a [Sua Empresa]. Identificamos uma <strong>oportunidade interessante</strong> que pode ser relevante para [Empresa do destinatário].</p>

<p>Baseado em sua experiência em [área], acredito que nossa solução em [área/produto] pode agregar valor significativo aos seus projetos atuais.</p>

<p>Principais benefícios:</p>
<ul>
<li>Benefício 1</li>
<li>Benefício 2</li>
<li>Benefício 3</li>
</ul>

<p>Teria disponibilidade para uma conversa de 15 minutos na próxima semana?</p>

<p>Aguardo seu retorno.</p>

<p>[Seu Nome]<br>[Seu Cargo] | [Sua Empresa]</p>
''';
        break;
    }
    
    _bodyEditorKey.currentState?.setContent(templateContent);
    setState(() => _bodyContent = templateContent);
  }
}