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

class LoadUnipileCalendarEvents extends UnifiedMessagingEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  
  const LoadUnipileCalendarEvents({this.startDate, this.endDate});

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

// ===== NOVOS EVENTS WHATSAPP =====

class SendWhatsAppMessage extends UnifiedMessagingEvent {
  final String accountId;
  final String phone;
  final String message;
  final List<String>? attachments;
  
  const SendWhatsAppMessage({
    required this.accountId,
    required this.phone,
    required this.message,
    this.attachments,
  });

  @override
  List<Object?> get props => [accountId, phone, message, attachments];
}

class SendWhatsAppVoiceMessage extends UnifiedMessagingEvent {
  final String accountId;
  final String phone;
  final String audioFilePath;
  final Duration duration;
  
  const SendWhatsAppVoiceMessage({
    required this.accountId,
    required this.phone,
    required this.audioFilePath,
    required this.duration,
  });

  @override
  List<Object?> get props => [accountId, phone, audioFilePath, duration];
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
    on<LoadUnipileCalendarEvents>(_onLoadCalendarEvents);
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
          accountId: emailAccount.id,
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
          accountId: calendarAccount.id,
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
      AppLogger.error('Erro ao carregar mensagens unificadas, usando mock', error: e);
      
      // Fallback mock para desenvolvimento/teste
      final mockAccounts = <UnipileAccount>[];
      final mockEmails = <UnipileEmail>[];
      final mockMessages = <UnipileMessage>[];
      final mockCalendarEvents = <UnipileCalendarEvent>[];
      
      emit(UnifiedMessagingLoaded(
        emails: mockEmails,
        messages: mockMessages,
        calendarEvents: mockCalendarEvents,
        connectedAccounts: mockAccounts,
        hasEmailAccount: false,
        hasCalendarAccount: false,
      ));
    }
  }

  Future<void> _onLoadCalendarEvents(
    LoadUnipileCalendarEvents event,
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
            accountId: calendarAccount.id,
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

          final result = await _unipileService.sendEmail(
            accountId: emailAccount.id,
            to: event.to,
            subject: event.subject,
            body: event.body,
          );

          if (result['success'] == true) {
            emit(const UnifiedMessagingSent(successMessage: 'Email enviado com sucesso!'));
            // Recarregar mensagens
            add(const LoadUnifiedMessages(refresh: true));
          } else {
            emit(const UnifiedMessagingError(message: 'Falha ao enviar email'));
          }
        } else {
          emit(const UnifiedMessagingError(message: 'Nenhuma conta de email conectada'));
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

        final result = await _unipileService.sendChatMessage(
          accountId: messagingAccount.id,
          chatId: event.chatId,
          message: event.message,
        );

        if (result['success'] == true) {
          emit(const UnifiedMessagingSent(successMessage: 'Mensagem enviada com sucesso!'));
          // Recarregar mensagens
          add(const LoadUnifiedMessages(refresh: true));
        } else {
          emit(const UnifiedMessagingError(message: 'Falha ao enviar mensagem'));
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
            description: event.description ?? '',
            attendees: event.attendees,
          );

          emit(const UnifiedMessagingSent(successMessage: 'Evento criado com sucesso!'));
          
          // Atualizar lista de eventos
          final updatedEvents = [...currentState.calendarEvents, newEvent];
          emit(currentState.copyWith(calendarEvents: updatedEvents));
          
        } else {
          emit(const UnifiedMessagingError(message: 'Nenhuma conta de calendário conectada'));
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
        recipient: event.recipientId,
        subject: event.subject,
        message: event.body,
      );

      if (result['success'] == true) {
        emit(const UnifiedMessagingSent(successMessage: 'InMail enviado com sucesso!'));
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
        recipient: event.userId,
        message: event.message ?? '',
      );

      if (result['success'] == true) {
        emit(const UnifiedMessagingSent(successMessage: 'Convite LinkedIn enviado com sucesso!'));
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
        emit(const UnifiedMessagingSent(successMessage: 'Email respondido com sucesso!'));
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
        emit(const UnifiedMessagingSent(successMessage: 'Email arquivado com sucesso!'));
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
        emit(const UnifiedMessagingSent(successMessage: 'Rascunho criado com sucesso!'));
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
