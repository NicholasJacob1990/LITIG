import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_document.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_case_documents_usecase.dart';
import 'package:meu_app/src/features/cases/domain/usecases/upload_document_usecase.dart';
import 'package:meu_app/src/features/cases/domain/usecases/delete_document_usecase.dart';

part 'case_documents_event.dart';
part 'case_documents_state.dart';

class CaseDocumentsBloc extends Bloc<CaseDocumentsEvent, CaseDocumentsState> {
  final GetCaseDocumentsUseCase getCaseDocumentsUseCase;
  final UploadDocumentUseCase uploadDocumentUseCase;
  final DeleteDocumentUseCase deleteDocumentUseCase;

  CaseDocumentsBloc({
    required this.getCaseDocumentsUseCase,
    required this.uploadDocumentUseCase,
    required this.deleteDocumentUseCase,
  }) : super(CaseDocumentsInitial()) {
    on<LoadCaseDocuments>(_onLoadCaseDocuments);
    on<UploadDocument>(_onUploadDocument);
    on<DeleteDocument>(_onDeleteDocument);
    on<RefreshDocuments>(_onRefreshDocuments);
  }

  Future<void> _onLoadCaseDocuments(
    LoadCaseDocuments event,
    Emitter<CaseDocumentsState> emit,
  ) async {
    emit(CaseDocumentsLoading());
    
    try {
      final documents = await getCaseDocumentsUseCase(event.caseId);
      emit(CaseDocumentsLoaded(documents: documents));
    } catch (e) {
      emit(CaseDocumentsError(message: e.toString()));
    }
  }

  Future<void> _onUploadDocument(
    UploadDocument event,
    Emitter<CaseDocumentsState> emit,
  ) async {
    if (state is CaseDocumentsLoaded) {
      emit(DocumentUploading());
      
      try {
        final newDocument = await uploadDocumentUseCase(
          caseId: event.caseId,
          fileName: event.fileName,
          fileBytes: event.fileBytes,
          category: event.category,
        );
        
        // Recarregar lista completa após upload
        add(LoadCaseDocuments(event.caseId));
        emit(DocumentUploadSuccess(document: newDocument));
      } catch (e) {
        emit(DocumentUploadError(message: e.toString()));
        // Voltar ao estado anterior em caso de erro
        if (state is CaseDocumentsLoaded) {
          emit(state as CaseDocumentsLoaded);
        }
      }
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<CaseDocumentsState> emit,
  ) async {
    if (state is CaseDocumentsLoaded) {
      final currentState = state as CaseDocumentsLoaded;
      
      try {
        await deleteDocumentUseCase(
          caseId: event.caseId,
          documentId: event.documentId,
        );
        
        // Remover documento da lista local
        final updatedDocuments = currentState.documents
            .where((doc) => doc.name != event.documentName)
            .toList();
        
        emit(CaseDocumentsLoaded(documents: updatedDocuments));
      } catch (e) {
        emit(CaseDocumentsError(message: e.toString()));
      }
    }
  }

  Future<void> _onRefreshDocuments(
    RefreshDocuments event,
    Emitter<CaseDocumentsState> emit,
  ) async {
    add(LoadCaseDocuments(event.caseId));
  }
} 