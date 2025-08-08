import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_bloc.dart';
import 'package:meu_app/src/features/search/presentation/bloc/search_event.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';
import 'package:meu_app/src/features/search/presentation/widgets/location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:meu_app/src/core/enums/legal_areas.dart';
import '../../../../shared/services/analytics_service.dart';

class LawyerSearchForm extends StatefulWidget {
  const LawyerSearchForm({super.key});

  @override
  State<LawyerSearchForm> createState() => _LawyerSearchFormState();
}

class _LawyerSearchFormState extends State<LawyerSearchForm> {
  final _searchController = TextEditingController();
  // Localização selecionada
  String? _selectedLocationAddress;
  double? _selectedLatitude;
  double? _selectedLongitude;
  LegalArea? _selectedLegalArea;
  RangeValues _priceRange = const RangeValues(100, 1000);
  double _minRating = 0.0;
  double _radiusKm = 50;
  bool _includeFirms = false;
  
  // Analytics
  late AnalyticsService _analytics;
  DateTime? _searchStartTime;
  Map<String, dynamic> _currentFilters = {};

  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
    _setupSearchListeners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeAnalytics() async {
    _analytics = await AnalyticsService.getInstance();
  }

  void _setupSearchListeners() {
    _searchController.addListener(() {
      if (_searchStartTime == null && _searchController.text.isNotEmpty) {
        _searchStartTime = DateTime.now();
        _trackSearchStart();
      }
    });
  }

  void _trackSearchStart() {
    _analytics.trackSearch(
      'lawyer_search',
      _searchController.text,
      results: [], // Will be filled when results arrive
      searchContext: 'lawyer_search_form',
    );
  }

  void _performSearch() {
    _updateCurrentFilters();
    _trackSearchExecution();
    
    final params = SearchParams(
      query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      preset: 'balanced',
      includeFirms: _includeFirms,
      area: _selectedLegalArea?.name,
      minRating: _minRating,
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      radiusKm: _selectedLatitude != null && _selectedLongitude != null ? _radiusKm : null,
    );

    context.read<SearchBloc>().add(SearchRequested(params));
  }

  void _updateCurrentFilters() {
    _currentFilters = {
      'query': _searchController.text,
      'location': _selectedLocationAddress,
      'legal_area': _selectedLegalArea?.name,
      'min_price': _priceRange.start,
      'max_price': _priceRange.end,
      'min_rating': _minRating,
      'radius_km': _radiusKm,
      'include_firms': _includeFirms,
      'has_location_filter': _selectedLatitude != null && _selectedLongitude != null,
      'has_legal_area_filter': _selectedLegalArea != null,
      'has_price_filter': _priceRange.start > 100 || _priceRange.end < 1000,
      'has_rating_filter': _minRating > 0.0,
    };
  }

  void _trackSearchExecution() {
    final searchDuration = _searchStartTime != null 
        ? DateTime.now().difference(_searchStartTime!) 
        : null;

    _analytics.trackSearch(
      'lawyer_search',
      _searchController.text,
      results: [], // Will be filled when results arrive
      searchContext: 'lawyer_search_form',
      appliedFilters: _currentFilters,
      searchDuration: searchDuration,
    );
  }

