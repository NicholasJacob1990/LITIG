import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_preset_entity.dart';
import '../repositories/sla_settings_repository.dart';

class UpdateSlaSettingsUseCase implements UseCase<SlaPresetEntity, UpdateSlaSettingsParams> {
  final SlaSettingsRepository repository;

  UpdateSlaSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, SlaPresetEntity>> call(UpdateSlaSettingsParams params) async {
    return await repository.updateSettings(
      firmId: params.firmId,
      settings: params.settings,
    );
  }
}

class UpdateSlaSettingsParams {
  final String firmId;
  final SlaPresetEntity settings;

  UpdateSlaSettingsParams({
    required this.firmId,
    required this.settings,
  });
}