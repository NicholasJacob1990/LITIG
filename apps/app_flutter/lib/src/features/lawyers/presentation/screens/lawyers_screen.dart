import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/lawyers_bloc.dart';
import 'package:meu_app/src/features/recommendations/presentation/widgets/lawyer_match_card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class LawyersScreen extends StatelessWidget {
  const LawyersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LawyersBloc(),
      child: const LawyersView(),
    );
  }
}

class LawyersView extends StatefulWidget {
  const LawyersView({super.key});

  @override
  State<LawyersView> createState() => _LawyersViewState();
}

class _LawyersViewState extends State<LawyersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Advogados',
          style: TextStyle(
            fontFamily: 'Sans-serif',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal),
            onPressed: () {
              // TODO: Implementar modal de filtros avançados
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recomendações'),
            Tab(text: 'Buscar Advogado'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RecommendationsTabView(),
          SearchTabView(),
        ],
      ),
    );
  }
}

class RecommendationsTabView extends StatefulWidget {
  const RecommendationsTabView({super.key});

  @override
  State<RecommendationsTabView> createState() => _RecommendationsTabViewState();
}

class _RecommendationsTabViewState extends State<RecommendationsTabView> {
  
  // Dados mock para demonstração
  final List<Map<String, dynamic>> _mockLawyers = [
    {
      'lawyer_id': '1',
      'nome': 'Dr. João Silva',
      'primary_area': 'Direito Civil',
      'rating': 4.8,
      'distance_km': 5.2,
      'is_available': true,
      'experience_years': 15,
      'awards': ['OAB Destaque 2023', 'Melhor Advogado Civil SP', 'Top Lawyer 2022'],
      'professional_summary': 'Especialista em Direito Civil com 15 anos de experiência. Formado pela USP, com mestrado em Direito Contratual. Atua principalmente em contratos empresariais, responsabilidade civil e direito imobiliário. Reconhecido pela OAB-SP como advogado destaque em 2023.',
      'features': {
        'area_match': 0.95,
        'case_similarity': 0.87,
        'success_rate': 0.92,
        'geography': 0.88,
        'qualification': 0.90,
        'urgency': 0.85,
        'review_score': 0.96,
        'soft_skills': 0.89,
      },
      'fair': 0.89,
      'equity': 0.85,
      'avatar_url': 'https://ui-avatars.com/api/?name=João+Silva&background=6B7280&color=fff',
    },
    {
      'lawyer_id': '2',
      'nome': 'Dra. Maria Santos',
      'primary_area': 'Direito Trabalhista',
      'rating': 4.6,
      'distance_km': 8.7,
      'is_available': true,
      'experience_years': 12,
      'awards': ['Top Lawyer 2022', 'Especialista Trabalhista', 'OAB Reconhecimento 2021'],
      'professional_summary': 'Advogada trabalhista com sólida experiência em ações trabalhistas, acordos coletivos e consultoria empresarial. Formada pela PUC-SP, especialista em Direito do Trabalho. Reconhecida como Top Lawyer pela revista Análise Advocacia em 2022.',
      'features': {
        'area_match': 0.92,
        'case_similarity': 0.83,
        'success_rate': 0.88,
        'geography': 0.82,
        'qualification': 0.94,
        'urgency': 0.90,
        'review_score': 0.92,
        'soft_skills': 0.91,
      },
      'fair': 0.87,
      'equity': 0.88,
      'avatar_url': 'https://ui-avatars.com/api/?name=Maria+Santos&background=6B7280&color=fff',
    },
    {
      'lawyer_id': '3',
      'nome': 'Dr. Carlos Oliveira',
      'primary_area': 'Direito Empresarial',
      'rating': 4.9,
      'distance_km': 3.1,
      'is_available': false,
      'experience_years': 20,
      'awards': ['Advogado do Ano 2023', 'Especialista Empresarial', 'Reconhecimento FIESP'],
      'professional_summary': 'Advogado empresarial com mais de 20 anos de experiência. Especialista em fusões e aquisições, direito societário e compliance. Formado pela FGV, com MBA em Gestão Empresarial. Atuou em grandes operações de M&A no mercado brasileiro.',
      'features': {
        'area_match': 0.88,
        'case_similarity': 0.91,
        'success_rate': 0.95,
        'geography': 0.95,
        'qualification': 0.98,
        'urgency': 0.82,
        'review_score': 0.98,
        'soft_skills': 0.87,
      },
      'fair': 0.92,
      'equity': 0.91,
      'avatar_url': 'https://ui-avatars.com/api/?name=Carlos+Oliveira&background=8B5CF6&color=fff',
    },
  ];

