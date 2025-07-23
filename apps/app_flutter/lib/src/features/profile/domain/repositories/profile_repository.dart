import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/client_profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ClientProfile>> getProfile(String userId);
  Future<Either<Failure, ClientProfile>> updateProfile(ClientProfile profile);
  Future<Either<Failure, Document>> uploadDocument({
    required String clientId,
    required DocumentType type,
    required String filePath,
    required String originalFileName,
    Map<String, dynamic>? metadata,
  });
  Future<Either<Failure, void>> deleteDocument(String documentId);
  Future<Either<Failure, List<Document>>> getDocuments(String clientId);
  Future<Either<Failure, Document>> verifyDocument(String documentId);
  Future<Either<Failure, void>> updateCommunicationPreferences({
    required String clientId,
    required CommunicationPreferences preferences,
  });
  Future<Either<Failure, void>> updatePrivacySettings({
    required String clientId,
    required PrivacySettings settings,
  });
  Future<Either<Failure, void>> exerciseDataSubjectRight({
    required String clientId,
    required String rightType,
    Map<String, dynamic>? parameters,
  });
  Future<Either<Failure, Map<String, dynamic>>> exportClientData(String clientId);
}