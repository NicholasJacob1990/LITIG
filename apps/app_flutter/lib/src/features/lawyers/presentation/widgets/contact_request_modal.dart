import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/entities/matched_lawyer.dart';
import '../../../../core/config/app_config.dart';

enum ContactRequestResult {
  success,
  linkedinFallback,
  noContact,
  error,
}

class ContactRequestModal extends StatefulWidget {
  final MatchedLawyer lawyer;
  final String caseId;
  final Function(ContactRequestResult) onResult;

  const ContactRequestModal({
    super.key,
    required this.lawyer,
    required this.caseId,
    required this.onResult,
  });

  @override
  State<ContactRequestModal> createState() => _ContactRequestModalState();
}

class _ContactRequestModalState extends State<ContactRequestModal> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sendContactRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/v1/invites/client-request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.userToken ?? "demo-token"}',
        },
                  body: jsonEncode({
            'target_profile': {
              'name': widget.lawyer.nome,
              'email': 'demo@email.com', // Placeholder - não temos email na entidade
              'linkedin_url': 'https://linkedin.com/in/demo', // Placeholder - não temos linkedin na entidade
              'specialties': widget.lawyer.specializations,
            },
          'case_info': {
            'id': widget.caseId,
            'summary': 'Solicitação de contato via LITIG',
          },
          'client_info': {
            'id': AppConfig.currentUserId ?? 'demo-user',
            'name': AppConfig.currentUserName ?? 'Cliente Demo',
          },
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final status = responseData['status'];
        final channel = responseData['channel'];

        switch (status) {
          case 'success':
            if (channel == 'platform_email') {
              _showSuccessMessage();
              widget.onResult(ContactRequestResult.success);
            }
            break;
          case 'fallback':
            if (channel == 'linkedin_assisted') {
              _showLinkedInFallback(
                responseData['linkedin_message'],
                responseData['linkedin_profile_url'],
              );
              widget.onResult(ContactRequestResult.linkedinFallback);
            }
            break;
          case 'failed':
            _showNoContactFallback();
            widget.onResult(ContactRequestResult.noContact);
            break;
        }
      } else {
        throw Exception(responseData['detail'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao enviar solicitação: $e';
      });
      widget.onResult(ContactRequestResult.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                "✅ Notificamos Dr(a). ${widget.lawyer.nome} por e-mail",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                "Você será avisado quando ele(a) responder.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: const Text("Entendi"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Fechar também o modal principal
              },
            ),
          ],
        );
      },
    );
  }

  void _showLinkedInFallback(String message, String profileUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.link, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text("Conecte-se no LinkedIn!"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "📱 Para maior eficácia, envie você mesmo:",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: SelectableText(
                  message,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text("Copiar Mensagem"),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Mensagem copiada!")),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text("Abrir LinkedIn"),
                    onPressed: () => _openLinkedIn(profileUrl),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showNoContactFallback() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text("Contato não encontrado"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "⚠️ Não foi possível encontrar contato público para Dr(a). ${widget.lawyer.nome}",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Para conexão garantida, escolha um Advogado Verificado:",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: const Text("Ver Advogados Verificados"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Fechar também o modal principal
                _showVerifiedLawyers();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVerifiedLawyers() {
    // Navegar para a tela de advogados verificados filtrando apenas os internos
    Navigator.pushReplacementNamed(
      context,
      '/lawyers',
      arguments: {
        'filter': 'verified_only',
        'case_id': widget.caseId,
      },
    );
  }

  Future<void> _openLinkedIn(String profileUrl) async {
    try {
      final Uri url = Uri.parse(profileUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Não foi possível abrir o LinkedIn');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao abrir LinkedIn: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(widget.lawyer.avatarUrl),
            child: widget.lawyer.avatarUrl.isEmpty
                ? Text(widget.lawyer.nome.substring(0, 1).toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Solicitar Contato",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.lawyer.nome,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.lawyer.isExternal) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Este é um perfil público. Tentaremos estabelecer contato.",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            "Como deseja proceder?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enviaremos uma notificação profissional para este advogado sobre sua consulta jurídica.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendContactRequest,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Solicitar Contato"),
        ),
      ],
    );
  }
} 