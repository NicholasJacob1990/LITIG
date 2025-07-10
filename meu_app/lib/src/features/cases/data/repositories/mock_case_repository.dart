import 'package:flutter/material.dart';
import '../../domain/entities/case_detail_models.dart';
import '../../domain/repositories/case_repository.dart';

class MockCaseRepository implements CaseRepository {
  @override
  Future<CaseDetail> getCaseDetail(String caseId) async {
    // Simular delay de rede
    await Future.delayed(const Duration(seconds: 1));
    
    // Retornar dados mockados para teste
    return CaseDetail(
      title: 'Rescisão Trabalhista',
      caseNumber: caseId,
      status: 'Em Andamento',
      lawyer: Lawyer(
        avatarUrl: 'https://i.pravatar.cc/150?u=carlos',
        name: 'Dr. Carlos Mendes',
        specialty: 'Direito Trabalhista',
        rating: 4.8,
        experienceYears: 12,
      ),
      consultationInfo: ConsultationInfo(
        date: '16/01/2024',
        duration: '45 minutos',
        mode: 'Vídeo',
        plan: 'Plano por Ato',
      ),
      preAnalysis: PreAnalysis(
        priority: 'High',
        tag: 'Análise Preliminar por IA',
        tagColor: Colors.deepPurple,
        estimatedTime: '15 dias úteis',
        urgency: 8,
        summary: 'Com base nas informações fornecidas, identifica-se uma possível demissão sem justa causa...',
        requiredDocs: [
          'Contrato de trabalho',
          'Carta de demissão',
          'Comprovantes de pagamento',
        ],
        costs: [
          CostEstimate(label: 'Consulta', value: 'R\$ 350,00'),
          CostEstimate(label: 'Representação', value: 'R\$ 2.500,00'),
        ],
        risk: 'Risco baixo. Documentação sólida e jurisprudência favorável.',
      ),
      nextSteps: [
        NextStep(
          title: 'Enviar documentos',
          description: 'Contrato de trabalho, carta de demissão e comprovantes',
          dueDate: '24/01/2024',
          priority: 'HIGH',
          status: 'PENDING'
        ),
        NextStep(
          title: 'Análise dos documentos',
          description: 'Advogado analisará a documentação enviada',
          dueDate: '27/01/2024',
          priority: 'MEDIUM',
          status: 'PENDING'
        ),
      ],
      documents: [
        DocumentItem(name: 'Relatório da Consulta', sizeDate: '2.3 MB • 16/01/2024'),
        DocumentItem(name: 'Modelo de Petição', sizeDate: '1.1 MB • 17/01/2024'),
      ],
    );
  }
} 