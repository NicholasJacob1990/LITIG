import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/core/services/api_service.dart';
import 'chat_triage_event.dart';
import 'chat_triage_state.dart';

class ChatTriageBloc extends Bloc<ChatTriageEvent, ChatTriageState> {
  String? _caseId;

  ChatTriageBloc() : super(ChatTriageInitial()) {
    on<StartConversation>(_onStartConversation);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
  }

  Future<void> _onStartConversation(
      StartConversation event, Emitter<ChatTriageState> emit) async {
    print('DEBUG: _onStartConversation iniciado');
    emit(ChatTriageLoading());
    print('DEBUG: Estado ChatTriageLoading emitido');
    try {
      final response = await ApiService.startIntelligentTriage();
      _caseId = response['case_id'];
      final initialMessage = response['message'] as String;
      
      emit(ChatTriageActive(messages: [ChatMessage(text: initialMessage, isUser: false)]));
    } catch (e) {
      print('DEBUG: Erro na API, usando fallback mock: $e');
      // Fallback mock para desenvolvimento
      _caseId = 'mock_case_${DateTime.now().millisecondsSinceEpoch}';
      final mockMessage = '''Olá! Sou sua assistente jurídica inteligente. 

Estou aqui para entender seu problema legal e conectar você ao advogado mais adequado para seu caso.

Por favor, descreva brevemente sua situação jurídica. Por exemplo:
• Qual é o problema que você está enfrentando?
• Quando isso aconteceu?
• Que tipo de ajuda legal você precisa?

Pode começar me contando sobre sua situação...''';
      
      emit(ChatTriageActive(messages: [ChatMessage(text: mockMessage, isUser: false)]));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatTriageState> emit) async {
    if (_caseId == null) {
      emit(const ChatTriageError('A conversa ainda não foi iniciada.'));
      return;
    }

    final currentState = state;
    if (currentState is ChatTriageActive) {
      // Adiciona a mensagem do usuário imediatamente
      final userMessage = ChatMessage(text: event.message, isUser: true);
      final newMessages = List<ChatMessage>.from(currentState.messages)..add(userMessage);

      emit(ChatTriageActive(messages: newMessages, isTyping: true));

      try {
        final response = await ApiService.continueIntelligentTriage(
          caseId: _caseId!,
          message: event.message,
        );

        final aiMessage = response['message'] as String;
        final status = response['status'] as String;

        add(MessageReceived(aiMessage, isUser: false));

        if (status == 'completed') {
          emit(ChatTriageFinished(_caseId!));
        }

      } catch (e) {
        print('DEBUG: Erro na API continue, usando mock response: $e');
        
        // Mock response inteligente baseada na mensagem do usuário
        String mockResponse = _generateMockResponse(event.message);
        
        // Simular delay da IA
        await Future.delayed(const Duration(seconds: 1));
        
        add(MessageReceived(mockResponse, isUser: false));
        
        // Simular finalização da triagem após algumas trocas
        final messageCount = (currentState as ChatTriageActive).messages.length;
        if (messageCount >= 6) { // Após 3 pares de mensagens (user + AI)
          await Future.delayed(const Duration(seconds: 1));
          add(MessageReceived('''Perfeito! Com base nas informações que você forneceu, já tenho o suficiente para encontrar os melhores advogados para seu caso.

🎯 **Análise Concluída:**
• Área identificada: Direito Civil/Consumidor
• Urgência: Média
• Complexidade: Padrão

Agora vou conectar você com advogados especializados em sua região. Você receberá propostas personalizadas em breve!''', isUser: false));
          
          await Future.delayed(const Duration(seconds: 2));
          emit(ChatTriageFinished(_caseId!));
        }
      }
    }
  }

  void _onMessageReceived(MessageReceived event, Emitter<ChatTriageState> emit) {
     final currentState = state;
     if (currentState is ChatTriageActive) {
        final message = ChatMessage(text: event.message, isUser: event.isUser);
        final updatedMessages = List<ChatMessage>.from(currentState.messages)..add(message);
        emit(ChatTriageActive(messages: updatedMessages, isTyping: false));
     }
  }

  String _generateMockResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // Respostas baseadas em palavras-chave
    if (message.contains('trabalho') || message.contains('emprego') || message.contains('demitido') || message.contains('demissão')) {
      return '''Entendi que sua questão envolve relações trabalhistas. 

Preciso de mais alguns detalhes:
• Você foi demitido ou está com problemas no trabalho atual?
• Há quanto tempo isso aconteceu?
• Você tem carteira assinada?
• Houve alguma irregularidade específica?

Essas informações me ajudarão a encontrar o advogado trabalhista ideal para você.''';
    }
    
    if (message.contains('acidente') || message.contains('bateu') || message.contains('carro') || message.contains('moto')) {
      return '''Compreendo que houve um acidente. Isso pode envolver direito civil e/ou seguros.

Para te ajudar melhor:
• Quando aconteceu o acidente?
• Houve ferimentos ou apenas danos materiais?
• Já foi feito boletim de ocorrência?
• O seguro da outra parte está cooperando?

Com essas informações, posso encontrar advogados especialistas em acidentes de trânsito.''';
    }
    
    if (message.contains('compra') || message.contains('produto') || message.contains('serviço') || message.contains('consumidor') || message.contains('loja')) {
      return '''Sua questão parece ser de direito do consumidor. Vou te ajudar com isso!

Me conte mais:
• O que você comprou e onde?
• Qual foi o problema com o produto/serviço?
• Já tentou resolver diretamente com a empresa?
• Você tem nota fiscal ou comprovantes?

Direito do consumidor é uma área muito importante e temos ótimos especialistas.''';
    }
    
    if (message.contains('família') || message.contains('divórcio') || message.contains('pensão') || message.contains('guarda') || message.contains('casamento')) {
      return '''Entendo que é uma questão de direito de família. Essas situações requerem cuidado especial.

Para te orientar melhor:
• É sobre divórcio, guarda, pensão ou outro assunto familiar?
• Há filhos envolvidos?
• Já houve tentativa de acordo amigável?
• É urgente ou podemos tratar com calma?

Temos advogados especialistas em família que são muito experientes e sensíveis a esses casos.''';
    }
    
    // Resposta genérica para continuar a conversa
    const responses = [
      '''Obrigada por compartilhar essas informações. Estou analisando seu caso.

Preciso entender mais alguns pontos:
• Há urgência para resolver essa situação?
• Você já consultou algum advogado sobre isso?
• Você tem documentos relacionados ao caso?
• Em qual cidade você está localizado?''',
      
      '''Perfeito! Essas informações são muito úteis. 

Para completar a análise:
• Qual o valor aproximado envolvido (se houver)?
• Você prefere tentar um acordo primeiro ou partir para ação judicial?
• Há prazos legais que precisamos respeitar?
• Você tem condições de arcar com custos processuais se necessário?''',
      
      '''Muito bem! Estou começando a entender melhor seu caso.

Últimas perguntas importantes:
• Qual sua expectativa de resultado?
• Você tem preferência por advogado homem ou mulher?
• Prefere atendimento presencial ou online?
• Há algo mais importante que devo saber sobre sua situação?'''
    ];
    
    // Retorna uma resposta aleatória baseada no número de mensagens
    final currentState = state as ChatTriageActive;
    final responseIndex = (currentState.messages.length ~/ 2) % responses.length;
    return responses[responseIndex];
  }
} 