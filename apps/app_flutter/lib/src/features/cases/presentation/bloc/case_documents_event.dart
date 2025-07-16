part of 'case_documents_bloc.dart';

abstract class CaseDocumentsEvent extends Equatable {
  const CaseDocumentsEvent();
}

class LoadCaseDocuments extends CaseDocumentsEvent {
  final String caseId;

  const LoadCaseDocuments(this.caseId);

  @override
  List<Object> get props => [caseId];
}

class UploadDocument extends CaseDocumentsEvent {
  final String caseId;
  final String fileName;
  final List<int> fileBytes;
  final String category;

  const UploadDocument({
    required this.caseId,
    required this.fileName,
    required this.fileBytes,
    required this.category,
  });

  @override
  List<Object> get props => [caseId, fileName, fileBytes, category];
}

class DeleteDocument extends CaseDocumentsEvent {
  final String caseId;
  final String documentId;
  final String documentName;

  const DeleteDocument({
    required this.caseId,
    required this.documentId,
    required this.documentName,
  });

  @override
  List<Object> get props => [caseId, documentId, documentName];
}

class RefreshDocuments extends CaseDocumentsEvent {
  final String caseId;

  const RefreshDocuments(this.caseId);

  @override
  List<Object> get props => [caseId];
} 