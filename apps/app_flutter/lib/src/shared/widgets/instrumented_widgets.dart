/// INSTRUMENTED WIDGETS - DATA FLYWHEEL IMPLEMENTATION
/// ===================================================
/// 
/// Widgets que automaticamente capturam interações do usuário para o data flywheel.
/// Cada widget envolve funcionalidades existentes com instrumentação transparente.
/// 
/// Uso:
/// - Substitua widgets normais por versões instrumentadas
/// - Mantenha a mesma API, adicione contexto de tracking
/// - Analytics é capturado automaticamente sem impacto na UX
library;

import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

/// Botão instrumentado - captura cliques e ações
class InstrumentedButton extends StatelessWidget {
  final String elementId;
  final String context;
  final VoidCallback? onPressed;
  final Widget child;
  final Map<String, dynamic>? additionalData;

  const InstrumentedButton({
    super.key,
    required this.elementId,
    required this.context,
    required this.onPressed,
    required this.child,
    this.additionalData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (onPressed != null) {
          final analytics = await AnalyticsService.getInstance();
          await analytics.trackUserClick(
            elementId,
            this.context,
            additionalData: additionalData,
          );
          onPressed!();
        }
      },
      child: child,
    );
  }
}

/// Botão de ação instrumentado - captura ações principais
class InstrumentedActionButton extends StatelessWidget {
  final String actionType;
  final String elementId;
  final String context;
  final VoidCallback? onPressed;
  final Widget child;
  final Map<String, dynamic>? additionalData;

  const InstrumentedActionButton({
    super.key,
    required this.actionType,
    required this.elementId,
    required this.context,
    required this.onPressed,
    required this.child,
    this.additionalData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (onPressed != null) {
          final analytics = await AnalyticsService.getInstance();
          await analytics.trackUserAction(
            actionType,
            properties: {
              'element_id': elementId,
              'context': this.context,
              ...?additionalData,
            },
          );
          onPressed!();
        }
      },
      child: child,
    );
  }
}

/// Card de conteúdo instrumentado - captura visualizações e cliques em casos/documentos
class InstrumentedContentCard extends StatefulWidget {
  final String contentId;
  final String contentType; // 'case', 'document', 'offer'
  final String sourceContext; // 'case_list', 'dashboard', 'search_results'
  final Widget child;
  final VoidCallback? onTap;
  final String? listContext;
  final double? listRank;
  final Map<String, dynamic>? additionalData;

  const InstrumentedContentCard({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.sourceContext,
    required this.child,
    this.onTap,
    this.listContext,
    this.listRank,
    this.additionalData,
  });

  @override
  State<InstrumentedContentCard> createState() => _InstrumentedContentCardState();
}

class _InstrumentedContentCardState extends State<InstrumentedContentCard> {
  DateTime? _viewStartTime;
  late AnalyticsService _analytics;

  @override
  void initState() {
    super.initState();
    _viewStartTime = DateTime.now();
    _initAnalytics();
  }

  void _initAnalytics() async {
    _analytics = await AnalyticsService.getInstance();
    // Track content view when card becomes visible
    _analytics.trackContentEngagement(
      widget.contentId,
      widget.contentType,
      action: 'view',
      sourceContext: widget.sourceContext,
    );
  }

  @override
  void dispose() {
    _trackViewEnd();
    super.dispose();
  }

  void _trackViewEnd() {
    if (_viewStartTime != null) {
      final viewDuration = DateTime.now().difference(_viewStartTime!);
      _analytics.trackContentEngagement(
        widget.contentId,
        widget.contentType,
        action: 'view_end',
        engagementTime: viewDuration,
        sourceContext: widget.sourceContext,
      );
      _viewStartTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        _trackViewEnd(); // Track view duration on tap
        await _analytics.trackUserClick(
          'content_${widget.contentType}_${widget.contentId}',
          widget.sourceContext,
          additionalData: {
            'content_id': widget.contentId,
            'content_type': widget.contentType,
            'action_type': 'navigate',
            'list_context': widget.listContext,
            'list_rank': widget.listRank,
            ...?widget.additionalData,
          },
        );
        widget.onTap?.call();
      },
      child: widget.child,
    );
  }
}

