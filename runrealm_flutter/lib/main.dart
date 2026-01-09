import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'services/firebase_service.dart';
import 'screens/home_screen.dart';
import 'screens/run_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/clubs_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/territory_screen.dart';
import 'screens/create_group_screen.dart';
import 'theme/futuristic_theme.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await FirebaseService.initialize();
  final authProvider = AuthProvider();
  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  late final GoRouter _router;

  MyApp({required this.authProvider}) {
    _router = GoRouter(
      refreshListenable: authProvider,
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(path: '/', builder: (context, state) => HomeScreen()),
            GoRoute(path: '/run', builder: (context, state) => RunScreen()),
            GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
            GoRoute(path: '/history', builder: (context, state) => HistoryScreen()),
            GoRoute(path: '/clubs', builder: (context, state) => ClubsScreen()),
            GoRoute(path: '/clubs', builder: (context, state) => ClubsScreen()),
            GoRoute(path: '/feed', builder: (context, state) => FeedScreen()),
            GoRoute(path: '/territory', builder: (context, state) => TerritoryScreen()),
            GoRoute(path: '/create-group', builder: (context, state) => CreateGroupScreen()),
          ],
        ),
        GoRoute(path: '/setup', builder: (context, state) => SetupScreen()),
      ],
      redirect: (context, state) {
        if (!authProvider.authReady) return null;
        if (authProvider.user == null) {
          authProvider.signInAnonymously();
          return null;
        }
        if (!authProvider.profileReady) return null;
        if (authProvider.setupComplete == false) return '/setup';
        
        // If we are in setup but setup is complete, go home
        if (state.matchedLocation == '/setup' && authProvider.setupComplete == true) {
          return '/';
        }
        
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: MaterialApp.router(
        routerConfig: _router,
        title: 'RunRealm',
        theme: FuturisticTheme.themeData,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final Widget child;
  MainScaffold({required this.child});

  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    RunScreen(),
    ProfileScreen(),
    HistoryScreen(),
    ClubsScreen(),
    FeedScreen(),
    TerritoryScreen(),
  ];

  final List<String> _routes = ['/', '/run', '/profile', '/history', '/clubs', '/feed', '/territory'];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    GoRouter.of(context).go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for glass effect over body
      body: widget.child,
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A24).withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.groups), label: ''), // Changed to groups
              BottomNavigationBarItem(icon: Icon(Icons.dynamic_feed), label: ''), // Changed to dynamic_feed
              BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent, // Transparent to show container
            elevation: 0,
            selectedItemColor: FuturisticTheme.primaryCyan,
            unselectedItemColor: Colors.grey.withOpacity(0.5),
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
          ),
        ),
      ),
    );
  }
}
