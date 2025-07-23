import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/client_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_data_source.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;
  
  const ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, ClientProfile>> getProfile(String userId) async {
    try {
      // Tentar buscar do cache local primeiro
      try {
        final cachedProfile = await localDataSource.getProfile(userId);
        if (cachedProfile != null) {
          // Sincronizar em background se necessário
          _syncProfileInBackground(userId);
          return Right(cachedProfile);
        }
      } catch (e) {
        // Se cache falhar, continuar para busca remota
      }
      
      // Buscar do servidor remoto
      final remoteProfile = await remoteDataSource.getProfile(userId);
      
      // Salvar no cache local
      await localDataSource.cacheProfile(remoteProfile);
      
      return Right(remoteProfile);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro do servidor'));
    } on CacheException {
      return const Left(CacheFailure(message: 'Erro no cache'));
    } catch (e) {
      return Left(GenericFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ClientProfile>> updateProfile(ClientProfile profile) async {
    try {
      // Validar dados antes de enviar
      final validationFailure = _validateProfile(profile);
      if (validationFailure != null) {
        return Left(validationFailure);
      }
      
      // Atualizar no servidor
      final updatedProfile = await remoteDataSource.updateProfile(profile);
      
      // Atualizar cache local
      await localDataSource.cacheProfile(updatedProfile);
      
      return Right(updatedProfile);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro do servidor'));
    } on ValidationException {
      return const Left(ValidationFailure(message: 'Erro de validação'));
    } catch (e) {
      return Left(GenericFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Document>> uploadDocument({
    required String clientId,
    required DocumentType type,
    required String filePath,
    required String originalFileName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validar arquivo
      final file = File(filePath);
      if (!await file.exists()) {
        return const Left(ValidationFailure(message: 'Arquivo não encontrado'));
      }
      
      final fileSize = await file.length();
      const maxSize = 10 * 1024 * 1024; // 10MB
      
      if (fileSize > maxSize) {
        return const Left(ValidationFailure(message: 'Arquivo muito grande. Máximo 10MB.'));
      }
      
      // Fazer upload
      final document = await remoteDataSource.uploadDocument(
        clientId: clientId,
        type: type,
        filePath: filePath,
        originalFileName: originalFileName,
        metadata: metadata,
      );
      
      // Atualizar cache local
      await localDataSource.cacheDocument(document);
      
      return Right(document);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro do servidor'));
    } on ValidationException {
      return const Left(ValidationFailure(message: 'Erro de validação'));
    } catch (e) {
      return Left(GenericFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDocument(String documentId) async {
    try {
      await remoteDataSource.deleteDocument(documentId);
      await localDataSource.removeDocument(documentId);
      return const Right(null);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro do servidor'));
    } catch (e) {
      return Left(GenericFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Document>>> getDocuments(String clientId) async {
    try {
      // Tentar buscar do cache primeiro
      try {
        final cachedDocuments = await localDataSource.getDocuments(clientId);
        if (cachedDocuments.isNotEmpty) {
          _syncDocumentsInBackground(clientId);
          return Right(cachedDocuments);
        }
      } catch (e) {
        // Continuar para busca remota se cache falhar
      }
      
      final documents = await remoteDataSource.getDocuments(clientId);
      
      // Salvar no cache
      for (final document in documents) {
        await localDataSource.cacheDocument(document);
      }
      
      return Right(documents);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro do servidor'));
    } catch (e) {
      return Left(GenericFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Document>> verifyDocument(String documentId) async {
    try {
      final verifiedDocument = await remoteDataSource.verifyDocument(documentId);
      await localDataSource.cacheDocument(verifiedDocument);
      return Right(verifiedDocument);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro do servidor'));
    } catch (e) {
      return Left(GenericFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCommunicationPreferences({
    required String clientId,
    required CommunicationPreferences preferences,
  }) async {
    try {
      await remoteDataSource.updateCommunicationPreferences(
        clientId: clientId,
        preferences: preferences,
      );
      
      // Atualizar cache local
      await localDataSource.cacheCommunicationPreferences(clientId, preferences);
      
      return const Right(null);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro do servidor'));
    } catch (e) {
      return Left(GenericFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePrivacySettings({
    required String clientId,
    required PrivacySettings settings,
  }) async {
    try {
      await remoteDataSource.updatePrivacySettings(
        clientId: clientId,
        settings: settings,
      );
      
      await localDataSource.cachePrivacySettings(clientId, settings);
      
      return const Right(null);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro do servidor'));
    } catch (e) {
      return Left(GenericFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> exerciseDataSubjectRight({
    required String clientId,
    required String rightType,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await remoteDataSource.exerciseDataSubjectRight(
        clientId: clientId,
        rightType: rightType,
        parameters: parameters,
      );
      
      return const Right(null);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro do servidor'));
    } catch (e) {
      return Left(GenericFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> exportClientData(String clientId) async {
    try {
      final exportedData = await remoteDataSource.exportClientData(clientId);
      return Right(exportedData);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro do servidor'));
    } catch (e) {
      return Left(GenericFailure(message: e.toString()));
    }
  }

  // Métodos privados auxiliares
  
  ValidationFailure? _validateProfile(ClientProfile profile) {
    // Validações básicas
    if (profile.id.isEmpty) {
      return const ValidationFailure(message: 'ID do perfil é obrigatório');
    }
    
    // Validação específica por tipo de cliente
    if (profile.type == ClientType.individual) {
      if (profile.personalData.cpf?.isEmpty ?? true) {
        return const ValidationFailure(message: 'CPF é obrigatório para pessoa física');
      }
    } else {
      if (profile.personalData.cnpj?.isEmpty ?? true) {
        return const ValidationFailure(message: 'CNPJ é obrigatório para pessoa jurídica');
      }
    }
    
    return null;
  }
  
  void _syncProfileInBackground(String userId) {
    // Sincronização em background sem bloquear UI
    Future.microtask(() async {
      try {
        final remoteProfile = await remoteDataSource.getProfile(userId);
        await localDataSource.cacheProfile(remoteProfile);
      } catch (e) {
        // Log error mas não propagar
        print('Background sync failed: $e');
      }
    });
  }
  
  void _syncDocumentsInBackground(String clientId) {
    Future.microtask(() async {
      try {
        final documents = await remoteDataSource.getDocuments(clientId);
        for (final document in documents) {
          await localDataSource.cacheDocument(document);
        }
      } catch (e) {
        print('Documents background sync failed: $e');
      }
    });
  }
}

// Exceptions customizadas
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
}