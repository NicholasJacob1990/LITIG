import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meu_app/src/core/services/unipile_service.dart';
import 'package:meu_app/src/core/utils/logger.dart';

// ===== EVENTS =====

abstract class UnifiedMessagingEvent extends Equatable {
  const UnifiedMessagingEvent();

  @override
  List<Object?> get props => [];
}

class LoadUnifiedMessages extends UnifiedMessagingEvent {
  final bool refresh;
  
  const LoadUnifiedMessages({this.refresh = false});
  
  @override
  List<Object?> get props => [refresh];
}

class LoadCalendarEvents extends UnifiedMessagingEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  
  const LoadCalendarEvents({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class SendEmailMessage extends UnifiedMessagingEvent {
  final String to;
  final String subject;
  final String body;
  final List<String>? cc;
  
  const SendEmailMessage({
    required this.to,
    required this.subject,
    required this.body,
    this.cc,
  });

  @override
  List<Object?> get props => [to, subject, body, cc];
}

class SendChatMessage extends UnifiedMessagingEvent {
  final String chatId;
  final String message;

  const SendChatMessage({
    required this.chatId,
    required this.message,
  });

  @override
  List<Object?> get props => [chatId, message];
}

class CreateCalendarEvent extends UnifiedMessagingEvent {
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final List<String>? attendees;
  
  const CreateCalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.attendees,
  });

  @override
  List<Object?> get props => [title, startTime, endTime, description, attendees];
}

class ConnectEmailAccount extends UnifiedMessagingEvent {
  final String provider; // 'gmail' ou 'outlook'

  const ConnectEmailAccount({required this.provider});

  @override
  List<Object?> get props => [provider];
}

// ===== NOVOS EVENTS LINKEDIN =====

class SendLinkedInInMail extends UnifiedMessagingEvent {
  final String accountId;
  final String recipientId;
  final String subject;
  final String body;
  final List<String>? attachments;
  
  const SendLinkedInInMail({
    required this.accountId,
    required this.recipientId,
    required this.subject,
    required this.body,
    this.attachments,
  });

  @override
  List<Object?> get props => [accountId, recipientId, subject, body, attachments];
}

class SendLinkedInInvitation extends UnifiedMessagingEvent {
  final String accountId;
  final String userId;
  final String? message;
  
  const SendLinkedInInvitation({
    required this.accountId,
    required this.userId,
    this.message,
  });

  @override
  List<Object?> get props => [accountId, userId, message];
}

// ===== NOVOS EVENTS EMAIL MANAGEMENT =====

class ReplyToEmail extends UnifiedMessagingEvent {
  final String emailId;
  final String accountId;
  final String replyBody;
  final bool replyAll;
  
  const ReplyToEmail({
    required this.emailId,
    required this.accountId,
    required this.replyBody,
    this.replyAll = false,
  });

  @override
  List<Object?> get props => [emailId, accountId, replyBody, replyAll];
}

class DeleteEmail extends UnifiedMessagingEvent {
  final String emailId;
  final String accountId;
  final bool permanent;
  
  const DeleteEmail({
    required this.emailId,
    required this.accountId,
    this.permanent = false,
  });

  @override
  List<Object?> get props => [emailId, accountId, permanent];
}

class ArchiveEmail extends UnifiedMessagingEvent {
  final String emailId;
  final String accountId;
  
  const ArchiveEmail({
    required this.emailId,
    required this.accountId,
  });

  @override
  List<Object?> get props => [emailId, accountId];
}

class CreateEmailDraft extends UnifiedMessagingEvent {
  final String accountId;
  final String to;
  final String subject;
  final String body;
  final List<String>? attachments;
  
  const CreateEmailDraft({
    required this.accountId,
    required this.to,
    required this.subject,
    required this.body,
    this.attachments,
  });

  @override
  List<Object?> get props => [accountId, to, subject, body, attachments];
}

// ===== STATES =====

abstract class UnifiedMessagingState extends Equatable {
  const UnifiedMessagingState();

  @override
  List<Object?> get props => [];
}

class UnifiedMessagingInitial extends UnifiedMessagingState {}

class UnifiedMessagingLoading extends UnifiedMessagingState {}

