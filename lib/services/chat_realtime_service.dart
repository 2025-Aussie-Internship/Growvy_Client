import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// 채팅방 실시간 메시지 이벤트.
class ChatIncomingEvent {
  const ChatIncomingEvent({required this.roomId, required this.raw});

  final int roomId;
  final Map<String, dynamic> raw;
}

/// 채팅 리스트용 STOMP 구독 (채팅방별 토픽).
class ChatRealtimeService {
  ChatRealtimeService._();

  static final ChatRealtimeService instance = ChatRealtimeService._();

  static const String wsUrl =
      'wss://growvy.mirim-it-show.site/ws-stomp/websocket';

  StompClient? _client;
  Set<int> _roomIds = {};
  bool _isConnecting = false;

  final StreamController<ChatIncomingEvent> _events =
      StreamController<ChatIncomingEvent>.broadcast();

  Stream<ChatIncomingEvent> get messages => _events.stream;

  void connect() {
    if (_client != null || _isConnecting) return;
    _isConnecting = true;

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          debugPrint('[ChatRT] websocket error: $error');
          _scheduleReconnect();
        },
        onDisconnect: (StompFrame frame) {
          debugPrint('[ChatRT] disconnected');
          _client = null;
          _isConnecting = false;
          _scheduleReconnect();
        },
      ),
    );
    _client!.activate();
  }

  void _scheduleReconnect() {
    if (_roomIds.isEmpty) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (_client == null && _roomIds.isNotEmpty) {
        connect();
      }
    });
  }

  void _onConnect(StompFrame frame) {
    _isConnecting = false;
    debugPrint('[ChatRT] connected, subscribing ${_roomIds.length} rooms');
    for (final roomId in _roomIds) {
      _subscribeRoom(roomId);
    }
  }

  void _subscribeRoom(int roomId) {
    _client?.subscribe(
      destination: '/sub/chat/room/$roomId',
      callback: (StompFrame frame) {
        if (frame.body == null) return;
        try {
          final decoded = jsonDecode(frame.body!);
          if (decoded is! Map) return;
          final raw = Map<String, dynamic>.from(decoded);
          final resolvedId = _resolveRoomId(raw, roomId);
          _events.add(ChatIncomingEvent(roomId: resolvedId, raw: raw));
        } catch (e) {
          debugPrint('[ChatRT] parse error: $e');
        }
      },
    );
  }

  int _resolveRoomId(Map<String, dynamic> raw, int fallback) {
    final value = raw['chatRoomId'] ?? raw['roomId'] ?? fallback;
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  /// 구독할 채팅방 목록을 갱신한다. 변경 시 연결을 재설정한다.
  void updateRoomSubscriptions(Iterable<int> roomIds) {
    final next = roomIds.toSet();
    if (setEquals(next, _roomIds) && _client != null) return;

    _roomIds = next;
    if (_roomIds.isEmpty) {
      _client?.deactivate();
      _client = null;
      _isConnecting = false;
      return;
    }

    if (_client != null) {
      _client!.deactivate();
      _client = null;
      _isConnecting = false;
    }
    connect();
  }

  void dispose() {
    _client?.deactivate();
    _client = null;
    _isConnecting = false;
    _roomIds = {};
  }
}