  void _trackFilterChange(String filterType, dynamic value) {
    _analytics.trackUserClick(
      'search_filter_$filterType',
      'lawyer_search_form',
      additionalData: {
        'filter_type': filterType,
        'filter_value': value,
        'current_query': _searchController.text,
        'has_query': _searchController.text.isNotEmpty,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBackgroundColor = isDark
        ? color.surfaceVariant.withOpacity(0.35)
        : color.surface;
    final hintTextColor = isDark
        ? color.onSurfaceVariant.withOpacity(0.9)
        : color.onSurfaceVariant;
    final labelTextColor = color.onSurface;
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color.outline.withOpacity(0.6), width: 1),
    );
    final inputDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: inputBackgroundColor,
      hintStyle: TextStyle(color: hintTextColor),
      labelStyle: TextStyle(color: labelTextColor),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color.primary, width: 1.5),
      ),
    );

    return Card(
      elevation: 1,
      color: color.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha compacta: busca + localização + include firms
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Buscar advogados',
                      hintText: 'Ex: trabalhista, divórcio, cível...',
                      prefixIcon: const Icon(LucideIcons.search),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _showLocationPicker,
                  icon: Icon(_selectedLatitude != null ? LucideIcons.mapPin : LucideIcons.plus, size: 18),
                  label: Text(_selectedLatitude != null ? 'Local' : 'Local', style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color.primary,
                    side: BorderSide(color: color.outline.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Row(children: [
                  Switch(
                    value: _includeFirms,
                    onChanged: (v) => setState(() => _includeFirms = v),
                  ),
                  const Text('Escritórios'),
                ]),
              ],
            ),

            if (_selectedLatitude != null && _selectedLongitude != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 16, color: color.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selectedLocationAddress ?? 'Lat: ${_selectedLatitude!.toStringAsFixed(4)}, Lng: ${_selectedLongitude!.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _clearLocation,
                    icon: const Icon(LucideIcons.x, size: 14),
                    label: const Text('Limpar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: color.error),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Filtros avançados recolhíveis
            Theme(
              data: Theme.of(context).copyWith(dividerColor: color.outline.withOpacity(0.2)),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                collapsedIconColor: color.primary,
                iconColor: color.primary,
                title: Row(
                  children: [
                    Icon(LucideIcons.slidersHorizontal, size: 18, color: color.primary),
                    const SizedBox(width: 8),
                    Text('Filtros avançados', style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                children: [
                  const SizedBox(height: 8),
                  DropdownButtonFormField<LegalArea>(
                    value: _selectedLegalArea,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Área Jurídica',
                      prefixIcon: const Icon(LucideIcons.scale),
                    ),
                    dropdownColor: inputBackgroundColor,
                    style: TextStyle(color: color.onSurface),
                    items: LegalArea.values.map((area) {
                      return DropdownMenuItem(value: area, child: Text(area.displayName));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedLegalArea = value);
                      _trackFilterChange('legal_area', value?.name);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Preço por hora (R\$)', style: Theme.of(context).textTheme.bodySmall),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: color.primary,
                                inactiveTrackColor: color.outline.withOpacity(0.3),
                                thumbColor: color.primary,
                                overlayColor: color.primary.withOpacity(0.1),
                                valueIndicatorColor: color.primary,
                              ),
                              child: RangeSlider(
                                values: _priceRange,
                                min: 50,
                                max: 2000,
                                divisions: 39,
                                labels: RangeLabels('R\$ ${_priceRange.start.round()}', 'R\$ ${_priceRange.end.round()}'),
                                onChanged: (values) {
                                  setState(() => _priceRange = values);
                                  _trackFilterChange('price_range', {'min': values.start, 'max': values.end});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Avaliação mínima: ${_minRating.toStringAsFixed(1)} ⭐', style: Theme.of(context).textTheme.bodySmall),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: color.primary,
                                inactiveTrackColor: color.outline.withOpacity(0.3),
                                thumbColor: color.primary,
                                overlayColor: color.primary.withOpacity(0.1),
                                valueIndicatorColor: color.primary,
                              ),
                              child: Slider(
                                value: _minRating,
                                min: 0,
                                max: 5,
                                divisions: 10,
                                onChanged: (value) {
                                  setState(() => _minRating = value);
                                  _trackFilterChange('min_rating', value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_selectedLatitude != null && _selectedLongitude != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Raio de busca: ${_radiusKm.toStringAsFixed(0)} km', style: Theme.of(context).textTheme.bodySmall),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: color.primary,
                                  inactiveTrackColor: color.outline.withOpacity(0.3),
                                  thumbColor: color.primary,
                                  overlayColor: color.primary.withOpacity(0.1),
                                ),
                                child: Slider(
                                  value: _radiusKm,
                                  min: 5,
                                  max: 200,
                                  divisions: 39,
                                  onChanged: (value) => setState(() => _radiusKm = value),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                ],
              ),
            ),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(LucideIcons.search),
                label: const Text('Buscar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          initialLocation: _selectedLatitude != null && _selectedLongitude != null
              ? LatLng(_selectedLatitude!, _selectedLongitude!)
              : null,
          initialAddress: _selectedLocationAddress,
          onLocationSelected: (location, address) {
            setState(() {
              _selectedLatitude = location.latitude;
              _selectedLongitude = location.longitude;
              _selectedLocationAddress = address;
            });
          },
        ),
      ),
    );
  }

  void _clearLocation() {
    setState(() {
      _selectedLocationAddress = null;
      _selectedLatitude = null;
      _selectedLongitude = null;
    });
  }
}