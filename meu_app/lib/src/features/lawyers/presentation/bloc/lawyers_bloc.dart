import 'package:bloc/bloc.dart';
import 'dart:async';

part 'lawyers_event.dart';
part 'lawyers_state.dart';

class LawyersBloc extends Bloc<LawyersEvent, LawyersState> {
  // final FindLawyersUseCase findLawyersUseCase;
  // final ExplainMatchUseCase explainMatchUseCase;

  LawyersBloc(/*{
    required this.findLawyersUseCase,
    required this.explainMatchUseCase,
  }*/) : super(LawyersInitial()) {
    on<FetchLawyers>(_onFetchLawyers);
    on<ExplainMatch>(_onExplainMatch);
  }

  Future<void> _onFetchLawyers(FetchLawyers event, Emitter<LawyersState> emit) async {
    emit(LawyersLoading());
    try {
      // Mock da chamada da API
      await Future.delayed(const Duration(seconds: 1));
      final mockLawyers = [
        {
          "lawyer_id": "lw-001", "nome": "Dr. João Silva", "fair": 0.95, "primary_area": "Trabalhista",
          "rating": 4.8, "distance_km": 2.5, "is_available": true, "avatar_url": "https://i.pravatar.cc/150?u=lw-001"
        },
        {
          "lawyer_id": "lw-002", "nome": "Dra. Maria Santos", "fair": 0.92, "primary_area": "Cível",
          "rating": 4.9, "distance_km": 5.1, "is_available": false, "avatar_url": "https://i.pravatar.cc/150?u=lw-002"
        },
      ];
      emit(LawyersLoaded(mockLawyers));
    } catch (e) {
      emit(const LawyersError('Falha ao buscar advogados.'));
    }
  }

  Future<void> _onExplainMatch(ExplainMatch event, Emitter<LawyersState> emit) async {
    try {
       // Mock da chamada da API
      await Future.delayed(const Duration(milliseconds: 500));
      const explanation = "Dr. João Silva é uma excelente opção! Com 95% de compatibilidade e alta taxa de sucesso em casos trabalhistas similares, ele está bem preparado para te ajudar. Além disso, seu escritório fica próximo a você.";
      
      // Encontrar o advogado na lista atual para passar para o modal
      if (state is LawyersLoaded) {
        final currentState = state as LawyersLoaded;
        final lawyer = currentState.lawyers.firstWhere((l) => l['lawyer_id'] == event.lawyerId, orElse: () => {});
        if(lawyer.isNotEmpty) {
           emit(ExplanationLoaded(explanation, lawyer));
        }
      }
    } catch (e) {
      // Tratar erro se a explicação falhar
    }
  }
} 