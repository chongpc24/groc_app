import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/account/account_screen.dart';
import 'features/search/explore_screen.dart';
import 'features/shopping_list/shopping_list_screen.dart';
import 'features/store/store_page.dart';
import 'models/product.dart';

const String supabaseUrl =
    'https://ztyngqmkgddgjkmrwsjk.supabase.co';

const String supabasePublishableKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp0eW5ncW1rZ2RkZ2prbXJ3c2prIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcxMDUzNTYsImV4cCI6MjEwMjY4MTM1Nn0.0P4FBZxtXe3wMQS9-q55UbJAUHFyxF_ePhyiYaOefzs';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GROC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme:
        InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const StartupGate(),
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() =>
      _StartupGateState();
}

class _StartupGateState
    extends State<StartupGate> {
  String _status =
      'Checking local data...';

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final hasData =
    await ProductRepository.hasLocalData();

    if (!mounted) {
      return;
    }

    if (!hasData) {
      setState(() {
        _status =
        'Downloading latest prices...';
      });

      try {
        final count =
        await ProductRepository.sync();

        if (!mounted) {
          return;
        }

        setState(() {
          _status =
          'Synced $count records';
        });
      } catch (error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _status =
          'Could not reach server: $error';
        });

        await Future.delayed(
          const Duration(seconds: 2),
        );

        if (!mounted) {
          return;
        }
      }
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
        const MainNavigation(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}

class MainNavigation
    extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState
    extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    ExploreScreen(),
    StorePage(),
    ShoppingListScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar:
      BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type:
        BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.storefront,
            ),
            label: 'Grocer',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.favorite_border,
            ),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
