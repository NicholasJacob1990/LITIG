# 💰 Implementação Financeira - Advogado Flutter

## 📊 Visão Geral

A seção financeira do advogado foi projetada para gerenciar três tipos distintos de honorários, sem cobrança por hora, oferecendo uma visão completa e organizada da receita profissional.

## 🏗️ Arquitetura da Seção Financeira

### Estrutura de Dados

```dart
// features/profile/domain/entities/financial_data.dart
class FinancialData {
  final List<ContractualFee> contractualFees;
  final List<SuccessFee> successFees;
  final List<AttorneyFee> attorneyFees;
  final FinancialSummary summary;
  final DateTime lastUpdated;

  const FinancialData({
    required this.contractualFees,
    required this.successFees,
    required this.attorneyFees,
    required this.summary,
    required this.lastUpdated,
  });
}

class FinancialSummary {
  final double totalContractual;
  final double totalSuccess;
  final double totalAttorney;
  final double totalReceived;
  final String period;

  const FinancialSummary({
    required this.totalContractual,
    required this.totalSuccess,
    required this.totalAttorney,
    required this.totalReceived,
    required this.period,
  });
}
```

### Tipos de Honorários

```dart
// features/profile/domain/entities/fee_types.dart

// 1. Honorários Contratuais
class ContractualFee {
  final String id;
  final String caseId;
  final String caseName;
  final double amount;
  final ContractualStatus status;
  final DateTime dueDate;
  final DateTime? receivedDate;
  final String packageType;

  const ContractualFee({
    required this.id,
    required this.caseId,
    required this.caseName,
    required this.amount,
    required this.status,
    required this.dueDate,
    this.receivedDate,
    required this.packageType,
  });
}

enum ContractualStatus { pending, partial, paid, overdue }

// 2. Honorários de Êxito
class SuccessFee {
  final String id;
  final String caseId;
  final String caseName;
  final double percentage;
  final double estimatedAmount;
  final double receivedAmount;
  final SuccessStatus status;
  final DateTime? conclusionDate;

  const SuccessFee({
    required this.id,
    required this.caseId,
    required this.caseName,
    required this.percentage,
    required this.estimatedAmount,
    required this.receivedAmount,
    required this.status,
    this.conclusionDate,
  });
}

enum SuccessStatus { inProgress, partial, completed, failed }

// 3. Honorários Sucumbenciais
class AttorneyFee {
  final String id;
  final String processNumber;
  final double amount;
  final DateTime sentenceDate;
  final DateTime? transitDate;
  final bool repassed;
  final DateTime? repassDate;
  final AttorneyStatus status;

  const AttorneyFee({
    required this.id,
    required this.processNumber,
    required this.amount,
    required this.sentenceDate,
    this.transitDate,
    required this.repassed,
    this.repassDate,
    required this.status,
  });
}

enum AttorneyStatus { sentenced, transited, requested, repassed }
```

## 🎨 Interface de Usuário

### Tela Principal Financeira

