import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'injection_container.dart' as di;
import 'core/theme/theme_notifier.dart';
import 'core/presentation/theme_switch_floating_button.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/recording/presentation/recorder_page.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/domain/profile_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const HuntingCallsApp());
}

class HuntingCallsApp extends StatelessWidget {
  const HuntingCallsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'Hunting Calls Perfection',
            theme: themeNotifier.currentTheme,
            home: const AuthWrapper(),
            builder: (context, child) {
               // Global Overlay for Theme Switcher could go here, 
               // but FloatingActionButton is requested on screens.
               return child!;
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? userId;

  @override
  void initState() {
    super.initState();
    di.sl<AuthRepository>().onAuthStateChanged.listen((user) {
      setState(() {
        userId = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const LoginScreen();
    }
    return HomeScreen(userId: userId!);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<UserProfile> profiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final allProfiles = await di.sl<ProfileRepository>().getAllProfiles();
    if (mounted) {
      setState(() {
        profiles = allProfiles;
        isLoading = false;
      });
    }
  }

  Future<void> _createNewProfile() async {
    String? name = await showDialog<String>(
      context: context,
      builder: (context) {
        String value = '';
        return AlertDialog(
          title: const Text('New Hunter Profile'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Hunter Name'),
            onChanged: (v) => value = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, value),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      setState(() => isLoading = true);
      final profile = await di.sl<ProfileRepository>().createProfile(name);
      await di.sl<AuthRepository>().signIn(profile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.forest, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              Text('Hunting Calls', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              const Text('Select Your Profile', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              
              if (isLoading)
                const CircularProgressIndicator()
              else if (profiles.isEmpty)
                 const Text("No profiles found. Create one to start.")
              else
                ...profiles.map((p) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(p.name[0].toUpperCase())),
                    title: Text(p.name),
                    subtitle: Text("${p.totalCalls} calls • ${p.averageScore.toStringAsFixed(1)}% avg"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => di.sl<AuthRepository>().signIn(p.id),
                  ),
                )),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Create New Profile'),
                onPressed: _createNewProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Handler";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final profile = await di.sl<ProfileRepository>().getProfile(widget.userId);
    if (mounted) {
      setState(() {
        userName = profile.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
               Navigator.of(context).push(
                 MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.userId)),
               );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => di.sl<AuthRepository>().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, $userName!', style: Theme.of(context).textTheme.headlineSmall),
            Text('ID: ${widget.userId}', style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text('Record Call'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RecorderPage(userId: widget.userId)),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: const ThemeSwitchFloatingButton(),
    );
  }
}

