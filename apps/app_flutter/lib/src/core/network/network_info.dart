import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    // A lista de resultados pode conter mais de uma conexão ativa (ex: WiFi e Dados Móveis)
    return !result.contains(ConnectivityResult.none);
  }
} 