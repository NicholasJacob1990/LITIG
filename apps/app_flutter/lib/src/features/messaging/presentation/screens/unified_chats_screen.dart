import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/app_colors.dart';
import 'package:meu_app/src/core/utils/logger.dart';
import 'package:meu_app/src/core/services/unipile_service.dart';
import 'package:meu_app/src/features/messaging/presentation/bloc/unified_messaging_bloc.dart';
import 'package:meu_app/src/features/messaging/presentation/widgets/calendar_integration_widget.dart';
import 'package:meu_app/src/features/messaging/presentation/widgets/email_actions_widget.dart';
import 'package:meu_app/src/features/messaging/presentation/widgets/linkedin_actions_widget.dart';
import 'package:meu_app/src/features/calendar/presentation/bloc/calendar_bloc.dart' as calendar;
import 'package:timeago/timeago.dart' as timeago;

class UnifiedChatsScreen extends StatefulWidget {
  const UnifiedChatsScreen({super.key});

  @override
  State<UnifiedChatsScreen> createState() => _UnifiedChatsScreenState();
}

class _UnifiedChatsScreenState extends State<UnifiedChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UnifiedMessagingBloc _messagingBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _messagingBloc = UnifiedMessagingBloc();
    
    // Carregar dados na inicialização
    _messagingBloc.add(const LoadUnifiedMessages());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messagingBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _messagingBloc),
        BlocProvider(
          create: (context) => calendar.CalendarBloc()
            ..add(calendar.LoadCalendarEvents(
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 30)),
            )),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comunicações'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(LucideIcons.messageCircle), text: 'Mensagens'),
              Tab(icon: Icon(LucideIcons.mail), text: 'E-mails'),
              Tab(icon: Icon(LucideIcons.calendar), text: 'Calendário'),
            ],
          ),
          actions: [
            BlocBuilder<UnifiedMessagingBloc, UnifiedMessagingState>(
              builder: (context, state) {
                return PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.plus),
                  onSelected: (value) => _handleMenuAction(context, value, state),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'connect_gmail',
                      child: ListTile(
                        leading: Icon(LucideIcons.mail, color: Colors.red),
                        title: Text('Conectar Gmail'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'connect_outlook',
                      child: ListTile(
                        leading: Icon(LucideIcons.mail, color: Colors.blue),
                        title: Text('Conectar Outlook'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'send_email',
                      child: ListTile(
                        leading: Icon(LucideIcons.send),
                        title: Text('Novo E-mail'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'create_event',
                      child: ListTile(
                        leading: Icon(LucideIcons.calendarPlus),
                        title: Text('Novo Evento'),
                        dense: true,
                      ),
                    ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: () => _messagingBloc.add(const LoadUnifiedMessages(refresh: true)),
            ),
          ],
        ),
        body: BlocListener<UnifiedMessagingBloc, UnifiedMessagingState>(
          listener: (context, state) {
            if (state is UnifiedMessagingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is UnifiedMessagingSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is UnifiedMessagingConnected) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${state.newAccount.provider} conectado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMessagesTab(),
              _buildEmailsTab(),
              _buildCalendarTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    return BlocBuilder<UnifiedMessagingBloc, UnifiedMessagingState>(
      builder: (context, state) {
        if (state is UnifiedMessagingLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is UnifiedMessagingLoaded) {
          final messages = state.messages;
          final connectedAccounts = state.connectedAccounts
              .where((account) => ['whatsapp', 'telegram', 'linkedin'].contains(account.provider))
              .toList();

          if (messages.isEmpty && connectedAccounts.isEmpty) {
            return _buildEmptyState(
              icon: LucideIcons.messageCircle,
              title: 'Nenhuma mensagem',
              subtitle: 'Conecte contas de messaging para ver mensagens',
              action: 'Conectar WhatsApp/LinkedIn',
              onActionPressed: () => _showConnectMessagingDialog(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _messagingBloc.add(const LoadUnifiedMessages(refresh: true));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + _getAdditionalSections(connectedAccounts),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildConnectionsHeader(connectedAccounts);
                }
                
                // LinkedIn Actions Widget
                if (index == 1 && _hasLinkedInAccount(connectedAccounts)) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: LinkedInActionsWidget(
                      accountId: _getLinkedInAccount(connectedAccounts)?.id ?? '',
                    ),
                  );
                }
                
                final messageIndex = index - _getAdditionalSections(connectedAccounts);
                if (messageIndex >= 0 && messageIndex < messages.length) {
                  final message = messages[messageIndex];
                  return _buildMessageCard(message);
                }
                
                return const SizedBox.shrink();
              },
      ),
    );
  }

        return _buildEmptyState(
          icon: LucideIcons.messageCircle,
          title: 'Erro ao carregar mensagens',
          subtitle: 'Tente novamente ou verifique sua conexão',
          action: 'Tentar Novamente',
          onActionPressed: () => _messagingBloc.add(const LoadUnifiedMessages()),
        );
      },
    );
  }

  Widget _buildEmailsTab() {
    return BlocBuilder<UnifiedMessagingBloc, UnifiedMessagingState>(
      builder: (context, state) {
        if (state is UnifiedMessagingLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is UnifiedMessagingLoaded) {
          final emails = state.emails;
          
          if (!state.hasEmailAccount) {
            return _buildEmptyState(
              icon: LucideIcons.mail,
              title: 'Nenhuma conta de e-mail conectada',
              subtitle: 'Conecte Gmail ou Outlook para ver seus e-mails',
              action: 'Conectar E-mail',
              onActionPressed: () => _showConnectEmailDialog(context),
            );
          }

          if (emails.isEmpty) {
            return _buildEmptyState(
              icon: LucideIcons.mailOpen,
              title: 'Caixa de entrada vazia',
              subtitle: 'Você não tem novos e-mails',
              action: 'Atualizar',
              onActionPressed: () => _messagingBloc.add(const LoadUnifiedMessages(refresh: true)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _messagingBloc.add(const LoadUnifiedMessages(refresh: true));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: emails.length,
              itemBuilder: (context, index) {
                final email = emails[index];
                return _buildEmailCard(email);
              },
            ),
          );
        }

        return _buildEmptyState(
          icon: LucideIcons.mail,
          title: 'Erro ao carregar e-mails',
          subtitle: 'Tente novamente ou verifique sua conexão',
          action: 'Tentar Novamente',
          onActionPressed: () => _messagingBloc.add(const LoadUnifiedMessages()),
        );
      },
    );
  }

  Widget _buildCalendarTab() {
    return const SingleChildScrollView(
      child: Column(
        children: [
          // Widget integrado do calendário usando Unipile V2
          CalendarIntegrationWidget(),
        ],
      ),
    );
  }

  Widget _buildConnectionsHeader(List<UnipileAccount> accounts) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.link, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
              Text(
                'Contas Conectadas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: accounts.map((account) => _buildAccountChip(account)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountChip(UnipileAccount account) {
    IconData icon;
    Color color;

    switch (account.provider.toLowerCase()) {
      case 'whatsapp':
        icon = LucideIcons.messageCircle;
        color = Colors.green;
        break;
      case 'linkedin':
        icon = LucideIcons.linkedin;
        color = Colors.blue;
        break;
      case 'telegram':
        icon = LucideIcons.send;
        color = Colors.cyan;
        break;
      default:
        icon = LucideIcons.messageSquare;
        color = Colors.grey;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        account.provider.toUpperCase(),
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _buildMessageCard(UnipileMessage message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
          child: Icon(
            LucideIcons.messageCircle,
            color: AppColors.primaryBlue,
            size: 20,
          ),
        ),
        title: Text(
          message.sender ?? 'Remetente desconhecido',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              message.timestamp != null 
                  ? timeago.format(message.timestamp, locale: 'pt_BR')
                  : 'Horário desconhecido',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          color: Colors.grey[400],
        ),
        onTap: () => _openMessageDetail(message),
      ),
    );
  }

  Widget _buildEmailCard(UnipileEmail email) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(email.id),
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          color: Colors.green,
          child: const Icon(
            LucideIcons.archive,
            color: Colors.white,
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red,
          child: const Icon(
            LucideIcons.trash2,
            color: Colors.white,
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Arquivar
            _archiveEmail(email);
            return true;
          } else if (direction == DismissDirection.endToStart) {
            // Deletar - mostrar confirmação
            return await _showDeleteConfirmation(email);
          }
          return false;
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: email.isRead 
                ? Colors.grey.withValues(alpha: 0.1)
                : AppColors.primaryBlue.withValues(alpha: 0.1),
            child: Icon(
              email.isRead ? LucideIcons.mailOpen : LucideIcons.mail,
              color: email.isRead ? Colors.grey : AppColors.primaryBlue,
              size: 20,
            ),
          ),
          title: Text(
            email.subject.isNotEmpty ? email.subject : 'Sem assunto',
            style: TextStyle(
              fontWeight: email.isRead ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email.from,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                email.receivedAt != null 
                    ? timeago.format(email.receivedAt, locale: 'pt_BR')
                    : 'Data desconhecida',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!email.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.moreVertical),
                onPressed: () => _showEmailActions(email),
                iconSize: 16,
              ),
            ],
          ),
          onTap: () => _openEmailDetail(email),
        ),
      ),
    );
  }

  Widget _buildEventCard(UnipileCalendarEvent event) {
    final isToday = _isSameDay(event.startTime, DateTime.now());
    final isPast = event.endTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isToday 
              ? Colors.orange.withValues(alpha: 0.1)
              : isPast 
                  ? Colors.grey.withValues(alpha: 0.1)
                  : AppColors.primaryBlue.withValues(alpha: 0.1),
          child: Icon(
            LucideIcons.calendar,
            color: isToday 
                ? Colors.orange
                : isPast 
                    ? Colors.grey
                    : AppColors.primaryBlue,
            size: 20,
          ),
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isPast ? Colors.grey[600] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description.isNotEmpty == true) ...[
              Text(
                event.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 2),
            ],
            Row(
              children: [
                Icon(LucideIcons.clock, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (event.location.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          color: Colors.grey[400],
        ),
        onTap: () => _openEventDetail(event),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onActionPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
      const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
      const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onActionPressed,
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, UnifiedMessagingState state) {
    switch (action) {
      case 'connect_gmail':
        _messagingBloc.add(const ConnectEmailAccount(provider: 'gmail'));
        break;
      case 'connect_outlook':
        _messagingBloc.add(const ConnectEmailAccount(provider: 'outlook'));
        break;
      case 'send_email':
        if (state is UnifiedMessagingLoaded && state.hasEmailAccount) {
          _showSendEmailDialog(context);
        } else {
          _showConnectEmailDialog(context);
        }
        break;
      case 'create_event':
        if (state is UnifiedMessagingLoaded && state.hasCalendarAccount) {
          _showCreateEventDialog(context);
        } else {
          _showConnectEmailDialog(context);
        }
        break;
    }
  }

  void _showConnectEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conectar Conta de E-mail'),
        content: const Text('Escolha um provedor para conectar sua conta de e-mail:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _messagingBloc.add(const ConnectEmailAccount(provider: 'gmail'));
            },
            child: const Text('Gmail'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _messagingBloc.add(const ConnectEmailAccount(provider: 'outlook'));
            },
            child: const Text('Outlook'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showConnectMessagingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conectar Messaging'),
        content: const Text('A conexão de contas de messaging será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSendEmailDialog(BuildContext context) {
    final toController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo E-mail'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: toController,
                decoration: const InputDecoration(
                  labelText: 'Para',
                  hintText: 'email@exemplo.com',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Assunto',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Mensagem',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (toController.text.isNotEmpty && subjectController.text.isNotEmpty) {
                Navigator.pop(context);
                _messagingBloc.add(SendEmailMessage(
                  to: toController.text,
                  subject: subjectController.text,
                  body: bodyController.text,
                ));
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime startDate = DateTime.now().add(const Duration(hours: 1));
    DateTime endDate = DateTime.now().add(const Duration(hours: 2));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Novo Evento'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Início'),
                  subtitle: Text(_formatDateTime(startDate)),
                  trailing: const Icon(LucideIcons.calendar),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startDate),
                      );
                      if (time != null) {
                        setState(() {
                          startDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          if (endDate.isBefore(startDate)) {
                            endDate = startDate.add(const Duration(hours: 1));
                          }
                        });
                      }
                    }
                  },
                ),
                ListTile(
                  title: const Text('Fim'),
                  subtitle: Text(_formatDateTime(endDate)),
                  trailing: const Icon(LucideIcons.calendar),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(endDate),
                      );
                      if (time != null) {
                        setState(() {
                          endDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _messagingBloc.add(CreateCalendarEvent(
                    title: titleController.text,
                    startTime: startDate,
                    endTime: endDate,
                    description: descriptionController.text.isEmpty 
                        ? null 
                        : descriptionController.text,
                  ));
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _openMessageDetail(UnipileMessage message) {
    AppLogger.info('Abrir detalhes da mensagem: ${message.id}');
    // TODO: Implementar tela de detalhes da mensagem
  }

  void _openEmailDetail(UnipileEmail email) {
    AppLogger.info('Abrir detalhes do e-mail: ${email.id}');
    // TODO: Implementar tela de detalhes do e-mail
  }

  void _openEventDetail(UnipileCalendarEvent event) {
    AppLogger.info('Abrir detalhes do evento: ${event.id}');
    // TODO: Implementar tela de detalhes do evento
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }

  // ===== HELPER METHODS =====

  int _getAdditionalSections(List<UnipileAccount> accounts) {
    int sections = 1; // Always have connections header
    if (_hasLinkedInAccount(accounts)) {
      sections++; // LinkedIn actions
    }
    return sections;
  }

  bool _hasLinkedInAccount(List<UnipileAccount> accounts) {
    return accounts.any((account) => account.provider == 'linkedin');
  }

  UnipileAccount? _getLinkedInAccount(List<UnipileAccount> accounts) {
    try {
      return accounts.firstWhere((account) => account.provider == 'linkedin');
    } catch (e) {
      return null;
    }
  }

  // ===== NOVOS MÉTODOS PARA AÇÕES DE EMAIL =====

  void _showEmailActions(UnipileEmail email) {
    final currentState = _messagingBloc.state;
    if (currentState is UnifiedMessagingLoaded) {
      final emailAccount = currentState.connectedAccounts.firstWhere(
        (account) => account.provider == 'gmail' || account.provider == 'outlook',
        orElse: () => throw Exception('Nenhuma conta de email encontrada'),
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => EmailActionsWidget(
          email: email,
          accountId: emailAccount.id,
          onEmailUpdated: () {
            _messagingBloc.add(const LoadUnifiedMessages(refresh: true));
          },
        ),
      );
    }
  }

  void _archiveEmail(UnipileEmail email) {
    final currentState = _messagingBloc.state;
    if (currentState is UnifiedMessagingLoaded) {
      final emailAccount = currentState.connectedAccounts.firstWhere(
        (account) => account.provider == 'gmail' || account.provider == 'outlook',
        orElse: () => throw Exception('Nenhuma conta de email encontrada'),
      );

      _messagingBloc.add(ArchiveEmail(
        emailId: email.id,
        accountId: emailAccount.id,
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email arquivado'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              // TODO: Implementar desfazer arquivamento
            },
          ),
        ),
      );
    }
  }

  Future<bool> _showDeleteConfirmation(UnipileEmail email) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Email'),
        content: Text('Deseja excluir o email "${email.subject}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
              _deleteEmail(email);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _deleteEmail(UnipileEmail email) {
    final currentState = _messagingBloc.state;
    if (currentState is UnifiedMessagingLoaded) {
      final emailAccount = currentState.connectedAccounts.firstWhere(
        (account) => account.provider == 'gmail' || account.provider == 'outlook',
        orElse: () => throw Exception('Nenhuma conta de email encontrada'),
      );

      _messagingBloc.add(DeleteEmail(
        emailId: email.id,
        accountId: emailAccount.id,
        permanent: false,
      ));
    }
  }
}

// WIDGET ANINHADO PARA A ABA DE CONVERSAS
class ConversationsView extends StatefulWidget {
  const ConversationsView({super.key});

  @override
  State<ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<ConversationsView> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<UnifiedChat> _allChats = [];
  List<ConnectedAccount> _connectedAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      _connectedAccounts = [
        ConnectedAccount(id: 'acc_1', provider: 'linkedin', accountName: 'João Silva', status: 'active', lastSync: DateTime.now().subtract(const Duration(minutes: 5))),
        ConnectedAccount(id: 'acc_2', provider: 'gmail', accountName: 'João Silva', accountEmail: 'joao@gmail.com', status: 'active', lastSync: DateTime.now().subtract(const Duration(minutes: 2))),
        ConnectedAccount(id: 'acc_3', provider: 'whatsapp', accountName: 'WhatsApp Business', status: 'active', lastSync: DateTime.now().subtract(const Duration(minutes: 1))),
      ];
      _allChats = [
        UnifiedChat(id: 'chat_1', provider: 'linkedin', chatName: 'Maria Santos', lastMessage: 'Preciso de consultoria...', lastMessageAt: DateTime.now().subtract(const Duration(minutes: 15)), unreadCount: 2),
        UnifiedChat(id: 'chat_2', provider: 'gmail', chatName: 'Dr. Carlos Mendes', lastMessage: 'Re: Proposta de parceria', lastMessageAt: DateTime.now().subtract(const Duration(hours: 2))),
        UnifiedChat(id: 'chat_3', provider: 'whatsapp', chatName: 'Ana Costa', lastMessage: 'Obrigada pela orientação!', lastMessageAt: DateTime.now().subtract(const Duration(hours: 4))),
        UnifiedChat(id: 'chat_4', provider: 'instagram', chatName: 'Empresa XYZ', lastMessage: 'Interessados em seus serviços', lastMessageAt: DateTime.now().subtract(const Duration(hours: 8)), unreadCount: 1),
      ];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryBlue,
            tabs: const [Tab(text: 'Todos'), Tab(text: 'Recentes'), Tab(text: 'Arquivados')],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAllChatsTab(), _buildRecentChatsTab(), _buildArchivedChatsTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context),
        backgroundColor: AppColors.primaryBlue,
        tooltip: 'Nova Conversa',
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildAllChatsTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final activeChats = _allChats.where((chat) => !chat.isArchived).toList();
    if (activeChats.isEmpty) return _buildEmptyState(icon: LucideIcons.messageCircle, title: 'Nenhuma conversa', subtitle: 'Suas conversas aparecerão aqui', actionText: 'Conectar Conta', onAction: () => _showConnectAccountDialog(context));
    return Column(children: [ _buildAccountsOverview(), Expanded(child: ListView.builder(itemCount: activeChats.length, itemBuilder: (context, index) => _buildChatTile(activeChats[index])) ) ]);
  }

  Widget _buildRecentChatsTab() {
     final recentChats = _allChats.where((c) => !c.isArchived && c.lastMessageAt != null && c.lastMessageAt!.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
     if (recentChats.isEmpty) return _buildEmptyState(icon: LucideIcons.clock, title: 'Nenhuma conversa recente', subtitle: 'Conversas das últimas 24 horas aparecerão aqui');
     return ListView.builder(itemCount: recentChats.length, itemBuilder: (context, index) => _buildChatTile(recentChats[index], showTimeAgo: true));
  }

  Widget _buildArchivedChatsTab() {
    final archivedChats = _allChats.where((chat) => chat.isArchived).toList();
    if (archivedChats.isEmpty) return _buildEmptyState(icon: LucideIcons.archive, title: 'Nenhuma conversa arquivada', subtitle: 'Conversas arquivadas aparecerão aqui');
    return ListView.builder(itemCount: archivedChats.length, itemBuilder: (context, index) => _buildChatTile(archivedChats[index], isArchived: true));
  }
  
  // MÉTODOS DE CONSTRUÇÃO DE UI (WIDGETS)
  Widget _buildAccountsOverview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.info.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(LucideIcons.link, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Text('Contas Conectadas', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.info)),
          const Spacer(),
          TextButton(onPressed: () => _showAccountsDialog(context), child: const Text('Gerenciar', style: TextStyle(color: AppColors.info)))
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: _connectedAccounts.map((account) => _buildProviderChip(account)).toList()),
      ]),
    );
  }

  Widget _buildProviderChip(ConnectedAccount account) {
    final config = _getProviderConfig(account.provider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: config.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: config.color.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.asset(config.svgAsset, width: 12, height: 12, colorFilter: ColorFilter.mode(config.color, BlendMode.srcIn)),
        const SizedBox(width: 4),
        Text(config.name, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: config.color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
  
  Widget _buildChatTile(UnifiedChat chat, {bool showTimeAgo = false, bool isArchived = false}) {
    final providerConfig = _getProviderConfig(chat.provider);
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(children: [
            CircleAvatar(radius: 24, backgroundColor: providerConfig.color.withValues(alpha: 0.1), child: chat.avatarUrl != null ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.network(chat.avatarUrl!, width: 48, height: 48, fit: BoxFit.cover)) : Icon(LucideIcons.user, color: providerConfig.color, size: 20)),
            Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)), child: SvgPicture.asset(providerConfig.svgAsset, width: 12, height: 12, colorFilter: ColorFilter.mode(providerConfig.color, BlendMode.srcIn)))),
          ]),
          title: Text(chat.chatName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (chat.lastMessage != null) ...[const SizedBox(height: 4), Text(chat.lastMessage!, style: theme.textTheme.bodySmall?.copyWith(color: chat.unreadCount > 0 ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal), maxLines: 2, overflow: TextOverflow.ellipsis)],
            if (showTimeAgo && chat.lastMessageAt != null) ...[const SizedBox(height: 4), Text(_formatTimeAgo(chat.lastMessageAt!), style: theme.textTheme.labelSmall?.copyWith(color: AppColors.info, fontWeight: FontWeight.w500))],
          ]),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (chat.lastMessageAt != null && !showTimeAgo) Text(_formatTimestamp(chat.lastMessageAt!), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (chat.unreadCount > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)), child: Text(chat.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              if (isArchived) ...[const SizedBox(width: 4), Icon(LucideIcons.archive, size: 12, color: theme.colorScheme.outline)],
            ]),
          ]),
          onTap: () => _openChat(context, chat),
          onLongPress: () => _showChatOptions(context, chat),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle, String? actionText, VoidCallback? onAction}) {
    final theme = Theme.of(context);
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: theme.colorScheme.outline),
      const SizedBox(height: 16),
      Text(title, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.outline)),
      const SizedBox(height: 8),
      Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.center),
      if (actionText != null && onAction != null) ...[const SizedBox(height: 24), ElevatedButton.icon(onPressed: onAction, icon: const Icon(LucideIcons.plus), label: Text(actionText), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white))],
    ])));
  }

  // MÉTODOS DE AÇÃO (HANDLERS)
  void _openChat(BuildContext context, UnifiedChat chat) {
    context.push('/unified-chat', extra: {
      'chatId': chat.id,
      'chatName': chat.chatName,
      'provider': chat.provider,
    });
  }

  void _showChatOptions(BuildContext context, UnifiedChat chat) {
    showModalBottomSheet(context: context, builder: (context) => Container(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: Icon(chat.isArchived ? LucideIcons.archiveRestore : LucideIcons.archive), title: Text(chat.isArchived ? 'Desarquivar' : 'Arquivar'), onTap: () { Navigator.pop(context); _toggleArchiveChat(chat); }),
      ListTile(leading: const Icon(LucideIcons.volumeX), title: const Text('Silenciar'), onTap: () => Navigator.pop(context)),
      ListTile(leading: const Icon(LucideIcons.trash2, color: AppColors.error), title: const Text('Deletar', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(context); _showDeleteChatDialog(context, chat); }),
    ])));
  }

  void _showAccountsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Contas Conectadas'),
      content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
        ..._connectedAccounts.map((account) {
          final config = _getProviderConfig(account.provider);
          return ListTile(leading: Icon(config.icon, color: config.color), title: Text(account.accountName ?? config.name), subtitle: Text(account.accountEmail ?? 'Conectado'), trailing: IconButton(icon: const Icon(LucideIcons.x, color: AppColors.error), onPressed: () => _disconnectAccount(account)));
        }),
        const Divider(),
        ListTile(leading: const Icon(LucideIcons.plus, color: AppColors.primaryBlue), title: const Text('Conectar Nova Conta', style: TextStyle(color: AppColors.primaryBlue)), onTap: () { Navigator.pop(context); _showConnectAccountDialog(context); }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    ));
  }
  
  void _showConnectAccountDialog(BuildContext context) { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Conectar Conta'), content: const Text('Funcionalidade em desenvolvimento'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))])); }
  void _showSearchDialog(BuildContext context) { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Buscar Conversas'), content: const TextField(decoration: InputDecoration(hintText: 'Digite para buscar...', prefixIcon: Icon(LucideIcons.search))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))])); }
  void _showNewChatDialog(BuildContext context) { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Nova Conversa'), content: const Text('Funcionalidade em desenvolvimento'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))])); }

  void _showDeleteChatDialog(BuildContext context, UnifiedChat chat) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Deletar Conversa'), content: Text('Tem certeza que deseja deletar a conversa com ${chat.chatName}?'), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      TextButton(onPressed: () { Navigator.pop(context); _deleteChat(chat); }, style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Deletar')),
    ]));
  }

  void _toggleArchiveChat(UnifiedChat chat) {
    setState(() => chat.isArchived = !chat.isArchived);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(chat.isArchived ? 'Conversa arquivada' : 'Conversa desarquivada'), backgroundColor: AppColors.success));
  }

  void _deleteChat(UnifiedChat chat) {
    setState(() => _allChats.remove(chat));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Conversa deletada'), backgroundColor: AppColors.error, action: SnackBarAction(label: 'Desfazer', textColor: Colors.white, onPressed: () => setState(() => _allChats.add(chat)))));
  }

  void _disconnectAccount(ConnectedAccount account) {
    setState(() => _connectedAccounts.remove(account));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conta ${account.provider} desconectada'), backgroundColor: AppColors.warning));
  }
  
  // MÉTODOS AUXILIARES (HELPERS)
  ProviderConfig _getProviderConfig(String provider) {
    switch (provider.toLowerCase()) {
      case 'linkedin': return const ProviderConfig(name: 'LinkedIn', icon: LucideIcons.linkedin, svgAsset: 'assets/icons/linkedin.svg', color: Color(0xFF0077B5));
      case 'instagram': return const ProviderConfig(name: 'Instagram', icon: LucideIcons.instagram, svgAsset: 'assets/icons/instagram.svg', color: Color(0xFFE4405F));
      case 'whatsapp': return const ProviderConfig(name: 'WhatsApp', icon: LucideIcons.messageCircle, svgAsset: 'assets/icons/whatsapp.svg', color: Color(0xFF25D366));
      case 'gmail': return const ProviderConfig(name: 'Gmail', icon: LucideIcons.mail, svgAsset: 'assets/icons/gmail.svg', color: Color(0xFFEA4335));
      case 'outlook': return const ProviderConfig(name: 'Outlook', icon: LucideIcons.building, svgAsset: 'assets/icons/outlook.svg', color: Color(0xFF0078D4));
      default: return const ProviderConfig(name: 'Mensagem', icon: LucideIcons.messageCircle, svgAsset: 'assets/icons/whatsapp.svg', color: Colors.grey);
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    if (now.difference(dateTime).inDays == 0) return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '${dateTime.day}/${dateTime.month}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) return 'há ${difference.inDays} dia${difference.inDays > 1 ? 's' : ''}';
    if (difference.inHours > 0) return 'há ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    if (difference.inMinutes > 0) return 'há ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    return 'agora';
  }
}

// CLASSES DE MODELO
class UnifiedChat {
  final String id;
  final String provider;
  final String chatName;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  bool isArchived;
  UnifiedChat({required this.id, required this.provider, required this.chatName, this.avatarUrl, this.lastMessage, this.lastMessageAt, this.unreadCount = 0, this.isArchived = false});
}

class ConnectedAccount {
  final String id;
  final String provider;
  final String? accountName;
  final String? accountEmail;
  final String status;
  final DateTime? lastSync;
  const ConnectedAccount({required this.id, required this.provider, this.accountName, this.accountEmail, required this.status, this.lastSync});
}

class ProviderConfig {
  final String name;
  final IconData icon;
  final String svgAsset;
  final Color color;
  const ProviderConfig({required this.name, required this.icon, required this.svgAsset, required this.color});
}