import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/widgets/instrumented_widgets.dart';
import '../../../../../injection_container.dart';
import '../bloc/services_bloc.dart';
import '../bloc/services_event.dart';
import '../bloc/services_state.dart';
import '../../domain/entities/legal_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ServicesBloc>()..add(LoadServices()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catálogo de Serviços Jurídicos'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Todos'),
              Tab(text: 'Populares'),
              Tab(text: 'Promoções'),
              Tab(text: 'Categorias'),
            ],
            onTap: (index) {
              final bloc = context.read<ServicesBloc>();
              switch (index) {
                case 0:
                  bloc.add(LoadServices());
                  break;
                case 1:
                  bloc.add(LoadPopularServices());
                  break;
                case 2:
                  bloc.add(LoadDiscountedServices());
                  break;
                case 3:
                  bloc.add(LoadServiceCategories());
                  break;
              }
            },
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildServicesTab(),
            _buildServicesTab(),
            _buildServicesTab(),
            _buildCategoriesTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showSearchDialog(context),
          child: const Icon(LucideIcons.search),
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is ServicesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is ServicesError) {
          return _buildErrorWidget(state.message, context);
        }
        
        if (state is ServicesLoaded) {
          return _buildServicesList(state.services);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildServicesList(List<LegalService> services) {
    if (services.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.briefcase, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum serviço encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ServicesBloc>().add(RefreshServices());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return LegalServiceCard(
            service: services[index],
            onTap: () => _onServiceTap(context, services[index]),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is ServicesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is ServicesError) {
          return _buildErrorWidget(state.message, context);
        }
        
        if (state is ServiceCategoriesLoaded) {
          return _buildCategoriesList(state.categories);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCategoriesList(List<Map<String, dynamic>> categories) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ServiceCategoryCard(
          category: category,
          onTap: () => _onCategoryTap(category['category']),
        );
      },
    );
  }

  Widget _buildErrorWidget(String message, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Erro',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<ServicesBloc>().add(LoadServices()),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  void _onServiceTap(BuildContext context, LegalService service) {
    _showServiceDetailDialog(context, service);
  }

  void _onCategoryTap(String category) {
    context.read<ServicesBloc>().add(LoadServicesByCategory(category: category));
    _tabController.animateTo(0); // Switch to "Todos" tab
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SearchServicesDialog(
        onSearch: (query, category, minPrice, maxPrice, minRating, sortBy) {
          context.read<ServicesBloc>().add(SearchServices(
            query: query,
            category: category,
            minPrice: minPrice,
            maxPrice: maxPrice,
            minRating: minRating,
            sortBy: sortBy,
          ));
          _tabController.animateTo(0); // Switch to "Todos" tab
        },
      ),
    );
  }

  void _showServiceDetailDialog(BuildContext context, LegalService service) {
    showDialog(
      context: context,
      builder: (context) => ServiceDetailDialog(service: service),
    );
  }
}

class LegalServiceCard extends StatelessWidget {
  final LegalService service;
  final VoidCallback onTap;

  const LegalServiceCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InstrumentedContentCard(
      contentId: service.id,
      contentType: 'legal_service',
      sourceContext: 'services_catalog',
      onTap: onTap,
      additionalData: {
        'service_name': service.name,
        'service_category': service.category,
        'service_price': service.finalPrice,
        'service_rating': service.rating,
        'has_discount': service.hasDiscount,
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.providerName ?? 'Provedor',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (service.hasDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '-${service.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                service.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(LucideIcons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    service.rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    ' (${service.reviewCount})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (service.hasDiscount) ...[
                    Text(
                      'R\$ ${service.basePrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'R\$ ${service.finalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceCategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const ServiceCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InstrumentedContentCard(
      contentId: category['category'],
      contentType: 'service_category',
      sourceContext: 'services_catalog',
      onTap: onTap,
      additionalData: {
        'category_name': category['name'],
        'services_count': category['count'],
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(category['icon']),
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                category['name'],
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${category['count']} serviços',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'gavel':
        return LucideIcons.gavel;
      case 'shield':
        return LucideIcons.shield;
      case 'briefcase':
        return LucideIcons.briefcase;
      case 'building':
        return LucideIcons.building;
      case 'users':
        return LucideIcons.users;
      case 'calculator':
        return LucideIcons.calculator;
      default:
        return LucideIcons.scale;
    }
  }
}

class SearchServicesDialog extends StatefulWidget {
  final Function(String?, String?, double?, double?, double?, String?) onSearch;

  const SearchServicesDialog({super.key, required this.onSearch});

  @override
  State<SearchServicesDialog> createState() => _SearchServicesDialogState();
}

class _SearchServicesDialogState extends State<SearchServicesDialog> {
  final _queryController = TextEditingController();
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  String? _sortBy;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buscar Serviços',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                labelText: 'Termo de busca',
                hintText: 'Ex: consultoria empresarial',
                prefixIcon: Icon(LucideIcons.search),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Preço mínimo',
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _minPrice = double.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Preço máximo',
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _maxPrice = double.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(labelText: 'Ordenar por'),
              items: const [
                DropdownMenuItem(value: 'price_asc', child: Text('Menor preço')),
                DropdownMenuItem(value: 'price_desc', child: Text('Maior preço')),
                DropdownMenuItem(value: 'rating', child: Text('Melhor avaliação')),
                DropdownMenuItem(value: 'popular', child: Text('Mais populares')),
              ],
              onChanged: (value) => setState(() => _sortBy = value),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onSearch(
                      _queryController.text.isEmpty ? null : _queryController.text,
                      _selectedCategory,
                      _minPrice,
                      _maxPrice,
                      _minRating,
                      _sortBy,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }
}

class ServiceDetailDialog extends StatelessWidget {
  final LegalService service;

  const ServiceDetailDialog({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      service.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.providerName ?? 'Provedor',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                service.expertise,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (service.hasDiscount) ...[
                              Text(
                                'R\$ ${service.basePrice.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            Text(
                              'R\$ ${service.finalPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${service.rating.toStringAsFixed(1)} (${service.reviewCount} avaliações)'),
                        const Spacer(),
                        Icon(LucideIcons.clock, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(service.duration),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Descrição',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(service.description),
                    const SizedBox(height: 16),
                    Text(
                      'Requisitos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...service.requirements.map((req) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.check, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(req)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                    Text(
                      'Entregáveis',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...service.deliverables.map((deliverable) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(LucideIcons.fileText, size: 16, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Expanded(child: Text(deliverable)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showBookingDialog(context, service);
                  },
                  child: const Text('Agendar Serviço'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, LegalService service) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de agendamento será implementada em breve'),
      ),
    );
  }
} 