import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

const String supabaseUrl =
    'https://njjsqppwbphutahmfeor.supabase.co';

const String supabasePublishableKey =
    'sb_publishable_Q2b0pDWwqfWxCLGUDlA8QA_TAJXkbvA';

final SupabaseClient supabase = Supabase.instance.client;

const Color friendzaGreen = Color(0xFFA78BFA);
const Color friendzaDarkGreen = Color(0xFF7C3AED);
const Color friendzaBackground = Color(0xFF101016);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const FriendzaApp());
}

class FriendzaApp extends StatelessWidget {
  const FriendzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friendza',
      debugShowCheckedModeBanner: false,
      
theme: ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: friendzaGreen,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: friendzaBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF101016),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Color(0xFF181720),
    indicatorColor: Color(0xFF3A2B52),
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: Color(0xFF24212D),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: friendzaGreen,
      foregroundColor: Color(0xFF171220),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
),

      home: const WelcomeScreen(),
    );
  }
}

// =====================================================
// WELCOME SCREEN
// =====================================================

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        friendzaGreen,
                        friendzaDarkGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 55,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Friendza',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your friends. Your conversations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 38),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountScreen(
                            createAccount: false,
                          ),
                        ),
                      );
                    },
                    child: const Text('Log In'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountScreen(
                            createAccount: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('Create Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// LOGIN AND SIGNUP
// =====================================================

class AccountScreen extends StatefulWidget {
  final bool createAccount;

  const AccountScreen({
    super.key,
    required this.createAccount,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (widget.createAccount) {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': _nameController.text.trim(),
          },
        );

        if (response.user == null) {
          _showMessage(
            'Account creation failed. Please try again.',
          );
          return;
        }

        if (response.session == null) {
          _showMessage(
            'Account created. Check your email to confirm your account, '
                'then log in.',
          );
          return;
        }

        await _saveProfile(
          response.user!.id,
          _nameController.text.trim(),
        );
      } else {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.session == null) {
          _showMessage('Login failed. Please try again.');
          return;
        }
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const FriendzaDashboard(),
        ),
            (route) => false,
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      debugPrint('Friendza login/signup error: $error');
      _showMessage(
        'Something went wrong. Check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveProfile(String userId, String name) async {
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'full_name': name,
      });
    } catch (error) {
      debugPrint('Friendza profile error: $error');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.createAccount ? 'Create Account' : 'Log In',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.forum_rounded,
                    size: 65,
                    color: friendzaGreen,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.createAccount
                        ? 'Join Friendza'
                        : 'Welcome Back',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (widget.createAccount) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          !value.trim().contains('@')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must contain at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        widget.createAccount
                            ? 'Create Account'
                            : 'Log In',
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
}

// =====================================================
// MAIN DASHBOARD
// =====================================================

class FriendzaDashboard extends StatefulWidget {
  const FriendzaDashboard({super.key});

  @override
  State<FriendzaDashboard> createState() =>
      _FriendzaDashboardState();
}

class _FriendzaDashboardState extends State<FriendzaDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ChatsScreen(),
    FriendsScreen(),
    StoriesScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    'Chats',
    'Friends',
    'Stories',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.forum_rounded,
              color: friendzaGreen,
            ),
            const SizedBox(width: 10),
            Text(
              'Friendza',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Stories',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// CHATS LIST
// =====================================================

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Please log in again.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final memberships = await supabase
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', userId);

      final chats = <Map<String, dynamic>>[];

      for (final membership in memberships) {
        final conversationId =
        membership['conversation_id'].toString();

        final members = await supabase
            .from('conversation_members')
            .select('user_id')
            .eq('conversation_id', conversationId);

        final otherMembers = (members as List)
            .cast<Map<String, dynamic>>()
            .where(
              (member) =>
          member['user_id'].toString() != userId,
        )
            .toList();

        if (otherMembers.isEmpty) continue;

        final friendId =
        otherMembers.first['user_id'].toString();

        var friendName = 'Friend';

        final profile = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', friendId)
            .maybeSingle();

        final profileName =
        profile?['full_name']?.toString().trim();

        if (profileName != null && profileName.isNotEmpty) {
          friendName = profileName;
        }

        final latest = await supabase
            .from('messages')
            .select('content, created_at')
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .limit(1);

        final latestMessages = latest as List;

        chats.add({
          'conversation_id': conversationId,
          'friend_id': friendId,
          'friend_name': friendName,
          'last_message': latestMessages.isEmpty
              ? 'Start a conversation'
              : (latestMessages.first['content'] ?? '').toString(),
          'last_time': latestMessages.isEmpty
              ? ''
              : (latestMessages.first['created_at'] ?? '').toString(),
        });
      }

      chats.sort(
            (a, b) => b['last_time']
            .toString()
            .compareTo(a['last_time'].toString()),
      );

      if (!mounted) return;

      setState(() {
        _chats = chats;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      debugPrint('Friendza conversation error: $error');

      setState(() {
        _loading = false;
        _error = 'Conversation error: $error';
      });
    }
  }

  void _openChat(Map<String, dynamic> chat) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId:
          chat['conversation_id'].toString(),
          friendId: chat['friend_id'].toString(),
          friendName: chat['friend_name'].toString(),
        ),
      ),
    )
        .then((_) => _loadChats());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadChats,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 75,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 18),
              const Text(
                'Your conversations start here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Open Friends, choose My Friends, and tap Message to start chatting.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadChats,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _chats.length,
        separatorBuilder: (context, index) =>
        const Divider(height: 1, indent: 76),
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final name = chat['friend_name'].toString();

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: friendzaGreen.withAlpha(30),
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(
                  color: friendzaDarkGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              chat['last_message'].toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openChat(chat),
          );
        },
      ),
    );
  }
}

