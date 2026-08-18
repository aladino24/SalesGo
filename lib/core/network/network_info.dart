import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  NetworkInfo({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Stream<List<ConnectivityResult>> get connectivityStream => _connectivity.onConnectivityChanged;
}
