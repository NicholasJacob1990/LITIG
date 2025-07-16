part of 'case_documents_bloc.dart';

abstract class CaseDocumentsState extends Equatable {
  const CaseDocumentsState();
}

class CaseDocumentsInitial extends CaseDocumentsState {
  @override
  List<Object> get props => [];
}

class CaseDocumentsLoading extends CaseDocumentsState {
  @override
  List<Object> get props => [];
}

class CaseDocumentsLoaded extends CaseDocumentsState {
  final List<CaseDocument> documents;

  const CaseDocumentsLoaded({required this.documents});

  @override
  List<Object> get props => [documents];
}

class CaseDocumentsError extends CaseDocumentsState {
  final String message;

  const CaseDocumentsError({required this.message});

  @override
  List<Object> get props => [message];
}

class DocumentUploading extends CaseDocumentsState {
  @override
  List<Object> get props => [];
}

class DocumentUploadSuccess extends CaseDocumentsState {
  final CaseDocument document;

  const DocumentUploadSuccess({required this.document});

  @override
  List<Object> get props => [document];
}

class DocumentUploadError extends CaseDocumentsState {
  final String message;

  const DocumentUploadError({required this.message});

  @override
  List<Object> get props => [message];
} 