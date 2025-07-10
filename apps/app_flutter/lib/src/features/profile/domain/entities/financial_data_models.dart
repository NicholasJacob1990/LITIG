
// --- Modelos de Dados Financeiros ---

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


// --- Tipos de Honorários ---

enum ContractualStatus { pending, partial, paid, overdue }

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


enum SuccessStatus { inProgress, partial, completed, failed }

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


enum AttorneyStatus { sentenced, transited, requested, repassed }

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