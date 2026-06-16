import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

void main() {
  runApp(const ChatProApp());
}

class ChatProApp extends StatelessWidget {
  const ChatProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BIJOY-V1 Chat Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SetupScreen(),
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _serverController = TextEditingController(
    text: 'http://192.168.1.100:3000',
  );

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  void _connect() {
    final username = _nameController.text.trim();
    final serverUrl = _serverController.text.trim();

    if (username.isEmpty) {
      _showMessage('Name dao');
      return;
    }

    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      _showMessage('Server URL http:// diye start hote hobe');
      return;
    }

    setState(() => _loading = true);

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            username: username,
            serverUrl: serverUrl,
          ),
        ),
      );
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 14,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: Color(0xFF1565C0),
                      child: Icon(
                        Icons.wifi_tethering,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'BIJOY-V1 Chat Pro',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Same WiFi e local chat',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Your name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _serverController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'http://192.168.1.100:3000',
                        prefixIcon: const Icon(Icons.router),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _connect,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: const Text(
                          'Connect',
                          style: TextStyle(fontSize: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Phone + PC same WiFi e thakte hobe.\nMobile app e localhost use korbe na.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.username,
    required this.serverUrl,
  });

  final String username;
  final String serverUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late io.Socket _socket;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatItem> _items = [];
  List<OnlineUser> _users = [];

  bool _connected = false;
  String _statusText = 'Connecting...';
  String? _typingUser;

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _socket.dispose();
    super.dispose();
  }

  void _connectSocket() {
    _socket = io.io(
      widget.serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(800)
          .disableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) {
      if (!mounted) return;
      setState(() {
        _connected = true;
        _statusText = 'Connected';
      });

      _socket.emit('join', {'username': widget.username});
    });

    _socket.onDisconnect((_) {
      if (!mounted) return;
      setState(() {
        _connected = false;
        _statusText = 'Disconnected';
      });
    });

    _socket.onConnectError((data) {
      if (!mounted) return;
      setState(() {
        _connected = false;
        _statusText = 'Connection failed';
      });
      _addSystemMessage('Server connect hocche na. IP/Firewall check koro.');
    });

    _socket.on('joined', (data) {
      _addSystemMessage('Welcome ${widget.username}');
    });

    _socket.on('users', (data) {
      if (!mounted || data is! List) return;

      setState(() {
        _users = data
            .map(
              (item) => OnlineUser(
                id: '${item['id'] ?? ''}',
                username: '${item['username'] ?? 'Guest'}',
              ),
            )
            .toList();
      });
    });

    _socket.on('system_message', (data) {
      _addSystemMessage('${data['text'] ?? ''}');
    });

    _socket.on('chat_message', (data) {
      if (!mounted || data == null) return;

      final message = ChatMessage(
        id: '${data['id'] ?? DateTime.now().millisecondsSinceEpoch}',
        senderId: '${data['senderId'] ?? ''}',
        username: '${data['username'] ?? 'Guest'}',
        text: '${data['text'] ?? ''}',
        timestamp: DateTime.tryParse('${data['timestamp'] ?? ''}') ??
            DateTime.now(),
      );

      setState(() {
        _items.add(ChatItem.message(message));
      });

      _scrollToBottom();
    });

    _socket.on('typing', (data) {
      if (!mounted || data == null) return;

      final username = '${data['username'] ?? ''}';
      final isTyping = data['isTyping'] == true;

      if (username == widget.username) return;

      setState(() {
        _typingUser = isTyping ? username : null;
      });

      if (isTyping) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => _typingUser = null);
        });
      }
    });

    _socket.connect();
  }

  void _addSystemMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _items.add(ChatItem.system(text.trim()));
    });

    _scrollToBottom();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (!_connected) {
      _addSystemMessage('Server disconnected. Message pathano gelo na.');
      return;
    }

    _socket.emit('chat_message', {
      'username': widget.username,
      'text': text,
    });

    _messageController.clear();
    _socket.emit('typing', {
      'username': widget.username,
      'isTyping': false,
    });
  }

  void _onTyping(String value) {
    if (!_connected) return;
    _socket.emit('typing', {
      'username': widget.username,
      'isTyping': value.trim().isNotEmpty,
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showUsers() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Online Users (${_users.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (_users.isEmpty)
                const Text('Kono user nei')
              else
                ..._users.map(
                  (user) => ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(user.username),
                    subtitle: Text(
                      user.username == widget.username ? 'You' : 'Online',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _typingUser == null
        ? '$_statusText • ${_users.length} online'
        : '$_typingUser typing...';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BIJOY Chat',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: CircleAvatar(
            backgroundColor: _connected ? Colors.green : Colors.redAccent,
            child: const Icon(Icons.wifi, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showUsers,
            icon: const Icon(Icons.group),
          ),
          IconButton(
            onPressed: () {
              _socket.disconnect();
              _socket.connect();
              _addSystemMessage('Reconnecting...');
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFEAF2FA),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  if (item.isSystem) {
                    return SystemBubble(text: item.systemText ?? '');
                  }

                  final message = item.message!;
                  final isMe = message.username == widget.username;
                  return MessageBubble(
                    message: message,
                    isMe: isMe,
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      onChanged: _onTyping,
                      decoration: InputDecoration(
                        hintText: 'Message lekho...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor:
                        _connected ? const Color(0xFF1565C0) : Colors.grey,
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? const Color(0xFF1565C0) : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.username,
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            if (!isMe) const SizedBox(height: 3),
            Text(
              message.text,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class SystemBubble extends StatelessWidget {
  const SystemBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }
}

class ChatItem {
  ChatItem.message(this.message) : systemText = null;
  ChatItem.system(this.systemText) : message = null;

  final ChatMessage? message;
  final String? systemText;

  bool get isSystem => systemText != null;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.username,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String senderId;
  final String username;
  final String text;
  final DateTime timestamp;
}

class OnlineUser {
  OnlineUser({
    required this.id,
    required this.username,
  });

  final String id;
  final String username;
}