```dart
// features/profile/presentation/screens/financial_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({Key? key}) : super(key: key);

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  String selectedPeriod = 'Mês Atual';
  String selectedFeeType = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: BlocBuilder<FinancialBloc, FinancialState>(
        builder: (context, state) {
          if (state is FinancialLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is FinancialError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<FinancialBloc>().add(
                      LoadFinancialData(period: selectedPeriod),
                    ),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (state is FinancialLoaded) {
            return Column(
              children: [
                _buildPeriodSelector(),
                _buildSummaryCards(state.data.summary),
                _buildFilterTabs(),
                Expanded(
                  child: _buildFinancialContent(state.data),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSummaryCards(FinancialSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: FinancialCard(
              title: 'Contratuais',
              amount: summary.totalContractual,
              color: const Color(0xFF3B82F6), // Azul
              icon: Icons.description,
              onTap: () => _navigateToDetail('contractual'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FinancialCard(
              title: 'Honorários de Êxito',
              amount: summary.totalSuccess,
              color: const Color(0xFF10B981), // Verde
              icon: Icons.trending_up,
              onTap: () => _navigateToDetail('success'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FinancialCard(
              title: 'Sucumbenciais',
              amount: summary.totalAttorney,
              color: const Color(0xFFF59E0B), // Amarelo/Dourado
              icon: Icons.gavel,
              onTap: () => _navigateToDetail('attorney'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          'Todos',
          'Contratuais',
          'Êxito',
          'Sucumbenciais',
        ].map((type) {
          final isSelected = selectedFeeType == type;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(type),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      selectedFeeType = type;
                    });
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFinancialContent(FinancialData data) {
    switch (selectedFeeType) {
      case 'Contratuais':
        return ContractualFeesSection(fees: data.contractualFees);
      case 'Êxito':
        return SuccessFeesSection(fees: data.successFees);
      case 'Sucumbenciais':
        return AttorneyFeesSection(fees: data.attorneyFees);
      default:
        return AllFeesSection(data: data);
    }
  }
}
```

### Componente do Card Financeiro

```dart
// features/profile/presentation/widgets/financial_card.dart
class FinancialCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const FinancialCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const cardBackgroundColor = Color(0xFF1F2937);
    const primaryTextColor = Color(0xFFFFFFFF);
    const borderColor = Color(0xFF374151);

    return Card(
      elevation: 4,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 160, // Altura fixa para consistência
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(amount),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
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

  String _formatCurrency(double amount) {
    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
```

## �� Seções Detalhadas

### 1. Honorários Contratuais

```dart
// features/profile/presentation/widgets/contractual_fees_section.dart
class ContractualFeesSection extends StatelessWidget {
  final List<ContractualFee> fees;

  const ContractualFeesSection({Key? key, required this.fees}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildBarChart(),
        _buildFeesList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.description, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          const Text(
            'Honorários Contratuais',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _exportContractual(),
            icon: const Icon(Icons.download),
            label: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF374151), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Evolução Mensal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ContractualBarChart(fees: fees),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeesList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: fees.length,
        itemBuilder: (context, index) {
          final fee = fees[index];
          return ContractualFeeCard(
            fee: fee,
            onTap: () => _showFeeDetail(fee),
          );
        },
      ),
    );
  }
}

class ContractualFeeCard extends StatelessWidget {
  final ContractualFee fee;
  final VoidCallback onTap;

  const ContractualFeeCard({
    Key? key,
    required this.fee,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1F2937),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF374151), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.description_outlined,
            color: _getStatusColor(),
          ),
        ),
        title: Text(
          fee.caseName,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pacote: ${fee.packageType}', style: const TextStyle(color: Color(0xFF9CA3AF))),
            Text('Vencimento: ${_formatDate(fee.dueDate)}', style: const TextStyle(color: Color(0xFF9CA3AF))),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatCurrency(fee.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            StatusBadge(
              status: fee.status.name,
              color: _getStatusColor(),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor() {
    switch (fee.status) {
      case ContractualStatus.paid:
        return Colors.green;
      case ContractualStatus.partial:
        return Colors.orange;
      case ContractualStatus.overdue:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
```

### 2. Honorários de Êxito

