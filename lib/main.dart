import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// AIテスト画面のインポート（同じフォルダーにある場合）
import 'ai_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // これで.envファイルが読み込まれます

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
      ),
      // 👇 ここを「MainNavigationScreen()」に戻します！
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // ⚠️ ここが重要です！
  // 2番目（インデックス1）の画面を、先ほど作った「AiTestScreen()」に差し替えます
  final List<Widget> _screens = [
    const Center(child: Text('ホーム画面')),
    const AiScreen(), // 👈 「AI支援」タブに先ほどのAI機能を組み込む！
    const Center(child: Text('ルーム画面')),
    const Center(child: Text('検索画面')),
    const Center(child: Text('比較画面')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index)git {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), selectedIcon: Icon(Icons.psychology), label: 'AI支援'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'ルーム'),
          NavigationDestination(icon: Icon(Icons.search), label: '検索'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '比較'),
        ],
      ),
    );
  }
}