/// Card de perfil instrumentado - captura visualizações e cliques
class InstrumentedProfileCard extends StatefulWidget {
  final String profileId;
  final String profileType; // 'lawyer', 'firm', 'case'
  final String sourceContext; // 'search_results', 'recommendation', etc.
  final Widget child;
  final VoidCallback? onTap;
  final String? searchQuery;
  final double? searchRank;
  final Map<String, dynamic>? searchFilters;
  final String? caseContext;

  const InstrumentedProfileCard({
    super.key,
    required this.profileId,
    required this.profileType,
    required this.sourceContext,
    required this.child,
    this.onTap,
    this.searchQuery,
    this.searchRank,
    this.searchFilters,
    this.caseContext,
  });

  @override
  State<InstrumentedProfileCard> createState() => _InstrumentedProfileCardState();
}

class _InstrumentedProfileCardState extends State<InstrumentedProfileCard> {
  DateTime? _viewStartTime;
  late AnalyticsService _analytics;

  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
    _trackProfileView();
  }

  Future<void> _initializeAnalytics() async {
    _analytics = await AnalyticsService.getInstance();
  }

  void _trackProfileView() {
    _viewStartTime = DateTime.now();
    
    // Track profile view imediatamente
    _analytics.trackProfileView(
      widget.profileId,
      widget.profileType,
      sourceContext: widget.sourceContext,
      searchQuery: widget.searchQuery,
      searchRank: widget.searchRank,
      searchFilters: widget.searchFilters,
      caseContext: widget.caseContext,
    );
  }

  void _trackProfileClick() {
    final viewDuration = _viewStartTime != null 
        ? DateTime.now().difference(_viewStartTime!)
        : null;

    // Track click com duração da visualização
    _analytics.trackUserClick(
      'profile_card_${widget.profileType}',
      widget.sourceContext,
      additionalData: {
        'profile_id': widget.profileId,
        'view_duration_ms': viewDuration?.inMilliseconds,
        'search_rank': widget.searchRank,
      },
    );

    // Track profile view com duração
    _analytics.trackProfileView(
      widget.profileId,
      widget.profileType,
      sourceContext: widget.sourceContext,
      viewDuration: viewDuration,
      searchQuery: widget.searchQuery,
      searchRank: widget.searchRank,
      searchFilters: widget.searchFilters,
      caseContext: widget.caseContext,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _trackProfileClick();
        widget.onTap?.call();
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    // Track final view duration if user navigates away
    if (_viewStartTime != null) {
      final finalDuration = DateTime.now().difference(_viewStartTime!);
      _analytics.trackProfileView(
        widget.profileId,
        widget.profileType,
        sourceContext: '${widget.sourceContext}_final',
        viewDuration: finalDuration,
      );
    }
    super.dispose();
  }
}

/// Botão de convite instrumentado - captura envios de convite
class InstrumentedInviteButton extends StatelessWidget {
  final String recipientId;
  final String invitationType;
  final String context;
  final Widget child;
  final VoidCallback? onPressed;
  final String? caseId;
  final double? matchScore;
  final String? recipientType;
  final List<String>? selectedCriteria;
  final Map<String, dynamic>? additionalData;

  const InstrumentedInviteButton({
    super.key,
    required this.recipientId,
    required this.invitationType,
    required this.context,
    required this.child,
    this.onPressed,
    this.caseId,
    this.matchScore,
    this.recipientType,
    this.selectedCriteria,
    this.additionalData,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed != null ? () => _handleInvitePressed() : null,
      child: child,
    );
  }

  Future<void> _handleInvitePressed() async {
    final analytics = await AnalyticsService.getInstance();

    // Track invitation sent - CRÍTICO para network effects
    await analytics.trackInvitationSent(
      invitationType,
      recipientId,
      context: context,
      caseId: caseId,
      matchScore: matchScore,
      recipientType: recipientType,
      selectedCriteria: selectedCriteria,
      additionalData: additionalData,
    );

    // Executar ação original
    onPressed?.call();
  }
}

