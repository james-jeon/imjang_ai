import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for Connectivity instance (overridable in tests)
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Stream provider that emits true when online, false when offline
final networkStatusProvider = StreamProvider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.onConnectivityChanged.map((results) {
    // results is List<ConnectivityResult>
    // Online if any result is not 'none'
    return !results.every((r) => r == ConnectivityResult.none);
  });
});

/// Stream provider that emits true when offline, false when online
/// (inverse of networkStatusProvider)
final isOfflineProvider = StreamProvider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.onConnectivityChanged.map((results) {
    return results.every((r) => r == ConnectivityResult.none);
  });
});
