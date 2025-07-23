import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/matches_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_match_card.dart';

class MatchesScreen extends StatefulWidget {
  final String? caseId;

  const MatchesScreen({super.key, this.caseId});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String _currentPreset = 'balanced';
  String _sortBy = 'compatibility'; // compatibility, rating, distance

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFiltersModal(),
    );
  }

  Widget _buildFiltersModal() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros e Ordenação',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Preset de Matching
          Text(
            'Tipo de Recomendação',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildPresetChip('balanced', 'Equilibrado'),
              _buildPresetChip('quality', 'Qualidade'),
              _buildPresetChip('speed', 'Rapidez'),
              _buildPresetChip('geographic', 'Proximidade'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Ordenação
          Text(
            'Ordenar Por',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildSortChip('compatibility', 'Compatibilidade', LucideIcons.target),
              _buildSortChip('rating', 'Avaliação', LucideIcons.star),
              _buildSortChip('distance', 'Distância', LucideIcons.mapPin),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Botões de Ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentPreset = 'balanced';
                      _sortBy = 'compatibility';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
          
          // Espaço para SafeArea
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String value, String label) {
    return FilterChip(
      selected: _currentPreset == value,
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          setState(() => _currentPreset = value);
        }
      },
    );
  }

  Widget _buildSortChip(String value, String label, IconData icon) {
    return FilterChip(
      selected: _sortBy == value,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _sortBy = value);
        }
      },
    );
  }

  void _applyFilters() {
    context.read<MatchesBloc>().add(FetchMatches(caseId: widget.caseId));
    // TODO: Implementar filtros no backend call
  }

  List<dynamic> _sortLawyers(List<dynamic> lawyers) {
    switch (_sortBy) {
      case 'rating':
        lawyers.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'distance':
        lawyers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case 'compatibility':
      default:
        lawyers.sort((a, b) => b.fair.compareTo(a.fair));
        break;
    }
    return lawyers;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<MatchesBloc>()..add(FetchMatches(caseId: widget.caseId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Advogados Recomendados'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              onPressed: _showFiltersModal,
              icon: const Icon(LucideIcons.slidersHorizontal),
              tooltip: 'Filtros',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() => _sortBy = value);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'compatibility',
                  child: Row(
                    children: [
                      Icon(LucideIcons.target, size: 16),
                      SizedBox(width: 8),
                      Text('Compatibilidade'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rating',
                  child: Row(
                    children: [
                      Icon(LucideIcons.star, size: 16),
                      SizedBox(width: 8),
                      Text('Avaliação'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'distance',
                  child: Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 16),
                      SizedBox(width: 8),
                      Text('Distância'),
                    ],
                  ),
                ),
              ],
              child: const Icon(LucideIcons.arrowUpDown),
            ),
          ],
        ),
        body: Column(
          children: [
            // Chips de Status dos Filtros
            if (_currentPreset != 'balanced' || _sortBy != 'compatibility')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_currentPreset != 'balanced')
                      Chip(
                        label: Text('Preset: ${_getPresetLabel(_currentPreset)}'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _currentPreset = 'balanced'),
                      ),
                    if (_sortBy != 'compatibility')
                      Chip(
                        label: Text('Ordenação: ${_getSortLabel(_sortBy)}'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _sortBy = 'compatibility'),
                      ),
                  ],
                ),
              ),
            
            // Lista de Advogados
            Expanded(
              child: BlocBuilder<MatchesBloc, MatchesState>(
                builder: (context, state) {
                  if (state is MatchesLoading || state is MatchesInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is MatchesError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao carregar advogados',
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.read<MatchesBloc>().add(FetchMatches(caseId: widget.caseId));
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is MatchesLoaded) {
                    if (state.lawyers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum advogado encontrado',
                                style: Theme.of(context).textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Não encontramos advogados disponíveis para este caso no momento.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final sortedLawyers = _sortLawyers(List.from(state.lawyers));
                    
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: sortedLawyers.length,
                      itemBuilder: (context, index) {
                        final lawyer = sortedLawyers[index];
                        return LawyerMatchCard(
                          lawyer: lawyer,
                          onSelect: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Advogado ${lawyer.nome} selecionado!'),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                            // TODO: Implementar fluxo de contratação
                          },
                          onExplain: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Por que este advogado?'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Compatibilidade: ${(lawyer.fair * 100).toStringAsFixed(1)}%'),
                                    const SizedBox(height: 8),
                                    Text('Taxa de Sucesso: ${(lawyer.features.successRate * 100).toStringAsFixed(1)}%'),
                                    const SizedBox(height: 8),
                                    Text('Soft Skills: ${(lawyer.features.softSkills * 100).toStringAsFixed(1)}%'),
                                    const SizedBox(height: 8),
                                    Text('Distância: ${lawyer.distanceKm.toStringAsFixed(1)} km'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Fechar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  }

                  return const Center(child: Text('Estado não previsto.'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPresetLabel(String preset) {
    switch (preset) {
      case 'quality': return 'Qualidade';
      case 'speed': return 'Rapidez';
      case 'geographic': return 'Proximidade';
      default: return 'Equilibrado';
    }
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'rating': return 'Avaliação';
      case 'distance': return 'Distância';
      default: return 'Compatibilidade';
    }
  }
} 