```dart
// features/profile/presentation/widgets/success_fees_section.dart
class SuccessFeesSection extends StatelessWidget {
  final List<SuccessFee> fees;

  const SuccessFeesSection({Key? key, required this.fees}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildProgressIndicator(),
        _buildFeesList(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final totalEstimated = fees.fold(0.0, (sum, fee) => sum + fee.estimatedAmount);
    final totalReceived = fees.fold(0.0, (sum, fee) => sum + fee.receivedAmount);
    final progress = totalEstimated > 0 ? totalReceived / totalEstimated : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF374151), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progresso Geral',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF374151),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recebido: ${_formatCurrency(totalReceived)}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                  ),
                  Text(
                    'Estimado: ${_formatCurrency(totalEstimated)}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% completado',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeesList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: fees.length,
        itemBuilder: (context, index) {
          final fee = fees[index];
          return SuccessFeeCard(
            fee: fee,
            onMarkReceived: () => _markAsReceived(fee),
          );
        },
      ),
    );
  }
}

class SuccessFeeCard extends StatelessWidget {
  final SuccessFee fee;
  final VoidCallback onMarkReceived;

  const SuccessFeeCard({
    Key? key,
    required this.fee,
    required this.onMarkReceived,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = fee.estimatedAmount > 0 
        ? fee.receivedAmount / fee.estimatedAmount 
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF374151), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fee.caseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${fee.percentage}% Success Fee',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                if (fee.status != SuccessStatus.completed)
                  OutlinedButton(
                    onPressed: onMarkReceived,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                    ),
                    child: const Text('Marcar Recebido'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF374151),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recebido: ${_formatCurrency(fee.receivedAmount)}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                ),
                Text(
                  'Estimado: ${_formatCurrency(fee.estimatedAmount)}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. Honorários Sucumbenciais

```dart
// features/profile/presentation/widgets/attorney_fees_section.dart
class AttorneyFeesSection extends StatelessWidget {
  final List<AttorneyFee> fees;

  const AttorneyFeesSection({Key? key, required this.fees}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildTimeline(),
        _buildFeesList(),
      ],
    );
  }

  Widget _buildTimeline() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF374151), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Timeline de Repasses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AttorneyFeesTimeline(fees: fees),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeesList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: fees.length,
        itemBuilder: (context, index) {
          final fee = fees[index];
          return AttorneyFeeCard(
            fee: fee,
            onRequestRepass: () => _requestRepass(fee),
          );
        },
      ),
    );
  }
}

class AttorneyFeeCard extends StatelessWidget {
  final AttorneyFee fee;
  final VoidCallback onRequestRepass;

