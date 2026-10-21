import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  // Singleton para garantir que exista apenas UMA conexão aberta no app inteiro
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late io.Socket socket;

  void initSocket(String baseUrl) {
    socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) => debugPrint('⚡ Conectado ao NestJS via Socket.io'));
    socket.onDisconnect((_) => debugPrint('❌ Desconectado do Socket.io'));
  }
}
