import 'package:flutter/material.dart';
import '../../domain/usecases/validate_sla_settings.dart';

class SlaValidationPanel extends StatelessWidget {
  final SlaValidationResult validationResult;
  final VoidCallback onDismiss;

  const SlaValidationPanel({
    super.key,
    required this.validationResult,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(context),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          if (validationResult.violations.isNotEmpty) _buildViolations(context),
          if (validationResult.warnings.isNotEmpty) _buildWarnings(context),
          _buildSummary(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(context).withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(context),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _getStatusColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusSubtitle(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(context).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              color: _getStatusColor(context),
            ),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildViolations(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Problemas Críticos (${validationResult.violations.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...validationResult.violations.map((violation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      color: Colors.red,
                      size: 8,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        violation.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildWarnings(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Avisos (${validationResult.warnings.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...validationResult.warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      color: Colors.orange,
                      size: 8,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Score: ${validationResult.score}/100',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (validationResult.isValid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Válido',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    if (validationResult.violations.isNotEmpty) return Colors.red;
    if (validationResult.warnings.isNotEmpty) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (validationResult.violations.isNotEmpty) return Icons.error;
    if (validationResult.warnings.isNotEmpty) return Icons.warning;
    return Icons.check_circle;
  }

  String _getStatusTitle() {
    if (validationResult.violations.isNotEmpty) return 'Configuração Inválida';
    if (validationResult.warnings.isNotEmpty) return 'Atenção Necessária';
    return 'Configuração Válida';
  }

  String _getStatusSubtitle() {
    if (validationResult.violations.isNotEmpty) {
      return 'Problemas críticos devem ser corrigidos';
    }
    if (validationResult.warnings.isNotEmpty) {
      return 'Verifique os avisos abaixo';
    }
    return 'Todas as validações passaram com sucesso';
  }
} 