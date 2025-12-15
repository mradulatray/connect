import 'dart:convert';
import 'dart:developer';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectapp/data/response/status.dart';
import 'package:connectapp/models/EnrolledCourses/enrolled_courses_model.dart';
import 'package:connectapp/models/UserLogin/user_login_model.dart';
import 'package:connectapp/models/UserProfile/user_profile_model.dart';
import 'package:connectapp/res/api_urls/api_urls.dart';
import 'package:connectapp/res/color/app_colors.dart';
import 'package:connectapp/res/fonts/app_fonts.dart';
import 'package:connectapp/utils/file_utils.dart';
import 'package:connectapp/view/message/audiorecord.dart';
import 'package:connectapp/view/message/community.dart';
import 'package:connectapp/view/message/editgroupinfo.dart';
import 'package:connectapp/view/message/groupmanagement.dart';
import 'package:connectapp/view/message/stickerprofile.dart';
import 'package:connectapp/view_models/controller/profile/user_profile_controller.dart';
import 'package:connectapp/view_models/controller/userPreferences/user_preferences_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../res/assets/image_assets.dart';
import '../../res/routes/routes_name.dart';
import '../../utils/cache_image_loader.dart';
import '../../utils/local_file_manager.dart';
import '../../view_models/controller/service/chatservice.dart';
import '../../view_models/controller/service/service.dart';
import '../../view_models/controller/service/socketservice.dart';
import 'badge_manager.dart';
import 'chat_profile.dart';
import 'notificationservice.dart';

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String? directUserId;

  const ChatScreen({super.key, this.chatId, this.directUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMessages = false;
  bool isGroup = false;
  Map<String, String?> lastReadMessageId = {};
  bool _hasShownUnreadSeparator = false;
  final UserPreferencesViewmodel _userPreferences = UserPreferencesViewmodel();
  String? selectedChatId;
  bool _isBold = false;
  final Map<String, GlobalKey> _messageKeys = {};
  bool _isItalic = false;
  final UserProfileController _profileController =
      Get.put(UserProfileController());
  final UserPreferencesViewmodel _prefs = UserPreferencesViewmodel();
  UserProfileModel? currentUserProfile;
  bool _isUnderline = false;
  bool showReplyPreview = false;
  String? _highlightedMessageId;
  bool _isEditingMode = false;
  final TextEditingController _editMessageController = TextEditingController();
  Message? _editingMessage;
  bool _showScrollToBottom = false;
  static const double _scrollThreshold = 50.0;
  static const double _bottomThreshold = 100.0;
  Timer? _highlightTimer;
  String selectedSection = 'all'; // 'all', 'direct', 'groups'
  List<GroupData> groups = [];
  List<Chat> directChats = [];
  LocalFileManager localFileManager = LocalFileManager();
  Map<String, List<dynamic>> pinnedMessagesByChat = {};
  late StreamSubscription _errorSubscription;

  List<GroupData> filteredGroups = [];
  String? _selectedReportReason;
  bool _showForwardDialog = false;
  Message? _messageToForward;
  final List<String> _selectedForwardChats = [];

  final LocalFileManager _localFileManager = LocalFileManager();
  String _forwardSearchQuery = '';
  final TextEditingController _forwardSearchController =
      TextEditingController();
  Map<String, List<dynamic>> chatPinnedMessages = {};
  String _reportDescription = '';
  final TextEditingController _reportDescriptionController =
      TextEditingController();
  List<Chat> filteredDirectChats = [];
  Map<String, List<Message>> messages = {};

  String otherId = "";

  // late ChatController _chatController;

  Set<String> joinedGroups = {};
  String? inviteLink;
  bool isGeneratingLink = false;
  bool loading = true;
  String? error;
  bool showEmojiPicker = false;
  bool showCommunityMembers = false;
  String? openMenuMemberId;
  String? activePrivateChat;
  String? pendingPrivateChatUserId;
  bool isNewPrivateChat = false;
  bool showChatList = true;
  bool showForwardModal = false; // Add this for forward modal
  String? forwardMessageId;
  List<ForwardTarget> availableForwardTargets = [];
  StreamSubscription<Map<String, dynamic>>? _newMessageSubscription;
  bool showGroupInfo = false;
  String? currentUserId;
  String? currentUserName;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isUserAtBottom = true;
  String? currentUserAvatar;
  late AnimationController _animationController;
  bool _isLoadingOlderMessages = false;
  final Map<String, bool> _hasMoreMessages =
      {}; // Track if more messages available for each chat
  final Map<String, String?> _oldestMessageId = {};
  late Animation<double> _fadeAnimation;
  Message? replyingToMessage;
  StreamSubscription<Map<String, dynamic>>? _groupDeletedSubscription;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _groupDetailsSubscription;

  // Add these StreamSubscriptions for lazy loading

  Color? appBackgroundColor = Colors.grey[300];

  final BadgeManager _badgeManager = NotificationService().badgeManager;
  StreamSubscription? _messageDeletedSubscription;
  StreamSubscription? _privateMessageSubscription;
  StreamSubscription? _reconnectSubscription;
  late final LifecycleEventHandler _lifecycleEventHandler;
  StreamSubscription? adminAddedSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageReactionSubscription;
  late StreamSubscription _pinnedMessageSubscription;
  StreamSubscription? _messagesReadSubscription;

  late StreamSubscription _unpinnedMessageSubscription;
  final List<String> emojiReactions = [
    "👍",
    "❤️",
    "😂",
    "😮",
    "😢",
    "👏",
    "🔥",
    "💯",
    "🤯",
    "😎",
    "🙌",
    "💀",
    "🤔",
    "😭",
    "🤷",
    "😇",
    "🤝",
    "⚡",
    "😍",
    "🤩",
    "😡",
    "🤬",
    "🥱",
    "😤",
    "😬",
    "🎉",
    "🥳",
    "🎂",
    "💤",
    "💪",
    "🥂",
    "😇",
    "😈",
    "🤡",
    "👀",
    "😴",
    "😷",
    "👎",
    "🌈",
    "😵",
    "🤓",
    "🤑",
    "😕",
    "🧠",
    "😐",
    "😌",
    "😳",
    "😔",
    "😅",
    "🎯",
    "📌",
    "😒",
    "🤗",
    "👊",
    "✌️",
    "🖤",
    "💔",
    "🌟",
    "💫",
    "🚀",
    "🥴"
  ];

  //imageuploadingstartsfromhere
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  List<Message> pinnedMessages = [];
  bool _isChatSearching = false;
  String _chatSearchQuery = '';
  final TextEditingController _chatSearchController = TextEditingController();
  List<Message> _chatFilteredMessages = [];

//forward message
// Add this method to show forward dialog
  void _showForwardMessageDialog(Message message) {
    setState(() {
      _messageToForward = message;
      _showForwardDialog = true;
      _selectedForwardChats.clear();
      _forwardSearchQuery = '';
      _forwardSearchController.clear();
    });
  }

// Add scroll listener for lazy loading
  // Fixed: _onScroll method with better logic
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    // Load older messages when scrolling near the top
    if (offset <= _scrollThreshold &&
        !_isLoadingOlderMessages &&
        selectedChatId != null &&
        (_hasMoreMessages[selectedChatId] ?? true)) {
      _loadOlderMessages();
    }
    // Existing scroll to bottom logic
    if (offset > 100) {
      if (!_showScrollToBottom) {
        setState(() {
          _showScrollToBottom = true;
        });
      }
    } else {
      if (_showScrollToBottom) {
        setState(() {
          _showScrollToBottom = false;
        });
      }
    }
  }

  // Load older messages method
  // Fixed: _loadOlderMessages method with timeout protection
  void _loadOlderMessages() {
    if (selectedChatId == null || _isLoadingOlderMessages) {
      return;
    }

    // Check if we have more messages to load
    if (_hasMoreMessages[selectedChatId] == false) {
      return;
    }

    setState(() {
      _isLoadingOlderMessages = true;
    });

    // Add timeout protection
    Timer(Duration(seconds: 10), () {
      if (_isLoadingOlderMessages) {
        setState(() {
          _isLoadingOlderMessages = false;
        });
        _showSnackBar('Request timeout. Please try again.');
      }
    });

    final chat = selectedChat;
    if (chat == null) {
      setState(() {
        _isLoadingOlderMessages = false;
      });
      return;
    }

    final currentMessages = messages[selectedChatId] ?? [];
    final oldestMessageId =
        currentMessages.isNotEmpty ? currentMessages.first.id : null;

    if (chat.isGroup) {
      isGroup = true;
      _socketService.loadOlderGroupMessages(
        groupId: selectedChatId!,
        beforeMessageId: oldestMessageId,
        limit: 50,
        onResponse: _handleOlderGroupMessages,
      );
    } else {
      isGroup = false;
      final otherParticipant = chat.participants?.firstWhere(
        (p) => p.id != currentUserId,
        // orElse: () => null,
      );

      if (otherParticipant != null && currentUserId != null) {
        _socketService.loadOlderPrivateMessages(
          user1Id: currentUserId!,
          user2Id: otherParticipant.id,
          beforeMessageId: oldestMessageId,
          limit: 50,
          onResponse: _handleOlderPrivateMessages,
        );
      } else {
        setState(() {
          _isLoadingOlderMessages = false;
        });
        _showSnackBar('Unable to load older messages');
      }
    }
  }

  void _forwardMessage() {
    if (_messageToForward == null || _selectedForwardChats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one chat to forward to'),
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final targets = _selectedForwardChats.map((chatId) {
      final chat = allChats.firstWhere((c) => c.id == chatId);
      return {
        'type': chat.isGroup ? 'group' : 'user', // FIXED
        'id': chatId, // FIXED
      };
    }).toList();

    // Call socket service to forward message
    _socketService.forwardMessage(
      originalMessageId: _messageToForward!.id,
      senderId: currentUserId!,
      targets: targets,
      callback: (success, message) {
        // Hide loading indicator
        Navigator.of(context).pop();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Message forwarded to ${_selectedForwardChats.length} chat(s)'),
              backgroundColor: Colors.green,
            ),
          );

          // Close forward dialog
          setState(() {
            _showForwardDialog = false;
            _messageToForward = null;
            _selectedForwardChats.clear();
            _forwardSearchQuery = '';
            _forwardSearchController.clear();
          });
          _sortAllChats();
        }
      },
    );
  }

// Add optimistic update method
  void _createOptimisticForwardUpdates(List<Map<String, dynamic>> targets) {
    final originalMessage = _messageToForward!;

    for (final target in targets) {
      final chatId = target['id'];
      final tempMessageId =
          'forward-temp-${DateTime.now().millisecondsSinceEpoch}-$chatId';

      // Create forwarded message
      final forwardedMessage = Message(
        id: tempMessageId,
        content: originalMessage.content,
        timestamp: DateTime.now(),
        sender: Sender(
          id: currentUserId!,
          name: currentUserName ?? 'Me',
          avatar: currentUserAvatar,
        ),
        isRead: false,
        messageType: originalMessage.messageType,
        isForwarded: true,
        fileInfo: originalMessage.fileInfo,
        replyTo: originalMessage.replyTo,
      );

      // Add to messages list optimistically
      setState(() {
        if (messages[chatId] == null) {
          messages[chatId] = [];
        }
        messages[chatId]!.add(forwardedMessage);
      });

      // Update chat list to show the new message
      _updateChatLastMessage(chatId, forwardedMessage);
    }
  }

  final Map<String, double> _chatScrollPositions = {};

// Enhanced scroll listener
  void _initScrollListener() {
    _scrollController.addListener(() {
      final position = _scrollController.position;
      final isAtBottom =
          position.pixels >= position.maxScrollExtent - _bottomThreshold;

      // Update user position state
      if (isAtBottom != _isUserAtBottom) {
        setState(() {
          _isUserAtBottom = isAtBottom;
        });
      }

      // Show/hide scroll to bottom button
      final shouldShowButton = !isAtBottom &&
          position.pixels < position.maxScrollExtent - _scrollThreshold;

      if (shouldShowButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = shouldShowButton;
        });
      }

      // Clear unread count when user scrolls to bottom
      if (isAtBottom && selectedChatId != null) {
        final currentUnreadCount =
            _badgeManager.unreadCounts[selectedChatId!] ?? 0;
        if (currentUnreadCount > 0) {
          // Send socket event to clear unread count
          _resetUnreadCountForChat(
            selectedChatId!,
          );
          _badgeManager.resetUnreadCount(selectedChatId!);
          setState(() {});
        }
      }
    });
  }