class UnifiedMessagingLoaded extends UnifiedMessagingState {
  final List<UnipileEmail> emails;
  final List<UnipileMessage> messages;
  final List<UnipileCalendarEvent> calendarEvents;
  final List<UnipileAccount> connectedAccounts;
  final bool hasEmailAccount;
  final bool hasCalendarAccount;
  
  const UnifiedMessagingLoaded({
    required this.emails,
    required this.messages,
    required this.calendarEvents,
    required this.connectedAccounts,
    required this.hasEmailAccount,
    required this.hasCalendarAccount,
  });

  @override
  List<Object?> get props => [
    emails,
    messages, 
    calendarEvents,
    connectedAccounts,
    hasEmailAccount,
    hasCalendarAccount,
  ];
  
  UnifiedMessagingLoaded copyWith({
    List<UnipileEmail>? emails,
    List<UnipileMessage>? messages,
    List<UnipileCalendarEvent>? calendarEvents,
    List<UnipileAccount>? connectedAccounts,
    bool? hasEmailAccount,
    bool? hasCalendarAccount,
  }) {
    return UnifiedMessagingLoaded(
      emails: emails ?? this.emails,
      messages: messages ?? this.messages,
      calendarEvents: calendarEvents ?? this.calendarEvents,
      connectedAccounts: connectedAccounts ?? this.connectedAccounts,
      hasEmailAccount: hasEmailAccount ?? this.hasEmailAccount,
      hasCalendarAccount: hasCalendarAccount ?? this.hasCalendarAccount,
    );
  }
}

class UnifiedMessagingError extends UnifiedMessagingState {
  final String message;
  
  const UnifiedMessagingError({required this.message});

  @override
  List<Object?> get props => [message];
}

class UnifiedMessagingSending extends UnifiedMessagingState {}

class UnifiedMessagingSent extends UnifiedMessagingState {
  final String successMessage;
  
  const UnifiedMessagingSent({required this.successMessage});

  @override
  List<Object?> get props => [successMessage];
}

class UnifiedMessagingConnecting extends UnifiedMessagingState {}

class UnifiedMessagingConnected extends UnifiedMessagingState {
  final UnipileAccount newAccount;
  
  const UnifiedMessagingConnected({required this.newAccount});

  @override
  List<Object?> get props => [newAccount];
}

// ===== BLOC =====

class UnifiedMessagingBloc extends Bloc<UnifiedMessagingEvent, UnifiedMessagingState> {
  final UnipileService _unipileService;
  
  UnifiedMessagingBloc({UnipileService? unipileService}) 
      : _unipileService = unipileService ?? UnipileService(),
        super(UnifiedMessagingInitial()) {
    
    on<LoadUnifiedMessages>(_onLoadUnifiedMessages);
    on<LoadCalendarEvents>(_onLoadCalendarEvents);
    on<SendEmailMessage>(_onSendEmailMessage);
    on<SendChatMessage>(_onSendChatMessage);
    on<CreateCalendarEvent>(_onCreateCalendarEvent);
    on<ConnectEmailAccount>(_onConnectEmailAccount);
    
    // Novos handlers LinkedIn
    on<SendLinkedInInMail>(_onSendLinkedInInMail);
    on<SendLinkedInInvitation>(_onSendLinkedInInvitation);
    
    // Novos handlers Email Management
    on<ReplyToEmail>(_onReplyToEmail);
    on<DeleteEmail>(_onDeleteEmail);
    on<ArchiveEmail>(_onArchiveEmail);
    on<CreateEmailDraft>(_onCreateEmailDraft);
  }

