import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus { online, limited, offline }

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    } else if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
      return ConnectivityStatus.online;
    } else {
      return ConnectivityStatus.limited;
    }
  });
});
