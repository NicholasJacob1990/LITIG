import 'package:flutter_bloc/flutter_bloc.dart';
import 'firm_profile_event.dart';
import 'firm_profile_state.dart';
import '../../domain/usecases/get_enriched_firm.dart';

class FirmProfileBloc extends Bloc<FirmProfileEvent, FirmProfileState> {
  final GetEnrichedFirmUseCase _getEnrichedFirm;
  final RefreshEnrichedFirmUseCase _refreshEnrichedFirm;

  FirmProfileBloc({
    required GetEnrichedFirmUseCase getEnrichedFirm,
    required RefreshEnrichedFirmUseCase refreshEnrichedFirm,
  }) : _getEnrichedFirm = getEnrichedFirm,
       _refreshEnrichedFirm = refreshEnrichedFirm,
       super(FirmProfileInitial()) {
    on<LoadFirmProfile>(_onLoadFirmProfile);
    on<RefreshFirmProfile>(_onRefreshFirmProfile);
  }

  Future<void> _onLoadFirmProfile(
    LoadFirmProfile event,
    Emitter<FirmProfileState> emit,
  ) async {
    emit(FirmProfileLoading());
    try {
      final enrichedFirm = await _getEnrichedFirm(event.firmId);
      emit(FirmProfileLoaded(enrichedFirm: enrichedFirm));
    } catch (e) {
      emit(FirmProfileError(message: e.toString()));
    }
  }

  Future<void> _onRefreshFirmProfile(
    RefreshFirmProfile event,
    Emitter<FirmProfileState> emit,
  ) async {
    emit(FirmProfileLoading());
    try {
      final enrichedFirm = await _refreshEnrichedFirm(event.firmId);
      emit(FirmProfileLoaded(enrichedFirm: enrichedFirm));
    } catch (e) {
      emit(FirmProfileError(message: e.toString()));
    }
  }
} 