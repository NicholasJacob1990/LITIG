import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/matches_bloc.dart';
import 'package:meu_app/src/core/enums/legal_areas.dart';

class LawyerSearchForm extends StatefulWidget {
  const LawyerSearchForm({super.key});

  @override
  State<LawyerSearchForm> createState() => _LawyerSearchFormState();
}

class _LawyerSearchFormState extends State<LawyerSearchForm> {
  final _searchController = TextEditingController();
  final _locationController = TextEditingController();
  LegalArea? _selectedLegalArea;
  RangeValues _priceRange = const RangeValues(100, 1000);
  double _minRating = 0.0;

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _performSearch() {
    context.read<MatchesBloc>().add(
      SearchLawyers(
        query: _searchController.text,
        location: _locationController.text,
        legalArea: _selectedLegalArea,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        minRating: _minRating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de busca principal
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar advogados',
                hintText: 'Ex: direito civil, divórcio, trabalhista...',
                prefixIcon: Icon(LucideIcons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            
            const SizedBox(height: 16),
            
            // Campo de localização
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Localização',
                hintText: 'Ex: São Paulo, SP',
                prefixIcon: Icon(LucideIcons.mapPin),
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dropdown de área jurídica
            DropdownButtonFormField<LegalArea>(
              value: _selectedLegalArea,
              decoration: const InputDecoration(
                labelText: 'Área Jurídica',
                prefixIcon: Icon(LucideIcons.scale),
                border: OutlineInputBorder(),
              ),
              items: LegalArea.values.map((area) {
                return DropdownMenuItem(
                  value: area,
                  child: Text(area.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLegalArea = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Faixa de preço
            Text(
              'Faixa de Preço por Hora',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: _priceRange,
              min: 50,
              max: 2000,
              divisions: 39,
              labels: RangeLabels(
                'R\$ ${_priceRange.start.round()}',
                'R\$ ${_priceRange.end.round()}',
              ),
              onChanged: (values) {
                setState(() {
                  _priceRange = values;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Avaliação mínima
            Text(
              'Avaliação Mínima: ${_minRating.toStringAsFixed(1)} ⭐',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: _minRating,
              min: 0,
              max: 5,
              divisions: 10,
              onChanged: (value) {
                setState(() {
                  _minRating = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Botão de busca
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(LucideIcons.search),
                label: const Text('Buscar Advogados'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}