import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';
import 'ai_screen.dart';
import 'friends_screen/friends_screen.dart';
import 'record_screen.dart';
import 'mypage_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Study Support App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        textTheme: GoogleFonts.notoSansJpTextTheme(),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AiScreen(),
    const FriendsScreen(),
    const RecordScreen(),
    const MypageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },

            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,

            selectedItemColor:const Color(0xFF3B82F6),
            unselectedItemColor: const Color(0xFF616161),

            selectedFontSize: 12,
            unselectedFontSize: 12,

            selectedLabelStyle: GoogleFonts.notoSansJp(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
            unselectedLabelStyle: GoogleFonts.notoSansJp(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),

            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'ホーム',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome),
                label: 'AIサポート',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.diversity_3_outlined),
                activeIcon: Icon(Icons.diversity_3),
                label: '学習仲間',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: '学習記録',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'マイページ',
              ),
            ],
          ),
        ),
    );
  }
}