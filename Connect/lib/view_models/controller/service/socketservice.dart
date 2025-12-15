import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../userPreferences/user_preferences_screen.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;
  // Add these controllers for reactions
  final _messageReactionUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _unreadCountController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _olderPrivateMessagesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _olderGroupMessagesController =
      StreamController<Map<String, dynamic>>.broadcast();

  final _groupDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _groupDetailsController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>>
      _privateMessageHistoryController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _pinnedMessageController =
      StreamController.broadcast();

  final StreamController<Map<String, dynamic>> _unpinnedMessageController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _errorController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get messageReactionUpdatedStream =>
      _messageReactionUpdatedController.stream;
  final StreamController<Map<String, dynamic>> _messageDeletedController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get messageDeletedStream =>
      _messageDeletedController.stream;
  final StreamController<Map<String, dynamic>> _adminAddedController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get groupDetailsStream =>
      _groupDetailsController.stream;
  Stream<Map<String, dynamic>> get privateMessageHistoryStream =>
      _privateMessageHistoryController.stream;
  Stream<Map<String, dynamic>> get pinnedMessageStream =>
      _pinnedMessageController.stream;
  Stream<Map<String, dynamic>> get unpinnedMessageStream =>
      _unpinnedMessageController.stream;
  Stream<Map<String, dynamic>> get unreadCountStream =>
      _unreadCountController.stream;
  final StreamController<Map<String, dynamic>> _messageHistoryController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get messageHistoryStream =>
      _messageHistoryController.stream;
  Stream<Map<String, dynamic>> get errorStream => _errorController.stream;
  final StreamController<Map<String, dynamic>> _newMessageController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _messagesReadController =
      StreamController.broadcast();
  final StreamController<void> _reconnectController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get groupDeletedStream =>
      _groupDeletedController.stream;
  Stream<Map<String, dynamic>> get newMessageStream =>
      _newMessageController.stream;
  Stream<Map<String, dynamic>> get messagesReadStream =>
      _messagesReadController.stream;

  Stream<Map<String, dynamic>> get adminAddedStream =>
      _adminAddedController.stream;
  Stream<void> get onReconnect => _reconnectController.stream;

  Future<void> connect(String serverUrl, String token) async {
    if (isConnected) {
      log("🔌 Already connected.");
      return;
    }
    final completer = Completer<void>();
    bool connectionFinished = false;
    bool stableConnected = false;

    try {
      final userPrefs = UserPreferencesViewmodel();
      await userPrefs.init();
      final user = await userPrefs.getUser();
      final String userId = user?.user.id ?? "";

      log("🔌 Connecting to socket: $serverUrl with userId: $userId, $token");

      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .enableReconnection()
            .setReconnectionDelay(500)
            .setReconnectionDelayMax(3000)
            .setPath('/socket.io')
            .setExtraHeaders({
              'user-id': userId,
              'Authorization': 'Bearer $token',
            })
            .build(),
      );

      // Basic connection lifecycle logs and handlers
      _socket?.onConnect((_) {
        log("⚡ onConnect triggered… validating stability…");

        Future.delayed(const Duration(milliseconds: 350), () {
          if (_socket?.connected == true && !connectionFinished) {
            stableConnected = true;
            connectionFinished = true;

            log("✅ STABLE SOCKET CONNECTION ESTABLISHED");

            if (!completer.isCompleted) completer.complete();
          }
        });
      });

      _socket?.onConnectError((err) {
        log("❌ onConnectError: $err");

        if (!connectionFinished && !completer.isCompleted) {
          connectionFinished = true;
          completer.completeError("Connect error: $err");
        }
      });

      _socket?.onDisconnect((reason) {
        log("⚠️ Socket disconnected: $reason");

        if (!stableConnected && !connectionFinished && !completer.isCompleted) {
          connectionFinished = true;
          completer.completeError("Disconnected before stable connect");
        }
      });

      _socket?.onError((err) {
        log('Socket error: $err');
      });

      Future.delayed(const Duration(seconds: 6), () {
        if (!connectionFinished && !completer.isCompleted) {
          connectionFinished = true;
          completer.completeError("Socket connect timeout after 6 seconds");
          log("⏳ TIMEOUT: Connection attempt failed");
        }
      });

      _socket?.onReconnect((attempt) {
        log("🔁 Reconnected (attempt: $attempt)");
        _reconnectController.add(null);
        // re-send authentication
        _socket?.emit("authenticate", {"token": token});

        // TODO: re-join rooms if needed
        // _socket?.emit("joinRoom", {"roomId": "XYZ"});
      });

      _socket?.onReconnectAttempt((attempt) {
        log("🔄 Reconnect attempt: $attempt");
      });

      _socket?.onReconnectError((err) {
        log("❌ Reconnect error: $err");
      });

      _socket?.onReconnectFailed((_) {
        log("🔴 Reconnect FAILED permanently");
      });

      // Debug: log every event the socket receives
      _socket?.onAny((event, data) {
        log("🔥 EVENT: $event");
        log("📦 DATA: $data");
      });

      // Register all existing listeners
      _socket?.on('groupDeleted', (data) {
        try {
          _groupDeletedController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          // if data isn't map-like, try wrapping it
          _groupDeletedController.add({'data': data});
        }
        // debugPrint('group deleted: $data');
      });

      _socket?.on('olderPrivateMessagesResponse', (data) {
        try {
          _olderPrivateMessagesController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          _olderPrivateMessagesController.add({'data': data});
        }
        log('Received older private messages response: $data');
      });

      _socket?.on('olderGroupMessagesResponse', (data) {
        try {
          _olderGroupMessagesController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          _olderGroupMessagesController.add({'data': data});
        }
        log('Received older group messages response: $data');
      });

      _socket?.on('receiveMessage', (data) {
        try {
          _messageController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          // if not map, wrap
          _messageController.add({'data': data});
        }
        log('receive message work');
      });

      _socket?.on('groupDetails', (data) {
        try {
          _groupDetailsController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          _groupDetailsController.add({'data': data});
        }
        log('group details work: $data');
      });

      _socket?.on('unreadMessageUpdate', (data) {
        try {
          _unreadCountController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          _unreadCountController.add({'data': data});
        }
        // debugPrint('Unread count updated: $data');
      });

      _socket?.on('messageHistory', (data) {
        try {
          _messageHistoryController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          _messageHistoryController.add({'data': data});
        }
        log('📥 messageHistory event received: $data');
      });

      // Pin/Unpin message listeners
      _socket?.on('messagePinned', (data) {
        try {
          _pinnedMessageController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          _pinnedMessageController.add({'data': data});
        }
        // debugPrint('message pinned: $data');
      });

      _socket?.on('messageUnpinned', (data) {
        try {
          _unpinnedMessageController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          _unpinnedMessageController.add({'data': data});
        }
        // debugPrint('message unpinned: $data');
      });

      _socket?.on('error', (data) {
        try {
          _errorController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          // if it's a plain string or other type:
          _errorController.add({'error': data});
        }
      });

      _socket?.on('newMessage', (data) {
        try {
          _newMessageController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          _newMessageController.add({'data': data});
        }
        // debugPrint('new message received (forwarded): $data');
      });

      _socket?.on('messageReactionUpdated', (data) {
        try {
          _messageReactionUpdatedController
              .add(Map<String, dynamic>.from(data));
        } catch (_) {
          _messageReactionUpdatedController.add({'data': data});
        }
        // debugPrint('Message reaction updated: $data');
      });

      // Add new listener for read receipts
      _socket?.on('messagesRead', (data) {
        try {
          _messagesReadController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          _messagesReadController.add({'data': data});
        }
        // debugPrint('Messages marked as read: $data');
      });

      // Add new listener for message deletion
      _socket?.on('messageDeleted', (data) {
        try {
          _messageDeletedController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          _messageDeletedController.add({'data': data});
        }
        // debugPrint('Message deleted: $data');
      });

      // New listeners for admin functionality
      _socket?.on('adminAdded', (data) {
        try {
          _adminAddedController.add(Map<String, dynamic>.from(data));
        } catch (_) {
          _adminAddedController.add({'data': data});
        }
        // debugPrint('admin added: $data');
      });
    } catch (e, st) {
      log('Socket connect exception: $e\n$st');
      if (!completer.isCompleted) completer.completeError(e);
    }
    return completer.future;
  }

  //**********************************new update ******************** */
  void editMessage({
    required String messageId,
    required String userId,
    required String newContent,
    required Function(bool success, String? message) callback,
  }) {
    if (_socket == null) {
      callback(false, 'Socket not connected');
      return;
    }

    final editMessageData = {
      'messageId': messageId,
      'userId': userId,
      'content': newContent, // Add the new content
    };

    _socket?.emitWithAck('EditMessage', editMessageData, ack: (response) {
      // debugPrint('Edit message response: $response');

      try {
        if (response != null) {
          Map<String, dynamic> data;

          if (response is List && response.isNotEmpty) {
            data = response[0] as Map<String, dynamic>;
          } else if (response is Map<String, dynamic>) {
            data = response;
          } else {
            callback(false, 'Invalid response format');
            return;
          }

          bool success = data['success'] ?? false;
          String? message = data['message'];
          callback(success, message);
        } else {
          callback(false, 'No response received from server');
        }
      } catch (e) {
        // debugPrint('Error parsing edit message response: $e');
        callback(false, 'Error parsing server response');
      }
    });

    // debugPrint('Editing message - MessageId: $messageId, UserId: $userId');
  }

  void updateUnreadCount(String chatId, int count) {
    _unreadCountController.add({
      'chatId': chatId,
      'unreadCount': count,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void makeAdmin({
    required String groupId,
    required String userId,
    required String ownerId, // Changed from adminId to match backend
    required Function(bool success, String? message) callback,
  }) {
    if (_socket == null) {
      callback(false, 'Socket not connected');
      return;
    }

    final makeAdminData = {
      'groupId': groupId,
      'userId': userId,
      'ownerId': ownerId, // Match backend parameter name
    };

    // Emit with callback - with proper null checking
    _socket?.emitWithAck('makeAdmin', makeAdminData, ack: (response) {
      // debugPrint('Received response: $response'); // Debug print

      try {
        if (response != null) {
          // Handle different response formats
          Map<String, dynamic> data;

          if (response is List && response.isNotEmpty) {
            data = response[0] as Map<String, dynamic>;
          } else if (response is Map<String, dynamic>) {
            data = response;
          } else {
            callback(false, 'Invalid response format');
            return;
          }

          bool success = data['success'] ?? false;
          String? message = data['message'];
          callback(success, message);
        } else {
          callback(false, 'No response received from server');
        }
      } catch (e) {
        // debugPrint('Error parsing response: $e');
        callback(false, 'Error parsing server response');
      }
    });

    // debugPrint(
    //     'Making user admin - Group: $groupId, User: $userId, Owner: $ownerId');
  }

  // Method to delete a message
  void deleteMessage({
    required String messageId,
    required String userId,
    required Function(bool success, String? message) callback,
  }) {
    if (_socket == null) {
      callback(false, 'Socket not connected');
      return;
    }

    final deleteMessageData = {
      'messageId': messageId,
      'userId': userId,
    };

    _socket?.emitWithAck('deleteMessage', deleteMessageData, ack: (response) {
      // debugPrint('Delete message response: $response');

      try {
        if (response != null) {
          Map<String, dynamic> data;

          if (response is List && response.isNotEmpty) {
            data = response[0] as Map<String, dynamic>;
          } else if (response is Map<String, dynamic>) {
            data = response;
          } else {
            callback(false, 'Invalid response format');
            return;
          }

          bool success = data['success'] ?? false;
          String? message = data['message'];
          callback(success, message);
        } else {
          callback(false, 'No response received from server');
        }
      } catch (e) {
        // debugPrint('Error parsing delete message response: $e');
        callback(false, 'Error parsing server response');
      }
    });

    // debugPrint('Deleting message - MessageId: $messageId, UserId: $userId');
  }

  // Method to mark messages as read
  void markMessagesAsRead({
    required String chatId,
    required String userId,
  }) {
    final readData = {
      'chatId': chatId,
      'userId': userId,
    };

    _socket?.emit('markAsRead', readData);
    // debugPrint('Marking messages as read for chat: $chatId, user: $userId');
  }

  // Updated socket service method with better error handling and timeout
  void forwardMessage({
    required String originalMessageId,
    required String senderId,
    required List<Map<String, String>> targets,
    required Function(bool success, String? message) callback,
  }) {
    if (_socket == null || _socket?.connected == false) {
      callback(false, 'Socket not connected');
      return;
    }

    final forwardData = {
      'originalMessageId': originalMessageId,
      'senderId': senderId,
      'targets': targets,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // debugPrint('Forwarding message with data: $forwardData');

    bool hasResponded = false;

    // Set timeout to prevent infinite loading
    Timer(const Duration(seconds: 3), () {
      if (!hasResponded) {
        hasResponded = true;
        callback(false, 'Request timeout - please try again');
      }
    });

    // Listen for various possible response events
    _socket?.once('messageForwarded', (data) {
      if (!hasResponded) {
        hasResponded = true;
        // debugPrint('Forward success response: $data');
        final success =
            data['success'] ?? true; // Default to true if not specified
        final message = data['message'] ?? 'Message forwarded successfully';
        callback(success, message);
      }
    });

    _socket?.once('forwardError', (data) {
      if (!hasResponded) {
        hasResponded = true;
        // debugPrint('Forward error response: $data');
        callback(false, data['message'] ?? 'Failed to forward message');
      }
    });

    _socket?.once('error', (data) {
      if (!hasResponded) {
        hasResponded = true;
        // debugPrint('General error response: $data');
        callback(false, data['message'] ?? 'Socket error occurred');
      }
    });

    // Also listen for generic success/error responses
    _socket?.once('success', (data) {
      if (!hasResponded) {
        hasResponded = true;
        // debugPrint('Generic success response: $data');
        callback(true, data['message'] ?? 'Message forwarded successfully');
      }
    });

    _socket?.once('failure', (data) {
      if (!hasResponded) {
        hasResponded = true;
        // debugPrint('Generic failure response: $data');
        callback(false, data['message'] ?? 'Failed to forward message');
      }
    });

    _socket?.emit('forwardMessage', forwardData);
  }

  void joinGroupRoom(String groupId, String userId, Function(bool) callback) {
    _socket?.emit('joinGroupRoom', {'groupId': groupId, 'userId': userId});
    _socket?.once('joinGroupRoom', (data) {
      callback(data['success'] ?? false);
    });
  }

  // void joinPrivateRoom(
  //     String user1Id, String user2Id, Function(Map<String, dynamic>) callback) {
  //   _socket?.emit('joinPrivateRoom', {'user1Id': user1Id, 'user2Id': user2Id});
  //   _socket?.once('joinPrivateRoom', (data) {
  //     callback(data);
  //   });
  // }

  void joinPrivateRoom(
    String user1Id,
    String user2Id,
    Function(Map<String, dynamic>) callback,
  ) {
    log("📤 Emitting joinPrivateRoom ---> user1:$user1Id user2:$user2Id");

    bool hasResponded = false;

    // Set a timeout
    Timer(const Duration(seconds: 5), () {
      if (!hasResponded) {
        hasResponded = true;
        callback({'success': false, 'message': 'Request timeout'});
      }
    });

    // Listen for messageHistory event (this is what your server actually sends)
    _socket?.once('messageHistory', (data) {
      if (!hasResponded) {
        hasResponded = true;
        log("📥 messageHistory event response: $data");

        try {
          final roomId = data['roomId'];
          final messages = data['messages'] ?? [];
          final status = data['status'];

          if (roomId != null && status == 200) {
            callback({
              'success': true,
              'chatId': roomId,
              'messages': messages,
            });
          } else {
            callback({'success': false, 'message': 'Invalid response'});
          }
        } catch (e) {
          log("❌ Error parsing messageHistory: $e");
          callback({'success': false, 'message': e.toString()});
        }
      }
    });

    // Also try ACK (in case server changes)
    _socket?.emitWithAck(
      'joinPrivateRoom',
      {
        'user1Id': user1Id,
        'user2Id': user2Id,
      },
      ack: (response) {
        if (!hasResponded) {
          hasResponded = true;
          log("📥 ACK response for joinPrivateRoom: $response");

          try {
            if (response == null) {
              callback({'success': false, 'message': 'No response'});
              return;
            }

            if (response is Map<String, dynamic>) {
              callback(response);
            } else if (response is List && response.isNotEmpty) {
              callback(Map<String, dynamic>.from(response[0]));
            } else {
              callback(
                  {'success': false, 'message': 'Invalid response format'});
            }
          } catch (e) {
            callback({'success': false, 'message': e.toString()});
          }
        }
      },
    );
  }

  void sendMessage({
    required String senderId,
    String? receiverId,
    String? groupId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? fileInfo,
    required Function(Map<String, dynamic>) callback,
    String? replyToMessageId,
  }) {
    _socket?.emit('sendMessage', {
      'senderId': senderId,
      'receiverId': receiverId,
      'groupId': groupId,
      'content': content,
      'messageType': messageType,
      if (fileInfo != null) 'fileInfo': fileInfo,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    });
    _socket?.once('sendMessage', (data) {
      callback(data);
    });
  }

  // Methods to emit pin/unpin events
  void pinMessage(
      {String? groupId, String? chatId, required String messageId}) {
    final data = {
      'messageId': messageId,
      if (groupId != null) 'groupId': groupId,
      if (chatId != null) 'chatId': chatId,
    };

    _socket?.emit('pinMessage', data);
    // debugPrint('Pinning message: $data');
  }

  // Unpin message method
  void unpinMessage({
    String? groupId,
    String? chatId,
    required String messageId,
    Function(Map<String, dynamic>)? callback,
  }) {
    if (_socket != null && _socket?.connected == true) {
      _socket?.emit('unpinMessage', {
        if (groupId != null) 'groupId': groupId,
        if (chatId != null) 'chatId': chatId,
        'messageId': messageId,
      });

      if (callback != null) {
        _socket?.once('unpinMessage', (data) {
          callback(data);
        });
      }
    }
  }

  // Optional: Method to get pinned messages for a chat
  void getPinnedMessages({String? groupId, String? chatId}) {
    final data = {
      if (groupId != null) 'groupId': groupId,
      if (chatId != null) 'chatId': chatId,
    };

    _socket?.emit('getPinnedMessages', data);
    // debugPrint('Getting pinned messages: $data');
  }

  void dispose() {
    _pinnedMessageController.close();
    _unreadCountController.close();
    _unpinnedMessageController.close();
    _errorController.close();
    // ... close other controllers ...
  }

  void removeMemberFromGroup(String groupId, String memberId, String ownerId,
      Function(bool) callback) {
    _socket?.emit('removeMemberFromGroup', {
      'groupId': groupId,
      'memberId': memberId,
      'ownerId': ownerId,
    });
    _socket?.once('removeMemberFromGroup', (data) {
      callback(data['success'] ?? false);
    });
  }

  // Add method to emit chatOpened event
  void chatOpened({
    required String chatId,
    required String userId,
    required bool isGroup,
  }) {
    _socket?.emit('chatOpened', {
      'chatId': chatId,
      'userId': userId,
      'isGroup': isGroup,
    });
  }

  // Method to delete group
  void deleteGroup({
    required String groupId,
    required String ownerId,
    required Function(bool success) callback,
  }) {
    final groupDeleteData = {
      'groupId': groupId,
      'ownerId': ownerId,
    };

    // Emit the delete group event
    _socket?.emit('deleteGroup', groupDeleteData);

    // Listen for the response (if server responds with 'deleteGroup' event)
    _socket?.once('deleteGroup', (response) {
      final success = response['success'] ?? false;
      // debugPrint('delete group response: $response');
      callback(success);
    });
  }

  void leaveGroup(String groupId, String userId, Function(bool) callback) {
    _socket?.emit('leaveGroup', {
      'groupId': groupId,
      'userId': userId,
    });
    _socket?.once('leaveGroup', (data) {
      callback(data['success'] ?? false);
    });
  }

  void requestGroupDetails(String groupId) {
    if (_socket != null && _socket?.connected == true) {
      _socket?.emit('getGroupDetails', {'groupId': groupId});
    }
  }

  void makeGroupAdmin(String groupId, String userId) {
    if (_socket != null && _socket?.connected == true) {
      _socket?.emit('makeGroupAdmin', {
        'groupId': groupId,
        'userId': userId,
      });
    }
  }

  void removeGroupAdmin(String groupId, String userId) {
    if (_socket != null && _socket?.connected == true) {
      _socket?.emit('removeGroupAdmin', {
        'groupId': groupId,
        'userId': userId,
      });
    }
  }

  void removeGroupMember(String groupId, String userId) {
    if (_socket != null && _socket?.connected == true) {
      _socket?.emit('removeGroupMember', {
        'groupId': groupId,
        'userId': userId,
      });
    }
  }

  void reportUser(String userId, String reason) {
    if (_socket != null && _socket?.connected == true) {
      _socket?.emit('reportUser', {
        'userId': userId,
        'reason': reason,
      });
    }
  }

  void addGroupMembers(String groupId, List<String> userIds) {
    if (_socket != null && _socket?.connected == true) {
      _socket?.emit('addGroupMembers', {
        'groupId': groupId,
        'userIds': userIds,
      });
    }
  }

  // Fixed: Use direct callback instead of streams
  void loadOlderGroupMessages({
    required String groupId,
    String? beforeMessageId,
    int limit = 50,
    required Function(Map<String, dynamic>) onResponse,
  }) {
    final data = {
      'groupId': groupId,
      'beforeMessageId': beforeMessageId,
      'limit': limit,
    };

    // debugPrint('Emitting loadOlderGroupMessages with data: $data');

    _socket?.emitWithAck('loadOlderGroupMessages', data, ack: (response) {
      // debugPrint('Received older group messages response: $response');
      if (response != null) {
        onResponse(Map<String, dynamic>.from(response));
      }
    });
  }

  // Fixed: Load older private messages with callback
  // Fixed: Use direct callback instead of streams
  void loadOlderPrivateMessages({
    required String user1Id,
    required String user2Id,
    String? beforeMessageId,
    int limit = 50,
    required Function(Map<String, dynamic>) onResponse,
  }) {
    final data = {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'beforeMessageId': beforeMessageId,
      'limit': limit,
    };

    // debugPrint('Emitting loadOlderPrivateChatMessages with data: $data');

    _socket?.emitWithAck('loadOlderPrivateChatMessages', data, ack: (response) {
      // debugPrint('Received older private messages response: $response');
      if (response != null) {
        onResponse(Map<String, dynamic>.from(response));
      }
    });
  }

  // Method to react to message
  void reactToMessage({
    required String messageId,
    required String userId,
    required String emoji,
  }) {
    final reactionData = {
      'messageId': messageId,
      'userId': userId,
      'emoji': emoji,
    };

    _socket?.emit('reactToMessage', reactionData);
    // debugPrint('Sent reaction: $reactionData');
  }

  void disconnect() {
    _socket?.disconnect();
    _olderPrivateMessagesController.close();
    _messageHistoryController.close();
    _olderGroupMessagesController.close();
    _adminAddedController.close();
    _unreadCountController.close();
    _groupDeletedController.close();
    _messageController.close();
    _groupDetailsController.close();
    _privateMessageHistoryController.close();
    _messageDeletedController.close();
    _pinnedMessageController.close();
    _unpinnedMessageController.close();
    _errorController.close();
    _messagesReadController.close();
    _groupDeletedController.close();
    _messageReactionUpdatedController.close();
    _reconnectController.close();
  }
}
