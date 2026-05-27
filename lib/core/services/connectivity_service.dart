import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  Future<bool> get isOnline async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }
}
