// TC-NET-001 ~ TC-NET-007
// 대상: lib/core/providers/network_provider.dart (S2에서 구현)
// 레이어: Unit — connectivity_plus 스트림 래퍼, 오프라인 감지

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imjang_app/core/providers/network_provider.dart';

import 'network_provider_test.mocks.dart';

@GenerateMocks([Connectivity])
void main() {
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockConnectivity = MockConnectivity();
  });

  group('networkStatusProvider — bool 스트림', () {
    test(
      'TC-NET-001: WiFi 연결 상태 → true emit',
      () async {
        when(mockConnectivity.onConnectivityChanged).thenAnswer(
          (_) => Stream.value([ConnectivityResult.wifi]),
        );

        final container = ProviderContainer(
          overrides: [
            connectivityProvider.overrideWithValue(mockConnectivity),
          ],
        );
        addTearDown(container.dispose);

        final stream = container.read(networkStatusProvider.stream);
        await expectLater(stream, emits(isTrue));
      },
    );

    test(
      'TC-NET-002: 모바일(LTE/5G) 연결 상태 → true emit',
      () async {
        when(mockConnectivity.onConnectivityChanged).thenAnswer(
          (_) => Stream.value([ConnectivityResult.mobile]),
        );

        final container = ProviderContainer(
          overrides: [
            connectivityProvider.overrideWithValue(mockConnectivity),
          ],
        );
        addTearDown(container.dispose);

        final stream = container.read(networkStatusProvider.stream);
        await expectLater(stream, emits(isTrue));
      },
    );

    test(
      'TC-NET-003: 연결 없음(none) → false emit',
      () async {
        when(mockConnectivity.onConnectivityChanged).thenAnswer(
          (_) => Stream.value([ConnectivityResult.none]),
        );

        final container = ProviderContainer(
          overrides: [
            connectivityProvider.overrideWithValue(mockConnectivity),
          ],
        );
        addTearDown(container.dispose);

        final stream = container.read(networkStatusProvider.stream);
        await expectLater(stream, emits(isFalse));
      },
    );

    test(
      'TC-NET-004: 온라인 → 오프라인 전환 → 순서대로 [true, false] emit',
      () async {
        final controller = StreamController<List<ConnectivityResult>>();

        when(mockConnectivity.onConnectivityChanged).thenAnswer(
          (_) => controller.stream,
        );

        final container = ProviderContainer(
          overrides: [
            connectivityProvider.overrideWithValue(mockConnectivity),
          ],
        );
        addTearDown(() {
          container.dispose();
          controller.close();
        });

        controller.add([ConnectivityResult.wifi]);
        controller.add([ConnectivityResult.none]);

        final stream = container.read(networkStatusProvider.stream);
        await expectLater(
          stream,
          emitsInOrder([isTrue, isFalse]),
        );
      },
    );

    test(
      'TC-NET-005: 오프라인 → 온라인 복구 → 순서대로 [false, true] emit',
      () async {
        final controller = StreamController<List<ConnectivityResult>>();

        when(mockConnectivity.onConnectivityChanged).thenAnswer(
          (_) => controller.stream,
        );

        final container = ProviderContainer(
          overrides: [
            connectivityProvider.overrideWithValue(mockConnectivity),
          ],
        );
        addTearDown(() {
          container.dispose();
          controller.close();
        });

        controller.add([ConnectivityResult.none]);
        controller.add([ConnectivityResult.wifi]);

        final stream = container.read(networkStatusProvider.stream);
        await expectLater(
          stream,
          emitsInOrder([isFalse, isTrue]),
        );
      },
    );
  });

  group('isOfflineProvider — 현재 오프라인 여부 (bool)', () {
    test(
      'TC-NET-006: 오프라인 상태에서 isOfflineProvider → true',
      () async {
        when(mockConnectivity.onConnectivityChanged).thenAnswer(
          (_) => Stream.value([ConnectivityResult.none]),
        );
        when(mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.none],
        );

        final container = ProviderContainer(
          overrides: [
            connectivityProvider.overrideWithValue(mockConnectivity),
          ],
        );
        addTearDown(container.dispose);

        // isOfflineProvider는 networkStatusProvider를 보고 반전
        final stream = container.read(isOfflineProvider.stream);
        await expectLater(stream, emits(isTrue));
      },
    );

    test(
      'TC-NET-007: 온라인 상태에서 isOfflineProvider → false',
      () async {
        when(mockConnectivity.onConnectivityChanged).thenAnswer(
          (_) => Stream.value([ConnectivityResult.wifi]),
        );
        when(mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => [ConnectivityResult.wifi],
        );

        final container = ProviderContainer(
          overrides: [
            connectivityProvider.overrideWithValue(mockConnectivity),
          ],
        );
        addTearDown(container.dispose);

        final stream = container.read(isOfflineProvider.stream);
        await expectLater(stream, emits(isFalse));
      },
    );
  });
}
