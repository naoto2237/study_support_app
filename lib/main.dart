import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen_folder/home_screen.dart';
import 'ai_screen_folder/ai_screen.dart';
import 'link_screen_folder/link_screen.dart';
import 'record_screen_folder/record_screen.dart';
import 'mypage_screen_folder/mypage_screen.dart';

import 'package:study_support_app/setting_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Study Support App',

          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          // ライトモード時のテーマ
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepPurple,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF7F7F7),
            canvasColor: const Color(0xFFF7F7F7),
            textTheme: GoogleFonts.notoSansJpTextTheme(),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color(0xFF2196F3),
              selectionColor: Color(0x552196F3),
              selectionHandleColor: Color(0xFF2196F3),
            ),
          ),

          // ダークモード時のテーマ（アプリ全体を確実に黒くする設定）
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepPurple,
            brightness: Brightness.dark,
            // ★ アプリ全体の背景を真っ黒（またはダークグレー）に強制
            scaffoldBackgroundColor: const Color(0xFF121212),
            canvasColor: const Color(0xFF121212),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
            cardColor: const Color(0xFF1E1E1E),
            textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData.dark().textTheme),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color(0xFF2196F3),
              selectionColor: Color(0x552196F3),
              selectionHandleColor: Color(0xFF2196F3),
            ),
          ),

          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  int todayTotalSeconds = 0;

  late AnimationController _controller;
  late Animation<double> _animation;
  int _animatedIndex = -1;

  List<Widget> get _screens => [
    HomeScreen(
      onStudyFinished: (seconds) {
        setState(() {
          todayTotalSeconds += seconds;
        });
      },
    ),
    const AiScreen(),
    const LinkScreen(),
    RecordScreen(totalSeconds: todayTotalSeconds),
    const MypageScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 77),
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
      _animatedIndex = index;
    });

    _controller.forward(from: 0);
  }

  Widget navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => _changeTab(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animatedIndex == index ? _animation.value : 1.0,
              child: child,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  icon,
                  size: 27,
                  color: selected
                      ? const Color(0xFF3D96E8)
                      : (isDark ? Colors.grey.shade500 : const Color(0xFFB5B5B5)),
                ),
              ),
              const SizedBox(height: 0),
              Text(
                label,
                style: GoogleFonts.notoSansJp(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  color: selected
                      ? const Color(0xFF3D96E8)
                      : (isDark ? Colors.grey.shade400 : const Color(0xFF9E9E9E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                navItem(icon: Icons.home, label: "ホーム", index: 0),
                navItem(icon: Icons.auto_awesome, label: "AIサポート", index: 1),
                navItem(icon: Icons.diversity_3, label: "Link", index: 2),
                navItem(icon: Icons.bar_chart, label: "学習記録", index: 3),
                navItem(icon: Icons.person, label: "マイページ", index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}