/// Campo de busca instrumentado - captura comportamento de busca
class InstrumentedSearchField extends StatefulWidget {
  final String searchType;
  final Function(String query, List<String> results)? onSearchCompleted;
  final Function(String selectedId)? onResultSelected;
  final String? searchContext;
  final Widget child;

  const InstrumentedSearchField({
    super.key,
    required this.searchType,
    required this.child,
    this.onSearchCompleted,
    this.onResultSelected,
    this.searchContext,
  });

  @override
  State<InstrumentedSearchField> createState() => _InstrumentedSearchFieldState();
}

class _InstrumentedSearchFieldState extends State<InstrumentedSearchField> {
  @override
  void initState() {
    super.initState();
  }

  // void _trackSearchStart(String query) {
  //   _searchStartTime = DateTime.now();
  //   _currentQuery = query;
  // }

  // void _trackSearchCompleted(List<String> results) {
  //   final searchDuration = _searchStartTime != null 
  //       ? DateTime.now().difference(_searchStartTime!)
  //       : null;

  //   _analytics.trackSearch(
  //     widget.searchType,
  //     _currentQuery,
  //     results: results,
  //     searchContext: widget.searchContext,
  //     searchDuration: searchDuration,
  //   );
  // }

  // void _trackResultSelection(String selectedId) {
  //   final searchDuration = _searchStartTime != null 
  //       ? DateTime.now().difference(_searchStartTime!)
  //       : null;

  //   _analytics.trackSearch(
  //     widget.searchType,
  //     _currentQuery,
  //     results: [], // Será preenchido pelo callback
  //     searchContext: widget.searchContext,
  //     searchDuration: searchDuration,
  //     resultClicks: 1,
  //     selectedResultId: selectedId,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // O widget child deve implementar callbacks para notificar sobre buscas
    // Por agora, retornamos o child original
    // Em implementação real, seria necessário modificar o widget de busca
    return widget.child;
  }
}

/// Formulário de proposta instrumentado - captura submissões
class InstrumentedProposalForm extends StatelessWidget {
  final String proposalType;
  final String targetId;
  final Map<String, dynamic> proposalData;
  final Widget child;
  final VoidCallback? onSubmitted;
  final String? caseId;
  final double? proposedFee;
  final Duration? timeToComplete;
  final String? methodology;

  const InstrumentedProposalForm({
    super.key,
    required this.proposalType,
    required this.targetId,
    required this.proposalData,
    required this.child,
    this.onSubmitted,
    this.caseId,
    this.proposedFee,
    this.timeToComplete,
    this.methodology,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSubmitted != null ? () => _handleSubmit() : null,
      child: child,
    );
  }

  Future<void> _handleSubmit() async {
    final analytics = await AnalyticsService.getInstance();

    // Track proposal submission
    await analytics.trackProposalSubmitted(
      proposalType,
      targetId,
      proposalData: proposalData,
      caseId: caseId,
      proposedFee: proposedFee,
      timeToComplete: timeToComplete,
      methodology: methodology,
    );

    // Executar ação original
    onSubmitted?.call();
  }
}

/// Widget de feedback instrumentado - captura avaliações
class InstrumentedFeedbackWidget extends StatelessWidget {
  final String feedbackType;
  final String targetId;
  final Widget child;
  final Function(double rating, String? comment)? onFeedbackSubmitted;
  final String? caseId;

  const InstrumentedFeedbackWidget({
    super.key,
    required this.feedbackType,
    required this.targetId,
    required this.child,
    this.onFeedbackSubmitted,
    this.caseId,
  });

  @override
  Widget build(BuildContext context) {
    // Wrapper que captura feedback quando submetido
    return child; // Implementação específica dependeria do widget de feedback
  }

  // Future<void> _handleFeedbackSubmit(double rating, String? comment, List<String>? tags) async {
  //   final analytics = await AnalyticsService.getInstance();

  //   // Track feedback - CRÍTICO para quality improvement
  //   await analytics.trackFeedback(
  //     feedbackType,
  //     targetId,
  //     rating: rating,
  //     comment: comment,
  //     tags: tags,
  //     caseId: caseId,
  //   );

  //   // Executar callback original
  //   onFeedbackSubmitted?.call(rating, comment);
  // }
}

