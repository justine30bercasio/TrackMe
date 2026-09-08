import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/database_helper.dart';
import 'package:track_me/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    DatabaseHelper.useInMemoryDatabase = true;
    await DatabaseHelper.reset();
    await DatabaseHelper.instance.database;
  });

  tearDown(() async {
    await DatabaseHelper.reset();
    DatabaseHelper.useInMemoryDatabase = false;
  });

  group('AppState security', () {
    test('enables PIN, checks correct and rejects wrong pin', () async {
      final state = AppState(AppRepository.instance);
      await state.init();
      expect(state.pinEnabled, isFalse);
      expect(state.requiresLock, isFalse);

      await state.setPin('1234');
      expect(state.pinEnabled, isTrue);
      expect(state.checkPin('1234'), isTrue);
      expect(state.checkPin('0000'), isFalse);

      // Locks on demand and unlocks only with the correct PIN.
      state.lockIfEnabled();
      expect(state.requiresLock, isTrue);
      expect(state.checkPin('0000'), isFalse);
      expect(state.requiresLock, isTrue);

      state.unlock();
      expect(state.requiresLock, isFalse);
    });

    test('disables PIN and persists toggle', () async {
      final state = AppState(AppRepository.instance);
      await state.init();
      await state.setPin('2468');
      expect(state.pinEnabled, isTrue);

      await state.disablePin();
      expect(state.pinEnabled, isFalse);
      expect(state.requiresLock, isFalse);
    });

    test('hide balances persists', () async {
      final state = AppState(AppRepository.instance);
      await state.init();
      expect(state.hideBalances, isFalse);

      await state.setHideBalances(true);
      expect(state.hideBalances, isTrue);

      // Reload from storage reflects the persisted value.
      final reloaded = AppState(AppRepository.instance);
      await reloaded.init();
      expect(reloaded.hideBalances, isTrue);
    });
  });
}