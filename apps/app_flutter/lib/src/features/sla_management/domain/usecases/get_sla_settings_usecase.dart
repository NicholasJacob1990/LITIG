import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_preset_entity.dart';
import '../repositories/sla_settings_repository.dart';

class GetSlaSettingsUseCase implements UseCase<SlaPresetEntity, GetSlaSettingsParams> {
  final SlaSettingsRepository repository;

  GetSlaSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, SlaPresetEntity>> call(GetSlaSettingsParams params) async {
    return await repository.getSettings(firmId: params.firmId);
  }
}

class GetSlaSettingsParams {
  final String firmId;

  GetSlaSettingsParams({required this.firmId});
}