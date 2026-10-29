import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color friendzaGreen = Color(0xFFA78BFA);
const Color friendzaDarkGreen = Color(0xFF7C3AED);
const Color friendzaInk = Color(0xFFF5F3FF);
const Color friendzaMuted = Color(0xFFAAA5B8);
const Color friendzaBackground = Color(0xFF101016);
const Color friendzaCard = Color(0xFF24212D);

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://njjsqppwbphutahmfeor.supabase.co',
    publishableKey: 'sb_publishable_Q2b0pDWwqfWxCLGUDlA8QA_TAJXkbvA',
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
        scaffoldBackgroundColor: friendzaBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: friendzaGreen,
          brightness: Brightness.dark,
          primary: friendzaGreen,
          secondary: friendzaDarkGreen,
          surface: friendzaCard,
        ),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: friendzaBackground,
          foregroundColor: friendzaInk,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: friendzaCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF181720),
          indicatorColor: Color(0xFF3A2B52),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1B1923),
          hintStyle: const TextStyle(color: friendzaMuted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: friendzaGreen, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: friendzaGreen,
            foregroundColor: const Color(0xFF171220),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: friendzaGreen,
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: Color(0xFF40384F)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

String friendlyError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) return error.message;
  return 'Something went wrong. Please try again.';
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String initials(String? name) {
  final clean = (name ?? '').trim();
  if (clean.isEmpty) return 'F';
  final pieces = clean.split(RegExp(r'\s+'));
  if (pieces.length == 1) return pieces.first.substring(0, 1).toUpperCase();
  return '${pieces.first[0]}${pieces.last[0]}'.toUpperCase();
}