/// Widget para tracking de ListView/GridView - scroll behavior e item views
class InstrumentedListView extends StatefulWidget {
  final String listId;
  final String listType; // 'list', 'grid', 'scroll'
  final String contentType; // 'cases', 'lawyers', 'firms', 'notifications'
  final String sourceContext; // 'dashboard', 'search_results', 'screen_name'
  final Widget child;
  final int? totalItems;
  final List<String>? itemIds;
  final Map<String, dynamic>? additionalData;

  const InstrumentedListView({
    super.key,
    required this.listId,
    required this.listType,
    required this.contentType,
    required this.sourceContext,
    required this.child,
    this.totalItems,
    this.itemIds,
    this.additionalData,
  });

  @override
  State<InstrumentedListView> createState() => _InstrumentedListViewState();
}

class _InstrumentedListViewState extends State<InstrumentedListView> {
  late AnalyticsService _analytics;
  ScrollController? _scrollController;
  DateTime? _scrollStartTime;
  DateTime? _lastScrollEventTime;

  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
    _setupScrollTracking();
  }

  Future<void> _initializeAnalytics() async {
    _analytics = await AnalyticsService.getInstance();
    _trackListView();
  }

  void _setupScrollTracking() {
    // Find ScrollController in the child widget tree if available
    _scrollController = _findScrollController(widget.child);
    
    if (_scrollController != null) {
      _scrollController!.addListener(_onScroll);
    }
  }

  ScrollController? _findScrollController(Widget widget) {
    // This is a simplified version - in practice, you might need to
    // pass the ScrollController explicitly or use a different approach
    return null;
  }

  void _onScroll() {
    if (_scrollController == null) return;

    final currentTime = DateTime.now();
    final currentPosition = _scrollController!.position.pixels;
    final maxExtent = _scrollController!.position.maxScrollExtent;

    // Track scroll start
    if (_scrollStartTime == null) {
      _scrollStartTime = currentTime;
      _trackScrollStart();
    }

    // Track scroll behavior every 500ms to avoid too many events
    if (_lastScrollEventTime == null || 
        currentTime.difference(_lastScrollEventTime!).inMilliseconds > 500) {
      
      _trackScrollBehavior(currentPosition, maxExtent);
      _lastScrollEventTime = currentTime;
    }

    // Track reaching end of list
    if (!_hasReachedEnd && currentPosition >= maxExtent * 0.95) {
      _hasReachedEnd = true;
      _trackListEndReached();
    }


  }

  void _trackListView() {
    _analytics.trackContentEngagement(
      widget.listId,
      widget.listType,
      action: 'list_view',
      sourceContext: widget.sourceContext,
    );
  }

  void _trackScrollStart() {
    _analytics.trackContentEngagement(
      widget.listId,
      widget.listType,
      action: 'scroll_start',
      sourceContext: widget.sourceContext,
    );
  }

  void _trackScrollBehavior(double position, double maxExtent) {
    final scrollPercent = maxExtent > 0 ? (position / maxExtent * 100).round() : 0;
    
    _analytics.trackContentEngagement(
      widget.listId,
      widget.listType,
      action: 'scroll_progress',
      scrollPercentage: scrollPercent.toDouble(),
      sourceContext: widget.sourceContext,
    );
  }

  void _trackListEndReached() {
    final duration = _scrollStartTime != null 
        ? DateTime.now().difference(_scrollStartTime!)
        : Duration.zero;
    
    _analytics.trackContentEngagement(
      widget.listId,
      widget.listType,
      action: 'list_end_reached',
      engagementTime: duration,
      sourceContext: widget.sourceContext,
    );
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Widget para tracking de item individual em listas
class InstrumentedListItem extends StatefulWidget {
  final String itemId;
  final String itemType;
  final int itemIndex;
  final String listContext;
  final Widget child;
  final VoidCallback? onTap;
  final Map<String, dynamic>? additionalData;

  const InstrumentedListItem({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemIndex,
    required this.listContext,
    required this.child,
    this.onTap,
    this.additionalData,
  });

  @override
  State<InstrumentedListItem> createState() => _InstrumentedListItemState();
}

class _InstrumentedListItemState extends State<InstrumentedListItem> {
  late AnalyticsService _analytics;
  DateTime? _viewStartTime;

  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
  }

  Future<void> _initializeAnalytics() async {
    _analytics = await AnalyticsService.getInstance();
  }

  // void _trackItemView() {
  //   if (_hasBeenViewed) return;
  //   
  //   _hasBeenViewed = true;
  //   _viewStartTime = DateTime.now();

  //   _analytics.trackContentEngagement(
  //     widget.itemId,
  //     widget.itemType,
  //     action: 'item_view',
  //     sourceContext: widget.listContext,
  //   );
  // }

  void _trackItemTap() {
    _analytics.trackUserClick(
      'list_item_tap',
      widget.itemId,
      additionalData: {
        'item_id': widget.itemId,
        'item_type': widget.itemType,
        'item_index': widget.itemIndex,
        'list_context': widget.listContext,
        'view_duration': _viewStartTime != null 
            ? DateTime.now().difference(_viewStartTime!).inMilliseconds
            : 0,
        ...?widget.additionalData,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _trackItemTap();
        widget.onTap?.call();
      },
      child: widget.child,
    );
  }
}

