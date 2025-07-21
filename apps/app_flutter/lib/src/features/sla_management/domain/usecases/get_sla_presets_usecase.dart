import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_preset_entity.dart';
import '../repositories/sla_settings_repository.dart';

class GetSlaPresetsUseCase implements UseCase<List<SlaPresetEntity>, GetSlaPresetsParams> {
  final SlaSettingsRepository repository;

  GetSlaPresetsUseCase(this.repository);

  @override
  Future<Either<Failure, List<SlaPresetEntity>>> call(GetSlaPresetsParams params) async {
    return await repository.getPresets(
      firmId: params.firmId,
      includeSystemPresets: params.includeSystemPresets,
    );
  }
}

class GetSlaPresetsParams {
  final String firmId;
  final bool includeSystemPresets;

  GetSlaPresetsParams({
    required this.firmId,
    this.includeSystemPresets = true,
  });
}