// =====================================================
// CHAT ROOM AND MESSAGING
// =====================================================

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final String friendId;
  final String friendName;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<ChatRoomScreen> createState() =>
      _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  bool _sending = false;
  bool _markingRead = false;
  bool _initialScrollDone = false;
  bool _wasNearBottom = true;

  String get _userId => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _markMessagesRead();
  }

  Future<void> _markMessagesRead() async {
    try {
      await supabase.rpc(
        'mark_messages_read',
        params: {
          'p_conversation_id': widget.conversationId,
        },
      );
    } catch (e) {
      debugPrint('Could not mark messages as read: $e');
    }
  }
  Future<void> _markMessagesReadIfNeeded(
      List<Map<String, dynamic>> messages,
      ) async {
    if (_markingRead) return;

    final hasUnreadMessages = messages.any(
          (message) =>
      message['sender_id'] != _userId &&
          message['read_at'] == null,
    );

    if (!hasUnreadMessages) return;

    _markingRead = true;

    try {
      await supabase.rpc(
        'mark_messages_read',
        params: {
          'p_conversation_id': widget.conversationId,
        },
      );
    } catch (e) {
      debugPrint('Could not mark messages as read: $e');
    } finally {
      _markingRead = false;
    }
  }
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _userId,
        'content': text,
        'message_type': 'text',
      });

      _messageController.clear();
      _scrollToBottom();
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Message could not be sent: ${error.message}',
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('Friendza send message error: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message could not be sent. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;

    return _scrollController.position.pixels < 160;
  }
  String _formatMessageTime(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '';

    final localDate = date.toLocal();

    final hour = localDate.hour % 12 == 0
        ? 12
        : localDate.hour % 12;

    final minute = localDate.minute.toString().padLeft(2, '0');

    final period = localDate.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: friendzaBackground,
    appBar: AppBar(
      backgroundColor: const Color(0xFF101016),
      foregroundColor: Colors.white,
      elevation: 0,

        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: friendzaGreen.withAlpha(30),
              child: Text(
                widget.friendName.isEmpty
                    ? '?'
                    : widget.friendName[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFA78BFA),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friendName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Friendza conversation',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Conversation options',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'More conversation options will be added later.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq(
                'conversation_id',
                widget.conversationId,
              )
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(
                    'Friendza message stream error: ${snapshot.error}',
                  );

                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Could not load messages. Check the messages SELECT policy and Realtime settings.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _markMessagesReadIfNeeded(messages);
                  }
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.waving_hand_outlined,
                            size: 54,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Say hello to ${widget.friendName}!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your messages will appear here.',
                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Scroll to the latest message when the chat first opens.
                // On later updates, only auto-scroll if the user was already
                // close to the bottom of the conversation.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || !_scrollController.hasClients) {
                    return;
                  }

                  if (!_initialScrollDone || _wasNearBottom) {
                    _scrollController.jumpTo(0);
                  }

                  _initialScrollDone = true;
                  _wasNearBottom = _isNearBottom();
                });

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification ||
                        notification is ScrollEndNotification) {
                      _wasNearBottom = _isNearBottom();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      18,
                      12,
                      18,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];

                      final isMine =
                          message['sender_id'].toString() == _userId;

                      final content =
                      (message['content'] ?? '').toString();

                      final time =
                      _formatMessageTime(message['created_at']);

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                            MediaQuery.of(context).size.width * 0.78,
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(
                            13,
                            10,
                            10,
                            7,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF24212D),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(17),
                              topRight: const Radius.circular(17),
                              bottomLeft: Radius.circular(
                                isMine ? 17 : 4,
                              ),
                              bottomRight: Radius.circular(
                                isMine ? 4 : 17,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  content,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    time,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (isMine) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.done_all,
                                      size: 15,
                                      color: message['read_at'] != null
                                          ? const Color(0xFFA78BFA)
                                          : const Color(0xFF53A6A0),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                10,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF181720),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization:
                      TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        filled: true,
                        fillColor: const Color(0xFF24212D),
                        hintStyle: const TextStyle(
                          color: Colors.white54,
                        ),    
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: const BorderSide(
                            color: Color(0xFFA78BFA),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: IconButton.filled(
                      onPressed: _sending ? null : _sendMessage,
                      icon: _sending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: friendzaGreen,
                        foregroundColor: Colors.white,
                      ),
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

// =====================================================
// FRIENDS
// =====================================================

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _searchController =
  TextEditingController();

  bool _loading = true;
  String? _error;
  String? _workingRequestId;

  final Set<String> _openingChats = {};

  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];
  List<Map<String, dynamic>> _acceptedIncoming = [];

  String get _userId => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );

    _loadFriendsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _loadFriendsData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = _userId;

      final results = await Future.wait([
        supabase
            .from('profiles')
            .select('id, full_name')
            .neq('id', userId)
            .order('full_name'),
        supabase
            .from('friend_requests')
            .select(
          'id, sender_id, receiver_id, status, created_at',
        )
            .eq('receiver_id', userId)
            .eq('status', 'pending')
            .order('created_at', ascending: false),
        supabase
            .from('friend_requests')
            .select(
          'id, sender_id, receiver_id, status, created_at',
        )
            .eq('sender_id', userId)
            .order('created_at', ascending: false),
        supabase
            .from('friend_requests')
            .select(
          'id, sender_id, receiver_id, status, created_at',
        )
            .eq('receiver_id', userId)
            .eq('status', 'accepted'),
      ]);

      if (!mounted) return;

      setState(() {
        _profiles =
        List<Map<String, dynamic>>.from(results[0] as List);

        _incomingRequests =
        List<Map<String, dynamic>>.from(results[1] as List);

        _outgoingRequests =
        List<Map<String, dynamic>>.from(results[2] as List);

        _acceptedIncoming =
        List<Map<String, dynamic>>.from(results[3] as List);

        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      debugPrint('Friendza friends error: $error');

      setState(() {
        _loading = false;
        _error =
        'Could not load friends. Check your connection and Supabase permissions.';
      });
    }
  }

  String _nameFor(String? id) {
    if (id == null) return 'Friend';

    for (final profile in _profiles) {
      if (profile['id']?.toString() == id) {
        final name = profile['full_name']?.toString().trim();

        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    }

    return 'Friend';
  }

  String? _requestStatusWith(String otherUserId) {
    for (final request in _outgoingRequests) {
      if (request['receiver_id']?.toString() == otherUserId) {
        return request['status']?.toString();
      }
    }

    for (final request in _incomingRequests) {
      if (request['sender_id']?.toString() == otherUserId) {
        return 'received';
      }
    }

    for (final request in _acceptedIncoming) {
      if (request['sender_id']?.toString() == otherUserId) {
        return 'accepted';
      }
    }

    return null;
  }

  bool _isMyFriend(String otherUserId) {
    for (final request in _outgoingRequests) {
      if (request['receiver_id']?.toString() == otherUserId &&
          request['status'] == 'accepted') {
        return true;
      }
    }

    for (final request in _acceptedIncoming) {
      if (request['sender_id']?.toString() == otherUserId) {
        return true;
      }
    }

    return false;
  }

  Future<void> _sendFriendRequest(String receiverId) async {
    if (receiverId == _userId) return;

    final status = _requestStatusWith(receiverId);

    if (status == 'accepted') {
      _message('You are already friends.');
      return;
    }

    if (status == 'pending') {
      _message('You have already sent a request.');
      return;
    }

    if (status == 'received') {
      _message(
        'This person has already sent you a request. Open Requests to respond.',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final outgoing = await supabase
          .from('friend_requests')
          .select('id, status')
          .eq('sender_id', _userId)
          .eq('receiver_id', receiverId);

      final incoming = await supabase
          .from('friend_requests')
          .select('id, status')
          .eq('sender_id', receiverId)
          .eq('receiver_id', _userId);

      if ((outgoing as List).isNotEmpty ||
          (incoming as List).isNotEmpty) {
        _message(
          'A request between these accounts already exists. Refresh Friends.',
        );

        await _loadFriendsData();
        return;
      }

      await supabase.from('friend_requests').insert({
        'sender_id': _userId,
        'receiver_id': receiverId,
        'status': 'pending',
      });

      _message(
        'Friend request sent to ${_nameFor(receiverId)}.',
      );

      await _loadFriendsData();
    } catch (error) {
      debugPrint('Friendza send request error: $error');

      _message(
        'Could not send the request. Check friend_requests permissions.',
      );

      await _loadFriendsData();
    }
  }

  Future<void> _respondToRequest(
      Map<String, dynamic> request,
      String newStatus,
      ) async {
    final requestId = request['id']?.toString();

    if (requestId == null) {
      _message('Request ID missing. Refresh and try again.');
      return;
    }

    setState(() => _workingRequestId = requestId);

    try {
      final updated = await supabase
          .from('friend_requests')
          .update({'status': newStatus})
          .eq('id', requestId)
          .eq('receiver_id', _userId)
          .eq('status', 'pending')
          .select('id');

      if ((updated as List).isEmpty) {
        _message(
          'The request was not updated. Check your UPDATE policy.',
        );
      } else {
        _message(
          newStatus == 'accepted'
              ? 'Friend request accepted!'
              : 'Friend request rejected.',
        );
      }

      await _loadFriendsData();
    } catch (error) {
      debugPrint('Friendza respond to request error: $error');

      _message(
        'Could not update the request. Check friend_requests permissions.',
      );
    } finally {
      if (mounted) {
        setState(() => _workingRequestId = null);
      }
    }
  }

  Future<void> _openChat(
      String friendId,
      String friendName,
      ) async {
    if (_openingChats.contains(friendId)) return;

    setState(() => _openingChats.add(friendId));

    try {
      final result = await supabase.rpc(
        'create_friend_conversation',
        params: {'friend_id': friendId},
      );

      final conversationId = result.toString();

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            conversationId: conversationId,
            friendId: friendId,
            friendName: friendName,
          ),
        ),
      );
    } on PostgrestException catch (error) {
      _message('Could not open chat: ${error.message}');
    } catch (error) {
      debugPrint('Friendza open chat error: $error');

      _message(
        'Could not open this chat. Check your connection and friend status.',
      );
    } finally {
      if (mounted) {
        setState(() => _openingChats.remove(friendId));
      }
    }
  }

  Widget _emptyState(
      IconData icon,
      String title,
      String subtitle,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 58,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindFriends() {
    final search = _searchController.text.trim().toLowerCase();

    final filtered = _profiles.where((profile) {
      final name =
      (profile['full_name'] ?? '').toString().toLowerCase();

      return name.contains(search);
    }).toList();

    if (filtered.isEmpty) {
      return _emptyState(
        Icons.person_search,
        'No users found',
        search.isEmpty
            ? 'Other registered users will appear here.'
            : 'Try another name.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriendsData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final profile = filtered[index];
          final id = profile['id'].toString();
          final name = _nameFor(id);
          final status = _requestStatusWith(id);
          final isFriend = _isMyFriend(id);

          var buttonText = 'Add Friend';
          var buttonIcon = Icons.person_add_alt_1;
          var disabled = false;

          if (isFriend) {
            buttonText = 'Friends';
            buttonIcon = Icons.people;
            disabled = true;
          } else if (status == 'pending') {
            buttonText = 'Requested';
            buttonIcon = Icons.schedule;
            disabled = true;
          } else if (status == 'received') {
            buttonText = 'Respond';
            buttonIcon = Icons.mark_chat_unread_outlined;
            disabled = true;
          } else if (status == 'rejected') {
            buttonText = 'Request Exists';
            buttonIcon = Icons.info_outline;
            disabled = true;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: friendzaGreen.withAlpha(30),
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: friendzaDarkGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isFriend
                    ? 'Your Friend'
                    : status == 'pending'
                    ? 'Friend request sent'
                    : status == 'received'
                    ? 'Sent you a friend request'
                    : 'Friendza member',
              ),
              trailing: OutlinedButton.icon(
                onPressed: disabled
                    ? null
                    : () => _sendFriendRequest(id),
                icon: Icon(buttonIcon, size: 17),
                label: Text(buttonText),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequests() {
    if (_incomingRequests.isEmpty) {
      return _emptyState(
        Icons.mark_email_read_outlined,
        'No new requests',
        'Friend requests sent to you will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriendsData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _incomingRequests.length,
        itemBuilder: (context, index) {
          final request = _incomingRequests[index];
          final senderId = request['sender_id'].toString();
          final requestId = request['id'].toString();
          final isWorking = _workingRequestId == requestId;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        _nameFor(senderId)[0].toUpperCase(),
                      ),
                    ),
                    title: Text(
                      _nameFor(senderId),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Wants to be your friend',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isWorking
                              ? null
                              : () => _respondToRequest(
                            request,
                            'accepted',
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isWorking
                              ? null
                              : () => _respondToRequest(
                            request,
                            'rejected',
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyFriends() {
    final friendsById = <String, Map<String, dynamic>>{};

    for (final request in _outgoingRequests) {
      if (request['status'] == 'accepted') {
        friendsById[request['receiver_id'].toString()] = request;
      }
    }

    for (final request in _acceptedIncoming) {
      friendsById[request['sender_id'].toString()] = request;
    }

    final friendIds = friendsById.keys.toList();

    if (friendIds.isEmpty) {
      return _emptyState(
        Icons.people_outline,
        'No friends yet',
        'Find people and send friend requests to build your friends list.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriendsData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: friendIds.length,
        itemBuilder: (context, index) {
          final friendId = friendIds[index];
          final name = _nameFor(friendId);
          final opening = _openingChats.contains(friendId);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: friendzaGreen.withAlpha(30),
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: friendzaDarkGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text('Friend'),
              trailing: FilledButton.icon(
                onPressed: opening
                    ? null
                    : () => _openChat(friendId, name),
                icon: opening
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                ),
                label: const Text('Message'),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            12,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search for people...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Find Friends'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (_incomingRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: friendzaGreen,
                      child: Text(
                        '${_incomingRequests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'My Friends'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : _error != null
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadFriendsData,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          )
              : TabBarView(
            controller: _tabController,
            children: [
              _buildFindFriends(),
              _buildRequests(),
              _buildMyFriends(),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================
// STORIES
// =====================================================

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {

  static const Color violet = Color(0xFFA78BFA);
  static const Color cardColor = Color(0xFF24212D);

  XFile? selectedMedia;
bool isVideo = false;

Future<List<Map<String, dynamic>>> _loadStories() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return [];

  final stories = await supabase
      .from('stories')
      .select()
      .gt('expires_at', DateTime.now().toUtc().toIso8601String())
      .order('created_at', ascending: false);

 return List<Map<String, dynamic>>.from(stories);
}

Future<String> _getStoryUrl(String mediaPath) async {
  final supabase = Supabase.instance.client;

  return await supabase.storage
      .from('friendza-stories')
      .createSignedUrl(mediaPath, 3600);
}

Future<void> _recordStoryView(String storyId) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return;

  await supabase.from('story_views').upsert(
    {
      'story_id': storyId,
      'viewer_id': user.id,
    },
    onConflict: 'story_id,viewer_id',
    ignoreDuplicates: true,
  );
}

// Load the people who viewed a story.
Future<List<Map<String, dynamic>>> _loadStoryViewers(
    String storyId) async {
  final supabase = Supabase.instance.client;

  final views = await supabase
      .from('story_views')
      .select('viewer_id, viewed_at')
      .eq('story_id', storyId)
      .order('viewed_at', ascending: false);

  if (views.isEmpty) return [];

  final viewerIds = views
      .map((view) => view['viewer_id'].toString())
      .toSet()
      .toList();

  final profiles = await supabase
      .from('profiles')
      .select('id, full_name, avatar_url')
      .inFilter('id', viewerIds);

  return views.map((view) {
    final profile = profiles.firstWhere(
      (profile) => profile['id'] == view['viewer_id'],
      orElse: () => <String, dynamic>{},
    );

    return {
      ...profile,
      'viewer_id': view['viewer_id'],
      'viewed_at': view['viewed_at'],
    };
  }).toList();
}

Future<void> _postStory() async {
    if (selectedMedia == null) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to post a story.'),
        ),
      );
      return;
    }

    try {
      final media = selectedMedia!;
      final bytes = await media.readAsBytes();

      final mediaType = isVideo ? 'video' : 'image';
      final contentType =
          media.mimeType ?? (isVideo ? 'video/mp4' : 'image/jpeg');

      final filePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${media.name}';

      await supabase.storage
          .from('friendza-stories')
          .uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );

      await supabase.from('stories').insert({
        'user_id': user.id,
        'media_path': filePath,
        'media_type': mediaType,
      });

      if (!mounted) return;

      setState(() {
        selectedMedia = null;
        isVideo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your story was posted successfully!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not post story: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101016),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101016),
        elevation: 0,
        title: const Text(
          'Stories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF5F3FF),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Share your moment',
            style: TextStyle(
              color: Color(0xFFF5F3FF),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Little moments bring friends closer.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),

          // My Story card
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? media = await picker.pickMedia();

              if (media == null) return;
              if (!context.mounted) return;

              setState(() {
                selectedMedia = media;
                isVideo = media.mimeType?.startsWith('video/') ?? false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Selected: ${media.name}')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A2B52),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: violet,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: violet,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Story',
                          style: TextStyle(
                            color: Color(0xFFF5F3FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Share a photo or video with friends',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: violet,
                  ),
                ],
              ),
            ),
          ),

          // PHOTO PREVIEW STARTS HERE
          if (selectedMedia != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: isVideo
                  ? Container(
                height: 220,
                color: cardColor,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_circle_outline,
                  color: violet,
                  size: 60,
                ),
              )
                  : FutureBuilder<Uint8List>(
                future: selectedMedia!.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Could not load this photo.',
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return Image.memory(
                    snapshot.data!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ],
          // PHOTO PREVIEW ENDS HERE

          if (selectedMedia != null) ...[
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _postStory,
                icon: const Icon(Icons.send),
                label: const Text('Post Story'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 30),

          const Text(
            'Recent stories',
            style: TextStyle(
              color: Color(0xFFF5F3FF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

    FutureBuilder<List<Map<String, dynamic>>>(
  future: _loadStories(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: violet),
        ),
      );
    }

    if (snapshot.hasError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Could not load stories: ${snapshot.error}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    final stories = snapshot.data ?? [];

    if (stories.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 32,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(Icons.auto_awesome, color: violet, size: 42),
            SizedBox(height: 14),
            Text(
              'Your friends’ stories will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF5F3FF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'When your friends share moments, '
              'you’ll find them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Group all stories belonging to the same person.
    final groupedStories = <String, List<Map<String, dynamic>>>{};

    for (final story in stories) {
      final userId = story['user_id']?.toString();
      final mediaPath = story['media_path']?.toString() ?? '';

      if (userId == null || userId.isEmpty || mediaPath.isEmpty) {
        continue;
      }

      groupedStories.putIfAbsent(userId, () => []);
      groupedStories[userId]!.add(story);
    }

    final storyGroups = groupedStories.values.toList();

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: storyGroups.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final personStories = storyGroups[index];
          final previewStory = personStories.first;
          final mediaPath = previewStory['media_path'].toString();
          final currentUserId =
              Supabase.instance.client.auth.currentUser?.id;

          return FutureBuilder<String>(
            future: _getStoryUrl(mediaPath),
            builder: (context, urlSnapshot) {
              return GestureDetector(
                onTap: () async {
                  if (!urlSnapshot.hasData) return;

                  // Record the first story view.
                  if (previewStory['user_id']?.toString() !=
                      currentUserId) {
                    try {
                      await _recordStoryView(
                        previewStory['id'].toString(),
                      );
                    } catch (error) {
                      debugPrint('Could not record story view: $error');
                    }
                  }

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        backgroundColor: const Color(0xFF101016),
                        appBar: AppBar(
                          backgroundColor: const Color(0xFF101016),
                          foregroundColor: Colors.white,
                          title: const Text('Friendza Story'),
                        ),
                        body: PageView.builder(
                          itemCount: personStories.length,
                          onPageChanged: (pageIndex) async {
                            final nextStory = personStories[pageIndex];

                            if (nextStory['user_id']?.toString() !=
                                currentUserId) {
                              try {
                                await _recordStoryView(
                                  nextStory['id'].toString(),
                                );
                              } catch (error) {
                                debugPrint(
                                  'Could not record story view: $error',
                                );
                              }
                            }
                          },
                          itemBuilder: (context, pageIndex) {
                            final currentStory =
                                personStories[pageIndex];

                            return FutureBuilder<String>(
                              future: _getStoryUrl(
                                currentStory['media_path'].toString(),
                              ),
                              builder: (context, mediaSnapshot) {
                                return Column(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: !mediaSnapshot.hasData
                                            ? const CircularProgressIndicator(
                                                color: violet,
                                              )
                                            : currentStory['media_type'] ==
                                                    'video'
                                                ? const Text(
                                                    'Video story playback will be added next.',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Image.network(
                                                    mediaSnapshot.data!,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) =>
                                                        const Icon(
                                                      Icons.broken_image_outlined,
                                                      color: violet,
                                                      size: 48,
                                                    ),
                                                  ),
                                      ),
                                    ),

                                    if (currentStory['user_id']
                                            ?.toString() ==
                                        currentUserId)
                                      FutureBuilder<
                                          List<Map<String, dynamic>>>(
                                        future: _loadStoryViewers(
                                          currentStory['id'].toString(),
                                        ),
                                        builder: (context, viewerSnapshot) {
                                          final viewers =
                                              viewerSnapshot.data ?? [];

                                          return Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            color: cardColor,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.visibility,
                                                      color: violet,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '${viewers.length} views',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                if (viewerSnapshot
                                                        .connectionState ==
                                                    ConnectionState.waiting)
                                                  const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: violet,
                                                    ),
                                                  )
                                                else if (viewers.isEmpty)
                                                  const Text(
                                                    'No viewers yet',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  )
                                                else
                                                  ...viewers.map((viewer) {
                                                    final avatarUrl =
                                                        viewer['avatar_url']
                                                                ?.toString() ??
                                                            '';

                                                    return ListTile(
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      leading: CircleAvatar(
                                                        backgroundColor: violet,
                                                        backgroundImage:
                                                            avatarUrl.isNotEmpty
                                                                ? NetworkImage(
                                                                    avatarUrl,
                                                                  )
                                                                : null,
                                                        child: avatarUrl.isEmpty
                                                            ? const Icon(
                                                                Icons.person,
                                                                color:
                                                                    Colors.white,
                                                              )
                                                            : null,
                                                      ),
                                                      title: Text(
                                                        viewer['full_name']
                                                                ?.toString() ??
                                                            'Friendza user',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: violet,
                      width: 3,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  clipBehavior: Clip.antiAlias,
                  child: urlSnapshot.hasData
                      ? previewStory['media_type'] == 'video'
                          ? const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: violet,
                                size: 48,
                              ),
                            )
                          : Image.network(
                              urlSnapshot.data!,
                              fit: BoxFit.cover,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) =>
                                  const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: violet,
                                  size: 32,
                                ),
                              ),
                            )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: violet,
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  },
),
        ],
      ),
    );
  }
}

// =====================================================
// PROFILE AND LOGOUT
// =====================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final metadata = user?.userMetadata;

    final fullName = metadata?['full_name']?.toString().trim();

    final displayName =
    fullName == null || fullName.isEmpty
        ? 'Friendza User'
        : fullName;

    final email = user?.email ?? '';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: friendzaGreen.withAlpha(30),
              child: Text(
                displayName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: friendzaDarkGreen,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF3A2B52),
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFFA78BFA),
                      ),
                    ),
                    title: const Text('Account'),
                    subtitle: const Text('Your Friendza account'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: const Color(0xFF24212D),
                          title: const Text('Your Friendza account'),
                          content: const Text(
                            'Manage your account and personal details here.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  color: Color(0xFFA78BFA),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: Color(0xFFA78BFA),
                    ),
                    title: const Text('About Friendza'),
                    subtitle: const Text(
                      'Your friends. Your conversations.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Friendza',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                        'Your friends. Your conversations.',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await supabase.auth.signOut();

                    if (!context.mounted) return;

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const WelcomeScreen(),
                      ),
                          (route) => false,
                    );
                  } catch (error) {
                    debugPrint('Friendza logout error: $error');

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not log out. Try again.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
