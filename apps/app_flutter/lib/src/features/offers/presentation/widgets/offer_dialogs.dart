import 'package:flutter/material.dart';
import 'package:meu_app/src/features/offers/domain/entities/case_offer.dart';

class RejectOfferDialog extends StatefulWidget {
  final CaseOffer offer;

  const RejectOfferDialog({super.key, required this.offer});

  @override
  State<RejectOfferDialog> createState() => _RejectOfferDialogState();
}

class _RejectOfferDialogState extends State<RejectOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rejeitar Oferta'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tem certeza que deseja rejeitar esta oferta? Esta ação não pode ser desfeita.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo da recusa',
                hintText: 'Ex: Conflito de interesse, fora da minha área, etc.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, informe o motivo.';
                }
                if (value.length < 10) {
                  return 'O motivo deve ter pelo menos 10 caracteres.';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_reasonController.text);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Confirmar Recusa'),
        ),
      ],
    );
  }
}

class AcceptOfferDialog extends StatelessWidget {
  final CaseOffer offer;

  const AcceptOfferDialog({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aceitar Oferta'),
      content: const Text('Ao aceitar, este caso será adicionado à sua lista de "Meus Casos" e você se tornará o responsável. Deseja continuar?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Confirmar e Aceitar'),
        ),
      ],
    );
  }
} 