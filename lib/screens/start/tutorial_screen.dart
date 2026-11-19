// ======================================================================
// 【画面】はじめての人向けのアプリの使い方（チュートリアル）
//
// 主なクラス: TutorialScreen
// 開き方: 初回登録画面（onboarding_screen.dart）で「保存してはじめる」を押したあと
//         設定画面（settings_screen.dart）の「使い方ガイド」
// ・設定から開いたときは、最後まで見るか「閉じる」で、設定画面へ戻る
// ・横にめくって、下のタブ（ホーム／AIサポート／Link／学習記録／マイページ）を順に紹介する
// ・「スキップ」か最後の「はじめる」で、メイン画面へ進む
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/main.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';

class TutorialScreen extends StatefulWidget {
  // 設定画面から開いたとき true（終わったらメイン画面へ進まず、もとの画面へ戻る）
  final bool fromSettings;

  const TutorialScreen({super.key, this.fromSettings = false});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

// 1ページ分の中身
class _TutorialPage {
  final IconData icon;
  final String tabName;
  final String title;
  final List<String> points;

  const _TutorialPage({
    required this.icon,
    required this.tabName,
    required this.title,
    required this.points,
  });
}

const _pages = [
  _TutorialPage(
    icon: Icons.menu_book_rounded,
    tabName: "ようこそ",
    title: "勉強を、記録して、\nみんなと続けよう",
    points: [
      "勉強した時間をはかって、自動で記録します",
      "AIに質問したり、友達と比べたりできます",
      "画面の下のタブで、5つの画面を切りかえます",
    ],
  ),
  _TutorialPage(
    icon: Icons.home,
    tabName: "ホーム",
    title: "タイマーで\n勉強時間をはかる",
    points: [
      "スタートを押すと、勉強時間をはかりはじめます",
      "1日の目標時間を、曜日ごとに決められます",
      "今日どれだけ進んだかが、ひと目でわかります",
    ],
  ),
  _TutorialPage(
    icon: Icons.auto_awesome,
    tabName: "AIサポート",
    title: "わからないことは\nAIに聞く",
    points: ["勉強でわからないところを、AIに質問できます", "前の会話は、履歴からいつでも見返せます"],
  ),
  _TutorialPage(
    icon: Icons.diversity_3,
    tabName: "Link",
    title: "ほかの人と\nつながる",
    points: [
      "名前やユーザーIDで、ほかの人を探せます",
      "Q&Aやルームで、ほかの人と交流できます",
      "友達になると、チャットでやりとりできます",
    ],
  ),
  _TutorialPage(
    icon: Icons.bar_chart,
    tabName: "学習記録",
    title: "がんばりを\nグラフで見る",
    points: ["週・月・年ごとに、勉強した時間をグラフで見られます", "全体の平均や友達と、勉強時間を比べられます"],
  ),
  _TutorialPage(
    icon: Icons.person,
    tabName: "マイページ",
    title: "自分のプロフィールと\n友達",
    points: [
      "プロフィールやアイコンを、あとから変えられます",
      "友達の一覧や、自分の勉強の分析を見られます",
      "ダークモードなどは、右上の設定から変えられます",
    ],
  ),
];

class _TutorialScreenState extends State<TutorialScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 終わったとき：はじめての人はメイン画面へ進む（この画面には戻れないように置きかえる）
  // 設定から開いたときは、設定画面へ戻る
  void _finish() {
    if (widget.fromSettings) {
      Navigator.of(context).pop();
      return;
    }

    // それまでの画面は、すべて閉じてからホームへ（上の帯に「←」が出ないように）
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (_) => false,
    );
  }

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      backgroundColor: p.page,
      body: SafeArea(
        child: Column(
          children: [
            // 右上の「スキップ」（最後のページでは出さない）
            SizedBox(
              height: 52,
              child: Align(
                alignment: Alignment.centerRight,
                child: _isLastPage
                    ? null
                    : TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: p.secondary,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: Text(
                          widget.fromSettings ? "閉じる" : "スキップ",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
              ),
            ),

            // めくるページ
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) =>
                    _buildPage(_pages[index], index),
              ),
            ),

            // 今どのページかを表す点
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final isCurrent = index == _currentPage;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isCurrent ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary
                        : (p.isDark ? Colors.white24 : AppColors.primaryTrack),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            // 「次へ」／「はじめる」
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    _isLastPage ? (widget.fromSettings ? "閉じる" : "はじめる") : "次へ",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 1ページ分
  // ============================================================

  Widget _buildPage(_TutorialPage page, int index) {
    final p = context.pal;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // 大きなアイコン（うすい青の丸）
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: p.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, color: AppColors.primary, size: 64),
          ),

          const SizedBox(height: 24),

          // タブの名前（最初のページ以外は「何番目のタブか」も出す）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              index == 0 ? page.tabName : "下のタブ「${page.tabName}」",
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.text,
              fontSize: 23,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 22),

          // できること（白いカードに並べる）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < page.points.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          page.points[i],
                          style: TextStyle(
                            color: p.text,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
