import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/src/features/vip/presentation/bloc/vip_status_bloc.dart';

void main() {
  group('VipStatusBloc', () {
    late VipStatusBloc vipStatusBloc;

    setUp(() {
      vipStatusBloc = VipStatusBloc();
    });

    tearDown(() {
      vipStatusBloc.close();
    });

    test('initial state should be VipStatusInitial', () {
      expect(vipStatusBloc.state, equals(VipStatusInitial()));
    });

    group('CheckVipStatus', () {
      blocTest<VipStatusBloc, VipStatusState>(
        'emits [VipStatusLoading, VipStatusLoaded] when CheckVipStatus is added',
        build: () => vipStatusBloc,
        act: (bloc) => bloc.add(
          const CheckVipStatus(userId: 'test-user-id', userType: 'client'),
        ),
        expect: () => [
          VipStatusLoading(),
          isA<VipStatusLoaded>()
            .having((state) => state.userId, 'userId', 'test-user-id')
            .having((state) => state.currentPlan, 'currentPlan', 'VIP')
            .having((state) => state.isVip, 'isVip', true)
            .having((state) => state.benefits, 'benefits', isNotEmpty),
        ],
        wait: const Duration(milliseconds: 600),
      );

      blocTest<VipStatusBloc, VipStatusState>(
        'emits benefits for VIP plan',
        build: () => vipStatusBloc,
        act: (bloc) => bloc.add(
          const CheckVipStatus(userId: 'vip-user', userType: 'client'),
        ),
        expect: () => [
          VipStatusLoading(),
          isA<VipStatusLoaded>().having(
            (state) => state.benefits,
            'benefits',
            contains('Atendimento prioritário'),
          ),
        ],
        wait: const Duration(milliseconds: 600),
      );
    });

    group('UpdateVipPlan', () {
      blocTest<VipStatusBloc, VipStatusState>(
        'emits [VipStatusLoading] and triggers CheckVipStatus when UpdateVipPlan is added',
        build: () => vipStatusBloc,
        act: (bloc) => bloc.add(
          const UpdateVipPlan(userId: 'test-user', newPlan: 'ENTERPRISE'),
        ),
        expect: () => [
          VipStatusLoading(),
          VipStatusLoading(), // From the triggered CheckVipStatus
          isA<VipStatusLoaded>(),
        ],
        wait: const Duration(milliseconds: 900),
      );
    });

    group('Edge Cases', () {
      blocTest<VipStatusBloc, VipStatusState>(
        'handles empty user ID gracefully',
        build: () => vipStatusBloc,
        act: (bloc) => bloc.add(
          const CheckVipStatus(userId: '', userType: 'client'),
        ),
        expect: () => [
          VipStatusLoading(),
          isA<VipStatusLoaded>()
            .having((state) => state.userId, 'userId', ''),
        ],
        wait: const Duration(milliseconds: 600),
      );
    });

    group('State Properties', () {
      test('VipStatusLoaded equality works correctly', () {
        final state1 = VipStatusLoaded(
          userId: 'user1',
          currentPlan: 'VIP',
          isVip: true,
          benefits: const ['benefit1'],
          lastUpdated: DateTime(2023, 1, 1),
        );

        final state2 = VipStatusLoaded(
          userId: 'user1',
          currentPlan: 'VIP',
          isVip: true,
          benefits: const ['benefit1'],
          lastUpdated: DateTime(2023, 1, 1),
        );

        expect(state1, equals(state2));
      });

      test('VipStatusError equality works correctly', () {
        const error1 = VipStatusError(message: 'Test error');
        const error2 = VipStatusError(message: 'Test error');
        const error3 = VipStatusError(message: 'Different error');

        expect(error1, equals(error2));
        expect(error1, isNot(equals(error3)));
      });
    });

    group('Events', () {
      test('CheckVipStatus props work correctly', () {
        const event1 = CheckVipStatus(userId: 'user1', userType: 'client');
        const event2 = CheckVipStatus(userId: 'user1', userType: 'client');
        const event3 = CheckVipStatus(userId: 'user2', userType: 'client');

        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });

      test('UpdateVipPlan props work correctly', () {
        const event1 = UpdateVipPlan(userId: 'user1', newPlan: 'VIP');
        const event2 = UpdateVipPlan(userId: 'user1', newPlan: 'VIP');
        const event3 = UpdateVipPlan(userId: 'user1', newPlan: 'ENTERPRISE');

        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });
    });
  });
} 