// Add this method to get available emojis based on subscription
  List<String> _getAvailableEmojis() {
    // Get the number of allowed emojis from subscription features
    final allowedEmojis =
        currentUserProfile?.subscriptionFeatures?.reactionEmoji ?? 4;

    // Return emojis based on subscription level
    if (allowedEmojis >= emojiReactions.length) {
      return emojiReactions; // All emojis available
    } else {
      return emojiReactions.take(allowedEmojis).toList();
    }
  }

  Future<bool> _validateFileSize(File file) async {
    try {
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      // Get the file upload size limit from user profile (in MB)
      final fileUploadSizeLimit =
          currentUserProfile?.subscriptionFeatures?.fileUploadSize ??
              10; // Default 10MB if not found

      if (fileSizeInMB > fileUploadSizeLimit) {
        // Show warning dialog
        await _showFileSizeWarningDialog(fileSizeInMB, fileUploadSizeLimit);
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

// Dialog to show file size warning
  Future<void> _showFileSizeWarningDialog(
      double actualSize, int maxSize) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'File Size Limit Exceeded',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The selected file is too large to upload.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Details:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                        'Current file size: ${actualSize.toStringAsFixed(2)} MB'),
                    Text('Maximum allowed: $maxSize MB'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                maxSize < 100
                    ? 'Upgrade to premium for larger file uploads!'
                    : 'Please select a smaller file.',
                style: TextStyle(
                  color: maxSize < 100 ? Colors.blue : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            if (maxSize < 100) // Show upgrade button for non-premium users
              TextButton(
                child: Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.opensansRegular),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Add navigation to premium upgrade page
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => PremiumUpgradePage()));
                },
              ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Modified method to show emoji reactions in the chat
  Widget _buildEmojiReactionRow(String messageId) {
    final availableEmojis = _getAvailableEmojis();
    final displayEmojis =
        availableEmojis.take(4).toList(); // Show first 4 emojis
    final hasMore =
        availableEmojis.length > 4; // Check if there are more emojis

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show first 4 emojis
        ...displayEmojis.map(
          (emoji) => GestureDetector(
            onTap: () => _handleReaction(messageId, emoji),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        ),
        // Show + icon if there are more emojis
        if (hasMore)
          GestureDetector(
            onTap: () => _showEmojiReactions(messageId),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.add,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

// Add this method to build forward dialog
  Widget _buildForwardDialog() {
    if (!_showForwardDialog || _messageToForward == null) {
      return const SizedBox();
    }

    final filteredChats = _forwardSearchQuery.isEmpty
        ? allChats.where((chat) => chat.id != selectedChatId).toList()
        : allChats.where((chat) {
            final nameMatch =
                chat.name.toLowerCase().contains(_forwardSearchQuery);
            final participantMatch = chat.participants?.any((p) =>
                    p.name.toLowerCase().contains(_forwardSearchQuery)) ??
                false;
            return (nameMatch || participantMatch) && chat.id != selectedChatId;
          }).toList();

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: AppColors.greyColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.greyColor, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      onPressed: () =>
                          setState(() => _showForwardDialog = false),
                    ),
                    Text(
                      'Forward Message',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFonts.opensansRegular,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedForwardChats.isNotEmpty)
                      TextButton(
                        onPressed: _forwardMessage,
                        child: Text(
                          'Send (${_selectedForwardChats.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFonts.opensansRegular,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Message Preview
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.forward,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _messageToForward!.sender.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              fontFamily: AppFonts.opensansRegular,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildForwardPreviewContent(_messageToForward!)
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _forwardSearchController,
                  onChanged: (value) =>
                      setState(() => _forwardSearchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.opensansRegular,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Chat List
              Expanded(
                child: filteredChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No chats found',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: AppFonts.opensansRegular,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          final isSelected =
                              _selectedForwardChats.contains(chat.id);

                          return ListTile(
                            leading: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: CacheImageLoader(
                                      chat.avatar,
                                      ImageAssets.defaultProfileImg,
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            title: Text(
                              chat.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFonts.opensansRegular,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            subtitle: chat.isGroup
                                ? Text(
                                    '${chat.participants?.length ?? 0} members',
                                    style: TextStyle(
                                      fontFamily: AppFonts.opensansRegular,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  )
                                : null,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                if (_selectedForwardChats.contains(chat.id)) {
                                  _selectedForwardChats.remove(chat.id);
                                } else {
                                  _selectedForwardChats.add(chat.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForwardPreviewContent(Message msg) {
    final type = msg.messageType!.toLowerCase();
    final content = msg.content;

    switch (type) {
      case "text":
        return Text(
          content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontFamily: AppFonts.opensansRegular,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );

      case "images":
      case "sticker":
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            content,
            height: 50,
            width: 50,
            fit: BoxFit.cover,
          ),
        );

      case "video":
        return Container(
          height: 50,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.play_circle, size: 28, color: Colors.white),
            ],
          ),
        );

      case "audio":
        return Row(
          children: [
            Icon(Icons.audiotrack, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text(
              "Audio message",
              style: TextStyle(
                fontSize: 14,
                fontFamily: AppFonts.opensansRegular,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        );

      case "file":
        return Row(
          children: [
            Icon(Icons.insert_drive_file, size: 22, color: Colors.black),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                "File",
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: AppFonts.opensansRegular,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );

      default:
        return Text(
          content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

// 2. Add a new function to send sticker messages
  void _sendStickerMessage(String stickerUrl) {
    if (selectedChatId == null || currentUserId == null) return;

    final chat = selectedChat;
    final isGroup = chat?.isGroup ?? false;
    String? receiverId;

    if (isGroup) {
      receiverId = null;
    } else {
      if (pendingPrivateChatUserId != null) {
        receiverId = pendingPrivateChatUserId;
      } else {
        final otherParticipant = chat?.participants?.firstWhere(
          (p) => p.id != currentUserId,
          orElse: () =>
              Participant(id: 'unknown', name: 'Unknown', avatar: null),
        );
        receiverId = otherParticipant?.id;
      }
    }

    final tempMessageId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

    // Store reply information BEFORE clearing state
    final isReplying = showReplyPreview && replyingToMessage != null;
    final replyToMessageId = replyingToMessage?.id;

    // Create new sticker message
    final newMessage = Message(
      id: tempMessageId,
      content: stickerUrl,
      timestamp: DateTime.now(),
      sender: Sender(
        id: currentUserId!,
        name: currentUserName ?? 'Me',
        avatar: currentUserAvatar,
      ),
      isRead: false,
      messageType: 'sticker',
      replyTo: isReplying
          ? ReplyTo(
              id: replyingToMessage!.id,
              content: replyingToMessage!.content,
              sender: replyingToMessage!.sender,
            )
          : null,
    );

    // Optimistic UI update
    setState(() {
      messages[selectedChatId!] = [
        ...(messages[selectedChatId!] ?? []),
        newMessage
      ];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // ✅ CRITICAL FIX: Clear reply state IMMEDIATELY
    _cancelReply();

    // Send via socket
    _socketService.sendMessage(
      senderId: currentUserId!,
      receiverId: isGroup ? null : receiverId,
      groupId: isGroup ? selectedChatId : null,
      content: stickerUrl,
      messageType: 'sticker',
      replyToMessageId: isReplying ? replyToMessageId : null,
      // Use stored value
      callback: (response) {
        if (response['success'] == true && response['messageId'] != null) {
          // Replace temporary ID with real ID
          setState(() {
            final chatMessages = messages[selectedChatId!] ?? [];
            final updatedMessages = chatMessages
                .map((msg) => msg.id == tempMessageId
                    ? Message(
                        id: response['messageId']!,
                        content: msg.content,
                        timestamp: msg.timestamp,
                        sender: msg.sender,
                        isRead: msg.isRead,
                        messageType: msg.messageType,
                        replyTo: msg.replyTo,
                        reactions: msg.reactions,
                      )
                    : msg)
                .toList();
            messages[selectedChatId!] = updatedMessages;
          });
        } else {
          // Remove temporary message on failure
          setState(() {
            final chatMessages = messages[selectedChatId!] ?? [];
            messages[selectedChatId!] =
                chatMessages.where((msg) => msg.id != tempMessageId).toList();
          });
          _showSnackBar('Failed to send sticker');
        }
      },
    );
  }

  // 3. Update the _showStickerSelector function
  void _showStickerSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StickerSelectorWidget(
        onStickerSelected: (stickerUrl) {
          // Send the selected sticker
          _sendStickerMessage(stickerUrl);
          Navigator.pop(context);
        },
        userProfile: currentUserProfile,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      ),
    );
  }

  Future<void> _starMessage(dynamic message) async {
    LoginResponseModel? userData = await _userPreferences.getUser();
    final token = userData!.token;
    try {
      // Get the message ID
      String? messageId = _getMessageId(message);

      if (messageId == null) {
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Could not identify message'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Replace with your actual API endpoint
      final String apiUrl =
          '${ApiUrls.baseUrl}/connect/v1/api/chat/toggle-starred-message'; // Update this URL

      // Make the POST request
      final response = await http.post(
        Uri.parse('$apiUrl/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          // Add any authentication headers if needed
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // Success - show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  responseData['message'] ?? 'Message starred successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // API returned success: false
          throw Exception(responseData['message'] ?? 'Unknown error occurred');
        }
      } else {
        // HTTP error
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to star message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<dynamic>> _fetchStarredMessages() async {
    LoginResponseModel? userData = await _userPreferences.getUser();
    final token = userData!.token;
    try {
      // Replace with your actual API endpoint
      final String apiUrl =
          '${ApiUrls.baseUrl}/connect/v1/api/chat/get-starred-messages'; // Update this URL

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          // Add any authentication headers if needed
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return responseData['messages'] ?? [];
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to fetch starred messages');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> _removeStarFromMessage(String messageId) async {
    LoginResponseModel? userData = await _userPreferences.getUser();
    final token = userData!.token;
    try {
      // Replace with your actual API endpoint for removing star
      final String apiUrl =
          '${ApiUrls.baseUrl}/connect/v1/api/chat/toggle-starred-message'; // Update this URL

      final response = await http.post(
        // or POST, depending on your API
        Uri.parse('$apiUrl/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          // Add any authentication headers if needed
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

// Method to format date
  String _formatDates(String? dateString) {
    try {
      if (dateString == null || dateString.isEmpty) {
        return 'Unknown date';
      }
      final DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - HH:mm').format(dateTime);
    } catch (e) {
      return dateString ?? 'Unknown date';
    }
  }

// Method to show starred messages popup
  void _showStarredMessagesPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Starred Messages',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),

                // Content
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _fetchStarredMessages(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showStarredMessagesPopup(context);
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_border,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No starred messages',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final sender = message['sender'] ?? {};
                          final senderName =
                              sender['fullName']?.toString() ?? 'Unknown';
                          final content = message['content']?.toString() ?? '';
                          final createdAt = message['createdAt']?.toString() ??
                              message['updatedAt']?.toString() ??
                              '';
                          final messageId = message['_id']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Sender and date row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          senderName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatDates(createdAt),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Message content
                                  Text(
                                    content,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),

                                  // Remove star button
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        // Show loading indicator
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );

                                        // Remove star
                                        final success =
                                            await _removeStarFromMessage(
                                                messageId);

                                        // Close loading indicator
                                        Navigator.pop(context);

                                        if (success) {
                                          // Show success message
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Star removed successfully'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          // Refresh the popup
                                          Navigator.pop(context);
                                          _showStarredMessagesPopup(context);
                                        } else {
                                          // Show error message
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Failed to remove star'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Remove Star',
                                        style: TextStyle(color: Colors.orange),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

//link generator code
  Future<void> _generateInviteLink() async {
    LoginResponseModel? userData = await _userPreferences.getUser();
    final token = userData!.token;
    if (selectedGroup == null) return;

    setState(() {
      isGeneratingLink = true;
    });

    try {
      final response = await http.patch(
        Uri.parse(
            '${ApiUrls.baseUrl}/connect/v1/api/user/generate-group-invite-link/${selectedGroup!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add your auth token here
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          inviteLink = data['inviteLink'];

          isGeneratingLink = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(data['message'] ?? 'Invite link generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to generate invite link');
      }
    } catch (e) {
      setState(() {
        isGeneratingLink = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate invite link. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Method to copy link to clipboard
  Future<void> _copyInviteLink() async {
    if (inviteLink != null) {
      await Clipboard.setData(ClipboardData(text: inviteLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite link copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

// Method to show invite link dialog
  void _showInviteLinkDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Group Invite Link',
            style: TextStyle(fontFamily: AppFonts.opensansRegular),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share this link to invite others to the group:',
                style: TextStyle(
                  fontFamily: AppFonts.opensansRegular,
                  color: AppColors.blackColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  inviteLink ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontFamily: AppFonts.opensansRegular,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  fontFamily: AppFonts.opensansRegular,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _copyInviteLink();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.copy, size: 18, color: Colors.white),
              label: const Text(
                'Copy Link',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: AppFonts.opensansRegular,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shadowColor: Colors.grey,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            )
          ],
        );
      },
    );
  }

  // Fixed _removeMessageFromUI function
  void _removeMessageFromUI(String messageId) {
    if (messageId.isEmpty) return;

    setState(() {
      bool messageFound = false;
      // Remove from all chats
      messages.forEach((chatId, messageList) {
        final initialLength = messageList.length;
        // ✅ Filter out null values before checking ID
        messageList
            .removeWhere((message) => _getMessageId(message) == messageId);
        if (messageList.length < initialLength) {
          messageFound = true;
        }
      });
      if (!messageFound) {}
    });
  }

// join group
// Method to show join group dialog
  void _showJoinGroupDialog() {
    final TextEditingController inviteLinkController = TextEditingController();
    bool isJoining = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1D29),
              // Dark background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4285F4), // Blue color
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.link,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Join a Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the invite link to join an existing group',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invite Link',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: inviteLinkController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. https://connect-frontend-1ogx.onrender.com/invite/group/...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF2A2D3A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Paste the complete invite link here',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isJoining ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isJoining
                      ? null
                      : () async {
                          final inviteLink = inviteLinkController.text.trim();
                          if (inviteLink.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter an invite link'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isJoining = true;
                          });

                          await _joinGroupWithLink(inviteLink);
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isJoining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Join Group'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Method to extract token from invite link
  String? _extractTokenFromInviteLink(String inviteLink) {
    try {
      // Parse the URL
      final uri = Uri.parse(inviteLink);

      // Extract the token from the path
      // Expected format: https://connect-frontend-1ogx.onrender.com/invite/group/TOKEN
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 3 &&
          pathSegments[0] == 'invite' &&
          pathSegments[1] == 'group') {
        return pathSegments[2]; // This is the token
      }

      return null;
    } catch (e) {
      return null;
    }
  }

// Method to join group using invite link
  Future<void> _joinGroupWithLink(String inviteLink) async {
    LoginResponseModel? userData = await _userPreferences.getUser();
    final tokens = userData!.token;
    try {
      // Extract token from the invite link
      final token = _extractTokenFromInviteLink(inviteLink);

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid invite link format'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Make API call to join group
      final response = await http.patch(
        Uri.parse(
            '${ApiUrls.baseUrl}/connect/v1/api/user/join-group-using-invite/$token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokens',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Successfully joined the group!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh your groups list here if needed
        // await _refreshGroups();
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Failed to join group'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception('Failed to join group');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join group. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to get current chat's pinned messages
  List<dynamic> get currentChatPinnedMessages {
    if (selectedChatId == null) {
      return [];
    }

    final pinnedMessages = pinnedMessagesByChat[selectedChatId!] ?? [];

    if (pinnedMessages.isNotEmpty) {
    } else {
      // Additional debugging
      bool chatExists = pinnedMessagesByChat.containsKey(selectedChatId!);

      if (chatExists) {}
    }

    return pinnedMessages;
  }

  // Updated pin message function with chat-specific limits
  void _pinMessage(dynamic message) {
    if (selectedChatId == null) {
      _showErrorSnackBar('No chat selected');
      return;
    }

    List<dynamic> currentPinned = currentChatPinnedMessages;

    if (currentPinned.length >= 3) {
      _showErrorSnackBar(
          'Only 3 messages can be pinned at a time in this chat');
      return;
    }

    String? messageId = _getMessageId(message);
    if (messageId!.isEmpty) {
      _showErrorSnackBar('Invalid message');
      return;
    }

    if (currentPinned.any((m) => _getMessageId(m) == messageId)) {
      _showErrorSnackBar('Message is already pinned in this chat');
      return;
    }
    // OPTIMISTIC UPDATE: Add message to pinned list immediately
    setState(() {
      if (pinnedMessagesByChat[selectedChatId!] == null) {
        pinnedMessagesByChat[selectedChatId!] = [];
      }
      pinnedMessagesByChat[selectedChatId!]!.add(message);
    });

    isGroup = selectedChat?.isGroup == true;
    // Use SocketService to pin message
    _socketService.pinMessage(
      groupId: selectedChat?.isGroup == true ? selectedChatId : null,
      chatId: selectedChat?.isGroup != true ? selectedChatId : null,
      messageId: messageId,
    );
  }

// Updated unpin message function
  void _unpinMessage(dynamic message) {
    if (selectedChatId == null) {
      _showErrorSnackBar('No chat selected');
      return;
    }

    String? messageId = _getMessageId(message);
    if (messageId!.isEmpty) {
      _showErrorSnackBar('Invalid message');
      return;
    }
    // OPTIMISTIC UPDATE: Remove message from pinned list immediately
    setState(() {
      pinnedMessagesByChat[selectedChatId!]
          ?.removeWhere((m) => _getMessageId(m) == messageId);

      // Remove empty lists to keep the map clean
      if (pinnedMessagesByChat[selectedChatId!]?.isEmpty == true) {
        pinnedMessagesByChat.remove(selectedChatId!);
      }
    });

    // Use SocketService to unpin message
    _socketService.unpinMessage(
      groupId: selectedChat?.isGroup == true ? selectedChatId : null,
      chatId: selectedChat?.isGroup != true ? selectedChatId : null,
      messageId: messageId,
    );
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Enhanced file upload handler with audio support
  Future<void> _handleFileUpload() async {
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select File Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.image),
                  title: Text('Image'),
                  onTap: () => Navigator.pop(context, 'image'),
                ),
                ListTile(
                  leading: Icon(Icons.videocam),
                  title: Text('Video'),
                  onTap: () => Navigator.pop(context, 'video'),
                ),
                ListTile(
                  leading: Icon(Icons.audiotrack),
                  title: Text('Audio'),
                  onTap: () => Navigator.pop(context, 'audio'),
                ),
                ListTile(
                  leading: Icon(Icons.mic),
                  title: Text('Record Audio'),
                  onTap: () => Navigator.pop(context, 'record_audio'),
                ),
                ListTile(
                  leading: Icon(Icons.file_present),
                  title: Text('Document'),
                  onTap: () => Navigator.pop(context, 'document'),
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Camera'),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                ListTile(
                  leading: Icon(Icons.video_camera_back),
                  title: Text('Record Video'),
                  onTap: () => Navigator.pop(context, 'record_video'),
                ),
              ],
            ),
          );
        },
      );

      if (result != null) {
        File? selectedFile;

        switch (result) {
          case 'image':
            selectedFile = await _pickImageFromGallery();
            break;
          case 'video':
            selectedFile = await _pickVideoFromGallery();
            break;
          case 'audio':
            selectedFile = await _pickAudioFromStorage();
            break;
          case 'record_audio':
            selectedFile = await _recordAudio();
            break;
          case 'document':
            selectedFile = await _pickDocument();
            break;
          case 'camera':
            selectedFile = await _pickImageFromCamera();
            break;
          case 'record_video':
            selectedFile = await _pickVideoFromCamera();
            break;
        }

        if (selectedFile != null) {
          await _uploadFile(selectedFile);
        }
      }
    } catch (e) {
      _showSnackBar('Error selecting file: $e');
    }
  }

  Future<File?> _pickAudioFromStorage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<File?> _recordAudio() async {
    try {
      // Request permission
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        _showSnackBar('Microphone permission denied');
        return null;
      }

      // Show recording dialog
      return await showDialog<File?>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AudioRecorderDialog();
        },
      );
    } catch (e) {
      _showSnackBar('Error recording audio: $e');
      return null;
    }
  }

  // Helper function to check if URL is a sticker
  bool _isStickerUrl(String content) {
    // Check for known sticker domains/patterns
    return content.contains('flaticon.com') ||
        content.contains('cdn-icons-png.flaticon.com') ||
        content.contains('sticker') ||
        content.contains('emoji');
  }

  bool _containsUrl(String content) {
    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(content);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<File?> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image != null ? File(image.path) : null;
  }

// Add video picking methods
  Future<File?> _pickVideoFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    return video != null ? File(video.path) : null;
  }

  Future<File?> _pickVideoFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.camera);
    return video != null ? File(video.path) : null;
  }

  Future<File?> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    return image != null ? File(image.path) : null;
  }

  Future<File?> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

// Updated upload file method with size validation
  Future<void> _uploadFile(File file) async {
    LoginResponseModel? userData = await _userPreferences.getUser();
    final token = userData!.token;

    // Validate file size before uploading
    bool isValidSize = await _validateFileSize(file);
    if (!isValidSize) {
      return; // Stop upload if file size exceeds limit
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiUrls.baseUrl}/connect/v1/api/user/upload-message-file'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('messageFile', file.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        localFileManager.addFilePath(FileTypeFormat.media, result['fileUrl']);

        if (result['fileUrl'] != null) {
          // Get file info
          final fileInfo = {
            'name': file.path.split('/').last,
            'type': FileUtils.getFileType(file.path),
            'size': await file.length(),
          };

          // Send file message
          _sendFileMessage(result['fileUrl'], fileInfo);
          _showSnackBar('File uploaded successfully');
        } else {
          throw Exception('No file URL returned');
        }
      } else {
        throw Exception('File upload failed: ${response.statusCode}');
      }
    } catch (error) {
      _showSnackBar('Failed to upload file: $error');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _sendFileMessage(String fileUrl, Map<String, dynamic> fileInfo) {
    if (selectedChatId == null || currentUserId == null) return;

    final chat = selectedChat;
    final isGroup = chat?.isGroup ?? false;
    String? receiverId;

    if (isGroup) {
      receiverId = null;
    } else {
      if (pendingPrivateChatUserId != null) {
        receiverId = pendingPrivateChatUserId;
      } else {
        final otherParticipant = chat?.participants?.firstWhere(
          (p) => p.id != currentUserId,
          orElse: () =>
              Participant(id: 'unknown', name: 'Unknown', avatar: null),
        );
        receiverId = otherParticipant?.id;
      }
    }

    final tempMessageId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

    // Store reply information BEFORE clearing state
    final isReplying = showReplyPreview && replyingToMessage != null;
    final replyToMessageId = replyingToMessage?.id;

    // Create new file message
    final newMessage = Message(
      id: tempMessageId,
      content: fileUrl,
      timestamp: DateTime.now(),
      sender: Sender(
        id: currentUserId!,
        name: currentUserName ?? 'Me',
        avatar: currentUserAvatar,
      ),
      isRead: false,
      messageType: 'file',
      fileInfo: FileInfo(
        name: fileInfo['name'],
        type: fileInfo['type'],
        size: fileInfo['size'],
        url: fileUrl,
      ),
      replyTo: isReplying
          ? ReplyTo(
              id: replyingToMessage!.id,
              content: replyingToMessage!.content,
              sender: replyingToMessage!.sender,
            )
          : null,
    );

    // Optimistic UI update
    setState(() {
      messages[selectedChatId!] = [
        ...(messages[selectedChatId!] ?? []),
        newMessage
      ];
    });

    _scrollToBottom();

    // ✅ CRITICAL FIX: Clear reply state IMMEDIATELY
    _cancelReply();

    // Send via socket
    _socketService.sendMessage(
      senderId: currentUserId!,
      receiverId: isGroup ? null : receiverId,
      groupId: isGroup ? selectedChatId : null,
      content: fileUrl,
      messageType: 'file',
      replyToMessageId: isReplying ? replyToMessageId : null,
      // Use stored value
      callback: (response) {
        if (response['success'] == true && response['messageId'] != null) {
          // Replace temporary ID with real ID
          setState(() {
            final chatMessages = messages[selectedChatId!] ?? [];
            final updatedMessages = chatMessages
                .map((msg) => msg.id == tempMessageId
                    ? Message(
                        id: response['messageId']!,
                        content: msg.content,
                        timestamp: msg.timestamp,
                        sender: msg.sender,
                        isRead: msg.isRead,
                        messageType: msg.messageType,
                        fileInfo: msg.fileInfo,
                        replyTo: msg.replyTo, // Preserve reply data
                      )
                    : msg)
                .toList();
            messages[selectedChatId!] = updatedMessages;
          });
        } else {
          // Remove temporary message on failure
          setState(() {
            final chatMessages = messages[selectedChatId!] ?? [];
            messages[selectedChatId!] =
                chatMessages.where((msg) => msg.id != tempMessageId).toList();
          });
          _showSnackBar('Failed to send file');
        }
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildStickerMessage(Message message) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
        maxHeight: 200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message.content,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Failed to load sticker',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: 100,
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

// // Add the sticker message bubble function
//   Widget _buildStickerMessageBubble(Message message, bool isMe) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       child: Align(
//         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//         child: Row(
//           mainAxisAlignment:
//               isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             // if (!isMe) ...[
//             //   const SizedBox(width: 10),
//             //   _buildProfilePicture(message.sender.avatar),
//             // ],
//             if (isGroup && !isMe)
//               Row(
//                 children: [
//                   // Avatar
//
//                   CircleAvatar(
//                     backgroundColor: Colors.transparent,
//                     radius: 16,
//                         backgroundImage: CacheImageLoader(
//                           message.originalSender?.avatar ?? message.sender?.avatar,
//                           ImageAssets.defaultProfileImg,
//                         ),
//                   ),
//                   SizedBox(width: 10), // spacing between avatar and name
//                   // Name
//                   Text(
//                     message.originalSender?.name ?? '',
//                     // Replace with actual name
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             Flexible(
//               child: Column(
//                 crossAxisAlignment:
//                     isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//                 children: [
//                   // Reply preview if this message is a reply
//                   if (message.replyTo != null)
//                     Container(
//                       margin: const EdgeInsets.only(bottom: 4),
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             message.replyTo!.sender!.name,
//                             style: const TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue,
//                             ),
//                           ),
//                           Text(
//                             message.replyTo!.content!,
//                             style: const TextStyle(
//                               fontSize: 10,
//                               color: Colors.grey,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                     ),
//                   // Sticker container
//                   Container(
//                     constraints: BoxConstraints(
//                       maxWidth: MediaQuery.of(context).size.width * 0.6,
//                       maxHeight: 200,
//                     ),
//                     decoration: BoxDecoration(
//                       // color: isMe ? Colors.blue[100] : Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.all(8),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.network(
//                         message.content,
//                         fit: BoxFit.contain,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             padding: const EdgeInsets.all(16),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   Icons.error_outline,
//                                   color: Colors.red,
//                                   size: 32,
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   'Failed to load sticker',
//                                   style: TextStyle(
//                                     color: Colors.red,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                         loadingBuilder: (context, child, loadingProgress) {
//                           if (loadingProgress == null) return child;
//                           return Container(
//                             width: 100,
//                             height: 100,
//                             child: Center(
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 // color: Colors.blue,
//                                 value: loadingProgress.expectedTotalBytes !=
//                                         null
//                                     ? loadingProgress.cumulativeBytesLoaded /
//                                         (loadingProgress.expectedTotalBytes ??
//                                             1)
//                                     : null,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                   // Timestamp
//                   if (message.reactions != null &&
//                       message.reactions!.isNotEmpty)
//                     _buildReactionRow(message.reactions!),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         _formatTime(message.timestamp),
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: isMe ? Colors.grey[600] : Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(width: 4),
//                       if (isMe) _buildMessageStatus(message.status, isMe),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             // if (isMe) ...[
//             //   const SizedBox(width: 10),
//             //   _buildProfilePicture(message.sender.avatar),
//             // ],
//           ],
//         ),
//       ),
//     );
//   }

  // // Enhanced message bubble with clickable links
  // Widget _buildMessageBubble(Message message, bool isMe) {
  //   final bool isStickerUrl = _isStickerUrl(message.content);
  //   final bool isFileUrl = _isFileUrl(message.content);
  //   final bool hasFileInfo = message.fileInfo != null;
  //
  //   // Check for sticker messages FIRST - before file check
  //   if (message.messageType == 'sticker' || isStickerUrl) {
  //     return _buildStickerMessageBubble(message, isMe);
  //   }
  //   // Then check for file messages
  //   else if (message.messageType == 'file' || hasFileInfo || isFileUrl) {
  //     return Column(
  //       children: [
  //         // In your _buildMessageBubble method, update the sender name section:
  //         if (isGroup && !isMe)
  //     Padding(
  //       padding: const EdgeInsets.only(bottom: 6.0),
  //       child: Row(
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         children: [
  //           CircleAvatar(
  //             backgroundColor: Colors.transparent,
  //             radius: 16,
  //             backgroundImage: CacheImageLoader(
  //               message.originalSender?.avatar ?? message.sender.avatar ?? '',
  //               ImageAssets.defaultProfileImg,
  //             ),
  //           ),
  //           const SizedBox(width: 8),
  //           // Enhanced sender name with fallbacks
  //           Text(
  //             _getSafeSenderName(message, isMe),
  //             style: const TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w600,
  //               color: Colors.grey,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //         _buildFileMessageBubble(message, isMe),
  //       ],
  //     );
  //   } else {
  //     return Column(
  //       children: [
  //         if (isGroup && !isMe)
  //           SizedBox(
  //             height: 10,
  //           ),
  //         if (isGroup && !isMe)
  //           Padding(
  //             padding: const EdgeInsets.only(bottom: 6.0),
  //             child: Row(
  //               crossAxisAlignment: CrossAxisAlignment.center,
  //               children: [
  //                 // Avatar
  //                 CircleAvatar(
  //                   backgroundColor: Colors.transparent,
  //                   radius: 16,
  //                   backgroundImage:CacheImageLoader(message.originalSender?.avatar ??
  //                           message.sender.avatar!,ImageAssets.defaultProfileImg)
  //                 ),
  //                 const SizedBox(width: 8),
  //                 // Name
  //                 Text(
  //                   message.originalSender?.name ??
  //                       message.sender?.name ??
  //                       'User',
  //                   style: const TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w600,
  //                     color: Colors.grey,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //
  //         // Padding(
  //         //     padding: const EdgeInsets.only(bottom: 6.0),
  //         //     child: Row(
  //         //       crossAxisAlignment: CrossAxisAlignment.center,
  //         //       children: [
  //         //         // Avatar
  //         //         CircleAvatar(
  //         //           radius: 16,
  //         //           backgroundImage: message.originalSender?.avatar != null && message.originalSender!.avatar!.isNotEmpty
  //         //               ? CachedNetworkImageProvider(message.originalSender!.avatar!)
  //         //               : AssetImage(ImageAssets.defaultProfileImg) as ImageProvider,
  //         //         ),
  //         //         const SizedBox(width: 8),
  //         //         // Name
  //         //         Text(
  //         //           message.originalSender?.name ?? 'Unknown',
  //         //           style: const TextStyle(
  //         //             fontSize: 14,
  //         //             fontWeight: FontWeight.w600,
  //         //             color: Colors.grey,
  //         //           ),
  //         //         ),
  //         //       ],
  //         //     ),
  //         //   ),
  //
  //         Container(
  //           margin: const EdgeInsets.symmetric(vertical: 4),
  //           child: Align(
  //             alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
  //             child: Row(
  //               mainAxisAlignment:
  //                   isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
  //               crossAxisAlignment: CrossAxisAlignment.end,
  //               children: [
  //                 // Profile picture for received messages (left side)
  //                 // if (!isMe) ...[
  //                 //   _buildProfilePicture(message.sender.avatar),
  //                 //   const SizedBox(width: 12),
  //                 // ],
  //
  //                 // Message content
  //                 Flexible(
  //                   child: Column(
  //                     crossAxisAlignment: isMe
  //                         ? CrossAxisAlignment.end
  //                         : CrossAxisAlignment.start,
  //                     children: [
  //                       Container(
  //                         constraints: BoxConstraints(
  //                           maxWidth: MediaQuery.of(context).size.width * 0.75,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color:
  //                               isMe ? Colors.white : const Color(0xFF1565d8),
  //                           borderRadius: BorderRadius.only(
  //                             topLeft: const Radius.circular(16),
  //                             topRight: const Radius.circular(16),
  //                             bottomLeft: Radius.circular(isMe ? 16 : 4),
  //                             bottomRight: Radius.circular(isMe ? 4 : 16),
  //                           ),
  //                           boxShadow: [
  //                             BoxShadow(
  //                               color: Colors.black.withOpacity(0.1),
  //                               blurRadius: 3,
  //                               offset: const Offset(0, 1),
  //                             ),
  //                           ],
  //                         ),
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             // Reply indicator
  //                             if (message.replyTo != null) ...[
  //                               Container(
  //                                 width: double.infinity,
  //                                 padding:
  //                                     const EdgeInsets.fromLTRB(16, 12, 16, 8),
  //                                 decoration: BoxDecoration(
  //                                   color: isMe
  //                                       ? Colors.grey[100]
  //                                       : Colors.white.withOpacity(0.1),
  //                                   borderRadius: const BorderRadius.only(
  //                                     topLeft: Radius.circular(16),
  //                                     topRight: Radius.circular(16),
  //                                   ),
  //                                   border: Border(
  //                                     left: BorderSide(
  //                                       color:
  //                                           isMe ? Colors.blue : Colors.white,
  //                                       width: 3,
  //                                     ),
  //                                   ),
  //                                 ),
  //                                 child: Column(
  //                                   crossAxisAlignment:
  //                                       CrossAxisAlignment.start,
  //                                   children: [
  //                                     Text(
  //                                       message.replyTo!.sender?.name ??
  //                                           'Unknown',
  //                                       style: TextStyle(
  //                                         fontFamily: AppFonts.opensansRegular,
  //                                         fontSize: 12,
  //                                         fontWeight: FontWeight.w600,
  //                                         color: isMe
  //                                             ? Colors.blue[700]
  //                                             : Colors.white.withOpacity(0.9),
  //                                       ),
  //                                     ),
  //                                     const SizedBox(height: 2),
  //                                     Text(
  //                                       message.replyTo!.content ?? '',
  //                                       style: TextStyle(
  //                                         fontSize: 12,
  //                                         color: isMe
  //                                             ? Colors.grey[600]
  //                                             : Colors.white.withOpacity(0.7),
  //                                       ),
  //                                       maxLines: 2,
  //                                       overflow: TextOverflow.ellipsis,
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],
  //
  //                             // Main message content container
  //                             Padding(
  //                               padding: EdgeInsets.fromLTRB(16,
  //                                   message.replyTo != null ? 8 : 12, 16, 8),
  //                               child: Column(
  //                                 crossAxisAlignment: CrossAxisAlignment.start,
  //                                 children: [
  //                                   // Forwarded indicator
  //                                   if (message.isForwarded == true) ...[
  //                                     Row(
  //                                       children: [
  //                                         Icon(
  //                                           Icons.forward,
  //                                           size: 14,
  //                                           color: isMe
  //                                               ? Colors.grey[600]
  //                                               : Colors.white.withOpacity(0.8),
  //                                         ),
  //                                         const SizedBox(width: 4),
  //                                         Text(
  //                                           'Forwarded',
  //                                           style: TextStyle(
  //                                             fontSize: 12,
  //                                             color: isMe
  //                                                 ? Colors.grey[600]
  //                                                 : Colors.white
  //                                                     .withOpacity(0.8),
  //                                             fontStyle: FontStyle.italic,
  //                                             fontWeight: FontWeight.w500,
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ),
  //                                     const SizedBox(height: 8),
  //                                   ],
  //
  //                                   // Original sender info for forwarded messages
  //                                   if (message.isForwarded == true &&
  //                                       message.originalSender != null) ...[
  //                                     Text(
  //                                       'From: ${message.originalSender!.name}',
  //                                       style: TextStyle(
  //                                         fontFamily: AppFonts.opensansRegular,
  //                                         fontSize: 11,
  //                                         color: isMe
  //                                             ? Colors.grey[600]
  //                                             : Colors.white.withOpacity(0.7),
  //                                         fontWeight: FontWeight.w500,
  //                                       ),
  //                                     ),
  //                                     const SizedBox(height: 6),
  //                                     Container(
  //                                       height: 1,
  //                                       color: isMe
  //                                           ? Colors.grey[300]
  //                                           : Colors.white.withOpacity(0.2),
  //                                       margin:
  //                                           const EdgeInsets.only(bottom: 8),
  //                                     ),
  //                                   ],
  //
  //                                   // Message content with clickable links
  //                                   _buildMessageContent(
  //                                     message.content,
  //                                     textColor:
  //                                         isMe ? Colors.black87 : Colors.white,
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //
  //                             // Timestamp and status row
  //                             Padding(
  //                               padding:
  //                                   const EdgeInsets.fromLTRB(16, 0, 16, 12),
  //                               child: Row(
  //                                 mainAxisAlignment: MainAxisAlignment.end,
  //                                 mainAxisSize: MainAxisSize.min,
  //                                 children: [
  //                                   Text(
  //                                     _formatTime(message.timestamp),
  //                                     style: TextStyle(
  //                                       fontSize: 12,
  //                                       color: isMe
  //                                           ? Colors.grey[500]
  //                                           : Colors.white.withOpacity(0.7),
  //                                     ),
  //                                   ),
  //                                   if (isMe) ...[
  //                                     const SizedBox(width: 4),
  //                                     _buildMessageStatus(message.status, isMe),
  //                                   ],
  //                                 ],
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //
  //                       // Message reactions
  //                       if (message.reactions != null &&
  //                           message.reactions!.isNotEmpty) ...[
  //                         const SizedBox(height: 4),
  //                         _buildReactionRow(message.reactions!),
  //                       ],
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     );
  //   }
  // }

// Enhanced message content builder with link detection
  Widget _buildMessageContent(String content, {Color? textColor}) {
    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(content);

    if (matches.isEmpty) {
      // No URLs found, return plain text
      return Text(
        content,
        style: TextStyle(
          fontFamily: AppFonts.opensansRegular,
          fontSize: 16,
          color: textColor ?? Colors.black87,
          height: 1.3,
        ),
      );
    }

    // URLs found, build RichText with clickable links
    List<TextSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before URL
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: content.substring(lastEnd, match.start),
          style: TextStyle(
            fontSize: 16,
            color: textColor ?? Colors.black87,
            height: 1.3,
          ),
        ));
      }

      // Add clickable URL
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            fontFamily: AppFonts.opensansRegular,
            fontSize: 16,
            color: AppColors.blackColor,
            decoration: TextDecoration.underline,
            height: 1.3,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _openUrl(url),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastEnd),
        style: TextStyle(
          fontFamily: AppFonts.opensansRegular,
          fontSize: 16,
          color: textColor ?? Colors.black87,
          height: 1.3,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Future<void> _openUrl(String url) async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Open Link',
          style: TextStyle(
              fontFamily: AppFonts.opensansRegular,
              color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you want to open this link?',
              style: TextStyle(
                  fontFamily: AppFonts.opensansRegular,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                url,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                  fontFamily: AppFonts.opensansRegular,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Open',
              style: TextStyle(
                  fontFamily: AppFonts.opensansRegular,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );

    if (shouldOpen != true) return;

    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showSnackBar('Could not open link');
      }
    } catch (e) {
      _showSnackBar('Invalid URL: $e');
    }
  }

// Enhanced default avatar
  Widget _buildDefaultAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.grey[400]!, Colors.grey[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 18,
      ),
    );
  }

// Add this helper method:
//   String _getSafeSenderName(Message message, bool isMe) {
//     if (isMe) return 'Me';
//
//     try {
//       return message.originalSender?.name ??
//           message.sender.name ??
//           'Unknown User';
//     } catch (e) {
//       return 'Unknown User';
//     }
//   }

// Enhanced message status with modern styling
//   Widget _buildMessageStatus(String status, bool isMyMessage) {
//     if (!isMyMessage) return const SizedBox.shrink();
//
//     switch (status.toLowerCase()) {
//       case 'sent':
//         return Icon(
//           Icons.check,
//           size: 16,
//           color: Colors.grey[500],
//         );
//       case 'delivered':
//         return Icon(
//           Icons.done_all,
//           size: 16,
//           color: Colors.grey[500],
//         );
//       case 'read':
//         return Icon(
//           Icons.done_all,
//           size: 16,
//           color: Colors.blue[600],
//         );
//       default:
//         return Icon(
//           Icons.schedule,
//           size: 16,
//           color: Colors.grey[400],
//         );
//     }
//   }

// Enhanced reaction row builder
//   Widget _buildReactionRow(List<dynamic> reactions) {
//     return Container(
//       margin: const EdgeInsets.only(top: 4),
//       child: Wrap(
//         spacing: 4,
//         children: reactions.map((reaction) {
//           return Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   reaction['emoji'] ?? '👍',
//                   style: const TextStyle(fontSize: 14),
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   '${reaction['count'] ?? 0}',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

// Helper method to build profile picture

  Widget _buildProfilePicture(dynamic avatar) {
    String? imageUrl;

    // Extract image URL from avatar object

    if (avatar != null) {
      if (avatar is Map<String, dynamic>) {
        imageUrl = avatar['imageUrl'];
      } else if (avatar is String) {
        imageUrl = avatar;
      }
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 32,
                height: 35,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  return _buildDefaultAvatar();
                },
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

// Helper method to build default avatar

  // Widget _buildDefaultAvatar() {
  //   return Container(
  //     width: 32,
  //     height: 32,
  //     decoration: BoxDecoration(
  //       shape: BoxShape.circle,
  //       color: Colors.grey[400],
  //     ),
  //     child: Icon(
  //       Icons.person,
  //       color: Colors.white,
  //       size: 20,
  //     ),
  //   );
  // }
  //
  // Widget _buildMessageContent(String content) {
  //   // Parse formatted text first, then handle URLs
  //   return _buildFormattedContentWithUrls(content);
  // }

  Widget _buildFormattedContentWithUrls(String content) {
    // First, parse the formatting and create text spans
    List<TextSpan> formattedSpans = _parseFormattedText(content);

    // Then, process each span to handle URLs
    List<TextSpan> finalSpans = [];

    for (TextSpan span in formattedSpans) {
      if (span.text != null && _containsUrl(span.text!)) {
        // This span contains URLs, split it further
        finalSpans.addAll(_processUrlsInTextSpan(span));
      } else {
        // No URLs, keep the span as is
        finalSpans.add(span);
      }
    }

    return RichText(
      text: TextSpan(
        children: finalSpans,
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  List<TextSpan> _parseFormattedText(String text) {
    // Check for simple formatting (single format per message)
    if (_hasSimpleFormatting(text)) {
      return [_parseSimpleFormatting(text)];
    }

    // For complex formatting, parse multiple formats
    return _parseComplexFormatting(text);
  }

  List<TextSpan> _parseComplexFormatting(String text) {
    List<TextSpan> spans = [];
    int currentIndex = 0;

    while (currentIndex < text.length) {
      // Find the next formatting marker
      int nextMarkerIndex = text.length;
      String nextMarker = '';

      // Look for formatting markers
      for (String marker in ['*', '_', '~']) {
        int index = text.indexOf(marker, currentIndex);
        if (index != -1 && index < nextMarkerIndex) {
          nextMarkerIndex = index;
          nextMarker = marker;
        }
      }

      // Add plain text before the marker (if any)
      if (nextMarkerIndex > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, nextMarkerIndex),
          style: const TextStyle(fontSize: 16),
        ));
      }

      // If no more markers found, we're done
      if (nextMarkerIndex >= text.length || nextMarker.isEmpty) {
        break;
      }

      // Find the closing marker
      int closingIndex = text.indexOf(nextMarker, nextMarkerIndex + 1);

      if (closingIndex != -1) {
        // Extract the content between markers
        String content = text.substring(nextMarkerIndex + 1, closingIndex);

        // Apply formatting based on marker type
        TextStyle style = _getStyleForMarker(nextMarker);
        spans.add(TextSpan(
          text: content,
          style: style,
        ));

        // Move past the closing marker
        currentIndex = closingIndex + 1;
      } else {
        // No closing marker found, treat as plain text
        spans.add(TextSpan(
          text: text.substring(nextMarkerIndex),
          style: const TextStyle(fontSize: 16),
        ));
        break;
      }
    }

    return spans.isEmpty
        ? [TextSpan(text: text, style: const TextStyle(fontSize: 16))]
        : spans;
  }

  List<TextSpan> _processUrlsInTextSpan(TextSpan originalSpan) {
    final String text = originalSpan.text ?? '';
    final TextStyle baseStyle =
        originalSpan.style ?? const TextStyle(fontSize: 16);

    final urlRegex = RegExp(r'https?://[^\s]+');
    final matches = urlRegex.allMatches(text);

    if (matches.isEmpty) {
      return [originalSpan];
    }

    List<TextSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before URL
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      // Add clickable URL
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: baseStyle.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => FileUtils.openUrl(context, url, localFileManager),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }

  TextSpan _parseSimpleFormatting(String text) {
    String displayText = text;
    TextStyle style = const TextStyle(fontSize: 16);

    if (text.length > 2 && text.startsWith('*') && text.endsWith('*')) {
      // Bold
      displayText = text.substring(1, text.length - 1);
      style = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    } else if (text.length > 2 && text.startsWith('_') && text.endsWith('_')) {
      // Italic
      displayText = text.substring(1, text.length - 1);
      style = const TextStyle(fontSize: 16, fontStyle: FontStyle.italic);
    } else if (text.length > 2 && text.startsWith('~') && text.endsWith('~')) {
      // Underline
      displayText = text.substring(1, text.length - 1);
      style =
          const TextStyle(fontSize: 16, decoration: TextDecoration.underline);
    }

    return TextSpan(text: displayText, style: style);
  }

  bool _hasSimpleFormatting(String text) {
    return (text.length > 2 && text.startsWith('*') && text.endsWith('*')) ||
        (text.length > 2 && text.startsWith('_') && text.endsWith('_')) ||
        (text.length > 2 && text.startsWith('~') && text.endsWith('~'));
  }

// NEW: Get TextStyle for formatting markers
  TextStyle _getStyleForMarker(String marker) {
    switch (marker) {
      case '*':
        return const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
      case '_':
        return const TextStyle(fontSize: 16, fontStyle: FontStyle.italic);
      case '~':
        return const TextStyle(
            fontSize: 16, decoration: TextDecoration.underline);
      default:
        return const TextStyle(fontSize: 16);
    }
  }

  // // Enhanced file message bubble with audio support
  // Widget _buildFileMessageBubble(Message message, bool isMe) {
  //   FileInfo? fileInfo = message.fileInfo;
  //   String fileUrl = message.content;
  //   String fileName = '';
  //   String fileType = '';
  //   String fileSize = '';
  //
  //   if (fileInfo != null) {
  //     fileName = fileInfo.name;
  //     fileType = fileInfo.type;
  //     fileSize = _formatFileSize(fileInfo.size);
  //   } else {
  //     try {
  //       final uri = Uri.parse(fileUrl);
  //       fileName = uri.pathSegments.isNotEmpty
  //           ? uri.pathSegments.last
  //           : 'Unknown File';
  //       fileType = FileUtils.getFileType(fileName);
  //     } catch (e) {
  //       fileName = 'Unknown File';
  //       fileType = 'application/octet-stream';
  //     }
  //   }
  //
  //   final isImage = fileType.startsWith('image/');
  //   final isVideo = fileType.startsWith('video/');
  //   final isAudio = fileType.startsWith('audio/');
  //
  //   // Colors and border radius for sent and received
  //   final bgColor = isMe ? Colors.white : Color(0xFF1565d8);
  //   final textColor = isMe ? Colors.black87 : Colors.white;
  //   final borderRadius = BorderRadius.only(
  //     topLeft: const Radius.circular(12),
  //     topRight: const Radius.circular(12),
  //     bottomLeft: Radius.circular(isMe ? 12 : 0),
  //     bottomRight: Radius.circular(isMe ? 0 : 12),
  //   );
  //
  //   return Container(
  //     margin: const EdgeInsets.symmetric(vertical: 4),
  //     child: Align(
  //       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
  //       child: Container(
  //         constraints: BoxConstraints(
  //           maxWidth: MediaQuery.of(context).size.width * 0.75,
  //         ),
  //         padding: const EdgeInsets.all(12),
  //         decoration: BoxDecoration(
  //           color: bgColor,
  //           borderRadius: borderRadius,
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // if (isGroup && !isMe)
  //             //   Row(
  //             //     children: [
  //             //       // Avatar
  //             //       CircleAvatar(
  //             //         radius: 20,
  //             //         backgroundImage: CachedNetworkImageProvider(message
  //             //                 .originalSender?.avatar ??
  //             //             message.sender?.avatar ??
  //             //             ''), // Replace with actual image URL or AssetImage
  //             //       ),
  //             //       SizedBox(width: 10), // spacing between avatar and name
  //             //       // Name
  //             //       Text(
  //             //         message.originalSender?.name ??
  //             //             message.sender?.name ??
  //             //             '',
  //             //         // Replace with actual name
  //             //         style: TextStyle(
  //             //           fontSize: 16,
  //             //           fontWeight: FontWeight.w500,
  //             //         ),
  //             //       ),
  //             //     ],
  //             //   ),
  //
  //             Row(
  //               children: [
  //                 if (isImage)
  //                   ClipRRect(
  //                     borderRadius: BorderRadius.circular(8),
  //                     child: GestureDetector(
  //                       onTap: () => FileUtils.showImageFullScreen(
  //                           context, fileUrl, fileName, localFileManager),
  //                       child: Image.network(
  //                         fileUrl,
  //                         height: 70,
  //                         width: 70,
  //                         fit: BoxFit.cover,
  //                         loadingBuilder: (context, child, loadingProgress) {
  //                           if (loadingProgress == null) return child;
  //                           return Container(
  //                             height: 70,
  //                             width: 70,
  //                             color: Colors.grey[300],
  //                             child: Center(
  //                               child: CircularProgressIndicator(
  //                                 value: loadingProgress.expectedTotalBytes !=
  //                                         null
  //                                     ? loadingProgress.cumulativeBytesLoaded /
  //                                         loadingProgress.expectedTotalBytes!
  //                                     : null,
  //                               ),
  //                             ),
  //                           );
  //                         },
  //                         errorBuilder: (context, error, stackTrace) {
  //                           return Container(
  //                             height: 70,
  //                             width: 70,
  //                             color: Colors.grey[300],
  //                             child: const Column(
  //                               mainAxisAlignment: MainAxisAlignment.center,
  //                               children: [
  //                                 Icon(Icons.error, color: Colors.red),
  //                                 Text('Failed to load image'),
  //                               ],
  //                             ),
  //                           );
  //                         },
  //                       ),
  //                     ),
  //                   )
  //                 else if (isVideo)
  //                   ClipRRect(
  //                     borderRadius: BorderRadius.circular(8),
  //                     child: GestureDetector(
  //                       onTap: () => FileUtils.showVideoFullScreen(
  //                           context, fileUrl, fileName, localFileManager),
  //                       child: Container(
  //                         height: 70,
  //                         width: 70,
  //                         decoration: BoxDecoration(
  //                           color: isMe ? Colors.grey[100] : Colors.grey[900],
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                         child: Stack(
  //                           alignment: Alignment.center,
  //                           children: [
  //                             Icon(
  //                               Icons.video_library,
  //                               size: 64,
  //                               color: isMe ? Colors.black54 : Colors.white70,
  //                             ),
  //                             Container(
  //                               decoration: BoxDecoration(
  //                                 color: isMe ? Colors.black26 : Colors.black54,
  //                                 borderRadius: BorderRadius.circular(30),
  //                               ),
  //                               child: Icon(
  //                                 Icons.play_arrow,
  //                                 size: 48,
  //                                 color: Colors.white,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                   )
  //                 else if (isAudio)
  //                   GestureDetector(
  //                     onTap: () => FileUtils.showAudioPlayer(
  //                         context, fileUrl, fileName, localFileManager),
  //                     child: Container(
  //                       padding: const EdgeInsets.all(16),
  //                       decoration: BoxDecoration(
  //                         color: isMe ? Colors.grey[100] : Colors.grey[800],
  //                         borderRadius: BorderRadius.circular(8),
  //                         border: Border.all(
  //                             color:
  //                                 isMe ? Colors.grey[300]! : Colors.grey[700]!),
  //                       ),
  //                       child: Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Container(
  //                             padding: const EdgeInsets.all(8),
  //                             decoration: BoxDecoration(
  //                               color: isMe ? Colors.blue : Colors.blue[300],
  //                               borderRadius: BorderRadius.circular(20),
  //                             ),
  //                             child: const Icon(
  //                               Icons.play_arrow,
  //                               color: Colors.white,
  //                               size: 24,
  //                             ),
  //                           ),
  //                           const SizedBox(width: 12),
  //                           Flexible(
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 ConstrainedBox(
  //                                   constraints: BoxConstraints(
  //                                     maxWidth: 180,
  //                                   ),
  //                                   child: Text(
  //                                     fileName,
  //                                     style: TextStyle(
  //                                         fontSize: 12,
  //                                         color: Colors.grey,
  //                                         fontWeight: FontWeight.w600),
  //                                     maxLines: 3,
  //                                     overflow: TextOverflow.ellipsis,
  //                                   ),
  //                                 ),
  //                                 Text(
  //                                   'Audio',
  //                                   style: TextStyle(
  //                                     fontSize: 12,
  //                                     color: isMe
  //                                         ? Colors.grey[600]
  //                                         : Colors.white70,
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   )
  //                 else
  //                   GestureDetector(
  //                     onTap: () => FileUtils.openFile(
  //                         context, fileUrl, fileName, localFileManager),
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Icon(
  //                           _getFileIcon(fileType),
  //                           color: isMe ? Colors.blue : Colors.blue[300],
  //                           size: 32,
  //                         ),
  //                         const SizedBox(width: 8),
  //                         Flexible(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               ConstrainedBox(
  //                                 constraints: BoxConstraints(
  //                                   maxWidth: 220,
  //                                 ),
  //                                 child: Text(
  //                                   fileName,
  //                                   style: TextStyle(
  //                                       fontSize: 12,
  //                                       color: Colors.grey,
  //                                       fontWeight: FontWeight.w600),
  //                                   maxLines: 3,
  //                                   overflow: TextOverflow.ellipsis,
  //                                 ),
  //                               ),
  //                               if (fileInfo?.size != null)
  //                                 Text(
  //                                   _formatFileSize(fileInfo!.size!),
  //                                   style: TextStyle(
  //                                     fontSize: 12,
  //                                     color: isMe
  //                                         ? Colors.grey[600]
  //                                         : Colors.white70,
  //                                     overflow: TextOverflow.ellipsis,
  //                                   ),
  //                                 ),
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 const SizedBox(width: 4),
  //                 if (isImage)
  //                   Center(
  //                     child: Column(
  //                       children: [
  //                         ConstrainedBox(
  //                           constraints: BoxConstraints(
  //                             maxWidth: 200,
  //                           ),
  //                           child: Text(
  //                             fileName,
  //                             style: TextStyle(
  //                                 fontSize: 12,
  //                                 color: Colors.grey,
  //                                 fontWeight: FontWeight.w600),
  //                             maxLines: 3,
  //                             overflow: TextOverflow.ellipsis,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 4),
  //                         Text(
  //                           fileSize,
  //                           style: TextStyle(
  //                               fontSize: 10,
  //                               color: Colors.grey[700],
  //                               fontWeight: FontWeight.w600),
  //                           maxLines: 3,
  //                           overflow: TextOverflow.ellipsis,
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //               ],
  //             ),
  //             const SizedBox(height: 4),
  //             Align(
  //               alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
  //               child: Row(
  //                 children: [
  //                   Text(
  //                     _formatTime(message.timestamp),
  //                     style: TextStyle(
  //                       fontSize: 10,
  //                       color: Colors.grey[600],
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                   ),
  //                   if (isMe) _buildMessageStatus(message.status, isMe),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  //imageuploadingendshere
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  // IconData _getFileIcon(String fileType) {
  //   if (fileType.startsWith('image/')) {
  //     return Icons.image;
  //   } else if (fileType.startsWith('video/')) {
  //     return Icons.videocam;
  //   } else if (fileType.contains('pdf')) {
  //     return Icons.picture_as_pdf;
  //   } else if (fileType.contains('word') || fileType.contains('doc')) {
  //     return Icons.description;
  //   } else if (fileType.contains('excel') || fileType.contains('sheet')) {
  //     return Icons.table_chart;
  //   } else if (fileType.contains('text')) {
  //     return Icons.text_snippet;
  //   } else {
  //     return Icons.insert_drive_file;
  //   }
  // }

  // String _formatFileSize(int bytes) {
  //   if (bytes < 1024) return '$bytes B';
  //   if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  //   if (bytes < 1024 * 1024 * 1024)
  //     return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  //   return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  // }

  // final Map<String, dynamic> notificationdata = Get.arguments ?? {};

  @override
  void initState() {
    super.initState();
    _initializeChatSystem();
  }

  Future<void> _initializeChatSystem() async {
    _initScrollListener();
    _scrollController.addListener(_onScroll);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // ✅ CRITICAL FIX: Initialize BadgeManager FIRST
    await _badgeManager.initialize();

    _initializeChat();

    await _refreshBadgeCounts();
    // ✅ Load user profile to get user ID
    await _loadUserProfile();

    // ✅ Connect socket with proper order
    await _connectSocketFirst();

    // ✅ Fetch chats AFTER socket connection
    await _fetchGroups();
    await _fetchPrivateChats();
    _joinAllChatRooms();
    // ✅ Setup socket listeners AFTER fetching initial data
    _setupSocketListeners();

    // ✅ SYNC: Force badge sync with server on app start
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncBadgeWithServerOnStart();
    });
    _lifecycleEventHandler = LifecycleEventHandler(
      resumeCallBack: () => _handleAppResume(),
    );
    WidgetsBinding.instance.addObserver(_lifecycleEventHandler);

// Mark Changed
    // _socketService.messageHistoryStream.listen((data) {
    //   developer.log("🎯 Handling messageHistory from stream");
    //   if (mounted) _handlePrivateMessageHistory(data);
    // });

    _cleanupMessageKeys();

    // Parse args early
    final dynamic args = Get.arguments;
    final Map<String, dynamic>? notificationData =
        args is Map<String, dynamic> ? args : null;
    final String? directUserId =
        widget.directUserId ?? (args is String ? args : null);

    developer.log("Arguments type: ${args.runtimeType}");
    if (notificationData != null) {
      developer.log(
          "From notification data: ${notificationData['isfromnoticlick']}");
      developer.log("From notification chat id: ${notificationData['chatId']}");
      _refreshChatList();
    } else if (directUserId != null) {
      developer.log("Direct messaging with userId: $directUserId");
    }

    // Chain async init after frame (avoids build conflicts)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeChat();

      if (notificationData != null &&
          notificationData['isfromnoticlick'] == true) {
        _selectChat(notificationData['chatId']);
      } else if (directUserId != null) {
        await _initiateDirectChat(directUserId);
      }

      if (mounted) setState(() => loading = false);
    });

    // ✅ Initialize BadgeManager (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _badgeManager.initialize();
      await _syncBadgeOnScreenLoad();
    });

    // Add app lifecycle listener
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        resumeCallBack: () => _syncBadgeOnAppResume(),
      ),
    );
  }

  Future<void> _connectSocketFirst() async {
    if (_socketService.isConnected) return;
    final userData = await _userPreferences.getUser();
    final token = userData?.token;

    if (token != null) {
      await _socketService.connect(ApiUrls.baseUrl, token);
    }
  }

  Future<void> _syncBadgeWithServerOnStart() async {
    try {
      LoginResponseModel? userData = await _userPreferences.getUser();
      final token = userData?.token;

      if (token != null && currentUserId != null) {
        // Call your API to get actual unread counts from server
        final response = await http.get(
          Uri.parse('${ApiUrls.baseUrl}/connect/v1/api/chat/get-unread-counts'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['success'] == true) {
            final Map<String, dynamic> serverCounts =
                Map<String, dynamic>.from(data['unreadCounts'] ?? {});

            // Update BadgeManager with server counts
            for (final entry in serverCounts.entries) {
              final chatId = entry.key;
              final unreadCount = (entry.value as num).toInt();

              // Update badge manager with server data
              await _badgeManager.updateUnreadCount(chatId, unreadCount,
                  fromServer: true);
            }

            developer.log('[CHAT] ✅ Synced badge counts with server on start');

            // Trigger UI refresh
            if (mounted) {
              setState(() {
                _triggerChatListRefresh();
              });
            }
          }
        }
      }
    } catch (e) {
      developer.log('[CHAT] ❌ Error syncing badge with server on start: $e');
    }
  }

// Call this when you have counter issues to see what's happening
  Future<void> _initiateDirectChat(String targetUserId) async {
    if (currentUserId == null) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      _showSnackBar('Unable to start chat: User not authenticated');
      return;
    }

    await _refreshChatList();

    try {
      // Check existing chat
      // await _fetchPrivateChats();
      final existingChat = directChats.firstWhereOrNull(
        (chat) => chat.participants?.any((p) => p.id == targetUserId) == true,
      );

      debugPrint(
          'selectedChatId direct Before // Check existing chat : $selectedChatId');

      if (existingChat != null) {
        if (mounted) {
          setState(() {
            selectedChatId = existingChat.id;
            showChatList = false;
            showGroupInfo = false;
            selectedSection = 'direct';
            loading = false; // Clear loading
          });
        }

        _selectChat(existingChat.id);
        // _showSnackBar('Opening chat with existing contact');
        return;
      }

      debugPrint(
          'selectedChatId direct After // Check existing chat : $selectedChatId');

      // For new chat: Clear loading immediately (non-blocking), show snackbar for status
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      _showSnackBar('Creating new chat...'); // User feedback

      debugPrint(
          'selectedChatId direct After // currentUserId: $currentUserId');
      debugPrint('selectedChatId direct After // targetUserId: $targetUserId');
      // Call socket—handle in callback (no await/timeout to avoid blocking)

      _socketService.joinPrivateRoom(
        currentUserId!,
        targetUserId,
        (response) async {
          try {
            debugPrint(
                'selectedChatId direct After //  _socketService.joinPrivateRoom response: ${response.toString() ?? 'Unknown error'}');

            if (response['success'] == true && response['chatId'] != null) {
              final newChatId = response['chatId'];
              debugPrint(
                  'selectedChatId direct After // newChatId: $newChatId');
              await _fetchPrivateChats(); // Refresh list

              if (mounted) {
                setState(() {
                  selectedChatId = newChatId;
                  pendingPrivateChatUserId = targetUserId;
                  isNewPrivateChat = true;
                  showChatList = false;
                  showGroupInfo = false;
                  selectedSection = 'direct';
                });
              }
              await _selectChat(newChatId);
              _showSnackBar('Started new chat');
            } else {
              debugPrint(
                  'selectedChatId direct After // newChatId: ${response['message'] ?? 'Unknown error'}');
              throw Exception(response['message'] ?? 'Unknown error');
            }
          } catch (e) {
            debugPrint('Socket callback error: $e');
            _showSnackBar('Failed to start chat: $e. Tap again to retry.');
          }
        },
      );

      // Optional: Add a fallback timer (e.g., 30s) to show retry if no response
      Timer(const Duration(minutes: 1), () {
        if (mounted && selectedChatId == null) {
          _selectChat(selectedChatId);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      debugPrint('Direct chat error: $e');
      _showSnackBar('Unable to start chat: $e');
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    adminAddedSubscription?.cancel();
    _pinnedMessageSubscription.cancel();
    _errorSubscription.cancel();
    _messagesReadSubscription?.cancel();
    _messageReactionSubscription?.cancel();
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _groupDetailsSubscription?.cancel();
    _privateMessageSubscription?.cancel();
    _groupDeletedSubscription?.cancel();
    _reconnectSubscription?.cancel();

    // WidgetsBinding.instance.removeObserver(
    //   LifecycleEventHandler(resumeCallBack: _syncBadgeOnAppResume),
    // );
    WidgetsBinding.instance.removeObserver(_lifecycleEventHandler);

    super.dispose();
  }

  Future<void> _handleAppResume() async {
    log('App resumed, checking socket connection...');
    if (!_socketService.isConnected) {
      log('Socket disconnected, attempting to reconnect...');
      await _connectSocketFirst();
    }
    // Also sync badge counts
    await _syncBadgeOnAppResume();
  }

  Future<void> _loadUserProfile() async {
    try {
      // First try to get from SharedPreferences
      final profile = await _prefs.getUserProfile();
      if (profile != null) {
        setState(() {
          currentUserProfile = profile;
        });
      } else {
        // If not found in SharedPreferences, get from controller
        await _profileController.userListApi();
        if (_profileController.rxRequestStatus.value == Status.COMPLETED) {
          setState(() {
            currentUserProfile =
                _profileController.userList.value as UserProfileModel?;
          });
          // Save to SharedPreferences for future use
          await _prefs.saveUserProfile(
              _profileController.userList.value as UserProfileModel);
        }
      }
    } catch (e) {}
  }

  Future<void> _initializeChat() async {
    try {
      LoginResponseModel? userData = await _userPreferences.getUser();

      // ✅ RESTORED: Original immediate chat loading
      await _fetchGroups();
      await _fetchPrivateChats();

      if (mounted) {
        setState(() {
          currentUserId = userData?.user.id;
          currentUserName = userData?.user.fullName;
          currentUserAvatar = userData?.user.avatar.imageUrl ??
              'https://www.canto.com/blog/image-url/';
          loading = false;
        });
      }

      _animationController.forward();
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _syncBadgeOnScreenLoad() async {
    try {
      // Wait for BadgeManager to initialize and chats to load
      await Future.delayed(Duration(milliseconds: 500));

      final totalUnread = _badgeManager.getTotalUnreadCount();
      final currentBadge = _badgeManager.unreadCounts;

      developer.log(
          '[CHAT] 🔄 Initial badge sync - Total unread: $totalUnread, Current badge: $currentBadge');
    } catch (e) {
      developer.log('[CHAT] ❌ Error in initial badge sync: $e');
    }
  }

// Add this method to handle refresh for chat list
  Future<void> _refreshChatList() async {
    try {
      setState(() {
        loading = true;
      });

      await _fetchGroups();
      await _fetchPrivateChats();

      // Trigger sorting after refresh
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sortAllChats();
      });

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncBadgeOnAppResume() async {
    try {
      await _badgeManager.initialize();
      developer.log('[CHAT] 🔄 Badge synced on app resume');
    } catch (e) {
      developer.log('[CHAT] ❌ Error syncing badge on app resume: $e');
    }
  }

// Add this method to handle refresh for chat messages
  // Future<void> _refreshChatMessages() async {
  //   if (selectedChatId == null) return;

  //   try {
  //     setState(() {
  //       _isLoadingMessages = true;
  //     });

  //     // Fetch fresh messages for the selected chat
  //     await _fetchMessages(selectedChatId!);

  //     // Also refresh pinned messages if applicable
  //     await _fetchPinnedMessages(selectedChatId!);

  //     setState(() {
  //       _isLoadingMessages = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _isLoadingMessages = false;
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to refresh messages: ${e.toString()}'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  void _setupSocketListeners() {
    adminAddedSubscription = _socketService.adminAddedStream.listen((data) {
      _handleAdminAdded(data);
    });
    // Add new listener for read receipts
    _messagesReadSubscription =
        _socketService.messagesReadStream.listen((data) {
      _handleMessagesRead(data);
    });
    // Listen for all incoming messages (both group and private)
    _messageReactionSubscription =
        _socketService.messageReactionUpdatedStream.listen((data) {
      _handleMessageReactionUpdated(data);
    });
    // Add new listener for unread count updates
    _socketService.unreadCountStream.listen((data) {
      _handleUnreadCountUpdate(data);
    });

    _messageSubscription = _socketService.messageStream.listen((data) {
      _handleReceiveMessage(data);
      String? chatId;

      if (data['group'] != null) {
        chatId = data['group'];
      } else if (data['chat'] != null) {
        chatId = data['chat'];
      }

      // if (chatId != null && chatId != selectedChatId) {
      //   _badgeManager.resetUnreadCount(chatId);
      //   setState(() {});
      // }
    });

    _groupDetailsSubscription =
        _socketService.groupDetailsStream.listen((data) {
      _handleGroupDetails(data);
    });

    _groupDeletedSubscription =
        _socketService.groupDeletedStream.listen((data) {
      _handleGroupDeleted(data);
    });
    _messageDeletedSubscription =
        _socketService.messageDeletedStream.listen((data) {
      _handleMessageDeleted(data);
    });
    _privateMessageSubscription =
        _socketService.privateMessageHistoryStream.listen((data) {
      _handlePrivateMessageHistory(data);
    });

    _newMessageSubscription = _socketService.newMessageStream.listen((data) {
      try {
        // Handle regular new messages
        if (data['type'] == 'newMessage') {
          final message = Message.fromJson(data['message']);
          _addNewMessage(message, data['chatId']);
        }

        // Handle forwarded messages
        else if (data['type'] == 'forwardedMessage') {
          final forwardedMessage = Message.fromJson(data['message']);
          final targetChatId = data['chatId'];

          // Add forwarded message to the target chat
          _addNewMessage(forwardedMessage, targetChatId);

          // Show notification if not in the target chat
          if (selectedChatId != targetChatId) {
            _showForwardedMessageNotification(forwardedMessage, targetChatId);
          }
        }

        // Handle any new message (including forwarded)
        else {
          final message = Message.fromJson(data);
          final chatId = data['chatId'] ?? selectedChatId;
          if (chatId != null) {
            _addNewMessage(message, chatId);
          }
        }
      } catch (e) {}
    });

    // Listen for pinned messages
    // Listen for pinned messages - now mainly for syncing with other users
    _pinnedMessageSubscription =
        _socketService.pinnedMessageStream.listen((data) {
      final messageId = data['messageId']?.toString();
      final chatId = data['chatId']?.toString() ?? data['groupId']?.toString();
      final messageData =
          data['message']; // The full message object from server

      if (messageId != null && chatId != null && messageData != null) {
        setState(() {
          if (pinnedMessagesByChat[chatId] == null) {
            pinnedMessagesByChat[chatId] = [];
          }

          // Check if message is already in the list (from optimistic update)
          bool alreadyExists = pinnedMessagesByChat[chatId]!
              .any((m) => _getMessageId(m) == messageId);

          if (!alreadyExists) {
            // This handles cases where another user pinned the message
            pinnedMessagesByChat[chatId]!.add(messageData);
          } else {
            // Update the existing message with server data (in case of any differences)
            int index = pinnedMessagesByChat[chatId]!
                .indexWhere((m) => _getMessageId(m) == messageId);
            if (index != -1) {
              pinnedMessagesByChat[chatId]![index] = messageData;
            }
          }
        });

        // Only show success message if this is NOT the current user's action
        // (we already showed it optimistically)
        if (chatId == selectedChatId && data['userId'] != currentUserId) {
          _showSuccessSnackBar('Message pinned by another user');
        }
      }
    });

    // Listen for unpinned messages
    _unpinnedMessageSubscription =
        _socketService.unpinnedMessageStream.listen((data) {
      final messageId = data['messageId']?.toString();
      final chatId = data['chatId']?.toString() ?? data['groupId']?.toString();

      if (messageId != null && chatId != null) {
        setState(() {
          pinnedMessagesByChat[chatId]
              ?.removeWhere((m) => _getMessageId(m) == messageId);

          // Remove empty lists to keep the map clean
          if (pinnedMessagesByChat[chatId]?.isEmpty == true) {
            pinnedMessagesByChat.remove(chatId);
          }
        });

        // Only show success message if this is the current chat
        if (chatId == selectedChatId) {
          _showSuccessSnackBar('Message unpinned');
        }
      }
    });
    // Listen for errors
    _errorSubscription = _socketService.errorStream.listen((data) {
      _showErrorSnackBar(data['message']?.toString() ?? 'An error occurred');
    });

    _reconnectSubscription = _socketService.onReconnect.listen((_) {
      log('🔄 Re-joining all chat rooms after reconnect...');
      _joinAllChatRooms();
    });
  }

  void _startEditingMessage(Message message) {
    // Only check if it's the user's own message
    if (message.sender.id != currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit your own messages'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _editingMessage = message;
      _editMessageController.text = message.content;
      _isEditingMode = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingMessage = null;
      _editMessageController.clear();
      _isEditingMode = false;
    });
  }

  void _saveEditedMessage() {
    if (_editingMessage == null || _editMessageController.text.trim().isEmpty) {
      return;
    }

    final newContent = _editMessageController.text.trim();
    final messageId = _editingMessage!.id;

    print('Editing message with ID: $messageId');
    print('New content: $newContent');

    // Immediately update the UI (optimistic update)
    setState(() {
      for (String chatId in messages.keys) {
        messages[chatId] = messages[chatId]!.map((msg) {
          if (msg.id == messageId) {
            return msg.copyWith(
              content: newContent,
              isEdited: true,
              editedAt: DateTime.now(),
            );
          }
          return msg;
        }).toList();
      }
    });

    // Clear editing mode immediately
    _cancelEditing();

    // Send to server (for other users and persistence)
    _socketService.editMessage(
      messageId: messageId,
      userId: currentUserId!,
      newContent: newContent,
      callback: (success, message) {
        if (success) {
          // Message already updated in UI, just show success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message edited successfully')),
          );
        } else {
          // Revert the optimistic update on failure
          setState(() {
            for (String chatId in messages.keys) {
              messages[chatId] = messages[chatId]!.map((msg) {
                if (msg.id == messageId) {
                  return msg.copyWith(
                    content: _editingMessage!.content, // Revert to original
                    isEdited: _editingMessage!.isEdited,
                    editedAt: _editingMessage!.editedAt,
                  );
                }
                return msg;
              }).toList();
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to edit message: ${message ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    _clearInputStates();
  }

  // Handler for older private messages
  void _handleOlderPrivateMessages(Map<String, dynamic> data) {
    setState(() {
      _isLoadingOlderMessages = false; // Always reset loading state
    });

    if (data['status'] == 200) {
      final String chatId = data['roomId'];
      final List<dynamic> newMessages = data['messages'] ?? [];
      final bool hasMore = data['hasMore'] ?? false;

      setState(() {
        _hasMoreMessages[chatId] = hasMore;

        if (newMessages.isNotEmpty) {
          // Convert to Message objects
          final List<Message> messageObjects = newMessages.map((msgData) {
            return Message.fromJson(msgData);
          }).toList();

          // Prepend to existing messages
          final existingMessages = messages[chatId] ?? [];
          messages[chatId] = [...messageObjects, ...existingMessages];

          _cleanupMessageKeys();
          // Maintain scroll position
          _maintainScrollPosition(newMessages.length);
        }
      });
    } else {
      _showSnackBar('Failed to load older messages: ${data['message']}');
    }
  }

  // Fixed: Direct callback handler for older group messages
  void _handleOlderGroupMessages(Map<String, dynamic> data) {
    setState(() {
      _isLoadingOlderMessages = false; // Always reset loading state
    });

    if (data['status'] == 200) {
      final String groupId = data['groupId'];
      final List<dynamic> newMessages = data['messages'] ?? [];
      final bool hasMore = data['hasMore'] ?? false;

      setState(() {
        _hasMoreMessages[groupId] = hasMore;

        if (newMessages.isNotEmpty) {
          // Convert to Message objects
          final List<Message> messageObjects = newMessages.map((msgData) {
            return Message.fromJson(msgData);
          }).toList();

          // Prepend to existing messages
          final existingMessages = messages[groupId] ?? [];
          messages[groupId] = [...messageObjects, ...existingMessages];

          _cleanupMessageKeys();

          // Maintain scroll position
          _maintainScrollPosition(newMessages.length);
        }
      });
    } else {
      _showSnackBar('Failed to load older messages: ${data['message']}');
    }
  }

  void _maintainScrollPosition(int newMessageCount) {
    if (newMessageCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final currentScrollOffset = _scrollController.offset;
          final itemHeight = 80.0; // Adjust based on your actual message height
          final newScrollOffset =
              currentScrollOffset + (newMessageCount * itemHeight);

          _scrollController.jumpTo(newScrollOffset.clamp(
              0.0, _scrollController.position.maxScrollExtent));
        }
      });
      allChats.sort((a, b) {
        final unreadCompare = b.unread.compareTo(a.unread);
        if (unreadCompare != 0) return unreadCompare;

        return b.timestamp.compareTo(a.timestamp);
      });
    }
  }

// Dialog to show group creation limit warning
  Future<void> _showGroupLimitWarningDialog(
      int currentCount, int maxLimit) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                'Group Creation Limit Reached',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have reached your group creation limit.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.red[600], size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Limit Details:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Groups created: $currentCount'),
                    Text('Maximum allowed: $maxLimit'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              if (maxLimit <= 1) // Show upgrade message for basic users
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.blue[600], size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Upgrade to Premium',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create unlimited groups with premium subscription!',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              if (maxLimit >
                  1) // Show alternative suggestion for users with some limit
                Text(
                  'To create more groups, consider deleting some existing groups or upgrading your subscription.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            if (maxLimit <= 1) // Show upgrade button for basic users
              TextButton(
                child: Text(
                  'Upgrade Now',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to premium upgrade page
                  // _navigateToUpgradePage();
                },
              ),
            if (maxLimit >
                1) // Show manage groups button for users with some limit
              TextButton(
                child: Text(
                  'Manage Groups',
                  style: TextStyle(color: Colors.orange),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to group management to delete groups
                  // _navigateToGroupManagement();
                },
              ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Add this method to validate group creation limit
  Future<bool> _validateGroupCreationLimit() async {
    try {
      // Get current user's group limit from profile
      final groupLimit =
          currentUserProfile?.subscriptionFeatures?.publicGroup ??
              1; // Default 1 if not found

      // Get current number of groups created by user
      final currentGroupCount = await _getCurrentUserGroupCount();

      if (currentGroupCount >= groupLimit) {
        // Show warning dialog
        await _showGroupLimitWarningDialog(currentGroupCount, groupLimit);
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

// Method to count groups created by current user
  Future<int> _getCurrentUserGroupCount() async {
    try {
      // Get current user
      final userData = await _userPreferences.getUser();
      final currentUserId = userData?.user.id;
      if (currentUserId == null) {
        throw Exception('Current user ID not found');
      }

      int createdGroupsCount = 0;

      // 1️⃣ Try cached data first (instant + offline)
      final cachedGroups = await _chatService.getMyGroupsCached();
      if (cachedGroups.isNotEmpty) {
        createdGroupsCount =
            cachedGroups.where((g) => g.createdBy?.id == currentUserId).length;
      }

      // 2️⃣ Fetch fresh data (update Hive + count)
      try {
        final fetchedGroups = await _chatService.refreshMyGroups();
        createdGroupsCount =
            fetchedGroups.where((g) => g.createdBy?.id == currentUserId).length;
      } catch (networkError) {
        // silently ignore if offline
        debugPrint('🌐 Skipped network refresh: $networkError');
      }

      return createdGroupsCount;
    } catch (e) {
      debugPrint('❌ Error in _getCurrentUserGroupCount: $e');
      return 0;
    }
  }

  void _handleUnreadCountUpdate(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    final unreadCount = data['unreadCount'] as int? ?? 0;

    if (chatId != null) {
      _badgeManager.updateUnreadCount(chatId, unreadCount);

      // Trigger sorting after unread count update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sortAllChats();
      });
    }
  }

  //deletemessage
  void _handleMessageDeleted(Map<String, dynamic> data) {
    final messageId = data['messageId'];

    if (messageId != null) {
      setState(() {
        // Remove message from your messages map
        // Iterate through all chat IDs and remove the message from each list
        messages.forEach((chatId, messageList) {
          messageList
              .removeWhere((message) => _getMessageId(message) == messageId);
        });

        // Alternative: If you know the current chat ID, you can target it specifically
        // if (selectedChatId != null && messages[selectedChatId] != null) {
        //   messages[selectedChatId]!.removeWhere((message) => _getMessageId(message) == messageId);
        // }
      });

      // Show feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteMessage(dynamic message) {
    if (message == null) return;

    final messageId = _getMessageId(message);
    final currentid =
        currentUserId!; // Implement this method to get current user ID

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteMessage(messageId!, currentid);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performDeleteMessage(String messageId, String userId) {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    _socketService.deleteMessage(
      messageId: messageId,
      userId: userId,
      callback: (success, message) {
        // Hide loading indicator
        Navigator.of(context).pop();

        if (success) {
          _removeMessageFromUI(messageId);
          // Success is handled by the socket listener
          // The message will be removed from UI when 'messageDeleted' event is received
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message ?? 'Message deleted successfully')),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? 'Failed to delete message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

//admin code
  void _handleAdminAdded(Map<String, dynamic> data) {
    // Handle the admin added event
    String? userId = data['userId'];
    String? groupId = data['groupId'];
    String? userName = data['userName'];

    if (groupId != null && userName != null) {
      setState(() {
        // Update your groups/members list
        // Example implementation:
        final groupIndex = groups.indexWhere((group) => group.id == groupId);
        if (groupIndex != -1) {
          groups[groupIndex].admins?.add(userName);
        }
      });

      _showSnackBar('New admin added to group');
    }

    // if (userId != null && groupId != null && groupId == selectedGroup!.id) {
    //   // Update your groups list or current group data
    //   setState(() {
    //     // Add the user to admins list in your group model
    //     // This depends on your data structure
    //     // For example: currentGroup.admins.add(userId);
    //   });

    //   // Show success message
    //   _showSuccessSnackBar('${userName ?? 'User'} promoted to admin successfully');
    // }
  }

//rections code
// Handle when messages are marked as read
  // Handle when messages are marked as read
// Handle when messages are marked as read
  void _handleMessagesRead(Map<String, dynamic> data) {
    final chatId = data['chatId'];
    final userId = data['userId'];

    // Update your local message map to mark messages as read
    setState(() {
      // Get the messages for the specific chat
      if (messages.containsKey(chatId)) {
        final chatMessages = messages[chatId]!;

        // Update messages where the receiver (userId) is reading messages from other senders
        for (var message in chatMessages) {
          if (message.sender.id != userId) {
            message.status = 'read';
          }
        }
      }
    });
  }

  // Method to set last read position when marking as read
  void _setLastReadPosition(String chatId) {
    final chatMessages = messages[chatId] ?? [];
    if (chatMessages.isNotEmpty) {
      // Store the ID of the last message as the last read message
      lastReadMessageId[chatId] = chatMessages.last.id;
    }
  }

  // Fixed _handleMessageReactionUpdated method
  void _handleMessageReactionUpdated(Map<String, dynamic> updatedMessage) {
    final String messageIdToUpdate = updatedMessage['_id'];

    // Use your current chat ID variable (selectedChatId, currentChatId, etc.)
    if (selectedChatId == null) return;

    setState(() {
      List<Message> currentChatMessages = messages[selectedChatId!] ?? [];

      for (int i = 0; i < currentChatMessages.length; i++) {
        if (currentChatMessages[i].id == messageIdToUpdate) {
          currentChatMessages[i].reactions =
              (updatedMessage['reactions'] as List?)
                      ?.map((r) => Reaction.fromJson(r))
                      .toList() ??
                  [];

          break;
        }
      }
    });
  }

  void _handleReaction(String messageId, String emoji) {
    if (selectedChatId == null || currentUserId == null) return;

    _socketService.reactToMessage(
      messageId: messageId,
      userId: currentUserId!,
      emoji: emoji,
    );
  }

  void _showEmojiReactions(String messageId) {
    final availableEmojis = _getAvailableEmojis();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'React with an emoji',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${availableEmojis.length} available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: availableEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = availableEmojis[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _handleReaction(messageId, emoji);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (availableEmojis.length < emojiReactions.length) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Upgrade your subscription to access ${emojiReactions.length - availableEmojis.length} more emoji reactions!',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget _buildReactionRow(List<Reaction> reactions) {
  //   if (reactions.isEmpty) return const SizedBox.shrink();
  //
  //   // Group reactions by emoji
  //   Map<String, List<Reaction>> groupedReactions = {};
  //   for (var reaction in reactions) {
  //     if (groupedReactions.containsKey(reaction.emoji)) {
  //       groupedReactions[reaction.emoji]!.add(reaction);
  //     } else {
  //       groupedReactions[reaction.emoji] = [reaction];
  //     }
  //   }
  //
  //   return Container(
  //     margin: const EdgeInsets.only(top: 4),
  //     child: Wrap(
  //       spacing: 4,
  //       children: groupedReactions.entries.map((entry) {
  //         String emoji = entry.key;
  //         List<Reaction> emojiReactions = entry.value;
  //         bool hasCurrentUserReacted =
  //             emojiReactions.any((r) => r.user.id == currentUserId);
  //
  //         return GestureDetector(
  //           onTap: () {
  //             // Show who reacted with this emoji
  //             _showReactionDetails(emoji, emojiReactions);
  //           },
  //           child: Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //             decoration: BoxDecoration(
  //               color:
  //                   hasCurrentUserReacted ? Colors.blue[100] : Colors.grey[200],
  //               borderRadius: BorderRadius.circular(12),
  //               border: hasCurrentUserReacted
  //                   ? Border.all(color: Colors.blue, width: 1)
  //                   : null,
  //             ),
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text(emoji, style: const TextStyle(fontSize: 14)),
  //                 const SizedBox(width: 2),
  //                 Text(
  //                   emojiReactions.length.toString(),
  //                   style: TextStyle(
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.w500,
  //                     color: hasCurrentUserReacted
  //                         ? Colors.blue[700]
  //                         : Colors.grey[700],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

  void _showReactionDetails(String emoji, List<Reaction> reactions) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reacted with $emoji',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // const SizedBox(height: 6),
            ...reactions.map((reaction) => ListTile(
                  // leading: CircleAvatar(
                  //   backgroundImage: reaction.user.avatar != null
                  //       ? CachedNetworkImageProvider(reaction.user.avatar!)
                  //       : null,
                  //   child: reaction.user.avatar == null
                  //       ? Text(reaction.user.name[0].toUpperCase())
                  //       : null,
                  // ),
                  title: Text(reaction.user.name),
                  trailing: Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // Helper method to add new message to chat (fixed for your data structure)
  void _addNewMessage(Message message, String chatId) {
    setState(() {
      // Find the chat and update it
      final chatIndex = allChats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        // Create updated chat with new last message and timestamp
        final updatedChat = Chat(
          id: allChats[chatIndex].id,
          name: allChats[chatIndex].name,
          avatar: allChats[chatIndex].avatar,
          lastMessage: message.content,
          timestamp: message.timestamp,
          // Use timestamp, not lastMessageTime
          unread:
              allChats[chatIndex].unread + (selectedChatId == chatId ? 0 : 1),
          isGroup: allChats[chatIndex].isGroup,
          isOnline: allChats[chatIndex].isOnline,
          senderName: message.sender.name,
          participants: allChats[chatIndex].participants,
        );

        allChats[chatIndex] = updatedChat;

        if (selectedChatId == chatId) {
          (messages as Map<String, Message>)[message.id] = message;
        } else if (selectedChatId == chatId && messages is List) {
          (messages as List<Message>).add(message);
        }

        final chat = allChats.removeAt(chatIndex);
        allChats.insert(0, chat);
      }
    });
    _sortAllChats();
  }

  void _showForwardedMessageNotification(Message message, String chatId) {
    final chat = allChats.firstWhereOrNull((c) => c.id == chatId);
    if (chat != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New forwarded message in ${chat.name}'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              setState(() {
                selectedChatId = chatId;
                _selectChat(chatId); // Use your existing method to load chat
              });
            },
          ),
        ),
      );
    }
    _sortAllChats();
  }

  Widget _buildScrollToBottomButton() {
    final currentUnreadCount = selectedChatId != null
        ? (_badgeManager.unreadCounts[selectedChatId!] ?? 0)
        : 0;

    return AnimatedOpacity(
      opacity: _showScrollToBottom ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () {
              if (currentUnreadCount > 0) {
                _scrollToFirstUnreadMessage();
              } else {
                _scrollToBottom(force: true);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 24,
                  ),
                  if (currentUnreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          currentUnreadCount > 99
                              ? '99+'
                              : '$currentUnreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadMessageSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.greyColor.withOpacity(0.4),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'New messages',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.opensansRegular),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotificationIfNeeded(
      String chatId, Message message, bool isGroup) async {
    try {
      // Don't show if this is the current active chat
      if (selectedChatId == chatId) {
        return;
      }

      final chat = allChats.firstWhereOrNull((c) => c.id == chatId);
      if (chat == null) return;

      String senderName = message.sender.name ?? 'Unknown';
      String groupName = '';
      String? avatar;

      if (isGroup) {
        final group = groups.firstWhereOrNull((g) => g.id == chatId);
        groupName = group?.name ?? 'Group Chat';
        avatar = message.sender.avatar ?? group?.groupAvatar;
      } else {
        senderName = message.sender.name ?? chat.name ?? 'Unknown';
        avatar = message.sender.avatar;
      }

      await NotificationService().showMessageNotification(
          chatId: chatId,
          senderName: senderName,
          message: message.content ?? '',
          isGroup: isGroup,
          groupName: groupName,
          payload: jsonEncode({
            "type": "chat",
            "chat_id": chatId,
            "sender_id": "9988",
            "sender_name": senderName,
            "message": message.content,
            "isGroup": isGroup,
            "groupName": groupName
          }));

      log('[CHAT] 📲 Notification shown for $chatId');
    } catch (e) {
      log('[CHAT] ❌ Error showing notification: $e');
    }
  }

  // In your notification handling
  void _handleReceiveMessage(Map<String, dynamic> serverMessage) {
    try {
      final isGroupMessage = serverMessage['group'] != null;
      final chatId =
          isGroupMessage ? serverMessage['group'] : serverMessage['chat'];

      if (chatId == null) {
        developer.log('[CHAT] ❌ No chatId found in message');
        return;
      }

      final newMessage = Message.fromJson(serverMessage);
      final isCurrentChat = selectedChatId == chatId;

      developer.log(
          '[CHAT] 📩 New message in chat: $chatId, isCurrent: $isCurrentChat');

      // Update messages first
      setState(() {
        if (messages[chatId] == null) {
          messages[chatId] = [];
        }
        messages[chatId] = [...messages[chatId]!, newMessage];
      });

      if (isCurrentChat) {
        _cleanupMessageKeys();
      }

      // ✅ ENHANCED: Handle unread count update using BadgeManager
      if (!isCurrentChat && newMessage.originalSender?.id != currentUserId) {
        // Increment unread count using BadgeManager
        _badgeManager.incrementUnreadCount(chatId);

        // Show notification
        _showNotificationIfNeeded(chatId, newMessage, isGroupMessage);
      } else if (isCurrentChat && _isUserAtBottom) {
        // If it's the current chat and user is at bottom, mark as read immediately
        _markChatAsRead(chatId);
      }

      // Update chat list and trigger UI refresh
      _updateChatLastMessage(chatId, newMessage);
      _triggerChatListRefresh();

      // Auto-scroll if current chat
      if (isCurrentChat && _isUserAtBottom) {
        _scrollToBottom();
      }
    } catch (e) {
      developer.log('[CHAT] ❌ Error handling received message: $e');
    }
  }

  // Add this method to manually refresh badge counts
  Future<void> _refreshBadgeCounts() async {
    try {
      // Initialize BadgeManager
      await _badgeManager.initialize();

      // Get current counts for debugging
      final currentCounts = _badgeManager.unreadCounts;
      developer.log('[CHAT] 🔄 Current badge counts: $currentCounts');

      // Force UI refresh
      if (mounted) {
        setState(() {
          _triggerChatListRefresh();
        });
      }
    } catch (e) {
      developer.log('[CHAT] ❌ Error refreshing badge counts: $e');
    }
  }

  void _updateChatLastMessage(String chatId, Message message) {
    // Update direct chats
    final directChatIndex = directChats.indexWhere((chat) => chat.id == chatId);
    if (directChatIndex != -1) {
      setState(() {
        directChats[directChatIndex] = Chat(
          id: directChats[directChatIndex].id,
          name: directChats[directChatIndex].name,
          avatar: directChats[directChatIndex].avatar,
          lastMessage: message.content,
          timestamp: message.timestamp,
          unread: _badgeManager.unreadCounts[chatId] ??
              directChats[directChatIndex].unread + 1,
          isGroup: directChats[directChatIndex].isGroup,
          participants: directChats[directChatIndex].participants,
        );
      });

      // Trigger sorting after update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sortAllChats();
      });
    }
  }

  // Handle group deletion from server
  void _handleGroupDeleted(Map<String, dynamic> data) {
    final String deletedGroupId = data['groupId'] ?? '';

    setState(() {
      groups.removeWhere((group) => group.id == deletedGroupId);

      // If the deleted group was selected, clear selection
      if (selectedChatId == deletedGroupId) {
        selectedChatId = null;
        // selectedGroup = null;
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Group deleted successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Method to handle group deletion
  // Method to handle group deletion
  void handleDeleteGroup() {
    if (selectedGroup == null || currentUserId == null) {
      return;
    }

    // Check if current user is the admin/owner using your existing isAdmin getter
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only group admin can delete the group'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Group'),
          content: Text(
            'Are you sure you want to delete "${selectedGroup!.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performGroupDeletion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _performGroupDeletion() {
    if (selectedGroup == null || currentUserId == null) return;

    _socketService.deleteGroup(
      groupId: selectedGroup?.id ?? '',
      ownerId: selectedGroup?.createdBy?.id ?? '',
      callback: (bool success) {
        if (success) {
          setState(() {
            groups.removeWhere((group) => group.id == selectedGroup!.id);
            selectedChatId = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Group deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete group'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  void _handleGroupDetails(Map<String, dynamic> data) {
    final groupData = data['group'];

    final messagesList = data['messages'] as List;

    final transformedMessages =
        messagesList.map((msg) => Message.fromJson(msg)).toList();

    setState(() {
      messages[groupData['_id']] = transformedMessages;
    });
  }

  void _clearInputStates() {
    setState(() {
      // Ensure reply state is always cleared
      replyingToMessage = null;
      showReplyPreview = false;
      _isEditingMode = false;
      _editingMessage = null;
    });

    // Clear controllers
    _editMessageController.clear();
  }

  void _sortAllChats() {
    setState(() {
      allChats.sort((a, b) {
        // Priority 1: Latest activity timestamp (descending order)
        final DateTime aLatest = _getLatestTimestampFromSources(a);
        final DateTime bLatest = _getLatestTimestampFromSources(b);

        final timestampCompare = bLatest.compareTo(aLatest);
        if (timestampCompare != 0) return timestampCompare;

        // Priority 2: Unread messages come first
        final bool aHasUnread = a.unread > 0;
        final bool bHasUnread = b.unread > 0;

        if (aHasUnread && !bHasUnread) return -1;
        if (!aHasUnread && bHasUnread) return 1;

        // Priority 3: Unread count (higher count first)
        if (aHasUnread && bHasUnread) {
          return b.unread.compareTo(a.unread);
        }

        return 0;
      });
    });
    _debugChatOrdering();
  }

  void _handlePrivateMessageHistory(Map<String, dynamic> data) {
    final roomId = data['roomId'];
    final messagesList = data['messages'] as List;

    final transformedMessages =
        messagesList.map((msg) => Message.fromJson(msg)).toList();

    setState(() {
      messages[roomId] = transformedMessages;
      selectedChatId = roomId;
      _isLoadingMessages = false; // Clear initial loading state
      _isLoadingOlderMessages = false; // Clear older messages loading state
      // Initialize hasMore to true since we just loaded initial messages
      _hasMoreMessages[roomId] = true;
    });

    _cleanupMessageKeys();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(force: false);
    });
  }

  void _populatePinnedMessagesForGroups(List<GroupData> groups) {
    for (var group in groups) {
      final groupId = group.id ?? '';
      pinnedMessagesByChat[groupId] = group.pinnedMessages?.isNotEmpty == true
          ? List<dynamic>.from(group.pinnedMessages!)
          : [];
    }
  }

  Future<void> _fetchPrivateChats() async {
    developer.log("=========== _fetchPrivateChats called");
    if (!mounted) return;
    setState(() => _isLoadingMessages = true);

    try {
      final uid = currentUserId ?? '';
      if (uid.isEmpty) {
        developer
            .log('⚠️ currentUserId is null/empty during _fetchPrivateChats');
        setState(() => _isLoadingMessages = false);
        return;
      }

      // Fetch from service (this will update BadgeManager internally)
      final fetchedChats = await _chatService.refreshPrivateChats(uid);

      if (mounted) {
        setState(() {
          directChats = fetchedChats.cast<Chat>();
          _isLoadingMessages = false;
        });

        // ✅ Force refresh chat list to show BadgeManager counts
        _triggerChatListRefresh();
      }
    } catch (e) {
      developer.log('❌ Error in _fetchPrivateChats: $e');
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _fetchGroups() async {
    try {
      // Fetch from service (this will update BadgeManager internally)
      final fetchedGroups = await _chatService.refreshMyGroups();

      if (mounted) {
        setState(() {
          groups = fetchedGroups.cast<GroupData>();
          _populatePinnedMessagesForGroups(groups);
        });

        // ✅ Force refresh chat list to show BadgeManager counts
        _triggerChatListRefresh();
      }
    } catch (e) {
      developer.log('❌ Error in _fetchGroups: $e');
    }
  }

  void _populatePinnedMessagesForChats(List<Chat> chats) {
    for (var chat in chats) {
      final chatId = chat.id;
      pinnedMessagesByChat[chatId] = chat.pinnedMessages?.isNotEmpty == true
          ? List<dynamic>.from(chat.pinnedMessages!)
          : [];
    }
  }

  // void _onTabChanged(String newTab) {
  //   setState(() {
  //     selectedTab = newTab;
  //     _applyFilters(); // Reapply filters when tab changes
  //   });
  // }
  List<Chat> get allChats {
    final List<Chat> combined = [
      ...directChats.map((chat) {
        final chatMessages = messages[chat.id];
        final lastMessageTime = chatMessages?.isNotEmpty == true
            ? chatMessages!.last.timestamp
            : chat.timestamp;

        DateTime validTimestamp;
        try {
          validTimestamp = lastMessageTime is DateTime
              ? lastMessageTime
              : (lastMessageTime is String ? lastMessageTime : DateTime.now());
        } catch (e) {
          validTimestamp = DateTime.now();
        }

        // ✅ SINGLE SOURCE OF TRUTH: Get unread count from BadgeManager
        final unreadCount = _badgeManager.getUnreadCount(chat.id);

        return Chat(
          id: chat.id,
          name: chat.name,
          avatar: chat.avatar,
          lastMessage: chatMessages?.isNotEmpty == true
              ? chatMessages!.last.content
              : chat.lastMessage,
          timestamp: validTimestamp,
          unread: unreadCount, // Always use BadgeManager
          isGroup: chat.isGroup,
          participants: chat.participants,
        );
      }),
      ...groups.map((group) {
        final groupMessages = messages[group.id ?? ''];
        DateTime lastMessageTime;

        try {
          if (groupMessages?.isNotEmpty == true) {
            lastMessageTime = groupMessages!.last.timestamp;
          } else if (group.updatedAt != null) {
            lastMessageTime = DateTime.parse(group.updatedAt!);
          } else if (group.createdAt != null) {
            lastMessageTime = DateTime.parse(group.createdAt!);
          } else {
            lastMessageTime = DateTime.fromMillisecondsSinceEpoch(0);
          }
        } catch (e) {
          lastMessageTime = DateTime.now();
        }

        // ✅ SINGLE SOURCE OF TRUTH: Get unread count from BadgeManager
        final unreadCount = _badgeManager.getUnreadCount(group.id ?? '');

        return Chat(
          id: group.id ?? '',
          name: group.name ?? '',
          avatar: group.groupAvatar ?? ImageAssets.defaultProfileImg,
          lastMessage: (group.lastMessage ??
              ((groupMessages?.isNotEmpty ?? false)
                  ? groupMessages?.last.content
                  : 'Group created') ??
              'Group created'),
          timestamp: lastMessageTime,
          unread: unreadCount, // Always use BadgeManager
          isGroup: true,
          participants: group.members
              ?.map((member) => Participant(
                    id: member.userId.id,
                    name: member.userId.fullName,
                    avatar: member.userId.avatar?.imageUrl,
                  ))
              .toList(),
        );
      }),
    ];

    combined.sort((a, b) {
      try {
        // Priority 1: Latest activity timestamp (descending order)
        final DateTime aLatest = _getLatestTimestampFromSources(a);
        final DateTime bLatest = _getLatestTimestampFromSources(b);

        final timestampCompare = bLatest.compareTo(aLatest);
        if (timestampCompare != 0) return timestampCompare;

        // Priority 2: Unread messages come first
        final bool aHasUnread = a.unread > 0;
        final bool bHasUnread = b.unread > 0;

        if (aHasUnread && !bHasUnread) return -1;
        if (!aHasUnread && bHasUnread) return 1;

        // Priority 3: Unread count (higher count first)
        if (aHasUnread && bHasUnread) {
          return b.unread.compareTo(a.unread);
        }

        return 0;
      } catch (e) {
        return b.id.compareTo(a.id);
      }
    });

    return combined;
  }

  GroupData? get selectedGroup {
    try {
      return groups.firstWhere(
        (group) => group.id == selectedChatId,
      );
    } catch (e) {
      return null;
    }
  }

  Chat? get selectedChat {
    try {
      return allChats.firstWhere(
        (chat) => chat.id == selectedChatId,
      );
    } catch (e) {
      return null;
    }
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.fromMillisecondsSinceEpoch(0);

    try {
      if (timestamp is DateTime) return timestamp;
      if (timestamp is String) return DateTime.parse(timestamp);
      if (timestamp is int)
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime _getLatestTimestampFromSources(Chat chat) {
    return _parseTimestamp(chat.timestamp);
  }

  bool get isAdmin {
    final group = selectedGroup;
    return group?.admins?.contains(currentUserId) ?? false;
  }

// Force refresh of chat list UI
  void _triggerChatListRefresh() {
    if (mounted) {
      setState(() {
        // This forces the chat list to rebuild with updated unread counts
      });
    }

    // Also trigger sorting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sortAllChats();
    });
  }

// Enhanced mark as read method
  void _markChatAsRead(String chatId) {
    if (chatId.isEmpty || currentUserId == null) return;

    final currentUnread = _badgeManager.getUnreadCount(chatId);

    if (currentUnread > 0) {
      developer.log(
          '[CHAT] 📖 Marking chat as read: $chatId, unread: $currentUnread');

      _badgeManager.resetUnreadCount(chatId);

      // Update server via socket
      _socketService.markMessagesAsRead(
        chatId: chatId,
        userId: currentUserId!,
      );

      // Update chat list UI
      _triggerChatListRefresh();

      developer.log('[CHAT] ✅ Chat marked as read: $chatId');
    }
  }

// Enhanced select chat method
  Future<void> _selectChat(String? chatId) async {
    if (chatId == null || chatId.isEmpty) {
      _showSnackBar('Invalid chat selected');
      return;
    }

    try {
      // Save previous chat scroll position
      if (selectedChatId != null && _scrollController.hasClients) {
        _chatScrollPositions[selectedChatId!] = _scrollController.offset;
      }

      if (!mounted) return;

      // ✅ CRITICAL FIX: Mark previous chat as read on SERVER
      if (selectedChatId != null && selectedChatId != chatId) {
        // await _markChatAsReadOnServer(selectedChatId!);
      }
      _markChatAsRead(chatId);

      setState(() {
        selectedChatId = chatId;
        _showScrollToBottom = false;
        showChatList = MediaQuery.of(context).size.width <= 600 ? false : true;
        _isLoadingMessages = true;
        _isLoadingOlderMessages = false;
        _hasShownUnreadSeparator = false;
      });

      // ✅ CRITICAL FIX: Reset unread count LOCALLY and on SERVER
      await _resetUnreadCountForChat(chatId);

      // Join appropriate room
      final chat = allChats.firstWhereOrNull((c) => c.id == chatId);
      if (chat != null) {
        if (chat.isGroup) {
          _joinGroup(chatId, currentUserId!, chatId);
        } else {
          _joinPrivateChat(chatId);
        }
      }

      // Load messages
      await _loadMessagesForChat(chatId);

      if (mounted) setState(() => _isLoadingMessages = false);
    } catch (e) {
      developer.log('[CHAT] ❌ Error selecting chat: $e');
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

// Add this method to mark chat as read on server
  Future<void> _markChatAsReadOnServer(String chatId) async {
    if (chatId.isEmpty || currentUserId == null) return;

    try {
      LoginResponseModel? userData = await _userPreferences.getUser();
      final token = userData?.token;

      if (token != null) {
        // Call API to mark chat as read on server
        final response = await http.post(
          Uri.parse('${ApiUrls.baseUrl}/connect/v1/api/chat/mark-chat-read'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'chatId': chatId,
            'userId': currentUserId,
          }),
        );

        if (response.statusCode == 200) {
          developer.log('[CHAT] ✅ Marked chat as read on server: $chatId');
        }
      }
    } catch (e) {
      developer.log('[CHAT] ❌ Error marking chat as read on server: $e');
    }
  }

// Update existing method to also sync with server
  Future<void> _resetUnreadCountForChat(String chatId) async {
    if (chatId.isEmpty) return;

    // Reset locally
    await _badgeManager.resetUnreadCount(chatId);

    // Also reset on server
    // await _markChatAsReadOnServer(chatId);

    _markChatAsRead(chatId);

    // Update UI
    if (mounted) {
      setState(() {
        _triggerChatListRefresh();
      });
    }
  }

  void _debugChatOrdering() {
    debugPrint('=== CHAT ORDERING DEBUG ===');
    for (var i = 0; i < allChats.length; i++) {
      final chat = allChats[i];
      debugPrint(
          '[$i] ${chat.name} - Unread: ${chat.unread} - Time: ${chat.timestamp}');
    }
    debugPrint('=== END DEBUG ===');
  }

  // Add this method to load messages for a specific chat
  Future<void> _loadMessagesForChat(String chatId) async {
    if (chatId.isEmpty) return;

    try {
      setState(() {
        _isLoadingMessages = true;
      });

      final chat = allChats.firstWhereOrNull((c) => c.id == chatId);
      if (chat == null) {
        debugPrint('[MESSAGES] Chat not found: $chatId');
        setState(() => _isLoadingMessages = false);
        return;
      }

      debugPrint(
          '[MESSAGES] Loading messages for chat: $chatId, isGroup: ${chat.isGroup}');

      if (chat.isGroup) {
        // Load group messages
        await _loadGroupMessages(chatId);
      } else {
        // Load private messages
        await _loadPrivateMessages(chatId);
      }
    } catch (e) {
      debugPrint('[MESSAGES] Error loading messages for chat $chatId: $e');
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
      _showSnackBar('Failed to load messages');
    }
  }

// Helper method to load group messages
  Future<void> _loadGroupMessages(String groupId) async {
    try {
      _socketService.loadOlderGroupMessages(
        groupId: groupId,
        onResponse: (data) {
          if (mounted) {
            setState(() {
              _isLoadingMessages = false;
            });
          }

          if (data['status'] == 200) {
            final messagesList = data['messages'] as List;
            final transformedMessages =
                messagesList.map((msg) => Message.fromJson(msg)).toList();

            setState(() {
              messages[groupId] = transformedMessages;
              _hasMoreMessages[groupId] = data['hasMore'] ?? false;
            });

            _cleanupMessageKeys();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom(force: false);
            });
          } else {
            _showSnackBar('Failed to load group messages: ${data['message']}');
          }
        },
      );
    } catch (e) {
      debugPrint('[MESSAGES] Error in loadGroupMessages: $e');
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

// Helper method to load private messages
  Future<void> _loadPrivateMessages(String chatId) async {
    try {
      final chat = directChats.firstWhereOrNull((c) => c.id == chatId);
      if (chat == null || currentUserId == null) {
        setState(() => _isLoadingMessages = false);
        return;
      }

      // Find the other participant
      final otherParticipant = chat.participants?.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => Participant(id: '', name: 'Unknown', avatar: null),
      );

      if (otherParticipant == null || otherParticipant.id.isEmpty) {
        setState(() => _isLoadingMessages = false);
        _showSnackBar('Unable to load chat');
        return;
      }

      _socketService.loadOlderPrivateMessages(
        user1Id: currentUserId!,
        user2Id: otherParticipant.id,
        onResponse: (data) {
          if (mounted) {
            setState(() {
              _isLoadingMessages = false;
            });
          }

          if (data['status'] == 200) {
            final messagesList = data['messages'] as List;
            final transformedMessages =
                messagesList.map((msg) => Message.fromJson(msg)).toList();

            setState(() {
              messages[chatId] = transformedMessages;
              _hasMoreMessages[chatId] = data['hasMore'] ?? false;
            });

            _cleanupMessageKeys();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom(force: false);
            });
          } else {
            _showSnackBar('Failed to load messages: ${data['message']}');
          }
        },
      );
    } catch (e) {
      debugPrint('[MESSAGES] Error in loadPrivateMessages: $e');
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

// Method to mark messages as read and update last read position
  void _markMessagesAsRead(String chatId) {
    if (currentUserId == null) return;
    final chatMessages = messages[chatId] ?? [];
    if (chatMessages.isNotEmpty) {
      // Update last read message to the most recent one
      lastReadMessageId[chatId] = chatMessages.last.id;

      // Use your existing markChatAsRead method
      // _markMessagesAsRead(chatId);

      _socketService.markMessagesAsRead(
        chatId: chatId,
        userId: currentUserId!,
      );
    }
  }

  void _joinAllChatRooms() async {
    if (!_socketService.isConnected) {
      await _connectSocketFirst();
      if (!_socketService.isConnected) {
        return;
      }
    }

    final userId = currentUserId;
    if (userId == null) return;

    for (final chat in allChats) {
      if (chat.isGroup) {
        _socketService.joinGroupRoom(chat.id, userId, (success) {
          if (success) {
            print('Successfully joined group room: ${chat.id}');
          } else {
            print('Failed to join group room: ${chat.id}');
          }
        });
      } else {
        // For private chats, find the other participant's ID
        final otherParticipant = chat.participants?.firstWhere(
            (p) => p.id != userId,
            orElse: () => Participant(id: '', name: ''));
        if (otherParticipant != null && otherParticipant.id.isNotEmpty) {
          _socketService.joinPrivateRoom(userId, otherParticipant.id,
              (response) {
            if (response['success'] == true) {
              print('Successfully joined private room for chat: ${chat.id}');
            } else {
              print('Failed to join private room for chat: ${chat.id}');
            }
          });
        }
      }
    }
  }

  void _joinPrivateChat(String chatId) {
    debugPrint("=========== _joinPrivateChat called ");

    try {
      final chat = directChats.firstWhere((c) => c.id == chatId);

      // Safe participant access
      final otherParticipant = chat.participants?.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => Participant(id: '', name: 'Unknown', avatar: null),
      );

      if (otherParticipant != null &&
          otherParticipant.id.isNotEmpty &&
          currentUserId != null &&
          currentUserId!.isNotEmpty) {
        _socketService.joinPrivateRoom(
          currentUserId!,
          otherParticipant.id,
          (response) {
            debugPrint(
                'selectedChatId join private chat//  _socketService.joinPrivateRoom response: ${response.toString() ?? 'Unknown error'}');
            if (response['success'] == true) {
              setState(() {
                // joinedPrivateRooms.add(chatId);
              });
            } else {
              _showSnackBar('Failed to load chat history');
            }
          },
        );
      } else {
        _showSnackBar('Unable to find chat participant');
      }
    } catch (e) {
      debugPrint('Error joining private chat: $e');
      _showSnackBar('Error joining chat');
    }
  }

  Future<void> _safeInitializeUserData() async {
    try {
      LoginResponseModel? userData = await _userPreferences.getUser();

      // Safe user data access
      if (userData?.user.id != null &&
          userData?.token != null &&
          userData!.user.id.isNotEmpty &&
          userData.token.isNotEmpty) {
        setState(() {
          currentUserId = userData.user.id;
          currentUserName = userData.user.fullName ?? 'User';
          currentUserAvatar = userData.user.avatar.imageUrl;
        });
      } else {
        // Handle invalid user data
        debugPrint('Invalid user data - redirecting to login');
        // You might want to redirect to login here
      }
    } catch (e) {
      debugPrint('Error initializing user data: $e');
      // If user data is corrupted, clear and redirect to login
      await _userPreferences.removeUser();
      // Navigator.pushReplacementNamed(context, RouteName.loginView);
    }
  }

  void _joinGroup(String groupId, String userId, String chatId) {
    _socketService.joinGroupRoom(groupId, userId, (success) {
      if (success) {
        setState(() {
          joinedGroups.add(groupId);
        });
        _showSnackBar('Joined group successfully');
      } else {
        _showSnackBar('Failed to join group');
      }
    });
  }

  void _handleStartPrivateChat(String targetUserId) async {
    if (currentUserId == null) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      _showSnackBar('Unable to start chat: User not authenticated');
      return;
    }

    try {
      // Check existing chat first
      await _fetchPrivateChats();
      final existingChat = directChats.firstWhereOrNull(
        (chat) => chat.participants?.any((p) => p.id == targetUserId) == true,
      );

      debugPrint('Checking for existing chat with user: $targetUserId');
      debugPrint('Existing chat found: ${existingChat != null}');

      if (existingChat != null) {
        // ✅ EXISTING CHAT: Open it immediately
        debugPrint('Opening existing chat: ${existingChat.id}');
        if (mounted) {
          setState(() {
            selectedChatId = existingChat.id;
            showChatList = false;
            showGroupInfo = false;
            selectedSection = 'direct';
            loading = false;
          });
        }
        _selectChat(existingChat.id);
        return;
      }

      debugPrint('No existing chat found, creating new chat...');

      // ✅ NEW CHAT: Clear loading and show creating message
      if (mounted) {
        setState(() {
          loading = false;
          _isLoadingMessages = true; // Show loading in chat area
        });
      }

      _showSnackBar('Creating new chat...');

      // Call socket to create new chat
      _socketService.joinPrivateRoom(
        currentUserId!,
        targetUserId,
        (response) async {
          try {
            debugPrint(
                'selectedChatId After handle private chat //  _socketService.joinPrivateRoom response: ${response.toString() ?? 'Unknown error'}');
            debugPrint('Socket response: ${response.toString()}');

            if (response['success'] == true && response['chatId'] != null) {
              final newChatId = response['chatId'];
              debugPrint('New chat created with ID: $newChatId');

              // Refresh chats list to include the new chat
              await _fetchPrivateChats();

              if (mounted) {
                setState(() {
                  selectedChatId = newChatId;
                  pendingPrivateChatUserId = targetUserId;
                  isNewPrivateChat = true;
                  showChatList = false;
                  showGroupInfo = false;
                  selectedSection = 'direct';
                  _isLoadingMessages = false;
                });
              }

              // ✅ CRITICAL: Select the chat to load messages and open chat screen
              _selectChat(newChatId);
              _showSnackBar('Chat created successfully');
            } else {
              final errorMsg =
                  response['message'] ?? 'Unknown error creating chat';
              debugPrint('Chat creation failed: $errorMsg');
              throw Exception(errorMsg);
            }
          } catch (e) {
            debugPrint('Error in socket callback: $e');
            if (mounted) {
              setState(() {
                _isLoadingMessages = false;
              });
            }
            _showSnackBar('Failed to create chat: $e');
          }
        },
      );
    } catch (e) {
      debugPrint('Error in _handleStartPrivateChat: $e');
      if (mounted) {
        setState(() {
          loading = false;
          _isLoadingMessages = false;
        });
      }
      _showSnackBar('Unable to start chat: $e');
    }
  }

  Widget _buildSafeNetworkImage(String? imageUrl, String defaultAsset,
      {double? width, double? height, BoxFit? fit}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(
        defaultAsset,
        width: width,
        height: height,
        fit: fit,
      );
    }

    // Check if the URL might be problematic (Cloudinary with potential auth issues)
    if (imageUrl.contains('cloudinary.com') && imageUrl.contains('/upload/')) {
      // For Cloudinary URLs, we can try to handle them more gracefully
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Image.asset(
          defaultAsset,
          width: width,
          height: height,
          fit: fit,
        ),
        errorWidget: (context, url, error) {
          debugPrint('Image load error: $error for URL: $url');
          return Image.asset(
            defaultAsset,
            width: width,
            height: height,
            fit: fit,
          );
        },
        // Add headers if needed for authentication
        httpHeaders: {
          'Accept': 'image/*',
        },
      );
    } else {
      // For regular URLs
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Image.asset(
          defaultAsset,
          width: width,
          height: height,
          fit: fit,
        ),
        errorWidget: (context, url, error) => Image.asset(
          defaultAsset,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }
  }

// Helper method to find existing chat
  Future<void> _findAndSelectExistingChat(String user2Id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final existingChat = directChats.firstWhere(
        (chat) => chat.participants?.any((p) => p.id == user2Id) == true,
        orElse: () => Chat(
          id: '',
          name: '',
          avatar: '',
          lastMessage: '',
          timestamp: DateTime.now(),
          unread: 0,
          isGroup: false,
          participants: [],
        ),
      );

      if (existingChat.id.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          selectedChatId = existingChat.id;
          isNewPrivateChat = false;
          pendingPrivateChatUserId = null;
          showChatList = false;
          _isLoadingMessages = false;
        });
        _selectChat(existingChat.id);
      } else {
        throw Exception('Chat not found after creation');
      }
    } catch (e) {
      debugPrint('❌ _findAndSelectExistingChat error: $e');
      _showSnackBar('Could not find the chat. Please try again.');
      if (mounted) {
        setState(() {
          isNewPrivateChat = false;
          pendingPrivateChatUserId = null;
          _isLoadingMessages = false;
        });
      }
    }
  }

// Helper method to find chat by participant
  Future<void> _findAndSelectChatByParticipant(String user2Id) async {
    try {
      // Wait a bit more for chats to load
      await Future.delayed(Duration(milliseconds: 500));

      final existingChat = directChats.firstWhere(
        (chat) => chat.participants?.any((p) => p.id == user2Id) == true,
        orElse: () => Chat(
          id: '',
          name: '',
          avatar: '',
          lastMessage: '',
          timestamp: DateTime.now(),
          unread: 0,
          isGroup: false,
          participants: [],
        ),
      );

      if (existingChat.id.isNotEmpty) {
        setState(() {
          selectedChatId = existingChat.id;
          isNewPrivateChat = false;
          pendingPrivateChatUserId = null;
          showChatList = false;
          _isLoadingMessages = false;
        });
        _selectChat(existingChat.id);
      } else {
        throw Exception('Chat not found after creation');
      }
    } catch (e) {
      _showSnackBar('Could not find the new chat. Please try again.');
      setState(() {
        isNewPrivateChat = false;
        pendingPrivateChatUserId = null;
        _isLoadingMessages = false;
      });
    }
  }

  void _showMemberOptionsDialog(BuildContext context, GroupMember member) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: CacheImageLoader(
                    member.userId.avatar!.imageUrl,
                    ImageAssets.defaultProfileImg),
                child: member.userId.avatar?.imageUrl == null
                    ? Text(
                        member.userId.fullName.isNotEmpty
                            ? member.userId.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 16),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  member.userId.fullName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Member since: ${member.joinedAt != null ? DateFormat.yMMMd().format(DateTime.parse(member.joinedAt)) : member.joinedAt}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'What would you like to do?',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                startPrivateChatWithMember(member);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              // icon: const Icon(Icons.message),
              child: const Text('Message'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showReportDialog(context, member);
              },
              child: Text(
                'Report',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            if (isAdmin)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _makeUserAdmin(member);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
                child: const Text(
                  'Make Admin',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        );
      },
    );
  }

  void _makeUserAdmin(GroupMember member) {
    if (currentUserId == null) {
      _showErrorSnackBar('Unable to identify current user');
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Make Admin'),
          content: Text(
              'Are you sure you want to make ${member.userId.fullName} an admin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performMakeAdmin(member);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _performMakeAdmin(GroupMember member) {
    // Show loading
    _showLoadingSnackBar('Promoting user to admin...');

    _socketService.makeAdmin(
      groupId: selectedGroup!.id ?? '', // Use currentGroupId
      userId: member.userId.id,
      ownerId: currentUserId!,
      callback: (bool success, String? message) {
        ScaffoldMessenger.of(context).clearSnackBars();
        if (success) {
          _showSnackBar(message ?? 'User made admin successfully');
        } else {
          // _showErrorDialog(message ?? 'Failed to make user admin');
        }
      },
    );
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        duration: const Duration(minutes: 1), // Long duration for loading
      ),
    );
  }

  void startPrivateChatWithMember(GroupMember member) {
    // Don't allow messaging yourself
    if (member.userId.id == currentUserId) {
      _showSnackBar('You cannot send a message to yourself');
      return;
    } else {
      otherId = member.userId.id;
    }

    // Check if there's already an existing private chat with this user
    final existingChat = directChats.firstWhere(
      (chat) => chat.participants?.any((p) => p.id == member.userId.id) == true,
      orElse: () => null as Chat,
    );

    // If chat already exists, just open it
    setState(() {
      selectedChatId = existingChat.id;
      showChatList = false;
      showGroupInfo = false;
      selectedSection = 'direct'; // Switch to direct messages tab
    });
    _showSnackBar('Opening existing chat with ${member.userId.fullName}');
  }

//for
  void _showReportDialog(BuildContext context, GroupMember member) {
    _selectedReportReason = null;
    _reportDescription = '';
    _reportDescriptionController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Report User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Please provide details about the issue you\'re reporting.'),
                    const SizedBox(height: 16),

                    // Reported User (read-only)
                    const Text(
                      'Reported User',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: Text(
                        member.userId.fullName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reason dropdown
                    const Text(
                      'Reason',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReportReason,
                          hint: const Text('Select a reason'),
                          isExpanded: true,
                          items: [
                            'spam',
                            'abuse',
                            'misleading',
                            'inappropriate',
                            'other'
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedReportReason = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reportDescriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Please provide additional details about the report...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        _reportDescription = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _submitReport(context, member),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReport(BuildContext context, GroupMember member) async {
    try {
      // Validation
      if (_selectedReportReason == null || _selectedReportReason!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fill in all required fields"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get token from SharedPreferences
      final UserPreferencesViewmodel userPreferences =
          UserPreferencesViewmodel();
      LoginResponseModel? userData = await userPreferences.getUser();
      SharedPreferences.getInstance();
      final token = userData!.token;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Submitting report..."),
              ],
            ),
          );
        },
      );

      // Make API call
      final response = await http.post(
        Uri.parse('${ApiUrls.baseUrl}/connect/v1/api/report/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reportedUser': member.userId.id, // Assuming member has userId.id
          'reason': _selectedReportReason,
          'description': _reportDescription,
        }),
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        Navigator.of(context).pop(); // Close report dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Report submitted successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        _selectedReportReason = null;
        _reportDescription = '';
        _reportDescriptionController.clear();
      } else {
        // Error response
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to submit report');
      }
    } catch (error) {
      // Close loading dialog if it's still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      final errorMessage = error.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              errorMessage.isEmpty ? "Report submission failed" : errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildGroupInfo() {
    final group = selectedGroup!;
    final groupAdminName = group.members
        ?.firstWhere(
            (member) => group.admins?.contains(member.userId.id) ?? false)
        .userId
        .fullName;
    final description = group.description;
    final createdAtFormatted = DateFormat.yMMMd()
        .format(DateTime.parse(group.createdAt ?? group.updatedAt ?? ''));
    final totalMembers = group.members?.length ?? 0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(height: 20),
        // Header with back button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                onPressed: () => setState(() => showGroupInfo = false),
              ),
              const SizedBox(width: 8),
              Text(
                'Group Members',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 90),
              isAdmin
                  ? IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      onPressed: _showEditGroupDialog,
                    )
                  : Container(),
            ],
          ),
        ),
        // Group Info Section
        Padding(
          padding: const EdgeInsets.only(left: 22.0, top: 8.0, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.teal,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name ?? "",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description ?? 'no description',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontFamily: AppFonts.opensansRegular),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Created At: $createdAtFormatted',
                          style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppFonts.opensansRegular),
                        ),
                        Text(
                          'Group Admin: $groupAdminName',
                          style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppFonts.opensansRegular),
                        ),
                        Text(
                          'Total Members: $totalMembers',
                          style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppFonts.opensansRegular),
                        ),
                        const SizedBox(height: 8),
                        if (isAdmin)
                          Row(
                            children: [
                              const Icon(Icons.link, size: 18),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () async {
                                  if (inviteLink == null) {
                                    // Generate link first
                                    await _generateInviteLink();
                                  }

                                  if (inviteLink != null) {
                                    _showInviteLinkDialog();
                                  }
                                },
                                child: isGeneratingLink
                                    ? Row(
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Theme.of(context).primaryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Generating...',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        inviteLink == null
                                            ? 'Generate invite link'
                                            : 'Share invite link',
                                        style: TextStyle(
                                          color: AppColors.redColor,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        // Members list
        Expanded(
          child: ListView(
            children: groups
                .firstWhere((e) => e.id == selectedGroup!.id)
                .members!
                .map(
                  (member) => GestureDetector(
                    onTap: () => _showMemberOptionsDialog(context, member),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.grey[300]!, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: CacheImageLoader(
                              member.userId.avatar?.imageUrl,
                              ImageAssets.defaultProfileImg,
                            ),
                            child: member.userId.avatar?.imageUrl == null
                                ? Text(
                                    member.userId.fullName.isNotEmpty
                                        ? member.userId.fullName[0]
                                            .toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 16),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      member.userId.fullName,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (member.userId.id == currentUserId)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Me',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  'Joined: ${DateFormat.yMMMd().format(DateTime.parse(member.joinedAt.toString()))}',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  void _showEditGroupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EditGroupDialog(
          groupId: selectedGroup?.id ?? '',
          currentName: selectedGroup?.name ?? '',
          currentDescription: selectedGroup!.description,
          currentAvatarUrl: selectedGroup!.groupAvatar,
          onGroupUpdated: (updatedGroup) {
            // Update your local group data here
            setState(() {
              // Find and update the group in your groups list
              final index =
                  groups.indexWhere((g) => g.id == updatedGroup['_id']);
              if (index != -1) {
                // Update the group object with new data
                // You'll need to adapt this based on your Group model
                groups[index] = Group.fromJson(updatedGroup) as GroupData;
                // Or update individual fields:
                // groups[index].name = updatedGroup['name'];
                // groups[index].description = updatedGroup['description'];
                // groups[index].groupAvatar = updatedGroup['groupAvatar'];
              }
            });
          },
        );
      },
    );
  }

  // Modified _sendMessage method to ensure proper scrolling
// Enhanced _sendMessage method
  void _sendMessage() {
    if (selectedChatId == null ||
        _messageController.text.trim().isEmpty ||
        currentUserId == null) return;

    final chat = selectedChat;
    final isGroup = chat?.isGroup ?? false;
    String? receiverId;
    try {
      if (isGroup) {
        receiverId = null;
      } else {
        if (pendingPrivateChatUserId != null) {
          receiverId = pendingPrivateChatUserId;
          otherId = receiverId ?? '';
        } else {
          final otherParticipant = chat?.participants?.firstWhere(
            (p) => p.id != currentUserId,
            orElse: () =>
                Participant(id: 'unknown', name: 'Unknown', avatar: null),
          );
          receiverId = otherParticipant?.id;
          otherId = receiverId ?? '';
        }
      }
    } catch (ex) {}

    final messageContent = _messageController.text;
    String formattedContent = _applyFormatting(messageContent);
    final tempMessageId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

    // Store reply information BEFORE clearing state
    final replyToMessageId = replyingToMessage?.id;
    final isReplying = showReplyPreview && replyingToMessage != null;

    // Optimistic UI update
    final newMessage = Message(
      id: tempMessageId,
      content: formattedContent,
      timestamp: DateTime.now(),
      sender: Sender(
        id: currentUserId!,
        name: currentUserName ?? 'Me',
        avatar: currentUserAvatar,
      ),
      isRead: false,
      replyTo: isReplying
          ? ReplyTo(
              id: replyingToMessage!.id,
              content: replyingToMessage!.content,
              sender: replyingToMessage!.sender,
            )
          : null,
    );

    setState(() {
      messages[selectedChatId!] = [
        ...(messages[selectedChatId!] ?? []),
        newMessage
      ];
      _showScrollToBottom = false;
    });

    _messageController.clear();
    setState(() {
      _isBold = false;
      _isItalic = false;
      _isUnderline = false;
    });

    // ✅ CRITICAL FIX: Clear reply state IMMEDIATELY after UI update
    _cancelReply();

    // Always scroll to bottom when sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _socketService.sendMessage(
      senderId: currentUserId!,
      receiverId: isGroup ? null : receiverId,
      groupId: isGroup ? selectedChatId : null,
      content: formattedContent,
      replyToMessageId: isReplying ? replyToMessageId : null,
      // Use stored value
      callback: (response) {
        if (response['success'] == true && response['messageId'] != null) {
          setState(() {
            final chatMessages = messages[selectedChatId!] ?? [];
            final updatedMessages = chatMessages
                .map((msg) => msg.id == tempMessageId
                    ? Message(
                        id: response['messageId']!,
                        content: msg.content,
                        timestamp: msg.timestamp,
                        sender: msg.sender,
                        isRead: msg.isRead,
                        replyTo: msg.replyTo,
                        reactions: msg.reactions,
                      )
                    : msg)
                .toList();
            messages[selectedChatId!] = updatedMessages;
          });
        } else {
          setState(() {
            final chatMessages = messages[selectedChatId!] ?? [];
            messages[selectedChatId!] =
                chatMessages.where((msg) => msg.id != tempMessageId).toList();
          });
          _showSnackBar('Failed to send message');
        }
      },
    );
  }

  void _startReply(dynamic message) {
    setState(() {
      replyingToMessage =
          message is Message ? message : _convertToMessage(message);
      showReplyPreview = true;
    });
    // Focus on the text field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Message _convertToMessage(dynamic messageData) {
    if (messageData is Message) return messageData;

    // Convert from JSON/Map to Message object
    return Message(
      id: messageData['_id'] ?? messageData['id'],
      content: messageData['content'],
      timestamp: messageData['timestamp'] is DateTime
          ? messageData['timestamp']
          : DateTime.parse(messageData['createdAt'] ??
              messageData['updatedAt'] ??
              DateTime.now().toIso8601String()),
      sender: Sender(
        id: messageData['sender']['_id'] ?? messageData['sender']['id'],
        name:
            messageData['sender']['fullName'] ?? messageData['sender']['name'],
        avatar: messageData['sender']['avatar']?['imageUrl'],
      ),
      isRead: messageData['isRead'] ?? false,
      replyTo: messageData['replyTo'] != null
          ? ReplyTo(
              id: messageData['replyTo']['_id'] ?? messageData['replyTo']['id'],
              content: messageData['replyTo']['content'],
              sender: Sender(
                id: messageData['replyTo']['sender']['_id'] ??
                    messageData['replyTo']['sender']['id'],
                name: messageData['replyTo']['sender']['fullName'] ??
                    messageData['replyTo']['sender']['name'],
                avatar: messageData['replyTo']['sender']['avatar']?['imageUrl'],
              ),
            )
          : null,
    );
  }

// Add method to cancel reply
  void _cancelReply() {
    setState(() {
      replyingToMessage = null;
      showReplyPreview = false;
    });
    // Also clear any formatting states to ensure clean state
    setState(() {
      _isBold = false;
      _isItalic = false;
      _isUnderline = false;
    });
  }

  String _applyFormatting(String text) {
    String formattedText = text;

    if (_isBold) {
      formattedText = '*$formattedText*';
    }
    if (_isItalic) {
      formattedText = '_${formattedText}_';
    }
    if (_isUnderline) {
      formattedText = '~$formattedText~';
    }

    return formattedText;
  }

// Add this function to handle starting direct chat with a user from community search
  // FIXED: Add this function to handle starting direct chat with a user from community search
  void _startDirectChatWithUser(User user) {
    if (user.id.isEmpty) {
      _showSnackBar('Invalid user selected');
      return;
    }

    if (user.id == currentUserId) {
      _showSnackBar('You cannot send a message to yourself');
      return;
    }

    otherId = user.id;

    Chat? existingChat;
    try {
      final matchingChats = directChats.where(
        (chat) => chat.participants?.any((p) => p.id == user.id) == true,
      );

      existingChat = matchingChats.isNotEmpty ? matchingChats.first : null;
    } catch (_) {
      existingChat = null;
    }

    if (existingChat != null && existingChat.id.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        selectedChatId = existingChat?.id ?? '';
        showChatList = false;
        showGroupInfo = false;
        selectedSection = 'direct';
      });
      _showSnackBar('Opening existing chat with ${user.fullName ?? ''}');
    } else {
      if (!mounted) return;
      setState(() {
        showChatList = false;
        showGroupInfo = false;
        selectedSection = 'direct';
      });
      _showSnackBar('Starting new chat with ${user.fullName ?? ''}...');
      _handleStartPrivateChat(user.id ?? '');
    }
  }

  Future<void> _handleGroupCreation() async {
    // Validate group creation limit before proceeding
    bool canCreateGroup = await _validateGroupCreationLimit();

    if (!canCreateGroup) {
      return; // Stop group creation if limit is reached
    }

    // Proceed with group creation if within limit
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupManagementScreen(
          onJoinGroup: _showJoinGroupDialog,
        ),
      ),
    );
  }

// Helper function to wait for new chat to appear and select it
  void _waitForNewChatAndSelect(User user) {
    // This is a simple approach - you might want to implement a more sophisticated listener
    Future.delayed(Duration(milliseconds: 500), () {
      try {
        final newChat = directChats.firstWhere(
          (chat) => chat.participants?.any((p) => p.id == user.id) == true,
        );
        setState(() {
          selectedChatId = newChat.id;
        });
      } catch (e) {
        // Chat not yet available, you might want to retry or handle differently

        _waitForNewChatAndSelect(user);
      }
    });
  }

  void _scrollToBottom({bool force = true, bool isInitialLoad = false}) {
    if (_scrollController.hasClients) {
      if (isInitialLoad) {
        // For initial load, use multiple frame callbacks to ensure ListView is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            }
          });
        });
      } else {
        // For regular scrolling, jump immediately
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    }
    if (force) {
      _badgeManager.resetUnreadCount(selectedChatId!);
      setState(() {});
    }
  }

  void _scrollToFirstUnreadMessage() {
    if (!_scrollController.hasClients || selectedChatId == null) return;

    final currentMessages = messages[selectedChatId] ?? [];
    if (currentMessages.isEmpty) return;

    // Find the first unread message (you can customize this logic based on your needs)
    final currentUserId = this.currentUserId;

    if (currentUserId == null) return;

    // For simplicity, scroll to a position based on unread count
    final unreadCount = _badgeManager.unreadCounts[selectedChatId!] ?? 0;
    if (unreadCount > 0 && currentMessages.length >= unreadCount) {
      final targetIndex = currentMessages.length - unreadCount;
      final itemHeight = 80.0; // Approximate height per message
      final targetPosition = targetIndex * itemHeight;

      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
  // String _formatTime(dynamic timestamp) {
  //   try {
  //     DateTime dateTime;
  //
  //     // Handle different timestamp formats
  //     if (timestamp is String) {
  //       // Parse ISO 8601 string (like "2025-06-17T07:23:14.190Z")
  //       dateTime = DateTime.parse(timestamp);
  //     } else if (timestamp is DateTime) {
  //       dateTime = timestamp;
  //     } else if (timestamp is int) {
  //       // Handle milliseconds since epoch
  //       dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  //     } else {
  //       return 'Invalid time';
  //     }
  //
  //     // Convert to local time
  //     dateTime = dateTime.toLocal();
  //
  //     final now = DateTime.now();
  //     final today = DateTime(now.year, now.month, now.day);
  //     final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
  //
  //     // Format time part
  //     String hour = dateTime.hour.toString().padLeft(2, '0');
  //     String minute = dateTime.minute.toString().padLeft(2, '0');
  //     String timeString = '$hour:$minute';
  //
  //     // Check if message is from today
  //     if (messageDate == today) {
  //       return timeString;
  //     }
  //
  //     // Check if message is from yesterday
  //     final yesterday = today.subtract(const Duration(days: 1));
  //     if (messageDate == yesterday) {
  //       return 'Yesterday $timeString';
  //     }
  //
  //     // Check if message is from this week
  //     final weekAgo = today.subtract(const Duration(days: 7));
  //     if (messageDate.isAfter(weekAgo)) {
  //       return '${_getDayName(dateTime.weekday)} $timeString';
  //     }
  //
  //     // Check if message is from this year
  //     if (dateTime.year == now.year) {
  //       return '${dateTime.day} ${_getMonthName(dateTime.month)} $timeString';
  //     }
  //
  //     // Message is from previous year
  //     return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year} $timeString';
  //   } catch (e) {
  //     return 'Invalid time';
  //   }
  // }

  // String _getDayName(int weekday) {
  //   const days = [
  //     'Monday',
  //     'Tuesday',
  //     'Wednesday',
  //     'Thursday',
  //     'Friday',
  //     'Saturday',
  //     'Sunday'
  //   ];
  //   return days[weekday - 1];
  // }
  //
  // String _getMonthName(int month) {
  //   const months = [
  //     'Jan',
  //     'Feb',
  //     'Mar',
  //     'Apr',
  //     'May',
  //     'Jun',
  //     'Jul',
  //     'Aug',
  //     'Sep',
  //     'Oct',
  //     'Nov',
  //     'Dec'
  //   ];
  //   return months[month - 1];
  // }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.greyColor,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        cursorHeight: 20,
        cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
        controller: _searchController,
        onChanged: (value) {
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Search here..',
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontFamily: AppFonts.opensansRegular,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: SafeArea(
          // Add SafeArea here
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: SafeArea(
          // Add SafeArea here
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $error'),
                ElevatedButton(
                  onPressed: _initializeChat,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: selectedChatId == null
          ? AppBar(
              title: Text(
                'Chat',
                style: TextStyle(
                  fontFamily: AppFonts.opensansRegular,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              actions: [
                IconButton(
                  onPressed: () {
                    _showStarredMessagesPopup(context);
                  },
                  icon: Icon(
                    Icons.star,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  tooltip: 'Starred Message',
                ),
                IconButton(
                  onPressed: () => _handleGroupCreation(),
                  icon: Icon(
                    Icons.people,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  tooltip: 'Create Group',
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      showCommunityMembers = !showCommunityMembers;
                    });
                  },
                  icon: Icon(
                    Icons.search,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                )
              ],
            )
          : null,
      body: SafeArea(
        // Wrap the entire body with SafeArea
        child: Stack(children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Builder(builder: (context) {
              if (showGroupInfo && selectedGroup != null) {
                return _buildGroupInfo();
              }
              if (showCommunityMembers) {
                return CommunityMembersWidget(
                  onUserSelected: (User user) {
                    _startDirectChatWithUser(user);
                    setState(() {
                      showCommunityMembers = false;
                    });
                  },
                  onClose: () {
                    setState(() {
                      showCommunityMembers = false;
                    });
                  },
                );
              }

              return Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Row(
                  children: [
                    if (showChatList || MediaQuery.of(context).size.width > 600)
                      Container(
                        width: MediaQuery.of(context).size.width > 600
                            ? 350
                            : MediaQuery.of(context).size.width,
                        decoration: const BoxDecoration(
                          border: Border(
                              right:
                                  BorderSide(color: Colors.grey, width: 0.5)),
                        ),
                        child: Column(
                          children: [
                            _buildSearchBar(),
                            Expanded(child: _buildChatList()),
                          ],
                        ),
                      ),
                    if (selectedChatId != null &&
                        (!showChatList ||
                            MediaQuery.of(context).size.width > 600))
                      Expanded(child: _buildChatMessages()),
                  ],
                ),
              );
            }),
          ),
          if (_showForwardDialog) _buildForwardDialog(),
        ]),
      ),
    );
  }

  Widget _buildSectionTabs() {
    return Container(
      padding: const EdgeInsets.only(right: 15, left: 15, bottom: 5),
      child: Row(
        children: [
          _buildTab('All', 'all'),
          SizedBox(width: 4),
          _buildTab('Direct', 'direct'),
          SizedBox(width: 4),
          _buildTab('Circles', 'groups'),
        ],
      ),
    );
  }

  Widget _buildTab(String title, String section) {
    final isSelected = selectedSection == section;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedSection = section),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.textfieldColor
                : AppColors.loginContainerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontFamily: AppFonts.opensansRegular,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    List<Chat> filteredChats = allChats;

    // First filter by section (direct/groups)
    switch (selectedSection) {
      case 'direct':
        filteredChats = allChats.where((chat) => !chat.isGroup).toList();
        break;
      case 'groups':
        filteredChats = allChats.where((chat) => chat.isGroup).toList();
        break;
      default:
        break;
    }

    // Then filter by search query
    if (_searchController.text.isNotEmpty) {
      String searchQuery = _searchController.text.toLowerCase();
      filteredChats = filteredChats.where((chat) {
        return chat.name.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Show message when no results found
    if (filteredChats.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No chats found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshChatList,
      color: Colors.blueAccent,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredChats.length,
        itemBuilder: (context, index) {
          final chat = filteredChats[index];
          return _buildChatListItem(chat);
        },
      ),
    );
  }

  void _deleteChat(String chatId) {
    // Delete chat
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Chat'),
        content: Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // _socket?.emit('deleteChat', {'chatId': chatId});
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListItem(Chat chat) {
    try {
      // ✅ Get unread count from BadgeManager (single source of truth)
      final currentUnreadCount = _badgeManager.unreadCounts[chat.id] ?? 0;
      final displayName = _getSafeChatName(chat);

      return Container(
        constraints: BoxConstraints(maxHeight: 80),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
            child: ClipOval(
              child: _buildSafeNetworkImage(
                _getSafeAvatarUrl(chat.avatar),
                ImageAssets.defaultProfileImg,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(
            displayName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontFamily: AppFonts.opensansRegular,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Container(
            constraints: BoxConstraints(maxHeight: 40),
            child: _buildLastMessageSubtitle(chat),
          ),
          trailing: Container(
            constraints: BoxConstraints(maxWidth: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(chat.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (currentUnreadCount > 0) ...[
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      currentUnreadCount > 99 ? '99+' : '$currentUnreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          selected: selectedChatId == chat.id,
          onTap: () => _selectChat(chat.id),
        ),
      );
    } catch (e) {
      developer.log('Error building chat list item: $e');
      return _buildErrorChatListItem(chat);
    }
  }

  Widget _buildErrorChatListItem(Chat chat) {
    return ListTile(
      leading: CircleAvatar(child: Icon(Icons.error)),
      title: Text('Error loading chat'),
      subtitle: Text('Tap to retry'),
      onTap: () => _refreshChatList(),
    );
  }

  String _getSafeAvatarUrl(dynamic avatar) {
    try {
      if (avatar == null) return '';

      if (avatar is String) {
        if (avatar.isEmpty || avatar == 'null') return '';

        // Proper URL validation
        if (avatar.contains('cloudinary.com')) {
          if (avatar.startsWith('//')) {
            return 'https:$avatar';
          } else if (!avatar.startsWith('http')) {
            return 'https://$avatar';
          }
        }
        return avatar;
      }

      if (avatar is Map<String, dynamic>) {
        final imageUrl =
            avatar['imageUrl'] ?? avatar['url'] ?? avatar['avatar'];
        if (imageUrl is String && imageUrl.isNotEmpty) {
          return _getSafeAvatarUrl(imageUrl); // Recursively process
        }
      }

      return '';
    } catch (e) {
      debugPrint('Avatar URL error: $e');
      return '';
    }
  }

// Build subtitle showing last message with reaction/reply indicators
  Widget _buildLastMessageSubtitle(Chat chat) {
    try {
      final chatMessages = messages[chat.id];

      String messageText = '';
      String senderName = '';

      // Priority 1: Use messages from memory (most accurate)
      if (chatMessages?.isNotEmpty == true) {
        final lastMessage = chatMessages!.last;
        messageText = _getMessagePreview(lastMessage);

        // Get sender name for group chats
        if (chat.isGroup) {
          final senderId = lastMessage.sender.id;
          senderName = senderId == currentUserId
              ? 'Me'
              : (lastMessage.sender.name ?? 'Unknown');
        }
      } else if (chat.lastMessage != null) {
        messageText = _formatCachedLastMessage(chat);
      }

      // Build display text
      String displayText;
      if (chat.isGroup) {
        displayText = senderName.isNotEmpty && senderName != 'null'
            ? '$senderName: $messageText'
            : messageText.isEmpty
                ? ''
                : messageText;
      } else {
        // For direct chats, show message without sender name
        displayText = messageText.isEmpty ? '' : messageText;
      }

      return Text(
        displayText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
          fontFamily: AppFonts.opensansRegular,
          fontSize: 12,
        ),
      );
    } catch (e, st) {
      debugPrint('Error building last message subtitle: $e\n$st');
      return Text(
        'Message',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
          fontFamily: AppFonts.opensansRegular,
          fontSize: 12,
        ),
      );
    }
  }

// Add this new method to handle cached last messages
  String _formatCachedLastMessage(Chat chat) {
    try {
      final lastMessage = chat.lastMessage;

      if (lastMessage == null) return '';

      // If it's already a properly formatted string, return it
      if (lastMessage is String) {
        // Check if it's a file URL that needs formatting
        if (_isFileUrl(lastMessage) || _isStickerUrl(lastMessage)) {
          return _getMessagePreviewFromContent(lastMessage);
        }
        return lastMessage;
      }

      // If it's a Map, extract and format
      if (lastMessage is Map<String, dynamic>) {
        return _getMessagePreviewFromMap(lastMessage);
      }

      return 'Message';
    } catch (e) {
      debugPrint('Error formatting cached last message: $e');
      return 'Message';
    }
  }

// Add this helper method to format content directly
  String _getMessagePreviewFromContent(String content) {
    try {
      if (_isStickerUrl(content)) {
        return '🤡 Sticker';
      }

      if (_isFileUrl(content)) {
        final fileName = _extractFileNameFromUrl(content);
        if (fileName != null) {
          final fileExtension = fileName.split('.').last.toLowerCase();

          // Check file type
          if (fileExtension == 'jpg' ||
              fileExtension == 'jpeg' ||
              fileExtension == 'png' ||
              fileExtension == 'gif') {
            return '📷 Photo';
          } else if (fileExtension == 'mp4' ||
              fileExtension == 'mov' ||
              fileExtension == 'avi') {
            return '🎥 Video';
          } else if (fileExtension == 'mp3' ||
              fileExtension == 'wav' ||
              fileExtension == 'aac') {
            return '🎵 Audio';
          } else {
            return '📎 File';
          }
        }
        return '📎 File';
      }

      // Regular text message
      return content.length > 50 ? '${content.substring(0, 47)}...' : content;
    } catch (e) {
      debugPrint('Error getting message preview from content: $e');
      return 'Message';
    }
  }

// Enhanced message preview handler for Message objects with file names
  String _getMessagePreview(Message message) {
    try {
      final messageType = message.messageType?.toLowerCase() ?? 'text';
      final content = message.content ?? '';
      final fileInfo = message.fileInfo;

      switch (messageType) {
        case 'image':
          final fileName =
              _extractFileNameFromUrl(content) ?? fileInfo?.name ?? 'Photo';
          return '📷 ${_truncateFileName(fileName)}';

        case 'video':
          final fileName =
              _extractFileNameFromUrl(content) ?? fileInfo?.name ?? 'Video';
          return '🎥 ${_truncateFileName(fileName)}';

        case 'audio':
          final fileName =
              _extractFileNameFromUrl(content) ?? fileInfo?.name ?? 'Audio';
          return '🎵 ${_truncateFileName(fileName)}';

        case 'file':
          final fileName =
              fileInfo?.name ?? _extractFileNameFromUrl(content) ?? 'File';
          final fileExtension = fileName.split('.').last.toLowerCase();
          return _getFileTypePreview(fileName, fileExtension);

        case 'sticker':
          return '🤡 Sticker';

        case 'text':
        default:
          // Handle text with formatting markers
          final cleanText = _stripFormattingMarkers(content);
          return _truncateTextMessage(cleanText);
      }
    } catch (e) {
      debugPrint('Error getting message preview: $e');
      return 'Message';
    }
  }

// Helper to extract file name from fileInfo map or URL
  String? _extractFileNameFromMap(dynamic fileInfo, String content) {
    try {
      // First try to get from fileInfo
      if (fileInfo is Map<String, dynamic>) {
        final name = fileInfo['name']?.toString();
        if (name != null && name.isNotEmpty && name != 'null') {
          return name;
        }
      }

      // Then try to extract from URL
      if (content.isNotEmpty) {
        final fileName = _extractFileNameFromUrl(content);
        if (fileName != null && fileName.isNotEmpty && fileName != 'File') {
          return fileName;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting file name from map: $e');
      return null;
    }
  }

  String? _extractFileNameFromUrl(String url) {
    try {
      if (url.isEmpty) return null;

      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) return null;

      String fileName = pathSegments.last;

      // Remove query parameters if present
      final queryIndex = fileName.indexOf('?');
      if (queryIndex != -1) {
        fileName = fileName.substring(0, queryIndex);
      }

      // Remove any URL-encoded characters
      fileName = Uri.decodeComponent(fileName);

      // Validate it's a real file name (not just a random string)
      if (_isValidFileName(fileName)) {
        return fileName;
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting file name from URL: $e');
      return null;
    }
  }

// Validate if the extracted string is a proper file name
  bool _isValidFileName(String fileName) {
    if (fileName.isEmpty || fileName == 'null') return false;

    // Common invalid patterns in URLs
    final invalidPatterns = [
      'upload',
      'image',
      'video',
      'file',
      'media',
      'attachment',
      'download'
    ];

    // Check if it's just a common word without extension
    if (invalidPatterns
        .any((pattern) => fileName.toLowerCase().contains(pattern))) {
      // Only consider it valid if it has a proper file extension
      return _hasFileExtension(fileName);
    }

    return true;
  }

  bool _hasFileExtension(String fileName) {
    final extensions = [
      // Images
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'ico',
      // Videos
      'mp4', 'avi', 'mov', 'wmv', 'flv', '3gp', 'webm', 'mkv', 'm4v',
      // Audio
      'mp3', 'aac', 'wav', 'ogg', 'm4a', 'flac', 'wma',
      // Documents
      'pdf', 'doc', 'docx', 'txt', 'rtf', 'odt',
      // Spreadsheets
      'xls', 'xlsx', 'csv', 'ods',
      // Presentations
      'ppt', 'pptx', 'odp',
      // Archives
      'zip', 'rar', '7z', 'tar', 'gz'
    ];

    final fileExtension = fileName.split('.').last.toLowerCase();
    return extensions.contains(fileExtension) && fileName.contains('.');
  }

// Enhanced file type preview with better name handling
  String _getFileTypePreview(String fileName, String extension) {
    const fileTypeIcons = {
      // Documents
      'pdf': '📄',
      'doc': '📄',
      'docx': '📄',
      'txt': '📄',
      'rtf': '📄',
      'odt': '📄',

      // Spreadsheets
      'xls': '📊',
      'xlsx': '📊',
      'csv': '📊',
      'ods': '📊',

      // Presentations
      'ppt': '📊',
      'pptx': '📊',
      'odp': '📊',
    };

    // Use specific icon for known file types
    final icon = fileTypeIcons[extension] ?? '📎';

    // Return icon + truncated file name
    return '$icon ${_truncateFileName(fileName)}';
  }

  String _truncateFileName(String fileName) {
    if (fileName.length <= 20) return fileName;

    // For files with extensions, try to preserve the extension
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex != -1 && lastDotIndex > 0) {
      final name = fileName.substring(0, lastDotIndex);
      final extension = fileName.substring(lastDotIndex);

      if (name.length > 16) {
        return '${name.substring(0, 16)}..$extension';
      }
    }

    // For files without extensions or with very long names
    return '${fileName.substring(0, 18)}..';
  }

// Text message truncation
  String _truncateTextMessage(String text) {
    if (text.length <= 50) return text;
    return '${text.substring(0, 47)}...';
  }

// Helper to strip formatting markers from text
  String _stripFormattingMarkers(String text) {
    if (text.isEmpty) return text;

    // Remove simple formatting markers (*, _, ~)
    return text
        .replaceAll(RegExp(r'^\*|\*$'), '')
        .replaceAll(RegExp(r'^_|_$'), '')
        .replaceAll(RegExp(r'^~|~$'), '')
        .trim();
  }

// Helper to check if content is a file URL (keep existing implementation)
  bool _isFileUrl(String content) {
    try {
      if (content.isEmpty) return false;

      final uri = Uri.tryParse(content);
      if (uri == null) return false;

      final path = uri.path.toLowerCase();
      final fileExtensions = [
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.mp4',
        '.avi',
        '.mov',
        '.wmv',
        '.flv',
        '.3gp',
        '.webm',
        '.mp3',
        '.aac',
        '.wav',
        '.ogg',
        '.m4a',
        '.flac',
        '.pdf',
        '.doc',
        '.docx',
        '.txt',
        '.xls',
        '.xlsx',
      ];

      return fileExtensions.any((ext) => path.endsWith(ext));
    } catch (e) {
      return false;
    }
  }

  String _getMessagePreviewFromMap(Map<String, dynamic> messageData) {
    try {
      final messageType =
          (messageData['messageType'] ?? messageData['type'] ?? 'text')
              .toString()
              .toLowerCase();
      final content = messageData['content']?.toString() ??
          messageData['text']?.toString() ??
          '';
      final fileInfo = messageData['fileInfo'];

      // Handle file messages
      if (messageType == 'file' || _isFileUrl(content)) {
        if (fileInfo is Map<String, dynamic>) {
          final fileName = fileInfo['name']?.toString();
          if (fileName != null) {
            final fileExtension = fileName.split('.').last.toLowerCase();
            return _getFileTypePreview(fileName, fileExtension);
          }
        }

        // Fallback: extract from URL
        final fileName = _extractFileNameFromUrl(content);
        if (fileName != null) {
          final fileExtension = fileName.split('.').last.toLowerCase();
          return _getFileTypePreview(fileName, fileExtension);
        }

        return '📎 File';
      }

      switch (messageType) {
        case 'image':
          return '📷 Photo';
        case 'video':
          return '🎥 Video';
        case 'audio':
          return '🎵 Audio';
        case 'sticker':
          return '🤡 Sticker';
        case 'text':
        default:
          final cleanText = _stripFormattingMarkers(content);
          return cleanText.length > 50
              ? '${cleanText.substring(0, 47)}...'
              : cleanText;
      }
    } catch (e) {
      debugPrint('Error getting message preview from map: $e');
      return 'Message';
    }
  }

  String _getSafeChatName(Chat chat) {
    try {
      dynamic nameData = chat.name;

      // Case 1: Name is already a valid string
      if (nameData is String && nameData.isNotEmpty && nameData != 'null') {
        return nameData;
      }

      // Case 2: Name is a Map - extract from it
      if (nameData is Map<String, dynamic>) {
        dynamic name = nameData['name'];
        dynamic fullName = nameData['fullName'];
        dynamic username = nameData['username'];

        // Check each potential field with proper type checking
        if (name is String && name.isNotEmpty) return name;
        if (fullName is String && fullName.isNotEmpty) return fullName;
        if (username is String && username.isNotEmpty) return username;

        // Fallback: try to convert any value to string
        if (name != null) return name.toString();
        if (fullName != null) return fullName.toString();
        if (username != null) return username.toString();

        return 'Unknown Chat';
      }

      // Case 3: For direct chats, get name from participants
      if (!chat.isGroup &&
          chat.participants != null &&
          chat.participants!.isNotEmpty) {
        try {
          final otherParticipant = chat.participants!.firstWhere(
            (p) => p.id != currentUserId,
            orElse: () =>
                Participant(id: '', name: 'Unknown User', avatar: null),
          );

          // Safely extract participant name
          dynamic participantName = otherParticipant.name;
          if (participantName is String && participantName.isNotEmpty) {
            return participantName;
          } else if (participantName is Map<String, dynamic>) {
            dynamic name = participantName['name'];
            dynamic fullName = participantName['fullName'];
            if (name is String) return name;
            if (fullName is String) return fullName;
            if (name != null) return name.toString();
            if (fullName != null) return fullName.toString();
          }
        } catch (e) {
          // If finding participant fails, continue to fallback
        }
      }

      // Final fallback
      return 'Unknown Chat';
    } catch (e) {
      return 'Unknown Chat';
    }
  }

  void _replyToMessage(Message message) {
    // Implement repl
    //y functionality
  }

  void _showEmojiPicker(String messageId) {
    // Implement emoji picker dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Emoji'),
        content: Wrap(
          children: ['😀', '😂', '❤️', '👍', '👎', '😮', '😢', '😡', '🎉', '🔥']
              .map((emoji) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // _handleMessageReaction(messageId, emoji);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(emoji, style: TextStyle(fontSize: 24)),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 1. Edit-preview
          if (_isEditingMode && _editingMessage != null) _buildEditPreview(),

          // 3. Reply-preview
          if (!_isEditingMode && showReplyPreview && replyingToMessage != null)
            _buildReplyPreview(),

          // 4. Uploading indicator
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  const Text('Uploading file…', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: _uploadProgress),
                ],
              ),
            ),

          // 5. Formatting toolbar
          // _buildFormattingToolbar(),

          const SizedBox(height: 4),

          // 6. Input row
          _buildInputRow(),
        ],
      ),
    );
  }

  Widget _buildEditPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _editingMessage!.content,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.blue.shade700),
            onPressed: _cancelEditing,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.reply, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${replyingToMessage!.sender.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                // const SizedBox(height: 2),
                // Text(
                //   replyingToMessage!.content,
                //   style: const TextStyle(fontSize: 12, color: Colors.grey),
                //   maxLines: 2,
                //   overflow: TextOverflow.ellipsis,
                // ),

                _buildReplyPreviews(replyingToMessage!)
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelReply,
            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreviews(Message msg) {
    final url = msg.content.toLowerCase();

    // Detect file types
    final isImage = url.endsWith(".png") ||
        url.endsWith(".jpg") ||
        url.endsWith(".jpeg") ||
        url.endsWith(".gif");
    final isVideo =
        url.endsWith(".mp4") || url.endsWith(".mov") || url.endsWith(".mkv");
    final isAudio =
        url.endsWith(".mp3") || url.endsWith(".aac") || url.endsWith(".wav");

    switch (msg.messageType) {
      case "text":
        return Text(
          msg.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        );

      case "image":
      case "sticker":
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            msg.content,
            height: 40,
            width: 40,
            fit: BoxFit.cover,
          ),
        );

      case "file":
        if (isImage) {
          // file but image
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              msg.content,
              height: 40,
              width: 40,
              fit: BoxFit.cover,
            ),
          );
        } else if (isVideo) {
          // file but video
          return Row(
            children: const [
              Icon(Icons.videocam, size: 18, color: Colors.grey),
              SizedBox(width: 5),
              Text("Video", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          );
        } else if (isAudio) {
          // file but audio
          return Row(
            children: const [
              Icon(Icons.audiotrack, size: 18, color: Colors.grey),
              SizedBox(width: 5),
              Text("Audio", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          );
        } else {
          // unknown file
          return Row(
            children: const [
              Icon(Icons.insert_drive_file, size: 18, color: Colors.grey),
              SizedBox(width: 5),
              Text("File", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          );
        }

      case "audio":
        return Row(
          children: const [
            Icon(Icons.audiotrack, size: 18, color: Colors.grey),
            SizedBox(width: 5),
            Text("Audio", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        );

      case "video":
        return Row(
          children: const [
            Icon(Icons.videocam, size: 18, color: Colors.grey),
            SizedBox(width: 5),
            Text("Video", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        );

      default:
        return Text(
          msg.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        );
    }
  }

// Enhanced null-safe helper method to build reply preview for different message types
  Widget _buildReplyPreviewContent(ReplyTo? replyTo, String? msgtypes) {
    try {
      if (replyTo == null) {
        return _buildFallbackReplyPreview('Reply to message');
      }

      final messageType = msgtypes ?? 'text';
      final content = replyTo.content ?? '';
      final senderName = replyTo.sender?.name ?? 'Unknown User';

      Widget previewWidget;

      switch (messageType) {
        case 'image':
          previewWidget = Row(
            children: [
              Icon(Icons.photo, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$senderName: Photo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
          break;

        case 'video':
          previewWidget = Row(
            children: [
              Icon(Icons.videocam, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$senderName: Video',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
          break;

        case 'audio':
          previewWidget = Row(
            children: [
              Icon(Icons.audiotrack, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$senderName: Audio',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
          break;

        case 'file':
          previewWidget = Row(
            children: [
              Icon(Icons.insert_drive_file, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$senderName: ${_getFileNameFromUrl(content) ?? 'File'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
          break;

        case 'sticker':
          previewWidget = Row(
            children: [
              Icon(Icons.emoji_emotions, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$senderName: Sticker',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
          break;

        default: // text message
          previewWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                senderName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content.isNotEmpty ? content : 'Message',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
          break;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: previewWidget,
      );
    } catch (e) {
      debugPrint('Error building reply preview: $e');
      return _buildFallbackReplyPreview('Reply to message');
    }
  }

// Fallback widget for reply preview
  Widget _buildFallbackReplyPreview(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

// Null-safe helper method to extract filename from URL
  String? _getFileNameFromUrl(String? url) {
    try {
      if (url == null || url.isEmpty) return 'File';

      final uri = Uri.tryParse(url);
      if (uri == null) return 'File';

      final pathSegments = uri.pathSegments;
      return pathSegments.isNotEmpty ? pathSegments.last : 'File';
    } catch (e) {
      debugPrint('Error extracting filename from URL: $e');
      return 'File';
    }
  }

// Enhanced null-safe message bubble builder
  final RxMap<String, bool> _isTranslated = <String, bool>{}.obs;
  final RxMap<String, String> _translatedTexts = <String, String>{}.obs;
  final RxMap<String, bool> _isTranslating = <String, bool>{}.obs;

  Widget _buildMessageBubble(Message? message, bool isMe) {
    try {
      if (message == null) {
        return _buildErrorMessageBubble('Message not available', isMe);
      }

      final bool isStickerUrl = _isStickerUrl(message.content ?? '');
      final bool isFileUrl = _isFileUrl(message.content ?? '');
      final bool hasFileInfo = message.fileInfo != null;
      final messageId = message.id.toString();

      // Check for sticker messages FIRST - before file check
      if (message.messageType == 'sticker' || isStickerUrl) {
        return _buildStickerMessageBubble(message, isMe);
      }
      // Then check for file messages
      else if (message.messageType == 'file' || hasFileInfo || isFileUrl) {
        return Column(
          children: [
            if (isGroup && !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.transparent,
                      radius: 16,
                      backgroundImage: CacheImageLoader(
                        message.originalSender?.avatar ??
                            message.sender.avatar ??
                            '',
                        ImageAssets.defaultProfileImg,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getSafeSenderName(message, isMe),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            _buildFileMessageBubble(message, isMe),
          ],
        );
      } else {
        return Obx(() {
          final isTranslated = (_isTranslated[messageId] ?? false) &&
              _translatedTexts[messageId]?.isNotEmpty == true;
          final isTranslating = _isTranslating[messageId] ?? false;
          final displayContent = isTranslated
              ? _translatedTexts[messageId] ?? ''
              : message.content ?? '';

          return Column(
            children: [
              if (isGroup && !isMe) const SizedBox(height: 10),
              if (isGroup && !isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 16,
                        backgroundImage: CacheImageLoader(
                          message.originalSender?.avatar ??
                              message.sender.avatar ??
                              '',
                          ImageAssets.defaultProfileImg,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        message.originalSender?.name ??
                            message.sender.name ??
                            'User',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Translation button for received messages
                      if (!isMe) _buildTranslationButton(message, isMe),

                      Flexible(
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.white
                                    : const Color(0xFF1565d8),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Reply indicator - UPDATED
                                  if (message.replyTo != null) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 8),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.grey[100]
                                            : Colors.white.withOpacity(0.1),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                        border: Border(
                                          left: BorderSide(
                                            color: isMe
                                                ? Colors.blue
                                                : Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.replyTo!.sender?.name ??
                                                'Unknown',
                                            style: TextStyle(
                                              fontFamily:
                                                  AppFonts.opensansRegular,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isMe
                                                  ? Colors.blue[700]
                                                  : Colors.white
                                                      .withOpacity(0.9),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          _buildReplyContentPreview(
                                              message.replyTo!),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Main message content container
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        16,
                                        message.replyTo != null ? 8 : 12,
                                        16,
                                        8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Forwarded indicator
                                        if (message.isForwarded == true) ...[
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.forward,
                                                size: 14,
                                                color: isMe
                                                    ? Colors.grey[600]
                                                    : Colors.white
                                                        .withOpacity(0.8),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Forwarded',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isMe
                                                      ? Colors.grey[600]
                                                      : Colors.white
                                                          .withOpacity(0.8),
                                                  fontStyle: FontStyle.italic,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                        ],

                                        // Original sender info for forwarded messages
                                        if (message.isForwarded == true &&
                                            message.originalSender != null) ...[
                                          Text(
                                            'From: ${message.originalSender!.name ?? 'Unknown'}',
                                            style: TextStyle(
                                              fontFamily:
                                                  AppFonts.opensansRegular,
                                              fontSize: 11,
                                              color: isMe
                                                  ? Colors.grey[600]
                                                  : Colors.white
                                                      .withOpacity(0.7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            height: 1,
                                            color: isMe
                                                ? Colors.grey[300]
                                                : Colors.white.withOpacity(0.2),
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                          ),
                                        ],

                                        // Message content with clickable links
                                        _buildMessageContent(
                                          displayContent,
                                          textColor: isMe
                                              ? Colors.black87
                                              : Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Timestamp and status row with translation indicator
                                  Padding(
                                    padding: isMe
                                        ? const EdgeInsets.fromLTRB(
                                            16, 0, 4, 12)
                                        : const EdgeInsets.fromLTRB(
                                            12, 0, 16, 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Translation indicator
                                        if (isTranslated) ...[
                                          Icon(
                                            Icons.translate,
                                            size: 12,
                                            color: isMe
                                                ? Colors.grey[500]
                                                : Colors.white.withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          _formatTime(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isMe
                                                ? Colors.grey[500]
                                                : Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          _buildMessageStatus(
                                              message.status, isMe),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Message reactions
                            if (message.reactions != null &&
                                message.reactions!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _buildReactionRow(message.reactions!),
                            ],
                          ],
                        ),
                      ),

                      // Translation button for sent messages
                      if (isMe) _buildTranslationButton(message, isMe),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
      }
    } catch (e) {
      debugPrint('Error building message bubble: $e');
      return _buildErrorMessageBubble('Error displaying message', isMe);
    }
  }

  Widget _buildReplyContentPreview(ReplyTo replyTo) {
    // Extract content and type from replyTo
    final content = replyTo.content ?? '';
    final senderName = replyTo.sender?.name ?? 'Unknown';

    // Simple detection based on content patterns
    if (content.contains('/sticker/') || content.contains('sticker')) {
      return Row(
        children: [
          Icon(Icons.emoji_emotions, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text('Sticker', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      );
    } else if (content.contains('/image/') ||
        content.contains('.jpg') ||
        content.contains('.png') ||
        content.contains('.jpeg')) {
      return Row(
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: Image.network(
              content,
              fit: BoxFit.fill,
            ),
          ),
          // Icon(Icons.image, size: 14, color: Colors.grey),
          // SizedBox(width: 4),
          // Text('Photo', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      );
    } else if (content.contains('/video/') ||
        content.contains('.mp4') ||
        content.contains('.mov')) {
      return Row(
        children: [
          Icon(Icons.videocam, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text('Video', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      );
    } else if (content.contains('/audio/') ||
        content.contains('.mp3') ||
        content.contains('.wav')) {
      return Row(
        children: [
          Icon(Icons.audiotrack, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text('Audio', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      );
    } else if (content.contains('/pdf/') ||
        content.contains('.pdf') ||
        content.contains('.doc') ||
        content.contains('.zip')) {
      return Row(
        children: [
          Icon(Icons.picture_as_pdf, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text('Pdf File', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      );
    } else {
      // For text messages, show the actual content
      return Text(
        content,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

// Error message bubble fallback
  Widget _buildErrorMessageBubble(String error, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            error,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ),
      ),
    );
  }

// Enhanced null-safe file message bubble
  Widget _buildFileMessageBubble(Message message, bool isMe) {
    try {
      FileInfo? fileInfo = message.fileInfo;
      String fileUrl = message.content ?? '';
      String fileName = 'Unknown File';
      String fileType = 'application/octet-stream';
      String fileSize = '0 B';

      if (fileInfo != null) {
        fileName = fileInfo.name ?? 'Unknown File';
        fileType = fileInfo.type ?? 'application/octet-stream';
        fileSize = _formatFileSize(fileInfo.size ?? 0);
      } else {
        try {
          final uri = Uri.tryParse(fileUrl);
          if (uri != null) {
            fileName = uri.pathSegments.isNotEmpty
                ? uri.pathSegments.last
                : 'Unknown File';
            fileType = FileUtils.getFileType(fileName);
          }
        } catch (e) {
          debugPrint('Error parsing file URL: $e');
        }
      }

      final isImage = fileType.startsWith('image/');
      final isVideo = fileType.startsWith('video/');
      final isAudio = fileType.startsWith('audio/');

      // Colors and border radius for sent and received
      final bgColor = isMe ? Colors.white : const Color(0xFF1565d8);
      final textColor = isMe ? Colors.black87 : Colors.white;
      final borderRadius = BorderRadius.only(
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
        bottomLeft: Radius.circular(isMe ? 12 : 0),
        bottomRight: Radius.circular(isMe ? 0 : 12),
      );

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reply preview for file messages
                if (message.replyTo != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: _buildReplyPreviewContent(
                        message.replyTo, message.messageType),
                  ),
                ],

                Row(
                  children: [
                    if (isImage)
                      _buildImagePreview(fileUrl, fileName, isMe)
                    else if (isVideo)
                      _buildVideoPreview(fileUrl, fileName, isMe)
                    else if (isAudio)
                      _buildAudioPreview(fileUrl, fileName, isMe)
                    else
                      _buildDocumentPreview(fileUrl, fileName, fileInfo, isMe),
                    const SizedBox(width: 4),
                    if (isImage) _buildFileInfoColumn(fileName, fileSize, isMe),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildMessageStatus(message.status ?? 'sent', isMe),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building file message bubble: $e');
      return _buildErrorMessageBubble('Error displaying file', isMe);
    }
  }

// Null-safe image preview builder
  Widget _buildImagePreview(String fileUrl, String fileName, bool isMe) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () {
          try {
            FileUtils.showImageFullScreen(
                context, fileUrl, fileName, localFileManager);
          } catch (e) {
            debugPrint('Error opening image: $e');
            _showSnackBar('Cannot open image');
          }
        },
        child: Image.network(
          fileUrl,
          height: 70,
          width: 70,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 70,
              width: 70,
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 70,
              width: 70,
              color: Colors.grey[300],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red),
                  Text('Failed to load', style: TextStyle(fontSize: 10)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

// Null-safe video preview builder
  Widget _buildVideoPreview(String fileUrl, String fileName, bool isMe) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () {
          try {
            FileUtils.showVideoFullScreen(
                context, fileUrl, fileName, localFileManager);
          } catch (e) {
            debugPrint('Error opening video: $e');
            _showSnackBar('Cannot open video');
          }
        },
        child: Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: isMe ? Colors.grey[100] : Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.video_library,
                size: 64,
                color: isMe ? Colors.black54 : Colors.white70,
              ),
              Container(
                decoration: BoxDecoration(
                  color: isMe ? Colors.black26 : Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.play_arrow,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Null-safe audio preview builder
  Widget _buildAudioPreview(String fileUrl, String fileName, bool isMe) {
    return GestureDetector(
      onTap: () {
        try {
          FileUtils.showAudioPlayer(
              context, fileUrl, fileName, localFileManager);
        } catch (e) {
          debugPrint('Error opening audio: $e');
          _showSnackBar('Cannot open audio');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? Colors.grey[100] : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: isMe ? Colors.grey[300]! : Colors.grey[700]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.blue[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Audio',
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.grey[600] : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Null-safe document preview builder
  Widget _buildDocumentPreview(
      String fileUrl, String fileName, FileInfo? fileInfo, bool isMe) {
    return GestureDetector(
      onTap: () {
        try {
          FileUtils.openFile(context, fileUrl, fileName, localFileManager);
        } catch (e) {
          debugPrint('Error opening file: $e');
          _showSnackBar('Cannot open file');
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(fileInfo?.type ?? 'application/octet-stream'),
            color: isMe ? Colors.blue : Colors.blue[300],
            size: 32,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (fileInfo?.size != null)
                  Text(
                    _formatFileSize(fileInfo!.size),
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.grey[600] : Colors.white70,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Null-safe file info column builder
  Widget _buildFileInfoColumn(String fileName, String fileSize, bool isMe) {
    return Center(
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              fileName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            fileSize,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

// Enhanced null-safe sticker message bubble
  Widget _buildStickerMessageBubble(Message message, bool isMe) {
    try {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Reply preview for sticker messages
                    if (message.replyTo != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: _buildReplyPreviewContent(
                            message.replyTo, message.messageType),
                      ),
                    ],

                    // Sticker container
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                        maxHeight: 200,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          message.content ?? '',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load sticker',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 100,
                              height: 100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ??
                                              1)
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Timestamp and reactions
                    const SizedBox(height: 4),
                    if (message.reactions != null &&
                        message.reactions!.isNotEmpty)
                      _buildReactionRow(message.reactions!),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: isMe ? Colors.grey[600] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isMe)
                          _buildMessageStatus(message.status ?? 'sent', isMe),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building sticker message bubble: $e');
      return _buildErrorMessageBubble('Error displaying sticker', isMe);
    }
  }

// Enhanced null-safe message status builder
  Widget _buildMessageStatus(String? status, bool isMyMessage) {
    try {
      if (!isMyMessage) return const SizedBox.shrink();

      final statusValue = status?.toLowerCase() ?? 'sent';

      switch (statusValue) {
        case 'sent':
          return Icon(
            Icons.check,
            size: 16,
            color: Colors.grey[500],
          );
        case 'delivered':
          return Icon(
            Icons.done_all,
            size: 16,
            color: Colors.grey[500],
          );
        case 'read':
          return Icon(
            Icons.done_all,
            size: 16,
            color: Colors.blue[600],
          );
        default:
          return Icon(
            Icons.schedule,
            size: 16,
            color: Colors.grey[400],
          );
      }
    } catch (e) {
      debugPrint('Error building message status: $e');
      return const SizedBox.shrink();
    }
  }

// Enhanced null-safe reaction row builder
  Widget _buildReactionRow(List<Reaction> reactions) {
    try {
      if (reactions.isEmpty) return const SizedBox.shrink();

      // Group reactions by emoji
      Map<String, List<Reaction>> groupedReactions = {};
      for (var reaction in reactions) {
        final emoji = reaction.emoji;
        if (groupedReactions.containsKey(emoji)) {
          groupedReactions[emoji]!.add(reaction);
        } else {
          groupedReactions[emoji] = [reaction];
        }
      }

      return Container(
        margin: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 4,
          children: groupedReactions.entries.map((entry) {
            String emoji = entry.key;
            List<Reaction> emojiReactions = entry.value;
            bool hasCurrentUserReacted =
                emojiReactions.any((r) => r.user.id == currentUserId);

            return GestureDetector(
              onTap: () {
                try {
                  _showReactionDetails(emoji, emojiReactions);
                } catch (e) {
                  debugPrint('Error showing reaction details: $e');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasCurrentUserReacted
                      ? Colors.blue[100]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: hasCurrentUserReacted
                      ? Border.all(color: Colors.blue, width: 1)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 2),
                    Text(
                      emojiReactions.length.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: hasCurrentUserReacted
                            ? Colors.blue[700]
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    } catch (e) {
      debugPrint('Error building reaction row: $e');
      return const SizedBox.shrink();
    }
  }

// Enhanced null-safe sender name getter
  String _getSafeSenderName(Message message, bool isMe) {
    try {
      if (isMe) return 'Me';

      final originalSenderName = message.originalSender?.name;
      final senderName = message.sender.name;

      return originalSenderName ?? senderName ?? 'Unknown User';
    } catch (e) {
      debugPrint('Error getting sender name: $e');
      return 'Unknown User';
    }
  }

// Enhanced null-safe time formatter
  String _formatTime(dynamic timestamp) {
    try {
      DateTime dateTime;

      // Handle different timestamp formats
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return 'Invalid time';
      }

      // Convert to local time
      dateTime = dateTime.toLocal();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      // Format time part
      String hour = dateTime.hour.toString().padLeft(2, '0');
      String minute = dateTime.minute.toString().padLeft(2, '0');
      String timeString = '$hour:$minute';

      // Check if message is from today
      if (messageDate == today) {
        return timeString;
      }

      // Check if message is from yesterday
      final yesterday = today.subtract(const Duration(days: 1));
      if (messageDate == yesterday) {
        return 'Yesterday $timeString';
      }

      // Check if message is from this week
      final weekAgo = today.subtract(const Duration(days: 7));
      if (messageDate.isAfter(weekAgo)) {
        return '${_getDayName(dateTime.weekday)} $timeString';
      }

      // Check if message is from this year
      if (dateTime.year == now.year) {
        return '${dateTime.day} ${_getMonthName(dateTime.month)} $timeString';
      }

      // Message is from previous year
      return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year} $timeString';
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return 'Invalid time';
    }
  }

// Safe day name getter
  String _getDayName(int weekday) {
    try {
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      return days[weekday - 1];
    } catch (e) {
      return 'Day';
    }
  }

// Safe month name getter
  String _getMonthName(int month) {
    try {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return months[month - 1];
    } catch (e) {
      return 'Month';
    }
  }

// Enhanced null-safe file size formatter
  String _formatFileSize(int bytes) {
    try {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024)
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      debugPrint('Error formatting file size: $e');
      return 'Unknown size';
    }
  }

// Enhanced null-safe file icon getter
  IconData _getFileIcon(String fileType) {
    try {
      if (fileType.startsWith('image/')) {
        return Icons.image;
      } else if (fileType.startsWith('video/')) {
        return Icons.videocam;
      } else if (fileType.contains('pdf')) {
        return Icons.picture_as_pdf;
      } else if (fileType.contains('word') || fileType.contains('doc')) {
        return Icons.description;
      } else if (fileType.contains('excel') || fileType.contains('sheet')) {
        return Icons.table_chart;
      } else if (fileType.contains('text')) {
        return Icons.text_snippet;
      } else {
        return Icons.insert_drive_file;
      }
    } catch (e) {
      debugPrint('Error getting file icon: $e');
      return Icons.insert_drive_file;
    }
  }

  Widget _buildInputRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.greyColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: Colors.blue,
            onPressed: _isUploading ? null : _handleFileUpload,
          ),
          IconButton(
            icon: const Icon(Icons.image),
            color: Colors.blue,
            tooltip: 'Select Sticker',
            onPressed: _showStickerSelector,
          ),
          Expanded(
            child: TextField(
              controller:
                  _isEditingMode ? _editMessageController : _messageController,
              decoration: InputDecoration(
                hintText: _isEditingMode
                    ? 'Edit message…'
                    : (showReplyPreview ? 'Reply…' : 'Type a message…'),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              maxLines: null,
              onSubmitted: (_) {
                if (_isEditingMode) {
                  _saveEditedMessage();
                } else {
                  _sendMessage();
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(_isEditingMode ? Icons.check : Icons.send),
            onPressed: _isEditingMode ? _saveEditedMessage : _sendMessage,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  // Show message options (reply, copy, etc.)
  Widget _buildFormattingToolbar() {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Text(
            'Format: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),

          // Bold button
          _buildFormatButton(
            icon: Icons.format_bold,
            isActive: _isBold,
            onPressed: () => setState(() => _isBold = !_isBold),
            tooltip: 'Bold',
          ),

          // Italic button
          _buildFormatButton(
            icon: Icons.format_italic,
            isActive: _isItalic,
            onPressed: () => setState(() => _isItalic = !_isItalic),
            tooltip: 'Italic',
          ),

          // Underline button
          _buildFormatButton(
            icon: Icons.format_underline,
            isActive: _isUnderline,
            onPressed: () => setState(() => _isUnderline = !_isUnderline),
            tooltip: 'Underline',
          ),

          const SizedBox(width: 16),

          // Clear formatting button
          InkWell(
            onTap: () {
              setState(() {
                _isBold = false;
                _isItalic = false;
                _isUnderline = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Clear',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue[100] : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? Colors.blue : Colors.grey[300]!,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? Colors.blue : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10, // Number of shimmer items to show
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left avatar placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Message content placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 60,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Enhanced _buildChatMessages method with the new button
  Widget _buildChatMessages() {
    final chatMessages = messages[selectedChatId] ?? [];
    final chat = selectedChat;
    final isLoading = _isLoadingMessages;
    final pinnedMessagesForChat = currentChatPinnedMessages;

    // Filter messages based on search query
    final displayMessages = _isChatSearching && _chatSearchQuery.isNotEmpty
        ? _chatFilteredMessages
        : chatMessages;

    if (selectedChatId != null &&
        lastReadMessageId[selectedChatId!] == null &&
        displayMessages.length > 1) {
      final testLastReadId =
          _getMessageId(displayMessages[displayMessages.length - 2]);

      lastReadMessageId[selectedChatId!] = testLastReadId;
    }

    isGroup = chat?.isGroup ?? false;

    return Stack(
      // Change Column to Stack to allow Positioned widgets
      children: [
        Column(
          children: [
            // Chat Header
            Container(
              padding:
                  const EdgeInsets.only(top: 2, bottom: 2, left: 8, right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                    bottom: BorderSide(
                        color: AppColors.textfieldColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  if (MediaQuery.of(context).size.width <= 600)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      onPressed: () {
                        // Mark current chat as read before going back
                        setState(() {
                          showChatList = true;
                          selectedChatId = null;
                        });
                        // if (selectedChatId != null && currentUserId != null) {
                        //   _markMessagesAsRead(selectedChatId!);
                        // }
                      },
                    ),
                  InkWell(
                    onTap: () {
                      debugPrint("selected chat user id :- $currentUserId");

                      final chatProfile = ChatProfile(
                          userId: otherId ?? '',
                          name: chat?.name ?? '',
                          profileImageUrl:
                              chat?.avatar ?? ImageAssets.defaultProfileImg,
                          username: chat?.name ?? '');

                      Get.toNamed(RouteName.chatProfileScreen,
                          arguments: chatProfile);
                    },
                    child: chat != null?
                     CircleAvatar(
                      backgroundImage: CacheImageLoader(
                        chat.avatar,
                        ImageAssets.defaultProfileImg,
                      ),
                      child: chat.avatar == null
                          ? Text(chat.name.isNotEmpty == true
                              ? chat.name[0].toUpperCase()
                              : '?')
                          : null,
                    ) : Container(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isChatSearching
                        ? _buildChatSearchBar()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chat?.name ?? '',
                                style: TextStyle(
                                  fontFamily: AppFonts.opensansRegular,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                              ),
                              if (chat?.isGroup == true)
                                Text(
                                  '${chat?.participants?.length ?? 0} members',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: AppFonts.opensansRegular,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                ),
                            ],
                          ),
                  ),
                  // Search Icon
                  IconButton(
                    icon: Icon(
                      _isChatSearching ? Icons.close : Icons.search,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    onPressed: () {
                      setState(() {
                        _isChatSearching = !_isChatSearching;
                        if (!_isChatSearching) {
                          _chatSearchQuery = '';
                          _chatSearchController.clear();
                          _chatFilteredMessages.clear();
                        }
                      });
                    },
                  ),
                  if (chat?.isGroup == true && !_isChatSearching)
                    PopupMenuButton<String>(
                      iconColor: Theme.of(context).textTheme.bodyLarge?.color,
                      onSelected: _handleGroupMenuAction,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'info',
                          child: Text('Group Info'),
                        ),
                        if (isAdmin) ...[
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Group'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Group'),
                          ),
                        ],
                        const PopupMenuItem(
                          value: 'leave',
                          child: Text('Leave Group'),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Search Results Info
            if (_isChatSearching && _chatSearchQuery.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${_chatFilteredMessages.length} message${_chatFilteredMessages.length != 1 ? 's' : ''} found',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontFamily: AppFonts.opensansRegular,
                      ),
                    ),
                    const Spacer(),
                    if (_chatFilteredMessages.isNotEmpty)
                      TextButton(
                        onPressed: _clearChatSearch,
                        child: Text(
                          'Clear',
                          style: TextStyle(
                              color: AppColors.redColor,
                              fontFamily: AppFonts.opensansRegular),
                        ),
                      ),
                  ],
                ),
              ),

            // Pinned Messages Section
            if (pinnedMessagesForChat.isNotEmpty && !_isChatSearching)
              _buildPinnedMessagesSection(pinnedMessagesForChat),

            // Messages List
            Expanded(
              child: Stack(
                children: [
                  if (isLoading)
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: _buildShimmerLoading(),
                    )
                  else if (displayMessages.isEmpty)
                    _buildChatEmptyState()
                  else
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: displayMessages.length,
                      itemBuilder: (context, index) {
                        final message = displayMessages[index];
                        final isMe = message.sender.id == currentUserId;
                        if (!isMe) otherId = message.sender.id;
                        final showDateSeparator = index == 0 ||
                            !_isSameDay(message.timestamp,
                                displayMessages[index - 1].timestamp);
                        bool showUnreadSeparator = false;
                        if (!_isChatSearching &&
                            !_hasShownUnreadSeparator &&
                            selectedChatId != null) {
                          String? lastReadId =
                              lastReadMessageId[selectedChatId!];

                          if (lastReadId != null && lastReadId.isNotEmpty) {
                            // Show separator after the last read message
                            if (index > 0) {
                              final previousMessage =
                                  displayMessages[index - 1];
                              final previousMessageId =
                                  _getMessageId(previousMessage);

                              if (previousMessageId == lastReadId &&
                                  ((previousMessage.isRead ||
                                          previousMessage.isEdited ||
                                          previousMessage.isForwarded) ==
                                      false)) {
                                showUnreadSeparator = true;
                                _hasShownUnreadSeparator = true;
                                print(
                                    '✅ Showing unread separator after message: $lastReadId at index ${index - 1}');
                              }
                            }
                          }
                        }

                        _hasShownUnreadSeparator = showUnreadSeparator;
                        return Column(
                          children: [
                            if (showDateSeparator)
                              _buildDateSeparator(message.timestamp),
                            if (showUnreadSeparator)
                              _buildUnreadMessageSeparator(),
                            _buildMessageBubbleWithLongPress(message, isMe,
                                highlightSearch: _isChatSearching),
                          ],
                        );
                      },
                    ),

                  // Loading indicator for older messages - Fixed positioning
                  if (_isLoadingOlderMessages)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Message Input - Move this inside Column
            if (!_isChatSearching) _buildMessageInput(),
          ],
        ),

        // Scroll to bottom button - Now properly positioned in Stack
        if (_showScrollToBottom && !_isChatSearching)
          Positioned(
            bottom: 100, // Adjust this value based on your input height
            right: 16,
            child: _buildScrollToBottomButton(),
          ),
      ],
    );
  }

// Chat search bar widget
  Widget _buildChatSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        cursorHeight: 20,
        cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
        controller: _chatSearchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search messages...',
          hintStyle: TextStyle(
            fontFamily: AppFonts.opensansRegular,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onChanged: _onChatSearchChanged,
        style: TextStyle(
          fontFamily: AppFonts.opensansRegular,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

// Chat search functionality
  void _onChatSearchChanged(String query) {
    setState(() {
      _chatSearchQuery = query.toLowerCase();
      if (_chatSearchQuery.isEmpty) {
        _chatFilteredMessages.clear();
      } else {
        final chatMessages = messages[selectedChatId] ?? [];
        _chatFilteredMessages = chatMessages.where((message) {
          return message.content.toLowerCase().contains(_chatSearchQuery) ||
              message.sender.name.toLowerCase().contains(_chatSearchQuery);
        }).toList();
      }
    });
  }

  void _clearChatSearch() {
    setState(() {
      _chatSearchQuery = '';
      _chatSearchController.clear();
      _chatFilteredMessages.clear();
    });
  }

// Chat empty state widget
  Widget _buildChatEmptyState() {
    if (_isChatSearching && _chatSearchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No messages found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

// Updated Pinned Messages Section Widget to accept specific pinned messages
  Widget _buildPinnedMessagesSection(List<dynamic> pinnedMessagesForChat) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          itemCount: pinnedMessagesForChat.length,
          itemBuilder: (context, index) {
            final message = pinnedMessagesForChat[index];
            return _buildPinnedMessageCard(message);
          },
        ),
      ),
    );
  }

  void _scrollToMessagePrecise(dynamic pinnedMessage) {
    if (pinnedMessage == null) {
      _showErrorSnackBar('Invalid pinned message');
      return;
    }

    String? messageId = _getMessageId(pinnedMessage);

    if (messageId == null || messageId.isEmpty) {
      _showErrorSnackBar('Invalid pinned message ID');
      return;
    }

    final chatMessages = messages[selectedChatId] ?? [];
    int messageIndex = -1;

    for (int i = 0; i < chatMessages.length; i++) {
      if (_getMessageId(chatMessages[i]) == messageId) {
        messageIndex = i;
        break;
      }
    }

    if (messageIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message not found in current chat'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Set the highlighted message
    setState(() {
      _highlightedMessageId = messageId;
    });

    // Use Scrollable.ensureVisible for precise scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _messageKeys[messageId] ?? GlobalKey();

      _messageKeys[messageId] = key;
      final BuildContext? context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          alignment: 0.1, // Scroll to 10% from top
        ).then((_) {
          // Remove highlight after 3 seconds
          _highlightTimer?.cancel();
          _highlightTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _highlightedMessageId = null;
              });
            }
          });
        });
      }
    });
  }

  Widget _buildPinnedMessageCard(dynamic message) {
    return GestureDetector(
      onTap: () => {_scrollToMessage(message), _scrollToMessage(message)},
      onLongPress: () => _unpinMessage(message),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: _buildPinnedMessageContent(message),
      ),
    );
  }

  void _updateChatUnreadStatus(String chatId, int newCount) {
    setState(() {
      // Update direct chats
      final directIndex = directChats.indexWhere((chat) => chat.id == chatId);
      if (directIndex != -1) {
        directChats[directIndex] = Chat(
          id: directChats[directIndex].id,
          name: directChats[directIndex].name,
          avatar: directChats[directIndex].avatar,
          lastMessage: directChats[directIndex].lastMessage,
          timestamp: directChats[directIndex].timestamp,
          unread: newCount,
          isGroup: directChats[directIndex].isGroup,
          participants: directChats[directIndex].participants,
        );
      }

      // Update groups
      final groupIndex = groups.indexWhere((group) => group.id == chatId);
      if (groupIndex != -1) {
        // If your GroupData has unreadCount field, update it here
        // groups[groupIndex] = groups[groupIndex].copyWith(unreadCount: newCount);
      }
    });

    // Trigger UI refresh
    _sortAllChats();
  }

  Widget _buildPinnedMessageContent(dynamic message) {
    try {
      String? content;
      String? messageType;
      String? fileName;

      if (message is Map<String, dynamic>) {
        content = message['content']?.toString();
        messageType =
            message['messageType']?.toString() ?? message['type']?.toString();
        fileName = message['fileName']?.toString();
      } else {
        content = message.content?.toString();
        messageType = message.messageType?.toString();
        fileName = message.fileInfo?.name?.toString();
      }

      messageType = messageType?.toLowerCase() ?? "";

      // FORCE detect type by extension also
      if (content != null) {
        if (content.contains(".jpg") ||
            content.contains(".jpeg") ||
            content.contains(".png") ||
            messageType.contains("image")) {
          messageType = "image";
        } else if (content.contains(".mp4") ||
            content.contains(".mov") ||
            messageType.contains("video")) {
          messageType = "video";
        } else if (content.contains(".mp3") ||
            content.contains(".wav") ||
            messageType.contains("audio")) {
          messageType = "audio";
        } else if (messageType.contains("application") ||
            messageType.contains("file") ||
            messageType.contains("document")) {
          messageType = "file";
        }
      }

      // --------------------------
      // ALWAYS ICON + LABEL ONLY
      // --------------------------

      switch (messageType) {
        case 'image':
          return _iconLabelCard(Icons.image, "Photo");

        case 'video':
          return _iconLabelCard(Icons.videocam, "Video");

        case 'audio':
          return _iconLabelCard(Icons.audiotrack, "Audio");

        case 'file':
          String ext = "";
          if (fileName != null && fileName.contains(".")) {
            ext = fileName.split(".").last.toUpperCase();
          }
          return _iconLabelCard(
              Icons.insert_drive_file, ext.isEmpty ? "Document" : "$ext File");

        default:
          return _textCard(content ?? "Message");
      }
    } catch (e) {
      return _textCard("Message");
    }
  }

  Widget _iconLabelCard(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

  Widget _textCard(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

// Helper method to get sender name safely
  String _getSenderName(dynamic message) {
    try {
      if (message is Map<String, dynamic>) {
        final sender = message['sender'];
        if (sender is Map<String, dynamic>) {
          return sender['fullName']?.toString() ??
              sender['name']?.toString() ??
              'Unknown';
        }
        return 'Unknown';
      } else {
        // Assuming message is a Message object
        return message.sender?.name ?? message.sender?.fullName ?? 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

// Helper method to get message ID safely
  // Improved _getMessageId method with better error handling
  String? _getMessageId(dynamic message) {
    try {
      if (message == null) return null;

      if (message is Message) {
        return message.id;
      }

      if (message is Map<String, dynamic>) {
        // Handle all possible ID fields
        return message['_id'] ?? message['id'] ?? message['messageId'];
      }

      // Handle other types if needed
      if (message is String) return message;

      return null;
    } catch (e) {
      debugPrint('Error getting message ID: $e');
      return null;
    }
  }

  void _scrollToMessage(dynamic pinnedMessage) async {
    if (pinnedMessage == null) {
      _showErrorSnackBar('Invalid pinned message');
      return;
    }

    String? messageId = _getMessageId(pinnedMessage);

    if (messageId == null || messageId.isEmpty) {
      _showErrorSnackBar('Invalid pinned message ID');
      return;
    }

    // Wait for the next frame to ensure the list is built
    await Future.delayed(const Duration(milliseconds: 100));

    final chatMessages = messages[selectedChatId] ?? [];

    // Find the message index in the list
    int messageIndex = -1;
    for (int i = 0; i < chatMessages.length; i++) {
      if (_getMessageId(chatMessages[i]) == messageId) {
        messageIndex = i;
        break;
      }
    }

    if (messageIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message not found in current chat'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Set the highlighted message
    setState(() {
      _highlightedMessageId = messageId;
    });

    // Wait for the UI to update and keys to be assigned
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Try multiple approaches to ensure the message is scrolled to

      // Approach 1: Use ListView's scroll controller
      if (_scrollController.hasClients) {
        final itemHeight = 100.0; // Approximate height of each message
        final targetOffset = (messageIndex * itemHeight).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

      // Approach 2: Use GlobalKey if available (backup)
      final key = _messageKeys[messageId];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }

      // Remove highlight after 3 seconds
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    });
  }

// Updated _getPinnedMessagePreview method with proper content handling
  String _getPinnedMessagePreview(dynamic message) {
    try {
      // Handle both Message object and Map from socket
      String? content;
      String? messageType;
      String? fileName;

      if (message is Map<String, dynamic>) {
        content = message['content']?.toString();
        messageType =
            message['messageType']?.toString() ?? message['type']?.toString();
        fileName = message['fileName']?.toString();
      } else {
        // Message object - directly access the content field
        content = message.content?.toString();
        messageType = message.messageType?.toString();
        // Handle fileInfo if it exists
        fileName = message.fileInfo?.name?.toString();
      }

      // Always prioritize showing the actual content
      if (content != null && content.isNotEmpty) {
        return content;
      }

      // Fallback to message type indicators only if content is empty
      if (messageType == 'file') {
        return '📎 ${fileName ?? 'File'}';
      } else if (messageType == 'image') {
        return '📷 Photo';
      } else if (messageType == 'audio') {
        return '🎵 Audio';
      } else if (messageType == 'video') {
        return '🎥 Video';
      }

      return 'Message';
    } catch (e) {
      return 'Message';
    }
  }

  // Modified message bubble with long press functionality
  Widget _buildMessageBubbleWithLongPress(Message message, bool isMe,
      {bool highlightSearch = false}) {
    final messageId = message.id.toString();
    final isHighlighted = _highlightedMessageId == messageId;

    // Ensure the key is properly created and stored
    if (!_messageKeys.containsKey(messageId)) {
      _messageKeys[messageId] = GlobalKey();
    }

    final key = _messageKeys[messageId];

    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        _startReply(message);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(
          Icons.reply,
          color: Colors.blue,
          size: 24,
        ),
      ),
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(message, isMe),
        child: Container(
          key: key, // This is crucial - the key must be on the container
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Colors.yellow.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: isHighlighted
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : EdgeInsets.zero,
            child: _buildMessageBubble(message, isMe),
          ),
        ),
      ),
    );
  }

// Translation button widget
  Widget _buildTranslationButton(Message message, bool isMe) {
    return Obx(() {
      final messageId = message.id.toString();
      final isTranslated = _isTranslated[messageId] ?? false;
      final isTranslating = _isTranslating[messageId] ?? false;

      // Only show translation for text messages
      if (message.messageType != 'text' && message.messageType != null) {
        return const SizedBox(width: 8);
      }

      if (isMe) {
        return Container();
      }
      return Container(
        margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
        child: GestureDetector(
          onTap: isTranslating ? null : () => _handleTranslation(message),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isTranslated
                  ? (isMe ? Colors.white : const Color(0xFF1565d8))
                      .withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isTranslated
                    ? (isMe ? Colors.white : const Color(0xFF1565d8))
                        .withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: isTranslating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isMe ? Colors.white : const Color(0xFF1565d8),
                      ),
                    ),
                  )
                : Icon(
                    Icons.translate,
                    size: 16,
                    color: isTranslated
                        ? (isMe ? Colors.white : const Color(0xFF1565d8))
                        : (isMe
                            ? Colors.white.withOpacity(0.6)
                            : Colors.grey[500]),
                  ),
          ),
        ),
      );
    });
  }

  void _handleTranslation(Message message) async {
    final messageId = message.id.toString();

    final isCurrentlyTranslated = _isTranslated[messageId] ?? false;

    // If already translated, revert to original immediately
    if (isCurrentlyTranslated) {
      _isTranslated.remove(messageId);
      _translatedTexts.remove(messageId);
      return;
    }

    // Start translation process
    _isTranslating[messageId] = true;

    try {
      final translatedText =
          await ChatService().translateText(message.content ?? "") ?? "";

      // Update the reactive state
      _translatedTexts[messageId] = translatedText;
      _isTranslated[messageId] = true;
      debugPrint("========== _translatedTexts[messageId] $translatedText");
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Translation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Always remove loading state
      _isTranslating.remove(messageId);
    }
  }

// Fixed _showMessageOptions function
  void _showMessageOptions(dynamic message, bool isMe) {
    if (selectedChatId == null || message == null) return;

    String? messageId = _getMessageId(message);
    if (messageId!.isEmpty) {
      _showErrorSnackBar('Invalid message');
      return;
    }

    List<dynamic> currentPinned = currentChatPinnedMessages;
    final isPinned = currentPinned
        .where((m) => m != null && _getMessageId(m) == messageId)
        .isNotEmpty;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(context); // ✅ Ensure pop happens
                _showEmojiReactions(messageId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context); // ✅ Ensure pop happens
                _startReply(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context); // ✅ Ensure pop happens
                _showForwardMessageDialog(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Important'),
              onTap: () async {
                Navigator.pop(context); // ✅ Ensure pop happens
                _starMessage(message);
              },
            ),
            ListTile(
              leading:
                  Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(isPinned ? 'Unpin Message' : 'Pin Message'),
              onTap: () {
                Navigator.pop(context); // ✅ Ensure pop happens
                if (isPinned) {
                  _unpinMessage(message);
                } else {
                  _pinMessage(message);
                }
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context); // ✅ Ensure pop happens
                  _startEditingMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // ✅ Ensure pop happens
                  _deleteMessage(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context); // ✅ Ensure pop happens
                _copyMessage(message);
              },
            ),
          ],
        ),
      ),
    ).then((_) {
      // This ensures the modal is properly closed
      // Additional safety measure
    });
  }

  // Updated copy message function
  void _copyMessage(dynamic message) {
    try {
      String? content;
      String? messageType;

      if (message is Map<String, dynamic>) {
        content = message['content']?.toString();
        messageType =
            message['messageType']?.toString() ?? message['type']?.toString();
      } else {
        content = message.content?.toString();
        messageType =
            message.messageType?.toString() ?? message.type?.toString();
      }

      if (messageType == 'text' && content != null) {
        Clipboard.setData(ClipboardData(text: content));
        _showSuccessSnackBar('Message copied to clipboard');
      } else {
        _showErrorSnackBar('Cannot copy this message type');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to copy message');
    }
  }

  void _handleGroupMenuAction(String action) {
    switch (action) {
      case 'info':
        setState(() => showGroupInfo = true);
        break;
      case 'edit':
        _editGroup();
        break;
      case 'delete':
        _showDeleteGroupDialog();
        break;
      case 'leave':
        _showLeaveGroupDialog();
        break;
    }
  }

  void _editGroup() {
    _showSnackBar('Group edited successfully');
  }

  void _cleanupMessageKeys() {
    if (selectedChatId == null) return;

    final currentMessageIds = messages[selectedChatId]
            ?.map((msg) => _getMessageId(msg))
            .where((id) => id != null)
            .toSet() ??
        <String>{};

    // Remove keys for messages that no longer exist in current chat
    _messageKeys.keys
        .where((key) => !currentMessageIds.contains(key))
        .toList()
        .forEach(_messageKeys.remove);
  }

  void _showDeleteGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
            'Are you sure you want to delete this group? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              handleDeleteGroup();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveGroup();
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _leaveGroup() {
    final group = selectedGroup;
    if (group == null || currentUserId == null) return;

    _socketService.leaveGroup(
      group.id ?? "",
      currentUserId!,
      (success) {
        if (success) {
          setState(() {
            groups.removeWhere((g) => g.id == group.id);
            selectedChatId = null;
          });
          _showSnackBar('Left group successfully');
        } else {
          _showSnackBar('Failed to leave group');
        }
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDateSeparator(date),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  final VoidCallback resumeCallBack;

  LifecycleEventHandler({
    required this.resumeCallBack,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        resumeCallBack();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
    }
  }
}
