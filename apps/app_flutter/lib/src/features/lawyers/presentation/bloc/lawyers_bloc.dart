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
      // Dados mock dos advogados
      const mockLawyers = [
        {"id": "lw-001", "name": "Dra. Ana Costa", "specialties": ["Trabalhista", "Cível"], "rating": 4.8, "distance_km": 2.5, "is_available": true, "avatar_url": "https://ui-avatars.com/api/?name=Ana+Costa&background=3B82F6&color=fff"},
        {"id": "lw-002", "name": "Dr. Bruno Martins", "specialties": ["Criminal", "Família"], "rating": 4.9, "distance_km": 5.1, "is_available": false, "avatar_url": "https://ui-avatars.com/api/?name=Bruno+Martins&background=10B981&color=fff"},
        {"id": "lw-003", "name": "Dra. Carla Dias", "specialties": ["Consumidor"], "rating": 4.7, "distance_km": 8.0, "is_available": true, "avatar_url": "https://ui-avatars.com/api/?name=Carla+Dias&background=F59E0B&color=fff"},
        {"id": "lw-004", "name": "Dr. Daniel Farias", "specialties": ["Trabalhista", "Previdenciário"], "rating": 4.8, "distance_km": 12.3, "is_available": true, "avatar_url": "https://ui-avatars.com/api/?name=Daniel+Farias&background=8B5CF6&color=fff"},
      ];
      emit(const LawyersLoaded(mockLawyers));
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