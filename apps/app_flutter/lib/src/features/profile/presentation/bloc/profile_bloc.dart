import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/core/services/social_auth_service.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/entities/client_profile.dart';
import '../../../../core/error/failures.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;
  final SocialAuthService socialAuthService;
  String? currentUserId;

  ProfileBloc({
    required this.profileRepository,
    required this.socialAuthService,
  }) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<LoadSocialProfiles>(_onLoadSocialProfiles);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdatePersonalData>(_onUpdatePersonalData);
    on<UpdateContactData>(_onUpdateContactData);
    on<UpdateAddresses>(_onUpdateAddresses);
    on<AddDocument>(_onAddDocument);
    on<RemoveDocument>(_onRemoveDocument);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    
    currentUserId = event.userId;
    
    final result = await profileRepository.getProfile(event.userId);
    
    result.fold(
      (failure) => emit(ProfileError(_getFailureMessage(failure))),
      (profile) {
        emit(ProfileLoaded(profile));
        // Dispara o carregamento dos perfis sociais em sequência
        add(const LoadSocialProfiles());
      },
    );
  }

  Future<void> _onLoadSocialProfiles(
    LoadSocialProfiles event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      try {
        final socialData = await socialAuthService.getMySocialProfiles();
        if (socialData['success'] == true) {
          emit(currentState.copyWith(socialProfiles: socialData['profiles']));
        }
      } catch (e) {
        // Opcional: pode-se emitir um erro específico para dados sociais
        // ou simplesmente ignorar se não for crítico.
        print("Erro ao carregar perfis sociais: $e");
      }
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    
    final result = await profileRepository.updateProfile(event.profile);
    
    result.fold(
      (failure) => emit(ProfileError(_getFailureMessage(failure))),
      (profile) {
        // Mantém os dados sociais existentes ao atualizar o perfil
        final socialProfiles = state is ProfileLoaded ? (state as ProfileLoaded).socialProfiles : null;
        emit(ProfileUpdated(profile));
        emit(ProfileLoaded(profile, socialProfiles: socialProfiles));
      },
    );
  }

  Future<void> _onUpdatePersonalData(
    UpdatePersonalData event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      emit(ProfileLoading());
      
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedProfile = currentProfile.copyWith(
        personalData: event.personalData,
        updatedAt: DateTime.now(),
      );
      
      final result = await profileRepository.updateProfile(updatedProfile);
      
      result.fold(
        (failure) => emit(ProfileError(_getFailureMessage(failure))),
        (profile) {
          final socialProfiles = (state as ProfileLoaded).socialProfiles;
          emit(ProfileUpdated(profile));
          emit(ProfileLoaded(profile, socialProfiles: socialProfiles));
        },
      );
    }
  }

  Future<void> _onUpdateContactData(
    UpdateContactData event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      emit(ProfileLoading());
      
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedProfile = currentProfile.copyWith(
        contactData: event.contactData,
        updatedAt: DateTime.now(),
      );
      
      final result = await profileRepository.updateProfile(updatedProfile);
      
      result.fold(
        (failure) => emit(ProfileError(_getFailureMessage(failure))),
        (profile) {
          final socialProfiles = (state as ProfileLoaded).socialProfiles;
          emit(ProfileUpdated(profile));
          emit(ProfileLoaded(profile, socialProfiles: socialProfiles));
        },
      );
    }
  }

  Future<void> _onUpdateAddresses(
    UpdateAddresses event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      emit(ProfileLoading());
      
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedProfile = currentProfile.copyWith(
        addresses: event.addresses,
        updatedAt: DateTime.now(),
      );
      
      final result = await profileRepository.updateProfile(updatedProfile);
      
      result.fold(
        (failure) => emit(ProfileError(_getFailureMessage(failure))),
        (profile) {
          final socialProfiles = (state as ProfileLoaded).socialProfiles;
          emit(ProfileUpdated(profile));
          emit(ProfileLoaded(profile, socialProfiles: socialProfiles));
        },
      );
    }
  }

  Future<void> _onAddDocument(
    AddDocument event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded && currentUserId != null) {
      emit(ProfileLoading());
      
      // Primeiro, fazer upload do documento
      final uploadResult = await profileRepository.uploadDocument(
        clientId: currentUserId!,
        type: event.document.type,
        filePath: event.document.filePath,
        originalFileName: event.document.originalFileName,
        metadata: event.document.metadata,
      );
      
      uploadResult.fold(
        (failure) => emit(ProfileError(_getFailureMessage(failure))),
        (uploadedDocument) {
          // Então, atualizar o perfil com o novo documento
          final currentProfile = (state as ProfileLoaded).profile;
          final updatedDocuments = [...currentProfile.documents, uploadedDocument];
          final updatedProfile = currentProfile.copyWith(
            documents: updatedDocuments,
            updatedAt: DateTime.now(),
          );
          
          _updateProfileAndEmit(updatedProfile, emit);
        },
      );
    }
  }

  Future<void> _onRemoveDocument(
    RemoveDocument event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      emit(ProfileLoading());
      
      // Primeiro, excluir o documento do servidor
      final deleteResult = await profileRepository.deleteDocument(event.documentId);
      
      deleteResult.fold(
        (failure) => emit(ProfileError(_getFailureMessage(failure))),
        (_) {
          // Então, atualizar o perfil removendo o documento
          final currentProfile = (state as ProfileLoaded).profile;
          final updatedDocuments = currentProfile.documents
              .where((doc) => doc.id != event.documentId)
              .toList();
          final updatedProfile = currentProfile.copyWith(
            documents: updatedDocuments,
            updatedAt: DateTime.now(),
          );
          
          _updateProfileAndEmit(updatedProfile, emit);
        },
      );
    }
  }

  Future<void> _updateProfileAndEmit(
    ClientProfile profile,
    Emitter<ProfileState> emit,
  ) async {
    final result = await profileRepository.updateProfile(profile);
    
    result.fold(
      (failure) => emit(ProfileError(_getFailureMessage(failure))),
      (updatedProfile) {
        final socialProfiles = state is ProfileLoaded ? (state as ProfileLoaded).socialProfiles : null;
        emit(ProfileUpdated(updatedProfile));
        emit(ProfileLoaded(updatedProfile, socialProfiles: socialProfiles));
      },
    );
  }

  String _getFailureMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Erro do servidor. Tente novamente.';
      case CacheFailure:
        return 'Erro no cache local.';
      case ValidationFailure:
        return failure.message;
      case NetworkFailure:
        return 'Erro de conectividade. Verifique sua internet.';
      case AuthFailure:
        return 'Erro de autenticação. Faça login novamente.';
      default:
        return 'Erro inesperado: ${failure.message}';
    }
  }
}