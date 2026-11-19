// ======================================================================
// 【画面】設定
//
// 主なクラス: SettingsScreen
// 開き方: マイページの設定アイコン
// ・ダークモード（行のスイッチで、その場で切りかえる）
// ・学習記録の公開／非公開（行のスイッチで、その場で切りかえて保存する）
// ・使い方ガイド（tutorial_screen.dart を開く）
// ・ログアウト（確かめてから、サインアウトして初回登録画面へ）
// ・見た目はほかの画面とそろえて、白いカード（枠つき・角丸16）を並べる
// ・旧ファイル名: setting_screen.dart
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/main.dart'; // main.dart の isDarkModeNotifier を使う
import 'package:study_support_app/screens/start/welcome_screen.dart';
import 'package:study_support_app/screens/start/tutorial_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/error_dialog.dart';
import 'package:study_support_app/services/account_deleter.dart';
import 'package:study_support_app/services/google_account.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 学習記録を公開しているか
  bool _isPublic = true;

  // 公開設定を読み込み中か・保存中か
  bool _isLoadingPrivacy = true;
  bool _isSavingPrivacy = false;

  // 友達以外からのメッセージを受け取るか（users の allowNonFriendMessages。はじめはオフ）
  bool _allowMessages = false;
  bool _isSavingMessages = false;

  // ログアウトなど、危ない操作の赤
  static const Color _red = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _loadPrivacySetting();
  }

  // 友達以外からのメッセージの設定を、すぐに保存する
  // （失敗したときは、何も出さずにスイッチを元に戻す）
  Future<void> _setAllowMessages(bool value) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final previous = _allowMessages;

    setState(() {
      _allowMessages = value;
      _isSavingMessages = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'allowNonFriendMessages': value,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('メッセージの設定の保存に失敗しました: $e');

      if (mounted) setState(() => _allowMessages = previous);
    } finally {
      if (mounted) setState(() => _isSavingMessages = false);
    }
  }

  // ==============================================================
  // 公開設定の読み込み・保存
  // ==============================================================

  Future<void> _loadPrivacySetting() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = doc.data();

        if (data != null && mounted) {
          setState(() {
            if (data.containsKey('isPublic')) {
              _isPublic = data['isPublic'] == true;
            }
            _allowMessages = data['allowNonFriendMessages'] == true;
          });
        }
      }
    } catch (e) {
      debugPrint('公開設定の取得に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPrivacy = false;
        });
      }
    }
  }

  // スイッチを切りかえたら、すぐに保存する
  // （失敗したときは、スイッチを元に戻す）
  Future<void> _setPublic(bool value) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final previous = _isPublic;

    setState(() {
      _isPublic = value;
      _isSavingPrivacy = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isPublic': value,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('公開設定の保存に失敗しました: $e');

      if (!mounted) return;

      // スイッチが元に戻るので、それで保存できなかったことがわかる
      setState(() {
        _isPublic = previous;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPrivacy = false;
        });
      }
    }
  }

  // ==============================================================
  // ログアウト（確かめてから）
  // ==============================================================

  Future<void> _confirmLogout() async {
    final p = context.pal;

    // Google と連携していない（名前のないアカウントの）ときは、ログアウトすると
    // 二度と戻れない。そのため、ログアウトさせずに、先に連携をすすめる
    if (!GoogleAccount.isLinked) {
      final link = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: p.card,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              '先に Google と連携してください',
              style: TextStyle(
                color: p.text,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Google と連携していないため、今ログアウトすると、'
              'このアカウントには二度と戻れません。\n'
              '連携すると、「Google で続ける」から、いつでも戻れます。',
              style: TextStyle(color: p.secondary, fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('キャンセル', style: TextStyle(color: p.secondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'Google と連携する',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (link == true) await _linkGoogle();
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: p.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'ログアウトしますか？',
            style: TextStyle(
              color: p.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'もう一度使うときは、はじめの画面の「Google で続ける」から戻れます。',
            style: TextStyle(color: p.secondary, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('キャンセル', style: TextStyle(color: p.secondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'ログアウト',
                style: TextStyle(color: _red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await GoogleAccount.signOut();

      if (!mounted) return;

      // はじめの画面（ゲストか Google かをえらぶ）へ。それまでの画面は、すべて閉じる
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('ログアウトに失敗しました: $e');
      debugPrint(stackTrace.toString());
    }
  }

  // ==============================================================
  // Google と連携（今のアカウントとデータを、そのまま Google にひもづける）
  // ==============================================================

  bool _isLinking = false;

  Future<void> _linkGoogle() async {
    if (_isLinking) return;

    setState(() => _isLinking = true);

    try {
      await GoogleAccount.link();
    } on GoogleAccountException catch (e) {
      if (mounted) showErrorDialog(context, e.message);
    } catch (e) {
      debugPrint('Google と連携できませんでした: $e');
      if (mounted) {
        showErrorDialog(context, 'Google と連携できませんでした。\nもう一度お試しください。');
      }
    } finally {
      // 連携できたかどうかで、行の見た目が変わるので、描き直す
      if (mounted) setState(() => _isLinking = false);
    }
  }

  // ==============================================================
  // アカウントを削除（確かめてから。元に戻せない）
  // 消すものは account_deleter.dart
  // ==============================================================

  Future<void> _confirmDeleteAccount() async {
    final p = context.pal;

    // 自分のユーザーID（これを入れてもらってから消す。まちがって消さないように）
    String myUserId = '';
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        myUserId = (doc.data()?['userId'] ?? '').toString();
      }
    } catch (e) {
      debugPrint('ユーザーIDを読めませんでした: $e');
    }

    if (!mounted) return;

    if (myUserId.isEmpty) {
      showErrorDialog(context, 'アカウントの情報を読みこめませんでした。\n通信の状態を確かめて、もう一度お試しください。');
      return;
    }

    // 入力欄の「@」は自動でつく。自分で「@」を打っても、同じにあつかう
    String normalize(String text) {
      final t = text.trim();
      return t.replaceFirst(RegExp(r'^@+'), '');
    }

    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final matched = normalize(controller.text) == normalize(myUserId);

            return AlertDialog(
              backgroundColor: p.card,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'アカウントを削除',
                style: TextStyle(
                  color: p.text,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '学習記録・友達・チャット・AIの履歴・作ったルームなど、'
                    'すべてのデータが消えます。消したデータは、元に戻せません。',
                    style: TextStyle(
                      color: p.secondary,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    // ユーザーIDそのものは出さない（自分で思い出して入れてもらう）
                    '確かめのため、あなたのユーザーIDを入れてください',
                    style: TextStyle(
                      color: p.text,
                      fontSize: 13.5,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    style: TextStyle(color: p.text, fontSize: 15),
                    decoration: InputDecoration(
                      // はじめから「@」を出しておく（自分で打たなくてよい）
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 2),
                        child: Text(
                          '@',
                          style: TextStyle(
                            color: p.secondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: p.field,
                      // 「@」のすぐ右から文字が始まるよう、左の余白は小さく
                      contentPadding: const EdgeInsets.fromLTRB(2, 12, 12, 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _red, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text('キャンセル', style: TextStyle(color: p.secondary)),
                ),
                // ユーザーIDが合ったときだけ押せる
                TextButton(
                  onPressed: matched
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  child: Text(
                    '削除する',
                    style: TextStyle(
                      color: matched ? _red : p.muted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // 閉じるうごきが終わってから片付ける（すぐ片付けると、閉じる途中の入力欄がこわれる）
    Future.delayed(const Duration(milliseconds: 400), controller.dispose);

    if (ok != true || !mounted) return;

    // 消している間は、くるくるを出して、ほかの操作をできなくする
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );

    try {
      final deleted = await AccountDeleter.deleteMyAccount();

      if (!mounted) return;

      // Google の本人確認を閉じたときは、何も消さずに戻る
      if (!deleted) {
        Navigator.of(context).pop();
        return;
      }

      // はじめの画面（ゲストか Google かをえらぶ）へ。それまでの画面は、すべて閉じる
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('アカウントの削除に失敗しました: $e');
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      // くるくるを閉じてから知らせる
      Navigator.of(context).pop();

      showErrorDialog(
        context,
        e is GoogleAccountException
            ? e.message
            : 'アカウントを削除できませんでした。\n通信の状態を確かめて、もう一度お試しください。',
      );
    }
  }

  // ==============================================================
  // 共通の部品
  // ==============================================================

  // うすい青の角丸の四角にのせたアイコン（Link のメニューと同じ形）
  Widget _iconBox(IconData icon, {double size = 40, Color? color}) {
    final p = context.pal;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color == null ? p.primarySoft : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Icon(icon, size: size * 0.55, color: color ?? AppColors.primary),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: context.pal.secondary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card(List<Widget> rows) {
    final p = context.pal;

    final children = <Widget>[];

    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);

      if (i != rows.length - 1) {
        children.add(
          Divider(height: 1, thickness: 1, indent: 68, color: p.divider),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(children: children),
        ),
      ),
    );
  }

  // 設定の1行（左にアイコン、まん中に名前と説明、右にスイッチか「>」）
  Widget _row({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    final p = context.pal;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _iconBox(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color ?? p.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: p.secondary, fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _switch(bool value, ValueChanged<bool>? onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.primary,
    );
  }

  // ==============================================================
  // build
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    // ダークモードを切りかえたら、この画面もすぐ描き直す
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        final p = context.pal;

        return Scaffold(
          backgroundColor: p.page,
          appBar: AppBar(
            title: Transform.translate(
              offset: const Offset(-18, 0),
              child: Text(
                '設定',
                style: TextStyle(
                  color: p.text,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: p.card,
            iconTheme: IconThemeData(color: p.text),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(17, 18, 17, 32),
            children: [
              // ------------------------------------------
              // アプリの設定
              // ------------------------------------------
              _sectionTitle('アプリの設定'),
              _card([
                _row(
                  icon: Icons.dark_mode_outlined,
                  title: 'ダークモード',
                  subtitle: isDark ? '暗い色の画面にしています' : '明るい色の画面にしています',
                  trailing: _switch(
                    isDark,
                    (value) => isDarkModeNotifier.value = value,
                  ),
                  onTap: () => isDarkModeNotifier.value = !isDark,
                ),
                _row(
                  icon: _isPublic
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  title: '学習記録を公開する',
                  subtitle: _isLoadingPrivacy
                      ? '読み込み中…'
                      : (_isPublic
                            ? '他のユーザーも、あなたの学習記録を見られます'
                            : '学習記録は、あなただけが見られます'),
                  trailing: _switch(
                    _isPublic,
                    (_isLoadingPrivacy || _isSavingPrivacy) ? null : _setPublic,
                  ),
                  onTap: (_isLoadingPrivacy || _isSavingPrivacy)
                      ? null
                      : () => _setPublic(!_isPublic),
                ),
                _row(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: '友達以外からのメッセージ',
                  subtitle: _isLoadingPrivacy
                      ? '読み込み中…'
                      : (_allowMessages
                            ? '友達でない人も、あなたにメッセージを送れます'
                            : 'メッセージを送れるのは、友達だけです'),
                  trailing: _switch(
                    _allowMessages,
                    (_isLoadingPrivacy || _isSavingMessages)
                        ? null
                        : _setAllowMessages,
                  ),
                  onTap: (_isLoadingPrivacy || _isSavingMessages)
                      ? null
                      : () => _setAllowMessages(!_allowMessages),
                ),
              ]),

              const SizedBox(height: 24),

              // ------------------------------------------
              // アプリについて
              // ------------------------------------------
              _sectionTitle('アプリについて'),
              _card([
                _row(
                  icon: Icons.help_outline_rounded,
                  title: '使い方ガイド',
                  subtitle: 'それぞれの画面でできること',
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: p.muted,
                    size: 24,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TutorialScreen(fromSettings: true),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // ------------------------------------------
              // アカウント
              // ------------------------------------------
              _sectionTitle('アカウント'),
              _card([
                // Google と連携（連携ずみなら、メールアドレスを出すだけ）
                if (GoogleAccount.isLinked)
                  _row(
                    icon: Icons.verified_user_outlined,
                    title: 'Google と連携ずみ',
                    subtitle: GoogleAccount.email.isNotEmpty
                        ? GoogleAccount.email
                        : '機種を変えても、「Google で続ける」で戻れます',
                  )
                else
                  _row(
                    icon: Icons.link_rounded,
                    title: 'Google と連携',
                    subtitle: '機種を変えても、データを引きつげるようにします',
                    onTap: _isLinking ? null : _linkGoogle,
                    trailing: _isLinking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                _row(
                  icon: Icons.logout_rounded,
                  title: 'ログアウト',
                  color: _red,
                  onTap: _confirmLogout,
                ),
                _row(
                  icon: Icons.person_remove_outlined,
                  title: 'アカウントを削除',
                  subtitle: 'すべてのデータを消して、アプリをやめます',
                  color: _red,
                  onTap: _confirmDeleteAccount,
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}
