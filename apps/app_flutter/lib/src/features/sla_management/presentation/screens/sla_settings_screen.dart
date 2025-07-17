import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';
import '../bloc/sla_analytics_bloc.dart';
import '../bloc/sla_analytics_event.dart';
import '../bloc/sla_analytics_state.dart';
import '../widgets/sla_basic_settings_widget.dart';
import '../widgets/sla_presets_widget.dart';
import '../widgets/sla_business_rules_widget.dart';
import '../widgets/sla_notifications_widget.dart';
import '../widgets/sla_escalations_widget.dart';
import '../widgets/sla_analytics_widget.dart';
import '../widgets/sla_audit_widget.dart';
import '../widgets/sla_validation_panel.dart';
import '../widgets/sla_quick_actions_fab.dart';

class SlaSettingsScreen extends StatefulWidget {
  final String firmId;
  final String? userId;

  const SlaSettingsScreen({
    super.key,
    required this.firmId,
    this.userId,
  });

  @override
  State<SlaSettingsScreen> createState() => _SlaSettingsScreenState();
}

class _SlaSettingsScreenState extends State<SlaSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SlaSettingsBloc>().add(
        LoadSlaSettingsEvent(firmId: widget.firmId, userId: widget.userId),
      );
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _currentTabIndex = _tabController.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: BlocConsumer<SlaSettingsBloc, SlaSettingsState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          if (state is SlaSettingsLoading) {
            return const _LoadingView();
          }

          if (state is SlaSettingsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => _loadSettings(),
            );
          }

          if (state is SlaSettingsLoaded) {
            return _buildMainContent(state);
          }

          if (state is SlaSettingsValidationError) {
            return _buildValidationErrorView(state);
          }

          return const _InitialView();
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Configurações SLA'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 0,
      actions: [
        BlocBuilder<SlaSettingsBloc, SlaSettingsState>(
          builder: (context, state) {
            if (state is SlaSettingsLoaded) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.needsSaving)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: const Text('Não salvo'),
                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (state.hasValidationErrors)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text('${state.validationResult!.violations.length} erros'),
                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: state.needsSaving ? _saveSettings : null,
                    tooltip: 'Salvar configurações',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadSettings,
                    tooltip: 'Atualizar',
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'validate',
                        child: ListTile(
                          leading: Icon(Icons.check_circle_outline),
                          title: Text('Validar configurações'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: ListTile(
                          leading: Icon(Icons.download),
                          title: Text('Exportar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'import',
                        child: ListTile(
                          leading: Icon(Icons.upload),
                          title: Text('Importar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'backup',
                        child: ListTile(
                          leading: Icon(Icons.backup),
                          title: Text('Criar backup'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reset',
                        child: ListTile(
                          leading: Icon(Icons.restore),
                          title: Text('Restaurar padrões'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
      bottom: _buildTabBar(),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: Theme.of(context).colorScheme.onPrimary,
      unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
      indicatorColor: Theme.of(context).colorScheme.onPrimary,
      tabs: const [
        Tab(
          icon: Icon(Icons.settings),
          text: 'Configurações',
        ),
        Tab(
          icon: Icon(Icons.bookmark),
          text: 'Presets',
        ),
        Tab(
          icon: Icon(Icons.business),
          text: 'Regras de Negócio',
        ),
        Tab(
          icon: Icon(Icons.notifications),
          text: 'Notificações',
        ),
        Tab(
          icon: Icon(Icons.trending_up),
          text: 'Escalações',
        ),
        Tab(
          icon: Icon(Icons.analytics),
          text: 'Analytics',
        ),
        Tab(
          icon: Icon(Icons.history),
          text: 'Auditoria',
        ),
      ],
    );
  }

  Widget _buildMainContent(SlaSettingsLoaded state) {
    return Column(
      children: [
        // Validation Panel (if there are issues)
        if (state.hasValidationErrors || state.hasValidationWarnings)
          SlaValidationPanel(
            validationResult: state.validationResult!,
            onDismiss: () {
              context.read<SlaSettingsBloc>().add(
                const ClearValidationErrorsEvent(),
              );
            },
          ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SlaBasicSettingsWidget(
                settings: state.settings,
                onSettingsChanged: (settings) {
                  context.read<SlaSettingsBloc>().add(
                    UpdateSlaSettingsEvent(
                      settings: settings,
                      autoValidate: true,
                    ),
                  );
                },
              ),
              SlaPresetsWidget(
                presets: state.availablePresets,
                onPresetSelected: (preset) {
                  context.read<SlaSettingsBloc>().add(
                    ApplyPresetEvent(preset: preset),
                  );
                },
                onPresetCreated: (preset) {
                  context.read<SlaSettingsBloc>().add(
                    CreateCustomPresetEvent(preset: preset),
                  );
                },
              ),
              SlaBusinessRulesWidget(),
              SlaNotificationsWidget(),
              SlaEscalationsWidget(),
              SlaAnalyticsWidget(),
              SlaAuditWidget(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValidationErrorView(SlaSettingsValidationError state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Erros de Validação',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (state.validationResult != null) ...[
            const SizedBox(height: 16),
            SlaValidationPanel(
              validationResult: state.validationResult!,
              onDismiss: () {
                context.read<SlaSettingsBloc>().add(
                  const ClearValidationErrorsEvent(),
                );
              },
            ),
          ],
          
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  context.read<SlaSettingsBloc>().add(
                    const ClearValidationErrorsEvent(),
                  );
                },
                child: const Text('Corrigir Erros'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  context.read<SlaSettingsBloc>().add(
                    const SaveSlaSettingsEvent(forceSave: true),
                  );
                },
                child: const Text('Forçar Salvamento'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return BlocBuilder<SlaSettingsBloc, SlaSettingsState>(
      builder: (context, state) {
        return SlaQuickActionsFab(
          currentTab: _currentTabIndex,
          onQuickAction: _handleQuickAction,
          isLoaded: state is SlaSettingsLoaded,
        );
      },
    );
  }

  void _handleStateChanges(BuildContext context, SlaSettingsState state) {
    if (state is SlaSettingsUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (state is SlaSettingsError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Tentar Novamente',
            onPressed: _loadSettings,
          ),
        ),
      );
    }

    if (state is SlaSettingsExported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exportado para: ${state.filePath}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'validate':
        context.read<SlaSettingsBloc>().add(
          const ValidateSettingsEvent(),
        );
        break;
      case 'export':
        context.read<SlaSettingsBloc>().add(
          const ExportSettingsEvent(),
        );
        break;
      case 'import':
        // TODO: Implement file picker
        break;
      case 'backup':
        context.read<SlaSettingsBloc>().add(
          const CreateBackupEvent(),
        );
        break;
      case 'reset':
        _showResetConfirmationDialog();
        break;
    }
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'save':
        _saveSettings();
        break;
      case 'test':
        _showTestDialog();
        break;
      case 'preset':
        _tabController.animateTo(1); // Navigate to presets tab
        break;
      case 'validate':
        context.read<SlaSettingsBloc>().add(
          const ValidateSettingsEvent(),
        );
        break;
    }
  }

  void _saveSettings() {
    context.read<SlaSettingsBloc>().add(
      const SaveSlaSettingsEvent(),
    );
  }

  void _loadSettings() {
    context.read<SlaSettingsBloc>().add(
      LoadSlaSettingsEvent(firmId: widget.firmId, userId: widget.userId),
    );
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Configurações Padrão'),
        content: const Text(
          'Esta ação irá restaurar todas as configurações para os valores padrão. '
          'As configurações atuais serão perdidas. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SlaSettingsBloc>().add(
                const ResetToDefaultEvent(confirmReset: true),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _showTestDialog() {
    showDialog(
      context: context,
      builder: (context) => _SlaTestDialog(
        onTest: (priority, caseType, startTime, overrideHours) {
          context.read<SlaSettingsBloc>().add(
            TestSlaCalculationEvent(
              priority: priority,
              caseType: caseType,
              startTime: startTime,
              overrideHours: overrideHours,
            ),
          );
        },
      ),
    );
  }
}

// Helper Widgets
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando configurações SLA...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
              'Erro ao carregar configurações',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialView extends StatelessWidget {
  const _InitialView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Configurações SLA',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Aguardando carregamento...',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlaTestDialog extends StatefulWidget {
  final Function(String priority, String caseType, DateTime startTime, int? overrideHours) onTest;

  const _SlaTestDialog({required this.onTest});

  @override
  State<_SlaTestDialog> createState() => _SlaTestDialogState();
}

class _SlaTestDialogState extends State<_SlaTestDialog> {
  String _priority = 'normal';
  String _caseType = 'litigation';
  DateTime _startTime = DateTime.now();
  int? _overrideHours;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Testar Cálculo SLA'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _priority,
            decoration: const InputDecoration(labelText: 'Prioridade'),
            items: const [
              DropdownMenuItem(value: 'normal', child: Text('Normal')),
              DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
              DropdownMenuItem(value: 'emergency', child: Text('Emergência')),
            ],
            onChanged: (value) => setState(() => _priority = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _caseType,
            decoration: const InputDecoration(labelText: 'Tipo de Caso'),
            items: const [
              DropdownMenuItem(value: 'litigation', child: Text('Contencioso')),
              DropdownMenuItem(value: 'consultancy', child: Text('Consultivo')),
              DropdownMenuItem(value: 'contract', child: Text('Contratos')),
            ],
            onChanged: (value) => setState(() => _caseType = value!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Override (horas)'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _overrideHours = value.isEmpty ? null : int.tryParse(value);
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onTest(_priority, _caseType, _startTime, _overrideHours);
          },
          child: const Text('Testar'),
        ),
      ],
    );
  }
} 