  const AttorneyFeeCard({
    Key? key,
    required this.fee,
    required this.onRequestRepass,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF374151), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.gavel_outlined,
            color: Color(0xFFF59E0B),
          ),
        ),
        title: Text(
          'Processo ${fee.processNumber}',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sentença: ${_formatDate(fee.sentenceDate)}', style: const TextStyle(color: Color(0xFF9CA3AF))),
            if (fee.transitDate != null)
              Text('Trânsito: ${_formatDate(fee.transitDate!)}', style: const TextStyle(color: Color(0xFF9CA3AF))),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatCurrency(fee.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            if (!fee.repassed)
              ElevatedButton(
                onPressed: onRequestRepass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  'Solicitar',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
            else
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
```

## 🔄 Gerenciamento de Estado

```dart
// features/profile/presentation/bloc/financial_bloc.dart
class FinancialBloc extends Bloc<FinancialEvent, FinancialState> {
  final GetFinancialDataUseCase _getFinancialData;
  final ExportFinancialDataUseCase _exportFinancialData;
  final MarkSuccessFeeReceivedUseCase _markSuccessFeeReceived;
  final RequestAttorneyFeeRepassUseCase _requestAttorneyFeeRepass;

  FinancialBloc({
    required GetFinancialDataUseCase getFinancialData,
    required ExportFinancialDataUseCase exportFinancialData,
    required MarkSuccessFeeReceivedUseCase markSuccessFeeReceived,
    required RequestAttorneyFeeRepassUseCase requestAttorneyFeeRepass,
  })  : _getFinancialData = getFinancialData,
        _exportFinancialData = exportFinancialData,
        _markSuccessFeeReceived = markSuccessFeeReceived,
        _requestAttorneyFeeRepass = requestAttorneyFeeRepass,
        super(FinancialInitial()) {
    on<LoadFinancialData>(_onLoadFinancialData);
    on<ExportFinancialData>(_onExportFinancialData);
    on<MarkSuccessFeeReceived>(_onMarkSuccessFeeReceived);
    on<RequestAttorneyFeeRepass>(_onRequestAttorneyFeeRepass);
  }

  Future<void> _onLoadFinancialData(
    LoadFinancialData event,
    Emitter<FinancialState> emit,
  ) async {
    emit(FinancialLoading());
    
    final result = await _getFinancialData(
      GetFinancialDataParams(
        period: event.period,
        feeType: event.feeType,
      ),
    );
    
    result.fold(
      (failure) => emit(FinancialError(message: failure.message)),
      (data) => emit(FinancialLoaded(data: data)),
    );
  }

  Future<void> _onMarkSuccessFeeReceived(
    MarkSuccessFeeReceived event,
    Emitter<FinancialState> emit,
  ) async {
    final result = await _markSuccessFeeReceived(
      MarkSuccessFeeReceivedParams(
        feeId: event.feeId,
        amount: event.amount,
      ),
    );
    
    result.fold(
      (failure) => emit(FinancialError(message: failure.message)),
      (_) {
        // Recarregar dados após sucesso
        add(LoadFinancialData(period: 'Mês Atual'));
      },
    );
  }

  Future<void> _onRequestAttorneyFeeRepass(
    RequestAttorneyFeeRepass event,
    Emitter<FinancialState> emit,
  ) async {
    final result = await _requestAttorneyFeeRepass(
      RequestAttorneyFeeRepassParams(feeId: event.feeId),
    );
    
    result.fold(
      (failure) => emit(FinancialError(message: failure.message)),
      (_) {
        // Recarregar dados após sucesso
        add(LoadFinancialData(period: 'Mês Atual'));
      },
    );
  }
}
```

## 🎨 Design System

### Cores Específicas

```dart
// shared/utils/financial_colors.dart
class FinancialColors {
  // Cores de destaque baseadas na paleta do LITGO6
  static const Color contractual = Color(0xFF3B82F6); // Azul
  static const Color success = Color(0xFF10B981);     // Verde
  static const Color attorney = Color(0xFFF59E0B);    // Amarelo/Dourado

  // Cores base do tema escuro
  static const Color background = Color(0xFF111827);
  static const Color surface = Color(0xFF1F2937);
  static const Color border = Color(0xFF374151);
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF9CA3AF);
}
```

### Componentes Reutilizáveis

```dart
// shared/widgets/status_badge.dart
class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const StatusBadge({
    Key? key,
    required this.status,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

## 📱 Notificações e Alertas

```dart
// features/profile/presentation/widgets/financial_notifications.dart
class FinancialNotifications extends StatelessWidget {
  final List<FinancialNotification> notifications;

  const FinancialNotifications({
    Key? key,
    required this.notifications,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pendingCount = notifications.where((n) => !n.isRead).length;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => _showNotificationsModal(context),
        ),
        if (pendingCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                pendingCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NotificationsModal(
        notifications: notifications,
      ),
    );
  }
}
```

## 🔐 Segurança e Validação

```dart
// features/profile/domain/usecases/validate_financial_access.dart
class ValidateFinancialAccessUseCase {
  final AuthRepository _authRepository;

  ValidateFinancialAccessUseCase({required AuthRepository authRepository})
      : _authRepository = authRepository;

  Future<Either<Failure, bool>> call() async {
    try {
      final user = await _authRepository.getCurrentUser();
      
      if (user == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }
      
      if (user.role != UserRole.lawyer) {
        return Left(AuthFailure(message: 'Acesso negado'));
      }
      
      return Right(true);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }
}
```

---

Esta implementação fornece uma base sólida para a seção financeira do advogado, com foco nos três tipos de honorários especificados, interface intuitiva com cores consistentes e funcionalidades completas para gestão financeira profissional. 