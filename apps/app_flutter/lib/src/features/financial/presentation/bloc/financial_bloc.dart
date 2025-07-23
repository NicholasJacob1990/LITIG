import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_financial_data.dart';
import '../../domain/usecases/export_financial_data.dart' as export_usecase;
import '../../domain/usecases/mark_payment_received.dart' as mark_usecase;
import '../../domain/usecases/request_payment_repass.dart' as repass_usecase;
import 'financial_event.dart';
import 'financial_state.dart';

class FinancialBloc extends Bloc<FinancialEvent, FinancialState> {
  final GetFinancialData _getFinancialData;
  final export_usecase.ExportFinancialData _exportFinancialData;
  final mark_usecase.MarkPaymentReceived _markPaymentReceived;
  final repass_usecase.RequestPaymentRepass _requestPaymentRepass;

  FinancialBloc({
    required GetFinancialData getFinancialData,
    required export_usecase.ExportFinancialData exportFinancialData,
    required mark_usecase.MarkPaymentReceived markPaymentReceived,
    required repass_usecase.RequestPaymentRepass requestPaymentRepass,
  })  : _getFinancialData = getFinancialData,
        _exportFinancialData = exportFinancialData,
        _markPaymentReceived = markPaymentReceived,
        _requestPaymentRepass = requestPaymentRepass,
        super(const FinancialInitial()) {
    on<LoadFinancialData>(_onLoadFinancialData);
    on<ExportFinancialData>(_onExportFinancialData);
    on<MarkPaymentReceived>(_onMarkPaymentReceived);
    on<RequestPaymentRepass>(_onRequestPaymentRepass);
    on<RefreshFinancialData>(_onRefreshFinancialData);
  }

  Future<void> _onLoadFinancialData(
    LoadFinancialData event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());

    final result = await _getFinancialData(
      GetFinancialDataParams(
        period: event.period,
        feeType: event.feeType,
      ),
    );

    result.fold(
      (failure) => emit(FinancialError(message: failure.message)),
      (data) => emit(FinancialLoaded(data: data)),
    );
  }

  Future<void> _onExportFinancialData(
    ExportFinancialData event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialExporting());

    final result = await _exportFinancialData(
      export_usecase.ExportFinancialDataParams(
        format: event.format,
        period: event.period,
      ),
    );

    result.fold(
      (failure) => emit(FinancialError(message: failure.message)),
      (_) => emit(const FinancialExported()),
    );
  }

  Future<void> _onMarkPaymentReceived(
    MarkPaymentReceived event,
    Emitter<FinancialState> emit,
  ) async {
    final result = await _markPaymentReceived(
      mark_usecase.MarkPaymentReceivedParams(
        paymentId: event.paymentId,
      ),
    );

    result.fold(
      (failure) => emit(FinancialError(message: failure.message)),
      (_) => emit(const PaymentMarkedReceived()),
    );
  }

  Future<void> _onRequestPaymentRepass(
    RequestPaymentRepass event,
    Emitter<FinancialState> emit,
  ) async {
    final result = await _requestPaymentRepass(
      repass_usecase.RequestPaymentRepassParams(
        paymentId: event.paymentId,
      ),
    );

    result.fold(
      (failure) => emit(FinancialError(message: failure.message)),
      (_) => emit(const PaymentRepassRequested()),
    );
  }

  Future<void> _onRefreshFinancialData(
    RefreshFinancialData event,
    Emitter<FinancialState> emit,
  ) async {
    emit(const FinancialLoading());

    final result = await _getFinancialData(
      const GetFinancialDataParams(),
    );

    result.fold(
      (failure) => emit(FinancialError(message: failure.message)),
      (data) => emit(FinancialLoaded(data: data)),
    );
  }
} 