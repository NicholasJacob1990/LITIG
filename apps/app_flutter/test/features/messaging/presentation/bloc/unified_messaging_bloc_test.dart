import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:meu_app/src/features/messaging/presentation/bloc/unified_messaging_bloc.dart';

void main() {
  group('UnifiedMessagingBloc', () {
    late UnifiedMessagingBloc bloc;

    setUp(() {
      bloc = UnifiedMessagingBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is UnifiedMessagingInitial', () {
      expect(bloc.state, equals(const UnifiedMessagingInitial()));
    });

    group('LoadConnectedAccounts', () {
      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'emits [UnifiedMessagingLoading, AccountsLoaded] when LoadConnectedAccounts is added',
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadConnectedAccounts()),
        expect: () => [
          const UnifiedMessagingLoading(),
          isA<AccountsLoaded>()
            .having((state) => state.connectedAccounts, 'connectedAccounts', isA<Map>())
            .having((state) => state.connectedAccounts.containsKey('linkedin'), 'has linkedin account', isTrue),
        ],
      );

      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'loads accounts with correct data structure',
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadConnectedAccounts()),
        verify: (bloc) {
          final state = bloc.state as AccountsLoaded;
          final linkedinAccount = state.connectedAccounts['linkedin'];
          
          expect(linkedinAccount?.provider, equals('linkedin'));
          expect(linkedinAccount?.accountId, equals('ln_123'));
          expect(linkedinAccount?.accountName, equals('João Silva'));
          expect(linkedinAccount?.accountEmail, equals('joao@example.com'));
          expect(linkedinAccount?.isActive, isTrue);
        },
      );
    });

    group('ConnectAccount', () {
      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'emits [UnifiedMessagingLoading, AccountConnected] when ConnectAccount succeeds',
        build: () => bloc,
        act: (bloc) => bloc.add(const ConnectAccount(
          provider: 'whatsapp',
          credentials: {
            'username': 'Test User',
            'email': 'test@example.com',
          },
        )),
        expect: () => [
          const UnifiedMessagingLoading(),
          isA<AccountConnected>()
            .having((state) => state.provider, 'provider', 'whatsapp')
            .having((state) => state.account.accountName, 'account name', 'Test User'),
        ],
      );

      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'creates account with generated ID and current timestamp',
        build: () => bloc,
        act: (bloc) => bloc.add(const ConnectAccount(
          provider: 'gmail',
          credentials: {
            'username': 'Gmail User',
            'email': 'gmail@example.com',
          },
        )),
        verify: (bloc) {
          final state = bloc.state as AccountConnected;
          
          expect(state.account.provider, equals('gmail'));
          expect(state.account.accountId, startsWith('gmail_'));
          expect(state.account.accountName, equals('Gmail User'));
          expect(state.account.accountEmail, equals('gmail@example.com'));
          expect(state.account.isActive, isTrue);
          expect(state.account.lastSync, isNotNull);
        },
      );

      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'handles missing credentials gracefully',
        build: () => bloc,
        act: (bloc) => bloc.add(const ConnectAccount(
          provider: 'outlook',
          credentials: {},
        )),
        verify: (bloc) {
          final state = bloc.state as AccountConnected;
          
          expect(state.account.accountName, equals('Usuário'));
          expect(state.account.accountEmail, isNull);
        },
      );
    });

    group('DisconnectAccount', () {
      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'emits [UnifiedMessagingLoading, AccountDisconnected] when DisconnectAccount succeeds',
        build: () => bloc,
        act: (bloc) => bloc.add(const DisconnectAccount(provider: 'linkedin')),
        expect: () => [
          const UnifiedMessagingLoading(),
          isA<AccountDisconnected>()
            .having((state) => state.provider, 'provider', 'linkedin'),
        ],
      );

      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'disconnects account for any provider',
        build: () => bloc,
        act: (bloc) => bloc.add(const DisconnectAccount(provider: 'instagram')),
        verify: (bloc) {
          final state = bloc.state as AccountDisconnected;
          expect(state.provider, equals('instagram'));
        },
      );
    });

    group('LoadChats', () {
      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'emits [UnifiedMessagingLoading, ChatsLoaded] when LoadChats is added',
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadChats()),
        expect: () => [
          const UnifiedMessagingLoading(),
          isA<ChatsLoaded>()
            .having((state) => state.chats, 'chats', isA<List>())
            .having((state) => state.chats.length, 'chats count', greaterThan(0)),
        ],
      );

      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'loads chats from multiple providers',
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadChats()),
        verify: (bloc) {
          final state = bloc.state as ChatsLoaded;
          
          expect(state.chats.length, equals(4));
          
          // Check that we have chats from different providers
          final providers = state.chats.map((chat) => chat.provider).toSet();
          expect(providers, containsAll(['linkedin', 'whatsapp', 'gmail', 'internal']));
        },
      );
    });

    group('SendMessage', () {
      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'emits [UnifiedMessagingLoading, MessageSent] when SendMessage succeeds',
        build: () => bloc,
        act: (bloc) => bloc.add(const SendMessage(
          chatId: 'chat_123',
          provider: 'whatsapp',
          content: 'Hello, World!',
        )),
        expect: () => [
          const UnifiedMessagingLoading(),
          isA<MessageSent>()
            .having((state) => state.message.content, 'message content', 'Hello, World!')
            .having((state) => state.message.chatId, 'chat ID', 'chat_123'),
        ],
      );

      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'creates outgoing message with correct properties',
        build: () => bloc,
        act: (bloc) => bloc.add(const SendMessage(
          chatId: 'chat_456',
          provider: 'linkedin',
          content: 'Professional message',
          messageType: 'text',
        )),
        verify: (bloc) {
          final state = bloc.state as MessageSent;
          
          expect(state.message.isOutgoing, isTrue);
          expect(state.message.messageType, equals('text'));
          expect(state.message.sentAt, isNotNull);
          expect(state.message.id, isNotNull);
        },
      );
    });

    group('LoadChatMessages', () {
      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'emits [UnifiedMessagingLoading, ChatMessagesLoaded] when LoadChatMessages succeeds',
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadChatMessages(
          chatId: 'chat_123',
          provider: 'whatsapp',
        )),
        expect: () => [
          const UnifiedMessagingLoading(),
          isA<ChatMessagesLoaded>()
            .having((state) => state.chatId, 'chat ID', 'chat_123')
            .having((state) => state.messages, 'messages', isA<List>())
            .having((state) => state.messages.length, 'message count', greaterThan(0)),
        ],
      );

      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'loads messages with both incoming and outgoing',
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadChatMessages(
          chatId: 'test_chat',
          provider: 'gmail',
        )),
        verify: (bloc) {
          final state = bloc.state as ChatMessagesLoaded;
          
          expect(state.messages.length, equals(3));
          
          // Check we have both incoming and outgoing messages
          final hasIncoming = state.messages.any((msg) => !msg.isOutgoing);
          final hasOutgoing = state.messages.any((msg) => msg.isOutgoing);
          
          expect(hasIncoming, isTrue);
          expect(hasOutgoing, isTrue);
        },
      );
    });

    group('SyncAllMessages', () {
      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'emits [UnifiedMessagingLoading, MessagesSync] when SyncAllMessages succeeds',
        build: () => bloc,
        act: (bloc) => bloc.add(const SyncAllMessages()),
        expect: () => [
          const UnifiedMessagingLoading(),
          isA<MessagesSync>()
            .having((state) => state.syncResults, 'sync results', isA<Map>())
            .having((state) => state.syncResults.keys.length, 'provider count', greaterThan(0)),
        ],
      );

      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'syncs messages from multiple providers',
        build: () => bloc,
        act: (bloc) => bloc.add(const SyncAllMessages()),
        verify: (bloc) {
          final state = bloc.state as MessagesSync;
          
          expect(state.syncResults.containsKey('linkedin'), isTrue);
          expect(state.syncResults.containsKey('whatsapp'), isTrue);
          expect(state.syncResults.containsKey('gmail'), isTrue);
          
          // All sync results should be positive numbers
          for (final count in state.syncResults.values) {
            expect(count, greaterThanOrEqualTo(0));
          }
        },
      );
    });

    group('StartOAuthFlow', () {
      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'emits [UnifiedMessagingLoading, OAuthFlowStarted] when StartOAuthFlow succeeds',
        build: () => bloc,
        act: (bloc) => bloc.add(const StartOAuthFlow(provider: 'linkedin')),
        expect: () => [
          const UnifiedMessagingLoading(),
          isA<OAuthFlowStarted>()
            .having((state) => state.provider, 'provider', 'linkedin')
            .having((state) => state.authUrl, 'auth URL', contains('linkedin.com/oauth')),
        ],
      );

      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'generates correct OAuth URL for different providers',
        build: () => bloc,
        act: (bloc) => bloc.add(const StartOAuthFlow(provider: 'gmail')),
        verify: (bloc) {
          final state = bloc.state as OAuthFlowStarted;
          
          expect(state.provider, equals('gmail'));
          expect(state.authUrl, contains('google.com/oauth'));
        },
      );
    });

    group('CompleteOAuthFlow', () {
      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'emits [UnifiedMessagingLoading, OAuthCompleted] when CompleteOAuthFlow succeeds',
        build: () => bloc,
        act: (bloc) => bloc.add(const CompleteOAuthFlow(
          provider: 'linkedin',
          authCode: 'auth_code_123',
        )),
        expect: () => [
          const UnifiedMessagingLoading(),
          isA<OAuthCompleted>()
            .having((state) => state.provider, 'provider', 'linkedin')
            .having((state) => state.account.provider, 'account provider', 'linkedin'),
        ],
      );

      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'creates account from OAuth completion',
        build: () => bloc,
        act: (bloc) => bloc.add(const CompleteOAuthFlow(
          provider: 'instagram',
          authCode: 'ig_auth_456',
        )),
        verify: (bloc) {
          final state = bloc.state as OAuthCompleted;
          
          expect(state.account.accountId, startsWith('oauth_'));
          expect(state.account.isActive, isTrue);
          expect(state.account.lastSync, isNotNull);
        },
      );
    });

    group('Error Handling', () {
      // Note: The current implementation doesn't throw errors in the mock methods,
      // but we can test the error state structure
      test('UnifiedMessagingError state has correct properties', () {
        const error = UnifiedMessagingError(
          message: 'Test error',
          provider: 'test_provider',
        );
        
        expect(error.message, equals('Test error'));
        expect(error.provider, equals('test_provider'));
        expect(error.props, equals(['Test error', 'test_provider']));
      });

      test('UnifiedMessagingError state without provider', () {
        const error = UnifiedMessagingError(message: 'Generic error');
        
        expect(error.message, equals('Generic error'));
        expect(error.provider, isNull);
        expect(error.props, equals(['Generic error', null]));
      });
    });

    group('State Equality', () {
      test('UnifiedMessagingInitial states are equal', () {
        expect(
          const UnifiedMessagingInitial(),
          equals(const UnifiedMessagingInitial()),
        );
      });

      test('UnifiedMessagingLoading states are equal', () {
        expect(
          const UnifiedMessagingLoading(),
          equals(const UnifiedMessagingLoading()),
        );
      });

      test('AccountsLoaded states with same data are equal', () {
        const accounts = <String, ConnectedAccount>{};
        
        expect(
          const AccountsLoaded(connectedAccounts: accounts),
          equals(const AccountsLoaded(connectedAccounts: accounts)),
        );
      });

      test('UnifiedMessagingError states with same data are equal', () {
        expect(
          const UnifiedMessagingError(message: 'Error', provider: 'test'),
          equals(const UnifiedMessagingError(message: 'Error', provider: 'test')),
        );
      });
    });

    group('Event Equality', () {
      test('LoadConnectedAccounts events are equal', () {
        expect(
          const LoadConnectedAccounts(),
          equals(const LoadConnectedAccounts()),
        );
      });

      test('ConnectAccount events with same data are equal', () {
        expect(
          const ConnectAccount(provider: 'test', credentials: {'key': 'value'}),
          equals(const ConnectAccount(provider: 'test', credentials: {'key': 'value'})),
        );
      });

      test('SendMessage events with same data are equal', () {
        expect(
          const SendMessage(chatId: 'chat1', provider: 'test', content: 'hello'),
          equals(const SendMessage(chatId: 'chat1', provider: 'test', content: 'hello')),
        );
      });
    });

    group('Integration Tests', () {
      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'complete workflow: load accounts -> connect account -> load chats -> send message',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const LoadConnectedAccounts());
          await Future.delayed(const Duration(milliseconds: 1100));
          
          bloc.add(const ConnectAccount(
            provider: 'whatsapp', 
            credentials: {'username': 'Test User'}
          ));
          await Future.delayed(const Duration(milliseconds: 2100));
          
          bloc.add(const LoadChats());
          await Future.delayed(const Duration(milliseconds: 1100));
          
          bloc.add(const SendMessage(
            chatId: 'chat_123',
            provider: 'whatsapp',
            content: 'Integration test message',
          ));
        },
        expect: () => [
          const UnifiedMessagingLoading(),
          isA<AccountsLoaded>(),
          const UnifiedMessagingLoading(),
          isA<AccountConnected>(),
          const UnifiedMessagingLoading(),
          isA<ChatsLoaded>(),
          const UnifiedMessagingLoading(),
          isA<MessageSent>(),
        ],
      );

      blocTest<UnifiedMessagingBloc, UnifiedMessagingState>(
        'OAuth flow: start -> complete',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const StartOAuthFlow(provider: 'linkedin'));
          await Future.delayed(const Duration(milliseconds: 1100));
          
          bloc.add(const CompleteOAuthFlow(
            provider: 'linkedin',
            authCode: 'test_auth_code',
          ));
        },
        expect: () => [
          const UnifiedMessagingLoading(),
          isA<OAuthFlowStarted>(),
          const UnifiedMessagingLoading(),
          isA<OAuthCompleted>(),
        ],
      );
    });
  });
}