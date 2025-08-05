import 'package:flutter/material.dart';
import 'package:meu_app/src/features/offers/domain/entities/case_offer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/widgets/instrumented_widgets.dart';

class CaseOfferCard extends StatelessWidget {
  final CaseOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  // Novos parâmetros para instrumentação
  final String? sourceContext;
  final double? listRank;

  const CaseOfferCard({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onReject,
    this.sourceContext,
    this.listRank,
  });

  @override
  Widget build(BuildContext context) {
    final timeRemaining = offer.expiresAt.difference(DateTime.now());
    final isExpiringSoon = timeRemaining.inHours < 6;

    return InstrumentedContentCard(
      contentId: offer.id,
      contentType: 'offer',
      sourceContext: sourceContext ?? 'offers_list',
      listRank: listRank,
      additionalData: {
        'offer_amount': offer.estimatedFee,
        'legal_area': offer.legalArea,
        'urgency_level': offer.urgencyLevel,
        'expires_in_hours': timeRemaining.inHours,
        'is_expiring_soon': isExpiringSoon,
      },
      child: Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com área e urgência
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getAreaColor(offer.legalArea),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    offer.legalArea,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                _buildUrgencyBadge(offer.urgencyLevel),
                const Spacer(),
                _buildExpirationTimer(timeRemaining, isExpiringSoon),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Resumo do caso
            Text(
              offer.caseSummary,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Informações adicionais
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(offer.clientLocation, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(LucideIcons.dollarSign, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(offer.estimatedFee ?? 'A combinar', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação - Instrumentados
            Row(
              children: [
                Expanded(
                  child: InstrumentedButton(
                    elementId: 'reject_offer_${offer.id}',
                    context: 'case_offer_card',
                    onPressed: onReject,
                    additionalData: {
                      'offer_id': offer.id,
                      'action_type': 'reject_offer',
                      'offer_amount': offer.estimatedFee,
                      'legal_area': offer.legalArea,
                      'urgency_level': offer.urgencyLevel,
                      'time_to_decision_hours': DateTime.now().difference(offer.createdAt).inHours,
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.x, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Recusar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InstrumentedButton(
                    elementId: 'accept_offer_${offer.id}',
                    context: 'case_offer_card',
                    onPressed: onAccept,
                    additionalData: {
                      'offer_id': offer.id,
                      'action_type': 'accept_offer',
                      'offer_amount': offer.estimatedFee,
                      'legal_area': offer.legalArea,
                      'urgency_level': offer.urgencyLevel,
                      'time_to_decision_hours': DateTime.now().difference(offer.createdAt).inHours,
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Aceitar', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildUrgencyBadge(String urgency) {
    Color color;
    IconData icon;
    
    switch (urgency.toLowerCase()) {
      case 'alta':
        color = Colors.red;
        icon = LucideIcons.siren;
        break;
      case 'média':
        color = Colors.orange;
        icon = LucideIcons.clock;
        break;
      default:
        color = Colors.green;
        icon = LucideIcons.clock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(urgency, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExpirationTimer(Duration timeRemaining, bool isExpiringSoon) {
    String text;
    Color color = isExpiringSoon ? Colors.red : Colors.grey.shade600;

    if (timeRemaining.isNegative) {
      text = 'Expirada';
      color = Colors.red;
    } else if (timeRemaining.inHours < 1) {
      text = '${timeRemaining.inMinutes}min restantes';
    } else {
      text = '${timeRemaining.inHours}h restantes';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10),
      ),
    );
  }

  Color _getAreaColor(String area) {
    // A simple hash function to get a color from the area string
    final hash = area.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;
    return Color.fromRGBO(r, g, b, 1);
  }
} 