  @override
  Widget build(BuildContext context) {
            return ListView.builder(
      itemCount: _mockLawyers.length,
              itemBuilder: (context, index) {
        final lawyer = _mockLawyers[index];
                return LawyerMatchCard(
                  lawyer: lawyer,
                  onSelect: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Advogado ${lawyer['nome']} selecionado')),
            );
                  },
                  onExplain: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Explicação para ${lawyer['nome']}')),
                        );
                  },
                );
              },
            );
          }
}

class SearchTabView extends StatefulWidget {
  const SearchTabView({super.key});

  @override
  State<SearchTabView> createState() => _SearchTabViewState();
}

class _SearchTabViewState extends State<SearchTabView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedArea;
  String? _selectedUF;
  double _minRating = 0;
  double _maxDistance = 50;
  bool _onlyAvailable = false;
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  bool _isListView = true; // Controla se está vendo lista ou mapa
  
  // Google Maps
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  int? _selectedLawyerId;

  final List<String> _areas = [
    'Direito Civil',
    'Direito Penal',
    'Direito Trabalhista',
    'Direito Tributário',
    'Direito Empresarial',
    'Direito de Família',
    'Direito Previdenciário',
    'Direito Administrativo',
    'Direito Constitucional',
    'Direito Ambiental',
  ];

  final List<String> _estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    if (_searchController.text.trim().isEmpty && 
        _selectedArea == null && 
        _selectedUF == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um termo de busca ou selecione filtros')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    try {
      // TODO: Implementar busca real via API
      // Por enquanto, simular busca
      await Future.delayed(const Duration(seconds: 1));
      
      // Dados mock para demonstração com coordenadas
      _searchResults = [
        {
          'lawyer_id': '1',
          'nome': 'Dr. João Silva',
          'primary_area': _selectedArea ?? 'Direito Civil',
          'rating': 4.8,
          'distance_km': 5.2,
          'is_available': true,
          'experience_years': 15,
          'awards': ['OAB Destaque 2023', 'Melhor Advogado Civil SP', 'Top Lawyer 2022'],
          'professional_summary': 'Especialista em Direito Civil com 15 anos de experiência. Formado pela USP, com mestrado em Direito Contratual. Atua principalmente em contratos empresariais, responsabilidade civil e direito imobiliário. Reconhecido pela OAB-SP como advogado destaque em 2023.',
          'features': {
            'area_match': 0.95,
            'case_similarity': 0.87,
            'success_rate': 0.92,
            'geography': 0.88,
            'qualification': 0.90,
            'urgency': 0.85,
            'review_score': 0.96,
            'soft_skills': 0.89,
          },
          'fair': 0.89,
          'equity': 0.85,
          'avatar_url': 'https://ui-avatars.com/api/?name=João+Silva&background=6B7280&color=fff',
          'latitude': -23.5505,
          'longitude': -46.6333,
        },
        {
          'lawyer_id': '2',
          'nome': 'Dra. Maria Santos',
          'primary_area': _selectedArea ?? 'Direito Trabalhista',
          'rating': 4.6,
          'distance_km': 8.7,
          'is_available': true,
          'experience_years': 12,
          'awards': ['Top Lawyer 2022', 'Especialista Trabalhista', 'OAB Reconhecimento 2021'],
          'professional_summary': 'Advogada trabalhista com sólida experiência em ações trabalhistas, acordos coletivos e consultoria empresarial. Formada pela PUC-SP, especialista em Direito do Trabalho. Reconhecida como Top Lawyer pela revista Análise Advocacia em 2022.',
          'features': {
            'area_match': 0.92,
            'case_similarity': 0.83,
            'success_rate': 0.88,
            'geography': 0.82,
            'qualification': 0.94,
            'urgency': 0.90,
            'review_score': 0.92,
            'soft_skills': 0.91,
          },
          'fair': 0.87,
          'equity': 0.88,
          'avatar_url': 'https://ui-avatars.com/api/?name=Maria+Santos&background=6B7280&color=fff',
          'latitude': -23.5615,
          'longitude': -46.6565,
        },
        {
          'lawyer_id': '3',
          'nome': 'Dr. Carlos Oliveira',
          'primary_area': _selectedArea ?? 'Direito Empresarial',
          'rating': 4.9,
          'distance_km': 3.1,
          'is_available': false,
          'experience_years': 20,
          'awards': ['Advogado do Ano 2023', 'Especialista Empresarial', 'Reconhecimento FIESP'],
          'professional_summary': 'Advogado empresarial com mais de 20 anos de experiência. Especialista em fusões e aquisições, direito societário e compliance. Formado pela FGV, com MBA em Gestão Empresarial. Atuou em grandes operações de M&A no mercado brasileiro.',
          'features': {
            'area_match': 0.88,
            'case_similarity': 0.91,
            'success_rate': 0.95,
            'geography': 0.95,
            'qualification': 0.98,
            'urgency': 0.82,
            'review_score': 0.98,
            'soft_skills': 0.87,
          },
          'fair': 0.92,
          'equity': 0.91,
          'avatar_url': 'https://ui-avatars.com/api/?name=Carlos+Oliveira&background=8B5CF6&color=fff',
          'latitude': -23.5489,
          'longitude': -46.6388,
        },
      ];

      // Aplicar filtros locais
      _searchResults = _searchResults.where((lawyer) {
        if (_minRating > 0 && lawyer['rating'] < _minRating) return false;
        if (_maxDistance < 50 && lawyer['distance_km'] > _maxDistance) return false;
        if (_onlyAvailable && !lawyer['is_available']) return false;
        return true;
      }).toList();

      // Atualizar marcadores do mapa
      _updateMapMarkers();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na busca: $e')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _updateMapMarkers() {
    _markers.clear();
    
    for (int i = 0; i < _searchResults.length; i++) {
      final lawyer = _searchResults[i];
      final isSelected = _selectedLawyerId == int.parse(lawyer['lawyer_id']);
      
      _markers.add(
        Marker(
          markerId: MarkerId(lawyer['lawyer_id']),
          position: LatLng(lawyer['latitude'], lawyer['longitude']),
          infoWindow: InfoWindow(
            title: lawyer['nome'],
            snippet: '${lawyer['primary_area']} • ${lawyer['rating']}⭐',
          ),
          icon: isSelected 
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
              : BitmapDescriptor.defaultMarker,
          onTap: () {
            setState(() {
              _selectedLawyerId = int.parse(lawyer['lawyer_id']);
            });
          },
        ),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedArea = null;
      _selectedUF = null;
      _minRating = 0;
      _maxDistance = 50;
      _onlyAvailable = false;
      _searchResults.clear();
      _markers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de Pesquisa com botões de visualização
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar advogado por nome ou OAB...',
                        prefixIcon: Icon(LucideIcons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _performSearch,
                    child: _isSearching 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.search),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botões de alternância de visualização
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Lista'),
                        icon: Icon(LucideIcons.list),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Mapa'),
                        icon: Icon(LucideIcons.map),
                      ),
                    ],
                    selected: {_isListView},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isListView = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filtros Avançados
        ExpansionTile(
          title: const Text('Filtros Avançados'),
          leading: const Icon(LucideIcons.filter),
          trailing: _hasActiveFilters()
              ? Badge(
                  child: const Icon(Icons.expand_more),
                )
              : const Icon(Icons.expand_more),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Área Jurídica
                  const Text('Área Jurídica', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedArea,
                    hint: const Text('Selecione uma área'),
                    items: _areas.map((area) => DropdownMenuItem(
                      value: area,
                      child: Text(area),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedArea = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Estado
                  const Text('Estado (UF)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedUF,
                    hint: const Text('Selecione um estado'),
                    items: _estados.map((uf) => DropdownMenuItem(
                      value: uf,
                      child: Text(uf),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedUF = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Avaliação Mínima
                  Text('Avaliação Mínima: ${_minRating.toStringAsFixed(1)}⭐', 
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 50,
                    onChanged: (value) => setState(() => _minRating = value),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Distância Máxima
                  Text('Distância Máxima: ${_maxDistance.toStringAsFixed(0)} km', 
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (value) => setState(() => _maxDistance = value),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Apenas Disponíveis
                  CheckboxListTile(
                    title: const Text('Apenas advogados disponíveis'),
                    value: _onlyAvailable,
                    onChanged: (value) => setState(() => _onlyAvailable = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botões de Ação
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('Limpar Filtros'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _performSearch,
                          child: const Text('Aplicar Filtros'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Resultados da Busca
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _selectedArea != null || 
           _selectedUF != null || 
           _minRating > 0 || 
           _maxDistance < 50 || 
           _onlyAvailable;
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Buscando advogados...'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum resultado encontrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros ou termos de busca',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Alternar entre lista e mapa
    return _isListView ? _buildListView() : _buildMapView();
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final lawyer = _searchResults[index];
        return _buildLawyerProfileCard(lawyer);
      },
    );
  }

  Widget _buildMapView() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('Faça uma busca para ver advogados no mapa'),
      );
    }

    // Calcular bounds para mostrar todos os advogados
    double minLat = _searchResults.map((l) => l['latitude'] as double).reduce((a, b) => a < b ? a : b);
    double maxLat = _searchResults.map((l) => l['latitude'] as double).reduce((a, b) => a > b ? a : b);
    double minLng = _searchResults.map((l) => l['longitude'] as double).reduce((a, b) => a < b ? a : b);
    double maxLng = _searchResults.map((l) => l['longitude'] as double).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // Informações do advogado selecionado
        if (_selectedLawyerId != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSelectedLawyerInfo(),
          ),
        ],
        
        // Mapa
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (minLat + maxLat) / 2,
                    (minLng + maxLng) / 2,
                  ),
                  zoom: 12,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);
                  
                  // Ajustar câmera para mostrar todos os marcadores
                  Future.delayed(const Duration(milliseconds: 500), () async {
                    final GoogleMapController mapController = await _mapController.future;
                    mapController.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: LatLng(minLat - 0.01, minLng - 0.01),
                          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
                        ),
                        100.0,
                      ),
                    );
                  });
                },
                onTap: (position) {
                  // Desselecionar advogado ao tocar no mapa
                  setState(() {
                    _selectedLawyerId = null;
                  });
                  _updateMapMarkers();
                },
              ),
              
              // Controles do mapa
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: "zoom_in",
                      onPressed: () async {
                        final GoogleMapController controller = await _mapController.future;
                        controller.animateCamera(CameraUpdate.zoomIn());
                      },
                      child: const Icon(Icons.zoom_in),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "zoom_out",
                      onPressed: () async {
                        final GoogleMapController controller = await _mapController.future;
                        controller.animateCamera(CameraUpdate.zoomOut());
                      },
                      child: const Icon(Icons.zoom_out),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedLawyerInfo() {
    if (_selectedLawyerId == null) return const SizedBox.shrink();
    
    final lawyer = _searchResults.firstWhere(
      (l) => l['lawyer_id'] == _selectedLawyerId.toString(),
      orElse: () => null,
    );
    
    if (lawyer == null) return const SizedBox.shrink();
    
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(lawyer['avatar_url']),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lawyer['nome'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(lawyer['primary_area']),
              Row(
                children: [
                  Icon(LucideIcons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${lawyer['rating']}'),
                  const SizedBox(width: 16),
                  Icon(LucideIcons.mapPin, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${lawyer['distance_km']} km'),
                ],
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Contratando ${lawyer['nome']}')),
            );
          },
          child: const Text('Contratar'),
        ),
      ],
    );
  }

  Widget _buildLawyerProfileCard(Map<String, dynamic> lawyer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com foto e info básica
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(lawyer['avatar_url']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyer['nome'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(lawyer['primary_area']),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${lawyer['rating']}'),
                          const SizedBox(width: 16),
                          Icon(LucideIcons.mapPin, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${lawyer['distance_km']} km'),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${(lawyer['fair'] * 100).toInt()}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Experiência e Prêmios
            if (lawyer['experience_years'] != null) ...[
              Row(
                children: [
                  Icon(LucideIcons.briefcase, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${lawyer['experience_years']} anos de experiência',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  // Botão Ver Currículo
                  if (lawyer['professional_summary'] != null) ...[
                    TextButton.icon(
                      onPressed: () => _showCurriculumModal(context, lawyer),
                      icon: const Icon(LucideIcons.fileText, size: 16),
                      label: const Text('Ver Currículo'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Prêmios
            if (lawyer['awards'] != null && lawyer['awards'].isNotEmpty) ...[
              Row(
                children: [
                  Icon(LucideIcons.award, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (lawyer['awards'] as List)
                          .take(3)
                          .map((award) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                ),
                                child: Text(
                                  award,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.amber.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contratando ${lawyer['nome']}')),
                      );
                    },
                    icon: const Icon(LucideIcons.fileSignature),
                    label: const Text('Contratar'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.messageSquare),
                  tooltip: 'Chat',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.video),
                  tooltip: 'Vídeo Chamada',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCurriculumModal(BuildContext context, Map<String, dynamic> lawyer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Currículo - ${lawyer['nome']}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lawyer['experience_years'] != null) ...[
                            Text(
                              'Experiência: ${lawyer['experience_years']} anos',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          if (lawyer['awards'] != null && (lawyer['awards'] as List).isNotEmpty) ...[
                            Text(
                              'Prêmios e Reconhecimentos:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...(lawyer['awards'] as List).map((award) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $award', style: Theme.of(context).textTheme.bodyMedium),
                            )).toList(),
                            const SizedBox(height: 16),
                          ],
                          
                          Text(
                            'Resumo Profissional:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lawyer['professional_summary'] ?? 'Não disponível',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 