/// Widget para tracking de Modal/BottomSheet interactions
class InstrumentedModal extends StatefulWidget {
  final String modalId;
  final String modalType; // 'bottom_sheet', 'dialog', 'fullscreen_modal'
  final String sourceContext;
  final Widget child;
  final VoidCallback? onDismiss;
  final Map<String, dynamic>? additionalData;

  const InstrumentedModal({
    super.key,
    required this.modalId,
    required this.modalType,
    required this.sourceContext,
    required this.child,
    this.onDismiss,
    this.additionalData,
  });

  @override
  State<InstrumentedModal> createState() => _InstrumentedModalState();
}

class _InstrumentedModalState extends State<InstrumentedModal> {
  late AnalyticsService _analytics;
  DateTime? _modalOpenTime;
  bool _hasTrackedOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
    _modalOpenTime = DateTime.now();
  }

  Future<void> _initializeAnalytics() async {
    _analytics = await AnalyticsService.getInstance();
    _trackModalOpen();
  }

  void _trackModalOpen() {
    if (_hasTrackedOpen) return;
    _hasTrackedOpen = true;

    _analytics.trackUserClick(
      'modal_open',
      widget.modalId,
      additionalData: {
        'modal_id': widget.modalId,
        'modal_type': widget.modalType,
        'source_context': widget.sourceContext,
        'open_timestamp': DateTime.now().millisecondsSinceEpoch,
        ...?widget.additionalData,
      },
    );
  }

  void _trackModalClose(String closeReason) {
    final duration = _modalOpenTime != null 
        ? DateTime.now().difference(_modalOpenTime!).inMilliseconds
        : 0;

    _analytics.trackUserClick(
      'modal_close',
      widget.modalId,
      additionalData: {
        'modal_id': widget.modalId,
        'modal_type': widget.modalType,
        'close_reason': closeReason, // 'dismiss', 'action', 'back_button'
        'duration_ms': duration,
        'source_context': widget.sourceContext,
        ...?widget.additionalData,
      },
    );
  }

  @override
  void dispose() {
    _trackModalClose('dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _trackModalClose('back_button');
          widget.onDismiss?.call();
        }
      },
      child: widget.child,
    );
  }
}

/// Helper function para instrumentar showModalBottomSheet
Future<T?> showInstrumentedModalBottomSheet<T>({
  required BuildContext context,
  required String modalId,
  required String sourceContext,
  required Widget Function(BuildContext) builder,
  Map<String, dynamic>? additionalData,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  String? barrierLabel,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
}) async {
  final analytics = await AnalyticsService.getInstance();
  
  // Track modal show intent
  analytics.trackUserClick(
    'modal_show_intent',
    modalId,
    additionalData: {
      'modal_id': modalId,
      'modal_type': 'bottom_sheet',
      'source_context': sourceContext,
      'is_dismissible': isDismissible,
      'is_scroll_controlled': isScrollControlled,
      ...?additionalData,
    },
  );

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
    builder: (context) => InstrumentedModal(
      modalId: modalId,
      modalType: 'bottom_sheet',
      sourceContext: sourceContext,
      additionalData: additionalData,
      child: builder(context),
    ),
  );
}