  Future<void> _onLoadUnifiedMessages(
    LoadUnifiedMessages event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      if (event.refresh || state is UnifiedMessagingInitial) {
        emit(UnifiedMessagingLoading());
      }

      // Carregar contas conectadas
      final accounts = await _unipileService.getAccounts();
      
      final hasEmailAccount = accounts.any((account) => 
          account.provider == 'gmail' || account.provider == 'outlook');
      final hasCalendarAccount = accounts.any((account) => 
          account.provider == 'gmail' || account.provider == 'outlook');

      // Carregar emails se há conta de email
      List<UnipileEmail> emails = [];
      if (hasEmailAccount) {
        final emailAccount = accounts.firstWhere(
          (account) => account.provider == 'gmail' || account.provider == 'outlook',
        );
        emails = await _unipileService.getEmails(
          connectionId: emailAccount.id,
          limit: 50,
        );
      }

      // Carregar mensagens de chat
      List<UnipileMessage> messages = [];
      final messagingAccounts = accounts.where((account) => 
          account.provider == 'whatsapp' || 
          account.provider == 'telegram' ||
          account.provider == 'linkedin').toList();
      
      for (final account in messagingAccounts) {
        try {
          final accountMessages = await _unipileService.getMessages(
            connectionId: account.id,
            limit: 20,
          );
          messages.addAll(accountMessages);
        } catch (e) {
          AppLogger.warning('Erro ao carregar mensagens de ${account.provider}: $e');
        }
      }

      // Carregar eventos de calendário
      List<UnipileCalendarEvent> calendarEvents = [];
      if (hasCalendarAccount) {
        final calendarAccount = accounts.firstWhere(
          (account) => account.provider == 'gmail' || account.provider == 'outlook',
        );
        calendarEvents = await _unipileService.getCalendarEvents(
          connectionId: calendarAccount.id,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now().add(const Duration(days: 30)),
          limit: 100,
        );
      }

      emit(UnifiedMessagingLoaded(
        emails: emails,
        messages: messages,
        calendarEvents: calendarEvents,
        connectedAccounts: accounts,
        hasEmailAccount: hasEmailAccount,
        hasCalendarAccount: hasCalendarAccount,
      ));

    } catch (e) {
      AppLogger.error('Erro ao carregar mensagens unificadas', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao carregar mensagens: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCalendarEvents(
    LoadCalendarEvents event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      if (state is UnifiedMessagingLoaded) {
        final currentState = state as UnifiedMessagingLoaded;
        
        if (currentState.hasCalendarAccount) {
          final calendarAccount = currentState.connectedAccounts.firstWhere(
            (account) => account.provider == 'gmail' || account.provider == 'outlook',
          );
          
          final calendarEvents = await _unipileService.getCalendarEvents(
            connectionId: calendarAccount.id,
            startDate: event.startDate ?? DateTime.now().subtract(const Duration(days: 7)),
            endDate: event.endDate ?? DateTime.now().add(const Duration(days: 30)),
            limit: 100,
          );

          emit(currentState.copyWith(calendarEvents: calendarEvents));
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao carregar eventos de calendário', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao carregar calendário: ${e.toString()}'));
    }
  }

  Future<void> _onSendEmailMessage(
    SendEmailMessage event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(UnifiedMessagingSending());

      if (state is UnifiedMessagingLoaded) {
        final currentState = state as UnifiedMessagingLoaded;
        
        if (currentState.hasEmailAccount) {
          final emailAccount = currentState.connectedAccounts.firstWhere(
            (account) => account.provider == 'gmail' || account.provider == 'outlook',
          );

          final success = await _unipileService.sendEmail(
            connectionId: emailAccount.id,
            to: event.to,
            subject: event.subject,
            body: event.body,
            cc: event.cc,
          );

          if (success) {
            emit(UnifiedMessagingSent(successMessage: 'Email enviado com sucesso!'));
            // Recarregar mensagens
            add(const LoadUnifiedMessages(refresh: true));
          } else {
            emit(UnifiedMessagingError(message: 'Falha ao enviar email'));
          }
        } else {
          emit(UnifiedMessagingError(message: 'Nenhuma conta de email conectada'));
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao enviar email', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao enviar email: ${e.toString()}'));
    }
  }

  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(UnifiedMessagingSending());

