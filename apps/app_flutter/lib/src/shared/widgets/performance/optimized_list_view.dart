import 'package:flutter/material.dart';
import 'dart:async'; // Added for Timer

/// Widget otimizado para listas grandes com virtualização e lazy loading
/// 
/// Características:
/// - Lazy loading com paginação automática
/// - Virtualização de itens (só renderiza o que está visível)
/// - Cache inteligente de itens
/// - Indicadores de carregamento suaves
/// - Otimização de scroll performance
class OptimizedListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) onLoadPage;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context)? loadingMoreBuilder;
  final int pageSize;
  final int cacheSize;
  final double itemExtent;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool reverse;
  final String? semanticLabel;

  const OptimizedListView({
    super.key,
    required this.onLoadPage,
    required this.itemBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.loadingMoreBuilder,
    this.pageSize = 20,
    this.cacheSize = 100,
    this.itemExtent = 100.0,
    this.controller,
    this.padding,
    this.reverse = false,
    this.semanticLabel,
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
  late final ScrollController _scrollController;
  final List<T> _items = [];
  final Map<int, T> _itemCache = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    // Lazy loading quando próximo do final
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8; // Carrega quando 80% scrollado

    if (currentScroll >= threshold && !_isLoadingMore && !_hasReachedEnd) {
      _loadMoreData();
    }

    // Limpeza de cache para itens distantes
    _cleanupCache();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.onLoadPage(0, widget.pageSize);
      
      setState(() {
        _items.clear();
        _items.addAll(newItems);
        _itemCache.clear();
        _addToCache(newItems, 0);
        _currentPage = 0;
        _hasReachedEnd = newItems.length < widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || _hasReachedEnd) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final newItems = await widget.onLoadPage(nextPage, widget.pageSize);
      
      setState(() {
        _items.addAll(newItems);
        _addToCache(newItems, _items.length - newItems.length);
        _currentPage = nextPage;
        _hasReachedEnd = newItems.length < widget.pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      // Mostra erro temporário mas não bloqueia a lista
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar mais itens: $e')),
      );
    }
  }

  void _addToCache(List<T> items, int startIndex) {
    for (int i = 0; i < items.length; i++) {
      _itemCache[startIndex + i] = items[i];
    }
  }

  void _cleanupCache() {
    if (_itemCache.length <= widget.cacheSize) return;

    // Remove itens do cache que estão longe da área visível
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.position.pixels;
    
    final visibleStart = (currentOffset / widget.itemExtent).floor();
    final visibleEnd = ((currentOffset + viewportHeight) / widget.itemExtent).ceil();
    
    const cacheBuffer = 20; // Mantém 20 itens antes e depois da área visível
    final cacheStart = (visibleStart - cacheBuffer).clamp(0, _items.length);
    final cacheEnd = (visibleEnd + cacheBuffer).clamp(0, _items.length);

    final keysToRemove = _itemCache.keys.where((index) {
      return index < cacheStart || index > cacheEnd;
    }).toList();

    for (final key in keysToRemove) {
      _itemCache.remove(key);
    }
  }

  Future<void> refresh() async {
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingBuilder?.call(context) ?? _buildDefaultLoading();
    }

    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ?? _buildDefaultError();
    }

    if (_items.isEmpty) {
      return widget.emptyBuilder?.call(context) ?? _buildDefaultEmpty();
    }

    return Semantics(
      label: widget.semanticLabel,
      child: RefreshIndicator(
        onRefresh: refresh,
        child: ListView.builder(
          controller: _scrollController,
          padding: widget.padding,
          reverse: widget.reverse,
          itemExtent: widget.itemExtent,
          itemCount: _items.length + (_isLoadingMore ? 1 : 0),
          cacheExtent: widget.itemExtent * 10, // Cache 10 itens para scroll suave
          addAutomaticKeepAlives: false, // Performance: não mantém state de itens fora da tela
          addRepaintBoundaries: true, // Performance: evita repaints desnecessários
          itemBuilder: (context, index) {
            if (index >= _items.length) {
              // Item de loading mais
              return widget.loadingMoreBuilder?.call(context) ?? _buildDefaultLoadingMore();
            }

            final item = _items[index];
            
            return _OptimizedListItem(
              key: ValueKey(index),
              child: widget.itemBuilder(context, item, index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando...'),
        ],
      ),
    );
  }

  Widget _buildDefaultError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: refresh,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Nenhum item encontrado'),
        ],
      ),
    );
  }

  Widget _buildDefaultLoadingMore() {
    return Container(
      height: widget.itemExtent,
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Carregando mais...'),
        ],
      ),
    );
  }
}

