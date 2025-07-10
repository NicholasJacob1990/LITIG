part of 'case_detail_bloc.dart';

abstract class CaseDetailState {
  const CaseDetailState();
}

class CaseDetailInitial extends CaseDetailState {}

class CaseDetailLoading extends CaseDetailState {}

class CaseDetailLoaded extends CaseDetailState {
  final Map<String, dynamic> caseDetails;
  const CaseDetailLoaded(this.caseDetails);
}

class CaseDetailError extends CaseDetailState {
  final String message;
  const CaseDetailError(this.message);
}

class DocumentUploading extends CaseDetailState {}

class DocumentUploadSuccess extends CaseDetailState {}

class DocumentUploadError extends CaseDetailState {
  final String message;
  const DocumentUploadError(this.message);
} 