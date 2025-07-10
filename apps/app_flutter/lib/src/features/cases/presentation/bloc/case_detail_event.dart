part of 'case_detail_bloc.dart';

abstract class CaseDetailEvent {
  const CaseDetailEvent();
}

class FetchCaseDetails extends CaseDetailEvent {
  final String caseId;
  const FetchCaseDetails({required this.caseId});
}

class UploadDocument extends CaseDetailEvent {
  final String caseId;
  final String filePath;
  const UploadDocument({required this.caseId, required this.filePath});
} 