import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen_folder/home_screen.dart';
import 'ai_screen_folder/ai_screen.dart';
import 'link_screen_folder/link_screen.dart';
import 'record_screen_folder/record_screen.dart';
import 'mypage_screen_folder/mypage_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'splash_screen.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'timer_service.dart';

// アプリ全体で共有するダークモードの状態変数（初期値: false = ライト）
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);

// 目標時間も共有できるように保持
final ValueNotifier<double> dailyTargetHours = ValueNotifier<double>(0.0);

// 今日の学習時間
final ValueNotifier<int> todayStudySeconds = ValueNotifier<int>(0);

// 今週の学習時間
final ValueNotifier<int> weeklyStudySeconds = ValueNotifier<int>(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    FlutterForegroundTask.initCommunicationPort();
  }

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    initForegroundService();
  }

  runApp(const MyApp());
}

void initForegroundService() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'study_timer',
      channelName: '学習タイマー',
      channelDescription: '学習タイマーの実行状況を表示します。',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(250),
      stopWithTask: false,
      allowWakeLock: true,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilderでアプリ全体（MaterialApp）を囲み、
    // ダークモードが切り替わった瞬間にアプリ全体を再ビルドして黒ベースに反映させます
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Study Support App',

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          supportedLocales: const [Locale('ja')],

          // ライト用テーマとダーク用テーマを切り替える設定
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          // ライトモード時のテーマ
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFFF7F7F7),
            brightness: Brightness.light,
            textTheme: GoogleFonts.notoSansJpTextTheme(),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color(0xFF2196F3),
              selectionColor: Color(0x552196F3),
              selectionHandleColor: Color(0xFF2196F3),
            ),
          ),

          // ダークモード時（黒ベース）のテーマ
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            // 全体の背景を黒ベースに

            // ダークモード時のボトムナビゲーションの色を統一
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              selectedItemColor: Color(0xFF3D96E8),
              unselectedItemColor: Colors.white60,
            ),

            textTheme: GoogleFonts.notoSansJpTextTheme(
              ThemeData.dark().textTheme, // ダークモード用の文字色を適用
            ),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color(0xFF2196F3),
              selectionColor: Color(0x552196F3),
              selectionHandleColor: Color(0xFF2196F3),
            ),
          ),

          home: const SplashScreen(),
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

  late AnimationController _controller;
  late Animation<double> _animation;
  int _animatedIndex = -1;

  List<Widget> get _screens => [
    const HomeScreen(),

    const AiScreen(),
    const LinkScreen(),
    const RecordScreen(),
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

  @override
  Widget build(BuildContext context) {
    // Flutterのテーマから現在の明るさを直接取得（確実に連動します）
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Material(
        color: barColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
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
                  navItem(
                    icon: Icons.home,
                    label: "ホーム",
                    index: 0,
                    isDark: isDark,
                  ),
                  navItem(
                    icon: Icons.auto_awesome,
                    label: "AIサポート",
                    index: 1,
                    isDark: isDark,
                  ),
                  navItem(
                    icon: Icons.diversity_3,
                    label: "Link",
                    index: 2,
                    isDark: isDark,
                  ),
                  navItem(
                    icon: Icons.bar_chart,
                    label: "学習記録",
                    index: 3,
                    isDark: isDark,
                  ),
                  navItem(
                    icon: Icons.person,
                    label: "マイページ",
                    index: 4,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget navItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final selected = _selectedIndex == index;

    // 選択中・非選択中の色をダークモードに応じて分岐
    final selectedColor = const Color(0xFF3D96E8);
    final unselectedColor = isDark ? Colors.white60 : const Color(0xFFB5B5B5);
    final unselectedTextCol = isDark ? Colors.white60 : const Color(0xFF9E9E9E);

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
                  color: selected ? selectedColor : unselectedColor,
                ),
              ),
              const SizedBox(height: 0),
              Text(
                label,
                style: GoogleFonts.notoSansJp(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  color: selected ? selectedColor : unselectedTextCol,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