/// Helper function para instrumentar showDialog
Future<T?> showInstrumentedDialog<T>({
  required BuildContext context,
  required String modalId,
  required String sourceContext,
  required Widget Function(BuildContext) builder,
  Map<String, dynamic>? additionalData,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) async {
  final analytics = await AnalyticsService.getInstance();
  
  // Track dialog show intent
  analytics.trackUserClick(
    'modal_show_intent',
    modalId,
    additionalData: {
      'modal_id': modalId,
      'modal_type': 'dialog',
      'source_context': sourceContext,
      'is_dismissible': barrierDismissible,
      ...?additionalData,
    },
  );

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    builder: (context) => InstrumentedModal(
      modalId: modalId,
      modalType: 'dialog',
      sourceContext: sourceContext,
      additionalData: additionalData,
      child: builder(context),
    ),
  );
}

/// Widget para tracking de navegação
class InstrumentedNavigationAction extends StatelessWidget {
  final String routeName;
  final String actionType; // 'push', 'go', 'replace', 'pop'
  final VoidCallback? onPressed;
  final Widget child;
  final Map<String, dynamic>? additionalData;

  const InstrumentedNavigationAction({
    super.key,
    required this.routeName,
    required this.actionType,
    required this.child,
    this.onPressed,
    this.additionalData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final analytics = await AnalyticsService.getInstance();
        
        await analytics.trackUserClick(
          'navigation_action',
          routeName,
          additionalData: {
            'action_type': actionType,
            'target_route': routeName,
            'source_route': ModalRoute.of(context)?.settings.name ?? 'unknown',
            'navigation_method': actionType,
            ...?additionalData,
          },
        );

        onPressed?.call();
      },
      child: child,
    );
  }
}

/// Screen instrumentada - captura navegação e tempo de permanência
class InstrumentedScreen extends StatefulWidget {
  final String screenName;
  final Widget child;
  final Map<String, dynamic>? additionalProperties;

  const InstrumentedScreen({
    super.key,
    required this.screenName,
    required this.child,
    this.additionalProperties,
  });

  @override
  State<InstrumentedScreen> createState() => _InstrumentedScreenState();
}

