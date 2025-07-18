import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:meu_app/injection_container.dart';
import '../../domain/entities/case_rating.dart';
import '../bloc/rating_bloc.dart';
import '../bloc/rating_event.dart';
import '../bloc/rating_state.dart';

/// Tela para avaliar um caso finalizado
class CaseRatingScreen extends StatefulWidget {
  final String caseId;
  final String lawyerId;
  final String clientId;
  final String userType; // 'client' ou 'lawyer'

  const CaseRatingScreen({
    super.key,
    required this.caseId,
    required this.lawyerId,
    required this.clientId,
    required this.userType,
  });

  @override
  State<CaseRatingScreen> createState() => _CaseRatingScreenState();
}

class _CaseRatingScreenState extends State<CaseRatingScreen> {
  double _overallRating = 0;
  double _communicationRating = 0;
  double _expertiseRating = 0;
  double _responsivenessRating = 0;
  double _valueRating = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    // Escutar mudanças no controller para atualizar contador
    _commentController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<RatingBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
        ),
        body: BlocConsumer<RatingBloc, RatingState>(
          listener: (context, state) {
            if (state is RatingSubmitted) {
              _showSuccessDialog();
            } else if (state is RatingError) {
              _showErrorDialog(state.message);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildOverallRating(),
                  const SizedBox(height: 32),
                  _buildDetailedRatings(),
                  const SizedBox(height: 32),
                  _buildTagsSection(),
                  const SizedBox(height: 32),
                  _buildCommentSection(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(state),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.star_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(height: 12),
          Text(
            _getHeaderTitle(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getHeaderSubtitle(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avaliação Geral',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Como você avalia a experiência geral?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  RatingBar.builder(
                    initialRating: _overallRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 40,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _overallRating = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getRatingText(_overallRating),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _getRatingColor(_overallRating),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRatings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avaliação Detalhada',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Avalie aspectos específicos da experiência:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            _buildRatingRow(
              'Comunicação',
              'Clareza e frequência da comunicação',
              Icons.chat_bubble_outline,
              _communicationRating,
              (rating) => setState(() => _communicationRating = rating),
            ),
            const SizedBox(height: 16),
            _buildRatingRow(
              'Expertise',
              'Conhecimento técnico e experiência',
              Icons.psychology_outlined,
              _expertiseRating,
              (rating) => setState(() => _expertiseRating = rating),
            ),
            const SizedBox(height: 16),
            _buildRatingRow(
              'Responsividade',
              'Tempo de resposta e disponibilidade',
              Icons.schedule_outlined,
              _responsivenessRating,
              (rating) => setState(() => _responsivenessRating = rating),
            ),
            const SizedBox(height: 16),
            _buildRatingRow(
              'Custo-Benefício',
              'Valor do serviço em relação ao preço',
              Icons.attach_money_outlined,
              _valueRating,
              (rating) => setState(() => _valueRating = rating),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(
    String title,
    String description,
    IconData icon,
    double rating,
    Function(double) onRatingUpdate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RatingBar.builder(
                  initialRating: rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 24,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: onRatingUpdate,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    final availableTags = _getAvailableTags();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.label_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pontos Destacados',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione os aspectos que mais se destacaram:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comentário (Opcional)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Compartilhe sua experiência detalhada:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Descreva sua experiência, pontos positivos e sugestões de melhoria...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                counterText: '',
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                Text(
                  '${_commentController.text.length}/500',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(RatingState state) {
    final isLoading = state is RatingSubmitting;
    final canSubmit = _overallRating > 0 && _canSubmitRating();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit && !isLoading ? _submitRating : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Enviar Avaliação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Métodos auxiliares
  String _getTitle() {
    return widget.userType == 'client' ? 'Avaliar Advogado' : 'Avaliar Cliente';
  }

  String _getHeaderTitle() {
    return widget.userType == 'client' 
        ? 'Como foi sua experiência?' 
        : 'Como foi trabalhar com este cliente?';
  }

  String _getHeaderSubtitle() {
    return widget.userType == 'client'
        ? 'Sua avaliação ajuda outros clientes a encontrar bons advogados'
        : 'Sua avaliação ajuda outros advogados a conhecer este cliente';
  }

  List<String> _getAvailableTags() {
    if (widget.userType == 'client') {
      return [
        'Muito profissional',
        'Excelente comunicação',
        'Resposta rápida',
        'Conhecimento técnico',
        'Prestativo',
        'Pontual',
        'Estratégico',
        'Transparente',
        'Dedicado',
        'Resultado excelente',
      ];
    } else {
      return [
        'Cliente organizado',
        'Comunicação clara',
        'Pagamento pontual',
        'Colaborativo',
        'Respeitoso',
        'Documentos em ordem',
        'Expectativas realistas',
        'Comprometido',
        'Flexível',
        'Recomendaria',
      ];
    }
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excelente';
    if (rating >= 3.5) return 'Muito Bom';
    if (rating >= 2.5) return 'Bom';
    if (rating >= 1.5) return 'Regular';
    if (rating >= 1) return 'Ruim';
    return 'Selecione uma avaliação';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return AppColors.success;
    if (rating >= 3) return AppColors.warning;
    if (rating >= 2) return AppColors.error;
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
  }

  bool _canSubmitRating() {
    return _overallRating > 0 && 
           _communicationRating > 0 && 
           _expertiseRating > 0 && 
           _responsivenessRating > 0 && 
           _valueRating > 0;
  }

  void _submitRating() {
    final rating = CaseRating(
      id: '', // Será gerado no backend
      caseId: widget.caseId,
      lawyerId: widget.lawyerId,
      clientId: widget.clientId,
      raterId: '', // Será preenchido no backend baseado no usuário logado
      raterType: widget.userType,
      overallRating: _overallRating,
      communicationRating: _communicationRating,
      expertiseRating: _expertiseRating,
      responsivenessRating: _responsivenessRating,
      valueRating: _valueRating,
      comment: _commentController.text,
      tags: _selectedTags,
      createdAt: DateTime.now(),
      isVerified: true,
      isPublic: true,
      helpfulVotes: 0,
    );

    context.read<RatingBloc>().add(SubmitRating(rating));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Avaliação Enviada!'),
          ],
        ),
        content: const Text(
          'Obrigado pelo seu feedback. Sua avaliação foi registrada com sucesso e ajudará outros usuários.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erro'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 
} 