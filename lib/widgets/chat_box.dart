import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:scribble/models/user.dart';

import '../models/message.dart';
import '../theme/app_theme.dart';

class ChatBoxWidget extends StatefulWidget {
  final List<Message> messages;
  final String currentUserId;
  final bool isDrawingTurn;
  final Function(String) onSendMessage;
  final String? correctWord;
  final bool showCompactMode;

  const ChatBoxWidget({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.isDrawingTurn,
    required this.onSendMessage,
    this.correctWord,
    this.showCompactMode = false,
  });

  @override
  State<ChatBoxWidget> createState() => _ChatBoxWidgetState();
}

class _ChatBoxWidgetState extends State<ChatBoxWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _showEmojiPicker = false;
  late AnimationController _animationController;

  // Common emojis for quick reactions
  final List<String> _quickEmojis = [
    '👍',
    '😊',
    '😂',
    '👏',
    '🎉',
    '❓',
    '🤔',
    '👀',
  ];

  // Last correct guess animation
  bool _showCorrectGuessAnimation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didUpdateWidget(covariant ChatBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if there was a new correct guess
    if (widget.messages.isNotEmpty &&
        oldWidget.messages.isNotEmpty &&
        widget.messages.length > oldWidget.messages.length) {
      final latestMessage = widget.messages.last;
      if (latestMessage.type == MessageType.guessCorrect) {
        setState(() {
          _showCorrectGuessAnimation = true;
        });

        // Automatically hide animation after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showCorrectGuessAnimation = false;
            });
          }
        });
      }
    }

    // Scroll to bottom when new messages arrive
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.smallShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Chat',
                  style: GoogleFonts.fredoka(color: Colors.white, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.messages.length} message${widget.messages.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Correct guess animation overlay
          if (_showCorrectGuessAnimation)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                children: [
                  Lottie.asset(
                    'assets/animations/confetti.json',
                    width: 40,
                    height: 40,
                    repeat: false,
                    // If you don't have this animation, replace with:
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.celebration,
                          color: Colors.green,
                          size: 24,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Correct guess!',
                      style: GoogleFonts.fredoka(
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _showCorrectGuessAnimation = false;
                      });
                    },
                    color: Colors.green,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Word hint for guesser (if provided)
          if (widget.correctWord != null && !widget.isDrawingTurn)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Word: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    _getWordHint(widget.correctWord!),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final message = widget.messages[index];
                      return _buildMessageItem(context, message, index);
                    },
                  ),

                  // Empty state
                  if (widget.messages.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.isDrawingTurn
                                ? 'You are drawing'
                                : 'Guess the word!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isDrawingTurn
                                ? 'Messages will appear here'
                                : 'Type your guesses in the chat',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Emoji picker (when open)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _showEmojiPicker ? 70 : 0,
            color: Colors.white,
            child:
                _showEmojiPicker
                    ? GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                            childAspectRatio: 1,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _quickEmojis.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            _sendMessage(_quickEmojis[index]);
                            setState(() {
                              _showEmojiPicker = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _quickEmojis[index],
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      },
                    )
                    : null,
          ),

          // Chat input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Emoji button
                if (!widget.isDrawingTurn)
                  IconButton(
                    icon: Icon(
                      _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                      color: AppTheme.secondaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _showEmojiPicker = !_showEmojiPicker;
                      });
                      if (_showEmojiPicker) {
                        // Remove focus from text field
                        _focusNode.unfocus();
                      } else {
                        // Focus text field when closing emoji picker
                        _focusNode.requestFocus();
                      }
                    },
                    tooltip: 'Emojis',
                    splashRadius: 24,
                  ),

                // Text input field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText:
                            widget.isDrawingTurn
                                ? 'You are drawing...'
                                : 'Type your guess here...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        enabled: !widget.isDrawingTurn,
                      ),
                      style: const TextStyle(fontSize: 16),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      onTap: () {
                        // Close emoji picker when text field is tapped
                        if (_showEmojiPicker) {
                          setState(() {
                            _showEmojiPicker = false;
                          });
                        }
                      },
                      inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    ),
                  ),
                ),

                // Send button
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 0.5,
                      child: child,
                    );
                  },
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed:
                        widget.isDrawingTurn
                            ? null
                            : () {
                              _animationController.forward(from: 0);
                              _sendMessage(_messageController.text);
                            },
                    color: AppTheme.primaryColor,
                    disabledColor: Colors.grey.shade300,
                    tooltip: 'Send',
                    splashRadius: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, Message message, int index) {
    // Check if previous message is from same sender (for grouping)
    final isGrouped =
        index > 0 &&
        widget.messages[index - 1].sender?.id == message.sender?.id &&
        message.type == MessageType.chat &&
        widget.messages[index - 1].type == MessageType.chat;

    // System message
    if (message.type == MessageType.system) {
      return _buildSystemMessage(message);
    }

    // Correct guess message
    if (message.type == MessageType.guessCorrect) {
      return _buildCorrectGuessMessage(message);
    }

    // Regular chat message
    final isCurrentUser = message.sender?.id == widget.currentUserId;

    return Padding(
      padding: EdgeInsets.only(top: isGrouped ? 2.0 : 8.0, bottom: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar (only show for first message in group)
          if (!isCurrentUser && !isGrouped) ...[
            _buildMessageAvatar(message.sender),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                // Username (only show for first message in group)
                if (!isCurrentUser && !isGrouped && message.sender != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                    child: Text(
                      message.sender!.username,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isCurrentUser
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        isCurrentUser || isGrouped ? 16 : 4,
                      ),
                      topRight: Radius.circular(
                        isCurrentUser && !isGrouped ? 4 : 16,
                      ),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    border: Border.all(
                      color:
                          isCurrentUser
                              ? AppTheme.primaryColor.withOpacity(0.2)
                              : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: _isEmojiOnly(message.content) ? 24 : 14,
                    ),
                  ),
                ),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(
                    top: 2.0,
                    left: 4.0,
                    right: 4.0,
                  ),
                  child: Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),

          if (isCurrentUser && !isGrouped) ...[
            const SizedBox(width: 8),
            _buildMessageAvatar(message.sender),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageAvatar(User? user) {
    if (user == null) return const SizedBox(width: 32, height: 32);

    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        user.username.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSystemMessage(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCorrectGuessMessage(Message message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green,
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: message.sender?.username ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' guessed the word correctly!'),
                ],
              ),
            ),
          ),
          // Lottie animation - confetti
          SizedBox(
            width: 40,
            height: 40,
            child: Lottie.asset(
              'assets/animations/confetti.json',
              repeat: false,
              // If you don't have this animation, replace with:
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.celebration, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    final message = text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _messageController.clear();

      // Close emoji picker after sending
      if (_showEmojiPicker) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    }
  }

  bool _isEmojiOnly(String text) {
    // Simple check if the message contains only emoji
    // This is a simplified approach - a more robust solution would use regex
    return text.length <= 2 && text.codeUnits.every((unit) => unit > 127);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (today == messageDay) {
      // Today - show time only
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (today.subtract(const Duration(days: 1)) == messageDay) {
      // Yesterday
      return 'Yesterday ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Other day
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getWordHint(String word) {
    // Replace letters with underscores keeping spaces
    final chars = word.split('');
    for (int i = 0; i < chars.length; i++) {
      if (chars[i] != ' ') {
        chars[i] = '_';
      }
    }
    return chars.join(' ');
  }
}

// Note: Add lottie package to pubspec.yaml:
// dependencies:
//   lottie: ^2.1.0