class _InstrumentedScreenState extends State<InstrumentedScreen> with WidgetsBindingObserver {
  DateTime? _screenEnterTime;
  late AnalyticsService _analytics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnalytics();
    _trackScreenView();
  }

  Future<void> _initializeAnalytics() async {
    _analytics = await AnalyticsService.getInstance();
  }

  void _trackScreenView() {
    _screenEnterTime = DateTime.now();
    
    _analytics.trackScreenView(
      widget.screenName,
      properties: widget.additionalProperties,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _trackScreenExit();
    } else if (state == AppLifecycleState.resumed && _screenEnterTime == null) {
      _trackScreenView();
    }
  }

  void _trackScreenExit() {
    if (_screenEnterTime != null) {
      final duration = DateTime.now().difference(_screenEnterTime!);
      
      _analytics.trackPerformance(
        'screen_time',
        duration,
        properties: {
          'screen_name': widget.screenName,
          'session_type': 'screen_view',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _trackScreenExit();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Mixin para instrumentar transações
mixin InstrumentedTransaction {
  Future<void> trackTransactionCompleted(
    String transactionType,
    String transactionId, {
    required double amount,
    required String currency,
    String? caseId,
    String? partnerId,
    Duration? timeFromFirstContact,
    Map<String, dynamic>? serviceSummary,
    double? clientSatisfaction,
    double? providerSatisfaction,
  }) async {
    final analytics = await AnalyticsService.getInstance();

    // Track transaction completion - OBJETIVO FINAL DO FUNIL
    await analytics.trackTransactionCompleted(
      transactionType,
      transactionId,
      amount: amount,
      currency: currency,
      caseId: caseId,
      partnerId: partnerId,
      timeFromFirstContact: timeFromFirstContact,
      serviceSummary: serviceSummary,
      clientSatisfaction: clientSatisfaction,
      providerSatisfaction: providerSatisfaction,
    );
  }
}

/// Mixin para instrumentar onboarding
mixin InstrumentedOnboarding {
  Future<void> trackOnboardingStep(
    String stepId,
    String stepName, {
    required bool completed,
    Duration? timeSpent,
    int? attemptNumber,
    String? dropOffReason,
    Map<String, dynamic>? stepData,
  }) async {
    final analytics = await AnalyticsService.getInstance();

    await analytics.trackOnboardingStep(
      stepId,
      stepName,
      completed: completed,
      timeSpent: timeSpent,
      attemptNumber: attemptNumber,
      dropOffReason: dropOffReason,
      stepData: stepData,
    );
  }
}

/// Utility class para instrumentação manual
class AnalyticsInstrumentation {
  static late AnalyticsService _analytics;
  
  static Future<void> initialize() async {
    _analytics = await AnalyticsService.getInstance();
  }

  /// Track custom user interaction
  static Future<void> trackCustomInteraction(
    String eventType,
    Map<String, dynamic> properties,
  ) async {
    await _analytics.trackEvent(eventType, properties: properties);
  }

  /// Track content engagement
  static Future<void> trackContentEngagement(
    String contentId,
    String contentType, {
    required String action,
    Duration? engagementTime,
    double? scrollPercentage,
    String? sourceContext,
  }) async {
    await _analytics.trackContentEngagement(
      contentId,
      contentType,
      action: action,
      engagementTime: engagementTime,
      scrollPercentage: scrollPercentage,
      sourceContext: sourceContext,
    );
  }

  /// Track message exchange
  static Future<void> trackMessageExchange(
    String conversationId,
    String messageType, {
    required String participantId,
    int? messageLength,
    bool? hasAttachment,
    String? messageCategory,
    Duration? responseTime,
    String? caseContext,
  }) async {
    await _analytics.trackMessageExchange(
      conversationId,
      messageType,
      participantId: participantId,
      messageLength: messageLength,
      hasAttachment: hasAttachment,
      messageCategory: messageCategory,
      responseTime: responseTime,
      caseContext: caseContext,
    );
  }
}

/// Helper para criar instrumentação facilmente
class AnalyticsHelper {
  /// Wrapper para qualquer Widget com instrumentação de clique
  static Widget instrumentClick(
    Widget child,
    String elementId,
    String context, {
    Map<String, dynamic>? additionalData,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () async {
        final analytics = await AnalyticsService.getInstance();
        await analytics.trackUserClick(
          elementId,
          context,
          additionalData: additionalData,
        );
        onTap?.call();
      },
      child: child,
    );
  }

  /// Wrapper para instrumentar qualquer ação
  static VoidCallback instrumentAction(
    VoidCallback originalAction,
    String actionType,
    Map<String, dynamic> properties,
  ) {
    return () async {
      final analytics = await AnalyticsService.getInstance();
      await analytics.trackUserAction(
        actionType,
        properties: properties,
      );
      originalAction();
    };
  }
}

/**
 * EXEMPLO DE USO:
 * 
 * // Profile Card instrumentado
 * InstrumentedProfileCard(
 *   profileId: lawyer.id,
 *   profileType: 'lawyer',
 *   sourceContext: 'search_results',
 *   searchRank: index.toDouble(),
 *   child: LawyerCard(lawyer: lawyer),
 *   onTap: () => Navigator.push(...),
 * )
 * 
 * // Botão de convite instrumentado
 * InstrumentedInviteButton(
 *   recipientId: lawyer.id,
 *   invitationType: 'case_invitation',
 *   context: 'case_search',
 *   caseId: currentCase.id,
 *   matchScore: lawyer.matchScore,
 *   child: Text('Convidar'),
 *   onPressed: () => sendInvitation(),
 * )
 * 
 * // Screen instrumentada
 * InstrumentedScreen(
 *   screenName: 'lawyer_search',
 *   additionalProperties: {'case_id': caseId},
 *   child: LawyerSearchPage(),
 * )
 */