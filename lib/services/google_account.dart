// ======================================================================
// 【しくみ】Google アカウントでのログイン・連携
//
// 主な関数: GoogleAccount.link / signIn / reauthenticate / signOut
// 使う画面: settings_screen.dart（Google と連携）
//           welcome_screen.dart（Google で続ける）
//           account_deleter.dart（アカウントを消す前の確認）
//
// ・はじめは、名前のないアカウント（匿名ログイン）で使いはじめる
// ・「Google と連携」すると、今のアカウント（データ）をそのまま Google にひもづける
//   → ログアウトしたり、機種を変えたりしても、Google でログインすれば戻れる
// ・うまくいかなかったときは、画面に出す日本語の文を GoogleAccountException で返す
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAccount {
  GoogleAccount._();

  static bool _initialized = false;

  // 今のアカウントが Google と連携ずみか
  static bool get isLinked {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  // 連携している Google アカウントのメールアドレス（なければ空）
  static String get email {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    for (final p in user.providerData) {
      if (p.providerId == 'google.com') return p.email ?? '';
    }
    return user.email ?? '';
  }

  // Google のアカウントをえらんでもらい、Firebase で使える形にする
  // えらばずに閉じたときは null
  static Future<AuthCredential?> _pickGoogleAccount() async {
    try {
      final signIn = GoogleSignIn.instance;

      if (!_initialized) {
        await signIn.initialize();
        _initialized = true;
      }

      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        throw const GoogleAccountException('Google のログインに失敗しました。もう一度お試しください。');
      }

      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      debugPrint('Google のログインに失敗しました: $e');
      throw const GoogleAccountException('Google のログインに失敗しました。もう一度お試しください。');
    }
  }

  // 今のアカウントを、Google にひもづける（データはそのまま）
  // 連携できたら true、えらばずに閉じたら false
  static Future<bool> link() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final credential = await _pickGoogleAccount();
    if (credential == null) return false;

    try {
      await user.linkWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google と連携できませんでした: ${e.code} $e');

      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        throw const GoogleAccountException(
          'この Google アカウントは、別のアカウントですでに使われています。\n'
          'ほかの Google アカウントをえらんでください。',
        );
      }
      if (e.code == 'provider-already-linked') return true;

      throw const GoogleAccountException('Google と連携できませんでした。もう一度お試しください。');
    }
  }

  // Google でログインする（前に連携したアカウントに戻る）
  // 戻ったアカウントが登録ずみなら true（そのままアプリを使える）、
  // まだ登録していない Google アカウントなら false（はじめの登録をしてもらう）
  // えらばずに閉じたときは null
  static Future<bool?> signIn() async {
    final credential = await _pickGoogleAccount();
    if (credential == null) return null;

    final auth = FirebaseAuth.instance;

    try {
      // 今の名前のないアカウントが、まだ登録前（データなし）なら、消してから移る
      // （使われないアカウントが残らないように）
      final current = auth.currentUser;
      if (current != null && current.isAnonymous) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(current.uid)
            .get();
        if (!doc.exists) {
          try {
            await current.delete();
          } catch (e) {
            debugPrint('使わないアカウントを消せませんでした: $e');
          }
        }
      }

      final result = await auth.signInWithCredential(credential);
      final uid = result.user?.uid;
      if (uid == null) return false;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return userDoc.exists;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google でログインできませんでした: ${e.code} $e');
      throw const GoogleAccountException('Google でログインできませんでした。もう一度お試しください。');
    }
  }

  // アカウントを消す前など、本人かをもう一度確かめる（Google と連携している人だけ）
  // 確かめられたら true、えらばずに閉じたら false
  // ・ログイン中のアカウントを、そのまま使う（アカウントをえらぶ画面は、なるべく出さない）
  // ・えらぶ画面が出たときも、ログイン中のアカウント以外はえらべない（ほかの人を消さない）
  static Future<bool> reauthenticate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !isLinked) return true;

    final expected = email.toLowerCase();
    final signIn = GoogleSignIn.instance;

    GoogleSignInAccount? account;

    try {
      if (!_initialized) {
        await signIn.initialize();
        _initialized = true;
      }

      // まずは、画面を出さずに、今のアカウントで確かめる
      account = await signIn.attemptLightweightAuthentication();

      // だめだったら（または別のアカウントだったら）、えらぶ画面を出す
      if (account == null ||
          (expected.isNotEmpty && account.email.toLowerCase() != expected)) {
        account = await signIn.authenticate();
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      debugPrint('本人の確認に失敗しました: $e');
      throw const GoogleAccountException('本人の確認ができませんでした。もう一度お試しください。');
    }

    // ログイン中のアカウントと違うものは、使わない
    if (expected.isNotEmpty && account.email.toLowerCase() != expected) {
      throw GoogleAccountException(
        'ログイン中のアカウント（$email）をえらんでください。\n'
        'ほかのアカウントは、ここでは削除できません。',
      );
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const GoogleAccountException('本人の確認ができませんでした。もう一度お試しください。');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    try {
      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('本人の確認に失敗しました: ${e.code} $e');
      throw const GoogleAccountException(
        '本人の確認ができませんでした。\nこのアカウントと連携している Google アカウントをえらんでください。',
      );
    }
  }

  // ログアウト（次にログインするとき、Google のアカウントをえらびなおせるようにする）
  static Future<void> signOut() async {
    try {
      if (_initialized) await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google からのログアウトに失敗しました: $e');
    }
    await FirebaseAuth.instance.signOut();
  }
}

// Google のログイン・連携ができなかったとき。message は、そのまま画面に出せる日本語の文
class GoogleAccountException implements Exception {
  final String message;

  const GoogleAccountException(this.message);

  @override
  String toString() => message;
}