      if (state is UnifiedMessagingLoaded) {
        final currentState = state as UnifiedMessagingLoaded;
        
        // Encontrar conta de messaging apropriada
        final messagingAccount = currentState.connectedAccounts.firstWhere(
          (account) => account.provider == 'whatsapp' || 
                      account.provider == 'telegram' ||
                      account.provider == 'linkedin',
          orElse: () => throw Exception('Nenhuma conta de messaging conectada'),
        );

        final success = await _unipileService.sendMessage(
          connectionId: messagingAccount.id,
          chatId: event.chatId,
          message: event.message,
        );

        if (success) {
          emit(UnifiedMessagingSent(successMessage: 'Mensagem enviada com sucesso!'));
          // Recarregar mensagens
          add(const LoadUnifiedMessages(refresh: true));
        } else {
          emit(UnifiedMessagingError(message: 'Falha ao enviar mensagem'));
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao enviar mensagem', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao enviar mensagem: ${e.toString()}'));
    }
  }

  Future<void> _onCreateCalendarEvent(
    CreateCalendarEvent event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(UnifiedMessagingSending());

      if (state is UnifiedMessagingLoaded) {
        final currentState = state as UnifiedMessagingLoaded;
        
        if (currentState.hasCalendarAccount) {
          final calendarAccount = currentState.connectedAccounts.firstWhere(
            (account) => account.provider == 'gmail' || account.provider == 'outlook',
          );

          final newEvent = await _unipileService.createCalendarEvent(
            connectionId: calendarAccount.id,
            title: event.title,
            startTime: event.startTime,
            endTime: event.endTime,
            description: event.description,
            attendees: event.attendees,
          );

          emit(UnifiedMessagingSent(successMessage: 'Evento criado com sucesso!'));
          
          // Atualizar lista de eventos
          final updatedEvents = [...currentState.calendarEvents, newEvent];
          emit(currentState.copyWith(calendarEvents: updatedEvents));
          
        } else {
          emit(UnifiedMessagingError(message: 'Nenhuma conta de calendário conectada'));
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao criar evento', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao criar evento: ${e.toString()}'));
    }
  }

  Future<void> _onConnectEmailAccount(
    ConnectEmailAccount event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(UnifiedMessagingConnecting());

      UnipileAccount newAccount;
      if (event.provider == 'gmail') {
        newAccount = await _unipileService.connectGmail();
      } else if (event.provider == 'outlook') {
        newAccount = await _unipileService.connectOutlook();
      } else {
        throw Exception('Provedor não suportado: ${event.provider}');
      }

      emit(UnifiedMessagingConnected(newAccount: newAccount));
      
      // Recarregar tudo após conectar nova conta
      add(const LoadUnifiedMessages(refresh: true));

    } catch (e) {
      AppLogger.error('Erro ao conectar conta de email', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao conectar ${event.provider}: ${e.toString()}'));
    }
  }

  // ===== NOVOS HANDLERS LINKEDIN =====

  Future<void> _onSendLinkedInInMail(
    SendLinkedInInMail event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(UnifiedMessagingSending());

      final result = await _unipileService.sendInMail(
        accountId: event.accountId,
        recipientId: event.recipientId,
        subject: event.subject,
        body: event.body,
        attachments: event.attachments,
      );

      if (result['success'] == true) {
        emit(UnifiedMessagingSent(successMessage: 'InMail enviado com sucesso!'));
        add(const LoadUnifiedMessages(refresh: true));
      } else {
        emit(UnifiedMessagingError(message: result['error'] ?? 'Falha ao enviar InMail'));
      }
    } catch (e) {
      AppLogger.error('Erro ao enviar InMail', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao enviar InMail: ${e.toString()}'));
    }
  }

  Future<void> _onSendLinkedInInvitation(
    SendLinkedInInvitation event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(UnifiedMessagingSending());

      final result = await _unipileService.sendLinkedInInvitation(
        accountId: event.accountId,
        userId: event.userId,
        message: event.message,
      );

      if (result['success'] == true) {
        emit(UnifiedMessagingSent(successMessage: 'Convite LinkedIn enviado com sucesso!'));
      } else {
        emit(UnifiedMessagingError(message: result['error'] ?? 'Falha ao enviar convite'));
      }
    } catch (e) {
      AppLogger.error('Erro ao enviar convite LinkedIn', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao enviar convite: ${e.toString()}'));
    }
  }

  // ===== NOVOS HANDLERS EMAIL MANAGEMENT =====

  Future<void> _onReplyToEmail(
    ReplyToEmail event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(UnifiedMessagingSending());

      final result = await _unipileService.replyToEmail(
        emailId: event.emailId,
        accountId: event.accountId,
        replyBody: event.replyBody,
        replyAll: event.replyAll,
      );

      if (result['success'] == true) {
        emit(UnifiedMessagingSent(successMessage: 'Email respondido com sucesso!'));
        add(const LoadUnifiedMessages(refresh: true));
      } else {
        emit(UnifiedMessagingError(message: result['error'] ?? 'Falha ao responder email'));
      }
    } catch (e) {
      AppLogger.error('Erro ao responder email', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao responder email: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteEmail(
    DeleteEmail event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(UnifiedMessagingSending());

      final result = await _unipileService.deleteEmail(
        emailId: event.emailId,
        accountId: event.accountId,
        permanent: event.permanent,
      );

      if (result['success'] == true) {
        final action = event.permanent ? 'deletado permanentemente' : 'movido para lixeira';
        emit(UnifiedMessagingSent(successMessage: 'Email $action com sucesso!'));
        add(const LoadUnifiedMessages(refresh: true));
      } else {
        emit(UnifiedMessagingError(message: result['error'] ?? 'Falha ao deletar email'));
      }
    } catch (e) {
      AppLogger.error('Erro ao deletar email', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao deletar email: ${e.toString()}'));
    }
  }

  Future<void> _onArchiveEmail(
    ArchiveEmail event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(UnifiedMessagingSending());

      final result = await _unipileService.archiveEmail(
        emailId: event.emailId,
        accountId: event.accountId,
      );

      if (result['success'] == true) {
        emit(UnifiedMessagingSent(successMessage: 'Email arquivado com sucesso!'));
        add(const LoadUnifiedMessages(refresh: true));
      } else {
        emit(UnifiedMessagingError(message: result['error'] ?? 'Falha ao arquivar email'));
      }
    } catch (e) {
      AppLogger.error('Erro ao arquivar email', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao arquivar email: ${e.toString()}'));
    }
  }

  Future<void> _onCreateEmailDraft(
    CreateEmailDraft event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(UnifiedMessagingSending());

      final result = await _unipileService.createEmailDraft(
        accountId: event.accountId,
        to: event.to,
        subject: event.subject,
        body: event.body,
        attachments: event.attachments,
      );

      if (result['success'] == true) {
        emit(UnifiedMessagingSent(successMessage: 'Rascunho criado com sucesso!'));
      } else {
        emit(UnifiedMessagingError(message: result['error'] ?? 'Falha ao criar rascunho'));
      }
    } catch (e) {
      AppLogger.error('Erro ao criar rascunho', error: e);
      emit(UnifiedMessagingError(message: 'Erro ao criar rascunho: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _unipileService.dispose();
    return super.close();
  }
}

class OAuthFlowStarted extends UnifiedMessagingState {
  final String provider;
  final String authUrl;

  const OAuthFlowStarted({
    required this.provider,
    required this.authUrl,
  });

  @override
  List<Object?> get props => [provider, authUrl];
}

class OAuthCompleted extends UnifiedMessagingState {
  final String provider;
  final ConnectedAccount account;

  const OAuthCompleted({
    required this.provider,
    required this.account,
  });

  @override
  List<Object?> get props => [provider, account];
}

class UnifiedMessagingError extends UnifiedMessagingState {
  final String message;
  final String? provider;

  const UnifiedMessagingError({
    required this.message,
    this.provider,
  });

  @override
  List<Object?> get props => [message, provider];
}

// BLoC
class UnifiedMessagingBloc extends Bloc<UnifiedMessagingEvent, UnifiedMessagingState> {
  UnifiedMessagingBloc() : super(const UnifiedMessagingInitial()) {
    on<LoadConnectedAccounts>(_onLoadConnectedAccounts);
    on<ConnectAccount>(_onConnectAccount);
    on<DisconnectAccount>(_onDisconnectAccount);
    on<LoadChats>(_onLoadChats);
    on<SendMessage>(_onSendMessage);
    on<LoadChatMessages>(_onLoadChatMessages);
    on<SyncAllMessages>(_onSyncAllMessages);
    on<StartOAuthFlow>(_onStartOAuthFlow);
    on<CompleteOAuthFlow>(_onCompleteOAuthFlow);
  }

  Future<void> _onLoadConnectedAccounts(
    LoadConnectedAccounts event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(const UnifiedMessagingLoading());
      
      // Simular carregamento de contas conectadas
      await Future.delayed(const Duration(seconds: 1));
      
      final connectedAccounts = <String, ConnectedAccount>{
        'linkedin': const ConnectedAccount(
          provider: 'linkedin',
          accountId: 'ln_123',
          accountName: 'João Silva',
          accountEmail: 'joao@example.com',
          isActive: true,
          lastSync: '2024-01-15T10:30:00Z',
        ),
      };
      
      emit(AccountsLoaded(connectedAccounts: connectedAccounts));
    } catch (e) {
      emit(UnifiedMessagingError(message: 'Erro ao carregar contas: $e'));
    }
  }

  Future<void> _onConnectAccount(
    ConnectAccount event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(const UnifiedMessagingLoading());
      
      // Simular processo de conexão
      await Future.delayed(const Duration(seconds: 2));
      
      final account = ConnectedAccount(
        provider: event.provider,
        accountId: '${event.provider}_${DateTime.now().millisecondsSinceEpoch}',
        accountName: event.credentials['username'] ?? 'Usuário',
        accountEmail: event.credentials['email'],
        isActive: true,
        lastSync: DateTime.now().toIso8601String(),
      );
      
      emit(AccountConnected(provider: event.provider, account: account));
    } catch (e) {
      emit(UnifiedMessagingError(
        message: 'Erro ao conectar ${event.provider}: $e',
        provider: event.provider,
      ));
    }
  }

  Future<void> _onDisconnectAccount(
    DisconnectAccount event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(const UnifiedMessagingLoading());
      
      // Simular desconexão
      await Future.delayed(const Duration(seconds: 1));
      
      emit(AccountDisconnected(provider: event.provider));
    } catch (e) {
      emit(UnifiedMessagingError(
        message: 'Erro ao desconectar ${event.provider}: $e',
        provider: event.provider,
      ));
    }
  }

  Future<void> _onLoadChats(
    LoadChats event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(const UnifiedMessagingLoading());
      
      // Simular carregamento de chats
      await Future.delayed(const Duration(seconds: 1));
      
      final chats = [
        const UnifiedChatModel(
          id: 'chat_1',
          provider: 'linkedin',
          chatName: 'João Silva - LinkedIn',
          lastMessage: 'Olá! Vi seu perfil...',
          lastMessageAt: '2024-01-15T14:30:00Z',
          unreadCount: 2,
        ),
        const UnifiedChatModel(
          id: 'chat_2',
          provider: 'whatsapp',
          chatName: 'Maria Santos',
          lastMessage: 'Documentos enviados ✓',
          lastMessageAt: '2024-01-15T13:45:00Z',
          unreadCount: 0,
        ),
        const UnifiedChatModel(
          id: 'chat_3',
          provider: 'internal',
          chatName: 'Advocacia Silva & Associados',
          lastMessage: 'Reunião agendada para amanhã',
          lastMessageAt: '2024-01-15T12:20:00Z',
          unreadCount: 5,
        ),
      ];
      
      emit(ChatsLoaded(chats: chats));
    } catch (e) {
      emit(UnifiedMessagingError(message: 'Erro ao carregar chats: $e'));
    }
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(const UnifiedMessagingLoading());
      
      // Simular carregamento de mensagens
      await Future.delayed(const Duration(seconds: 1));
      
      final messages = [
        UnifiedMessageModel(
          id: 'msg_1',
          chatId: event.chatId,
          providerMessageId: '${event.provider}_msg_1',
          senderName: 'João Silva',
          content: 'Olá! Vi seu perfil no LinkedIn e gostaria de conversar.',
          isOutgoing: false,
          isRead: true,
          sentAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        UnifiedMessageModel(
          id: 'msg_2',
          chatId: event.chatId,
          providerMessageId: '${event.provider}_msg_2',
          senderName: 'Você',
          content: 'Olá! Fico feliz com seu interesse. Como posso ajudar?',
          isOutgoing: true,
          isRead: true,
          sentAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
      
      emit(ChatMessagesLoaded(chatId: event.chatId, messages: messages));
    } catch (e) {
      emit(UnifiedMessagingError(message: 'Erro ao carregar mensagens: $e'));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      // Simular envio de mensagem
      await Future.delayed(const Duration(seconds: 1));
      
      final message = UnifiedMessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        chatId: event.chatId,
        providerMessageId: '${event.provider}_${DateTime.now().millisecondsSinceEpoch}',
        senderName: 'Você',
        content: event.content,
        messageType: event.messageType,
        isOutgoing: true,
        isRead: false,
        sentAt: DateTime.now(),
      );
      
      emit(MessageSent(message: message));
    } catch (e) {
      emit(UnifiedMessagingError(message: 'Erro ao enviar mensagem: $e'));
    }
  }

  Future<void> _onSyncAllMessages(
    SyncAllMessages event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(const UnifiedMessagingLoading());
      
      // Simular sincronização
      await Future.delayed(const Duration(seconds: 3));
      
      final syncResults = {
        'linkedin': 12,
        'whatsapp': 8,
        'gmail': 5,
        'internal': 15,
      };
      
      emit(MessagesSync(syncResults: syncResults));
    } catch (e) {
      emit(UnifiedMessagingError(message: 'Erro na sincronização: $e'));
    }
  }

  Future<void> _onStartOAuthFlow(
    StartOAuthFlow event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      // Simular início do fluxo OAuth
      await Future.delayed(const Duration(seconds: 1));
      
      final authUrl = _getOAuthUrl(event.provider);
      
      emit(OAuthFlowStarted(provider: event.provider, authUrl: authUrl));
    } catch (e) {
      emit(UnifiedMessagingError(
        message: 'Erro ao iniciar OAuth para ${event.provider}: $e',
        provider: event.provider,
      ));
    }
  }

  Future<void> _onCompleteOAuthFlow(
    CompleteOAuthFlow event,
    Emitter<UnifiedMessagingState> emit,
  ) async {
    try {
      emit(const UnifiedMessagingLoading());
      
      // Simular conclusão do OAuth
      await Future.delayed(const Duration(seconds: 2));
      
      final account = ConnectedAccount(
        provider: event.provider,
        accountId: '${event.provider}_oauth_${DateTime.now().millisecondsSinceEpoch}',
        accountName: 'Usuário OAuth',
        accountEmail: 'user@example.com',
        isActive: true,
        lastSync: DateTime.now().toIso8601String(),
      );
      
      emit(OAuthCompleted(provider: event.provider, account: account));
    } catch (e) {
      emit(UnifiedMessagingError(
        message: 'Erro ao completar OAuth para ${event.provider}: $e',
        provider: event.provider,
      ));
    }
  }

  String _getOAuthUrl(String provider) {
    switch (provider.toLowerCase()) {
      case 'linkedin':
        return 'https://www.linkedin.com/oauth/v2/authorization?client_id=YOUR_CLIENT_ID';
      case 'gmail':
        return 'https://accounts.google.com/oauth2/auth?client_id=YOUR_CLIENT_ID';
      case 'outlook':
        return 'https://login.microsoftonline.com/oauth2/v2.0/authorize?client_id=YOUR_CLIENT_ID';
      default:
        return 'https://oauth.example.com/auth?provider=$provider';
    }
  }
}