String currentDisplayName() {
  final user = supabase.auth.currentUser;
  final metadataName = user?.userMetadata?['full_name']?.toString().trim();
  if (metadataName != null && metadataName.isNotEmpty) return metadataName;
  final emailName = user?.email?.split('@').first;
  if (emailName != null && emailName.isNotEmpty) return emailName;
  return 'Friendza User';
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentSession != null) {
          return const FriendzaShell();
        }
        return const WelcomeScreen();
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isLogin = true;
  bool busy = false;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!isLogin && name.isEmpty)) {
      showSnack(context, 'Please complete all the fields.');
      return;
    }
    if (password.length < 6) {
      showSnack(context, 'Your password must be at least 6 characters.');
      return;
    }

    setState(() => busy = true);
    try {
      if (isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name},
        );
        final user = response.user;
        if (user != null) {
          await supabase.from('profiles').upsert({
            'id': user.id,
            'full_name': name,
          });
        }
        if (mounted && response.session == null) {
          showSnack(
            context,
            'Account created. Check your email to confirm, then log in.',
          );
          setState(() => isLogin = true);
        }
      }
    } catch (error) {
      if (mounted) showSnack(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF101016), Color(0xFF191622), Color(0xFF211A30)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 84,
                      width: 84,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [friendzaGreen, friendzaDarkGreen],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: friendzaGreen.withValues(alpha: .22),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.forum_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Friendza',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: friendzaInk,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your friends. Your conversations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: friendzaMuted, fontSize: 15),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: friendzaCard,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFF393244)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: .12),
                            blurRadius: 35,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            isLogin ? 'Welcome back 👋' : 'Join Friendza ✨',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: friendzaInk,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            isLogin
                                ? 'Log in to catch up with your people.'
                                : 'Create an account and meet your people.',
                            style: const TextStyle(color: friendzaMuted),
                          ),
                          const SizedBox(height: 22),
                          if (!isLogin) ...[
                            TextField(
                              controller: nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline_rounded),
                                hintText: 'Your full name',
                              ),
                            ),
                            const SizedBox(height: 13),
                          ],
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                              hintText: 'Email address',
                            ),
                          ),
                          const SizedBox(height: 13),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            onSubmitted: (_) => submit(),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                              hintText: 'Password (6+ characters)',
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: busy ? null : submit,
                            child: busy
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(isLogin ? 'Log In' : 'Create Account'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => setState(() => isLogin = !isLogin),
                            child: Text(
                              isLogin
                                  ? 'New to Friendza? Create an account'
                                  : 'Already have an account? Log in',
                              style: const TextStyle(
                                color: friendzaDarkGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'A little closer, wherever you are.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: friendzaMuted, fontSize: 13),
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

class FriendzaShell extends StatefulWidget {
  const FriendzaShell({super.key});

  @override
  State<FriendzaShell> createState() => _FriendzaShellState();
}

class _FriendzaShellState extends State<FriendzaShell> {
  int selectedIndex = 0;

  final pages = const [
    ChatsScreen(),
    FriendsScreen(),
    StoriesScreen(),
    ProfileScreen(),
  ];

  final titles = const ['Messages', 'Friends', 'Stories', 'Your profile'];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: friendzaGreen,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.forum_rounded, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[selectedIndex],
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: friendzaInk,
                  ),
                ),
                const Text(
                  'Your friends. Your conversations.',
                  style: TextStyle(fontSize: 11, color: friendzaMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) => setState(() => selectedIndex = value),
              labelType: NavigationRailLabelType.all,
              backgroundColor: const Color(0xFF181720),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: Text('Chats'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: Text('Friends'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome_rounded),
                  label: Text('Stories'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: Text('Profile'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(index: selectedIndex, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (value) => setState(() => selectedIndex = value),
        backgroundColor: const Color(0xFF181720),
        indicatorColor: const Color(0xFF3A2B52),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Stories',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const SectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                  color: friendzaInk,
                ),
              ),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(color: friendzaMuted)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final searchController = TextEditingController();
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> chats = [];

  @override
  void initState() {
    super.initState();
    loadChats();
    searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadChats() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final memberships = await supabase
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', user.id);
      final ids = memberships
          .map((row) => row['conversation_id'].toString())
          .toSet()
          .toList();

      final results = <Map<String, dynamic>>[];
      for (final id in ids) {
        final messageRows = await supabase
            .from('messages')
            .select('id, conversation_id, sender_id, content, message_type, created_at')
            .eq('conversation_id', id)
            .order('created_at', ascending: false)
            .limit(1);
        Map<String, dynamic>? lastMessage;
        if (messageRows.isNotEmpty) {
          lastMessage = Map<String, dynamic>.from(messageRows.first);
        }

        final members = await supabase
            .from('conversation_members')
            .select('user_id')
            .eq('conversation_id', id);
        final otherIds = members
            .map((row) => row['user_id'].toString())
            .where((memberId) => memberId != user.id)
            .toList();

        String name = 'Conversation';
        String? otherId;
        if (otherIds.isNotEmpty) {
          otherId = otherIds.first;
          final profile = await supabase
              .from('profiles')
              .select('full_name')
              .eq('id', otherId)
              .maybeSingle();
          final foundName = profile?['full_name']?.toString().trim();
          if (foundName != null && foundName.isNotEmpty) name = foundName;
        }
        results.add({
          'conversation_id': id,
          'name': name,
          'other_id': otherId,
          'last_message': lastMessage?['content']?.toString() ?? 'Say hello 👋',
          'created_at': lastMessage?['created_at']?.toString() ?? '',
          'message_type': lastMessage?['message_type']?.toString() ?? 'text',
        });
      }
      results.sort((a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()));
      if (mounted) setState(() => chats = results);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String timeLabel(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
    }
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visibleChats = chats.where((chat) {
      return chat['name'].toString().toLowerCase().contains(query) ||
          chat['last_message'].toString().toLowerCase().contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: loadChats,
      color: friendzaGreen,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [friendzaGreen, friendzaDarkGreen],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: friendzaGreen.withValues(alpha: .18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good conversations\nstart here.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'Welcome back, ${currentDisplayName().split(' ').first}!',
                        style: const TextStyle(color: Color(0xFFE9DFFF)),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 66,
                  width: 66,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeading(
            title: 'Your conversations',
            subtitle: 'Pick up right where you left off.',
            trailing: IconButton.filledTonal(
              onPressed: loadChats,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search your conversations',
            ),
          ),
          const SizedBox(height: 16),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(35),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            ErrorPanel(message: error!, onRetry: loadChats)
          else if (visibleChats.isEmpty)
              EmptyPanel(
                icon: Icons.chat_bubble_outline_rounded,
                title: query.isEmpty ? 'Your chats start here' : 'No chats found',
                message: query.isEmpty
                    ? 'Add a friend and start your first conversation. Your people are only a message away.'
                    : 'Try another name or keyword.',
                actionLabel: query.isEmpty ? 'Refresh chats' : null,
                onAction: query.isEmpty ? loadChats : null,
              )
            else
              ...visibleChats.map((chat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: friendzaCard,
                    borderRadius: BorderRadius.circular(21),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(21),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              conversationId: chat['conversation_id'].toString(),
                              friendName: chat['name'].toString(),
                              friendId: chat['other_id']?.toString(),
                            ),
                          ),
                        );
                        loadChats();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            FriendzaAvatar(name: chat['name'].toString(), size: 54),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chat['name'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: friendzaInk,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    chat['last_message'].toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: friendzaMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeLabel(chat['created_at'].toString()),
                              style: const TextStyle(
                                color: friendzaMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final String friendName;
  final String? friendId;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.friendName,
    this.friendId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final messageController = TextEditingController();
  final ScrollController messageScrollController = ScrollController();

  int? lastMessageCount;
  bool sending = false;

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    final user = supabase.auth.currentUser;
    if (text.isEmpty || user == null || sending) return;

    setState(() => sending = true);
    try {
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': user.id,
        'content': text,
        'message_type': 'text',
      });
      messageController.clear();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    messageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: friendzaBackground,
        title: Row(
          children: [
            FriendzaAvatar(name: widget.friendName, size: 42),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friendName,
                    style: const TextStyle(
                      color: friendzaInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Your Friendza conversation',
                    style: TextStyle(color: friendzaMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('conversation_id', widget.conversationId)
                  .order('created_at'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load messages: ${snapshot.error}'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const EmptyPanel(
                    icon: Icons.waving_hand_rounded,
                    title: 'Say hello!',
                    message: 'Send the first message and get the conversation going.',
                  );
                }

                if (lastMessageCount != messages.length) {
                  lastMessageCount = messages.length;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && messageScrollController.hasClients) {
                      messageScrollController.jumpTo(
                        messageScrollController.position.maxScrollExtent,
                      );
                    }
                  });
                }
                return ListView.builder(
                  controller: messageScrollController,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final mine = message['sender_id']?.toString() == userId;
                    final content = message['content']?.toString() ?? '';
                    final date = DateTime.tryParse(message['created_at']?.toString() ?? '')?.toLocal();
                    final time = date == null
                        ? ''
                        : '${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .76,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(15, 11, 15, 8),
                        decoration: BoxDecoration(
                          color: mine ? friendzaGreen : friendzaCard,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(19),
                            topRight: const Radius.circular(19),
                            bottomLeft: Radius.circular(mine ? 19 : 5),
                            bottomRight: Radius.circular(mine ? 5 : 19),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              content,
                              style: TextStyle(
                                color: mine ? const Color(0xFF171220) : friendzaInk,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(
                                color: mine ? const Color(0xFF3B3150) : friendzaMuted,
                                fontSize: 10,
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
          Container(
            color: const Color(0xFF181720),
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Write a message...',
                        prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: FilledButton(
                      onPressed: sending ? null : sendMessage,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: sending
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.send_rounded),
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

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final searchController = TextEditingController();
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> people = [];
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> sentRequests = [];
  bool showRequests = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
    loadFriends();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadFriends() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profiles = await supabase
          .from('profiles')
          .select('id, full_name')
          .neq('id', user.id)
          .order('full_name')
          .limit(100);
      final allProfiles = profiles.map((e) => Map<String, dynamic>.from(e)).toList();

      final requestRows = await supabase
          .from('friend_requests')
          .select('id, sender_id, receiver_id, status, created_at')
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}');
      final allRequests = requestRows.map((e) => Map<String, dynamic>.from(e)).toList();

      final acceptedIds = <String>{};
      for (final row in allRequests.where((r) => r['status'] == 'accepted')) {
        final sender = row['sender_id'].toString();
        final receiver = row['receiver_id'].toString();
        acceptedIds.add(sender == user.id ? receiver : sender);
      }
      final incoming = allRequests
          .where((r) => r['receiver_id'] == user.id && r['status'] == 'pending')
          .toList();
      final outgoing = allRequests
          .where((r) => r['sender_id'] == user.id && r['status'] == 'pending')
          .toList();

      final requestPeople = <Map<String, dynamic>>[];
      for (final request in incoming) {
        final person = allProfiles.where((p) => p['id'].toString() == request['sender_id'].toString()).firstOrNull;
        if (person != null) {
          requestPeople.add({...person, 'request_id': request['id']});
        }
      }
      final sentPeople = <Map<String, dynamic>>[];
      for (final request in outgoing) {
        final person = allProfiles.where((p) => p['id'].toString() == request['receiver_id'].toString()).firstOrNull;
        if (person != null) {
          sentPeople.add({...person, 'request_id': request['id']});
        }
      }
      if (mounted) {
        setState(() {
          people = allProfiles.where((p) => acceptedIds.contains(p['id'].toString())).toList();
          requests = requestPeople;
          sentRequests = sentPeople;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> sendRequest(String friendId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('friend_requests').insert({
        'sender_id': user.id,
        'receiver_id': friendId,
        'status': 'pending',
      });
      if (mounted) showSnack(context, 'Friend request sent!');
      await loadFriends();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  Future<void> answerRequest(String requestId, String status) async {
    try {
      await supabase.from('friend_requests').update({'status': status}).eq('id', requestId);
      await loadFriends();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  Future<void> startChat(Map<String, dynamic> person) async {
    try {
      final result = await supabase.rpc(
        'create_friend_conversation',
        params: {'friend_id': person['id'].toString()},
      );
      final conversationId = result.toString();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            conversationId: conversationId,
            friendName: person['full_name']?.toString() ?? 'Friend',
            friendId: person['id'].toString(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final query = searchController.text.trim().toLowerCase();
    final suggestions = <Map<String, dynamic>>[];
    // Search only profiles visible to the signed-in user. RLS must permit this
    // profile lookup for people to discover each other.
    if (query.isNotEmpty) {
      // People not already connected or involved in a pending request are shown
      // from the profile list loaded by this screen.
      // The search list is loaded separately below through loadSuggestions.
    }

    return RefreshIndicator(
      onRefresh: loadFriends,
      color: friendzaGreen,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeading(
            title: 'Your people',
            subtitle: 'Keep the people who matter close.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search friends by name',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FriendsTab(
                  label: 'Friends (${people.length})',
                  selected: !showRequests,
                  onTap: () => setState(() => showRequests = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FriendsTab(
                  label: 'Requests (${requests.length})',
                  selected: showRequests,
                  onTap: () => setState(() => showRequests = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            ErrorPanel(message: error!, onRetry: loadFriends)
          else if (showRequests)
              if (requests.isEmpty)
                const EmptyPanel(
                  icon: Icons.mark_email_read_outlined,
                  title: 'All caught up',
                  message: 'New friend requests will show up here.',
                )
              else
                ...requests.map((person) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PersonTile(
                    name: person['full_name']?.toString() ?? 'Friend',
                    subtitle: 'Wants to connect with you',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filled(
                          tooltip: 'Accept',
                          onPressed: () => answerRequest(person['request_id'].toString(), 'accepted'),
                          icon: const Icon(Icons.check_rounded),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Decline',
                          onPressed: () => answerRequest(person['request_id'].toString(), 'declined'),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                ))
            else ...[
                if (people.isEmpty)
                  const EmptyPanel(
                    icon: Icons.people_outline_rounded,
                    title: 'Your circle is growing',
                    message: 'When you and another person accept each other’s friend request, they will appear here.',
                  )
                else
                  ...people
                      .where((p) => p['full_name'].toString().toLowerCase().contains(query))
                      .map((person) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PersonTile(
                      name: person['full_name']?.toString() ?? 'Friend',
                      subtitle: 'Your Friendza friend',
                      trailing: IconButton.filledTonal(
                        onPressed: () => startChat(person),
                        tooltip: 'Message',
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                      ),
                    ),
                  )),
                if (sentRequests.isNotEmpty && query.isEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Requests sent',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: friendzaInk),
                  ),
                  const SizedBox(height: 10),
                  ...sentRequests.map((person) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PersonTile(
                      name: person['full_name']?.toString() ?? 'Friend',
                      subtitle: 'Request waiting for a reply',
                      trailing: const Icon(Icons.schedule_rounded, color: friendzaMuted),
                    ),
                  )),
                ],
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: OutlinedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (dialogContext) => const DiscoverFriendsDialog(),
                      ).then((_) => loadFriends()),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Find people on Friendza'),
                    ),
                  ),
              ],
          if (suggestions.isNotEmpty) const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class DiscoverFriendsDialog extends StatefulWidget {
  const DiscoverFriendsDialog({super.key});

  @override
  State<DiscoverFriendsDialog> createState() => _DiscoverFriendsDialogState();
}

class _DiscoverFriendsDialogState extends State<DiscoverFriendsDialog> {
  final searchController = TextEditingController();
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> results = [];
  Set<String> alreadyRequested = {};

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
    loadPeople();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadPeople() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final user = supabase.auth.currentUser!;
      final profiles = await supabase
          .from('profiles')
          .select('id, full_name')
          .neq('id', user.id)
          .order('full_name')
          .limit(100);
      final requests = await supabase
          .from('friend_requests')
          .select('sender_id, receiver_id, status')
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}');
      final excluded = <String>{};
      for (final row in requests) {
        final sender = row['sender_id'].toString();
        final receiver = row['receiver_id'].toString();
        excluded.add(sender == user.id ? receiver : sender);
      }
      final found = profiles
          .map((row) => Map<String, dynamic>.from(row))
          .where((row) => !excluded.contains(row['id'].toString()))
          .toList();
      if (mounted) setState(() => results = found);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> requestFriend(String friendId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('friend_requests').insert({
        'sender_id': user.id,
        'receiver_id': friendId,
        'status': 'pending',
      });
      if (mounted) {
        setState(() {
          alreadyRequested.add(friendId);
          results.removeWhere((person) => person['id'].toString() == friendId);
        });
        showSnack(context, 'Friend request sent.');
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visible = results.where((person) {
      return (person['full_name']?.toString() ?? '').toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      title: const Text('Find people'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search by full name',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 330,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(child: Text(error!))
                  : visible.isEmpty
                  ? const Center(
                child: Text(
                  'No people found. Ask your friend to create a Friendza account first.',
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final person = visible[index];
                  final id = person['id'].toString();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: FriendzaAvatar(
                      name: person['full_name']?.toString() ?? 'Friend',
                      size: 42,
                    ),
                    title: Text(person['full_name']?.toString() ?? 'Friend'),
                    trailing: IconButton.filledTonal(
                      onPressed: alreadyRequested.contains(id) ? null : () => requestFriend(id),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _FriendsTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FriendsTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? friendzaGreen : friendzaCard,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? const Color(0xFF171220) : friendzaInk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class PersonTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final Widget? trailing;

  const PersonTile({
    super.key,
    required this.name,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: friendzaCard,
        border: Border.all(color: const Color(0xFF393244)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          FriendzaAvatar(name: name, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: friendzaInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: friendzaMuted, fontSize: 12)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        SectionHeading(
          title: 'Stories',
          subtitle: 'Little moments from your circle.',
        ),
        SizedBox(height: 22),
        EmptyPanel(
          icon: Icons.auto_awesome_rounded,
          title: 'Stories are coming soon',
          message: 'This space is ready for photo and video updates from your friends. Story posting and viewing are not connected yet.',
        ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool saving = false;
  String? bio;
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      final metadataBio = user.userMetadata?['bio']?.toString();
      if (mounted) {
        setState(() {
          bio = metadataBio;
          loadingProfile = false;
        });
      }
      final name = profile?['full_name']?.toString();
      if (name != null && name.trim().isNotEmpty &&
          user.userMetadata?['full_name']?.toString() != name) {
        await supabase.auth.updateUser(
          UserAttributes(data: {...?user.userMetadata, 'full_name': name}),
        );
      }
    } catch (_) {
      if (mounted) setState(() => loadingProfile = false);
    }
  }

  Future<void> editProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profile = await supabase
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted) return;

    final nameController = TextEditingController(
      text: profile?['full_name']?.toString() ??
          user.userMetadata?['full_name']?.toString() ??
          '',
    );
    final bioController = TextEditingController(text: bio ?? '');
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit your profile'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  hintText: 'Full name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                maxLines: 3,
                maxLength: 120,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.edit_note_rounded),
                  hintText: 'A little about you',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true) {
      nameController.dispose();
      bioController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final newBio = bioController.text.trim();
    nameController.dispose();
    bioController.dispose();
    if (name.isEmpty) {
      if (mounted) showSnack(context, 'Please enter your name.');
      return;
    }

    setState(() => saving = true);
    try {
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            ...?user.userMetadata,
            'full_name': name,
            'bio': newBio,
          },
        ),
      );
      await supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': name,
      });
      if (mounted) {
        setState(() => bio = newBio);
        showSnack(context, 'Profile updated.');
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can log back in whenever you want.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await supabase.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final name = currentDisplayName();
    final email = user?.email ?? '';
    final displayBio = (bio ?? '').trim().isEmpty
        ? 'Make every conversation count.'
        : bio!.trim();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(
          title: 'Your profile',
          subtitle: 'A little space that is all yours.',
        ),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            color: friendzaCard,
            border: Border.all(color: const Color(0xFF393244)),
            borderRadius: BorderRadius.circular(27),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 25),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [friendzaGreen, friendzaDarkGreen],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xFF312743),
                        child: Text(
                          initials(name),
                          style: const TextStyle(
                            fontSize: 28,
                            color: friendzaDarkGreen,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFDDF6ED)),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        '✦  Friendza member',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      displayBio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: friendzaMuted, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: saving ? null : editProfile,
                      icon: saving
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.edit_rounded),
                      label: const Text('Edit profile'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'ACCOUNT',
          style: TextStyle(
            color: friendzaMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        _ProfileOption(
          icon: Icons.mail_outline_rounded,
          title: 'Email address',
          subtitle: email.isEmpty ? 'Not available' : email,
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Your email'),
              content: Text(email.isEmpty ? 'No email is available.' : email),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
        _ProfileOption(
          icon: Icons.shield_outlined,
          title: 'Privacy and security',
          subtitle: 'Security options are not configured yet',
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Privacy and security'),
              content: const Text(
                'This section is a placeholder. Privacy controls and account security tools still need to be implemented.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
        _ProfileOption(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Notification preferences are coming soon',
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Notifications'),
              content: const Text(
                'Push notifications and notification preferences are not connected yet.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
        _ProfileOption(
          icon: Icons.info_outline_rounded,
          title: 'About Friendza',
          subtitle: 'Your friends. Your conversations.',
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'Friendza',
            applicationVersion: '0.1.0',
            applicationLegalese: 'Your friends. Your conversations.',
            children: const [
              SizedBox(height: 12),
              Text('A place to keep in touch with the people who matter.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: logout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log out of Friendza'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB44747),
            side: const BorderSide(color: Color(0xFF40384F)),
          ),
        ),
        if (loadingProfile) ...[
          const SizedBox(height: 12),
          const Center(
            child: Text('Loading profile…', style: TextStyle(color: friendzaMuted, fontSize: 12)),
          ),
        ],
        const SizedBox(height: 25),
        const Text(
          'Made for your circle ✨',
          textAlign: TextAlign.center,
          style: TextStyle(color: friendzaMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: friendzaCard,
          border: Border.all(color: const Color(0xFF393244)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 4,
            ),
            leading: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF342743),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: friendzaDarkGreen),
            ),
            title: Text(
              title,
              style: const TextStyle(color: friendzaInk, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: friendzaMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: friendzaMuted),
          ),
        ),
      );
  }
}

class FriendzaAvatar extends StatelessWidget {
  final String name;
  final double size;

  const FriendzaAvatar({
    super.key,
    required this.name,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B2A55), Color(0xFF5A3A80)],
        ),
        borderRadius: BorderRadius.circular(size * .36),
      ),
      child: Text(
        initials(name),
        style: TextStyle(
          color: const Color(0xFFE9DFFF),
          fontWeight: FontWeight.w900,
          fontSize: size * .32,
        ),
      ),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
      decoration: BoxDecoration(
        color: friendzaCard,
        border: Border.all(color: const Color(0xFF393244)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF342743),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Icon(icon, color: friendzaDarkGreen, size: 31),
          ),
          const SizedBox(height: 17),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: friendzaInk,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: friendzaMuted, height: 1.5),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyPanel(
      icon: Icons.cloud_off_rounded,
      title: 'Could not load this page',
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}