/// Widget otimizado para itens da lista
class _OptimizedListItem extends StatelessWidget {
  final Widget child;

  const _OptimizedListItem({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

/// Controller para controle externo da lista otimizada
class OptimizedListViewController<T> {
  _OptimizedListViewState<T>? _state;

  void _attach(_OptimizedListViewState<T> state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Força refresh da lista
  Future<void> refresh() async {
    await _state?.refresh();
  }

  /// Scroll para o topo
  void scrollToTop({Duration duration = const Duration(milliseconds: 300)}) {
    _state?._scrollController.animateTo(
      0,
      duration: duration,
      curve: Curves.easeOut,
    );
  }

  /// Scroll para posição específica
  void scrollToIndex(int index, {Duration duration = const Duration(milliseconds: 300)}) {
    final offset = index * (_state?.widget.itemExtent ?? 100.0);
    _state?._scrollController.animateTo(
      offset,
      duration: duration,
      curve: Curves.easeOut,
    );
  }

  /// Verifica se está carregando
  bool get isLoading => _state?._isLoading ?? false;

  /// Verifica se está carregando mais itens
  bool get isLoadingMore => _state?._isLoadingMore ?? false;

  /// Número de itens carregados
  int get itemCount => _state?._items.length ?? 0;

  /// Verifica se chegou ao final
  bool get hasReachedEnd => _state?._hasReachedEnd ?? false;
}

/// Widget de busca otimizada para listas grandes
class OptimizedSearchableListView<T> extends StatefulWidget {
  final Future<List<T>> Function(String query, int page, int pageSize) onSearch;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String Function(T item) getSearchText;
  final String hintText;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final int pageSize;
  final double itemExtent;
  final Duration searchDebounce;

  const OptimizedSearchableListView({
    super.key,
    required this.onSearch,
    required this.itemBuilder,
    required this.getSearchText,
    this.hintText = 'Buscar...',
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.pageSize = 20,
    this.itemExtent = 100.0,
    this.searchDebounce = const Duration(milliseconds: 500),
  });

  @override
  State<OptimizedSearchableListView<T>> createState() => _OptimizedSearchableListViewState<T>();
}

class _OptimizedSearchableListViewState<T> extends State<OptimizedSearchableListView<T>> {
  final TextEditingController _searchController = TextEditingController();
  final OptimizedListViewController<T> _listController = OptimizedListViewController<T>();
  Timer? _searchTimer;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(widget.searchDebounce, () {
      final query = _searchController.text.trim();
      if (query != _currentQuery) {
        _currentQuery = query;
        _listController.refresh();
      }
    });
  }

  Future<List<T>> _onLoadPage(int page, int pageSize) async {
    return await widget.onSearch(_currentQuery, page, pageSize);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textInputAction: TextInputAction.search,
          ),
        ),
        Expanded(
          child: OptimizedListView<T>(
            onLoadPage: _onLoadPage,
            itemBuilder: widget.itemBuilder,
            loadingBuilder: widget.loadingBuilder,
            errorBuilder: widget.errorBuilder,
            emptyBuilder: widget.emptyBuilder,
            pageSize: widget.pageSize,
            itemExtent: widget.itemExtent,
          ),
        ),
      ],
    );
  }
} 