// Models
class ConnectedAccount extends Equatable {
  final String provider;
  final String accountId;
  final String accountName;
  final String? accountEmail;
  final bool isActive;
  final String? lastSync;

  const ConnectedAccount({
    required this.provider,
    required this.accountId,
    required this.accountName,
    this.accountEmail,
    required this.isActive,
    this.lastSync,
  });

  @override
  List<Object?> get props => [
    provider,
    accountId,
    accountName,
    accountEmail,
    isActive,
    lastSync,
  ];
}

class UnifiedChatModel extends Equatable {
  final String id;
  final String provider;
  final String chatName;
  final String? chatType;
  final String? avatarUrl;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;
  final bool isArchived;

  const UnifiedChatModel({
    required this.id,
    required this.provider,
    required this.chatName,
    this.chatType,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isArchived = false,
  });

  @override
  List<Object?> get props => [
    id,
    provider,
    chatName,
    chatType,
    avatarUrl,
    lastMessage,
    lastMessageAt,
    unreadCount,
    isArchived,
  ];
}

class UnifiedMessageModel extends Equatable {
  final String id;
  final String chatId;
  final String providerMessageId;
  final String? senderId;
  final String? senderName;
  final String? senderEmail;
  final String messageType;
  final String? content;
  final List<Map<String, dynamic>> attachments;
  final bool isOutgoing;
  final bool isRead;
  final bool isDelivered;
  final DateTime? sentAt;
  final DateTime? receivedAt;

  const UnifiedMessageModel({
    required this.id,
    required this.chatId,
    required this.providerMessageId,
    this.senderId,
    this.senderName,
    this.senderEmail,
    this.messageType = 'text',
    this.content,
    this.attachments = const [],
    required this.isOutgoing,
    required this.isRead,
    this.isDelivered = false,
    this.sentAt,
    this.receivedAt,
  });

  @override
  List<Object?> get props => [
    id,
    chatId,
    providerMessageId,
    senderId,
    senderName,
