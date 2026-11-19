// ======================================================================
// 【画面】共有ノートを読む・書く・直す
//
// 主なクラス: RoomNoteEditScreen
// 開き方: 共有ノートの一覧（room_share_note_screen.dart）でノートを押す／「＋」を押す
// ・noteId が null のときは新しいノート、あるときはそのノートを読みこんで直す
// ・右上の「保存」で rooms/{id}/notes に保存して、一覧へ戻る
// ・書きかけのまま戻ろうとしたら、保存しないで戻るか確かめる
// ・右上のごみ箱：ノートを作った人だけに出す（確かめてから消す）
// ・失敗したときは、小さな画面で知らせる（下に出る短いお知らせは使わない）
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';

class RoomNoteEditScreen extends StatefulWidget {
  final String roomId;
  final String? noteId;

  const RoomNoteEditScreen({super.key, required this.roomId, this.noteId});

  @override
  State<RoomNoteEditScreen> createState() => _RoomNoteEditScreenState();
}

class _RoomNoteEditScreenState extends State<RoomNoteEditScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  late final CollectionReference<Map<String, dynamic>> _notes =
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('notes');

  bool get _isNew => widget.noteId == null;

  // 読みこんだときの中身（書きかえたかどうかを比べるため）
  String _savedTitle = '';
  String _savedBody = '';

  // ノートを作った人（ごみ箱を出すかどうか）
  String _createdBy = '';
  String _createdByName = '';

  bool _isLoading = false;
  bool _isSaving = false;
  bool _loadFailed = false;

  bool get _isDirty =>
      _titleController.text != _savedTitle ||
      _bodyController.text != _savedBody;

  bool get _canSave =>
      !_isSaving &&
      _isDirty &&
      (_titleController.text.trim().isNotEmpty ||
          _bodyController.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();

    // 書きかえるたびに、「保存」が押せるかどうかを出し直す
    _titleController.addListener(_onChanged);
    _bodyController.addListener(_onChanged);

    if (!_isNew) _load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    try {
      final doc = await _notes.doc(widget.noteId).get();
      final data = doc.data();

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
        return;
      }

      _savedTitle = (data['title'] ?? '').toString();
      _savedBody = (data['body'] ?? '').toString();
      _createdBy = (data['createdBy'] ?? '').toString();
      _createdByName = (data['createdByName'] ?? '').toString();
      _titleController.text = _savedTitle;
      _bodyController.text = _savedBody;

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('ノートの読み込みに失敗しました: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  // ============================================================
  // 保存
  // ============================================================

  Future<void> _save() async {
    if (!_canSave) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = (userDoc.data()?['name'] ?? 'ユーザー').toString();

      final title = _titleController.text.trim();
      final body = _bodyController.text.trimRight();

      if (_isNew) {
        await _notes.add({
          'title': title,
          'body': body,
          'createdBy': user.uid,
          'createdByName': userName,
          'updatedBy': user.uid,
          'updatedByName': userName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _notes.doc(widget.noteId).update({
          'title': title,
          'body': body,
          'updatedBy': user.uid,
          'updatedByName': userName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      // 保存したので、書きかけではなくなる（そのまま一覧へ戻る）
      _savedTitle = _titleController.text;
      _savedBody = _bodyController.text;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('ノートの保存に失敗しました: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('ノートを保存できませんでした。\n通信の状態を確かめて、もう一度お試しください。');
    }
  }

  // ============================================================
  // 削除（作った人だけ）
  // ============================================================

  Future<void> _confirmDelete() async {
    final ok = await _confirm(
      title: 'ノートを削除',
      message: 'このノートを削除しますか？\n削除すると元にもどせません。',
      okText: '削除',
      okColor: AppColors.red,
    );

    if (ok != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      await _notes.doc(widget.noteId).delete();

      if (!mounted) return;
      _savedTitle = _titleController.text;
      _savedBody = _bodyController.text;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('ノートの削除に失敗しました: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('ノートを削除できませんでした。\n通信の状態を確かめて、もう一度お試しください。');
    }
  }

  // ============================================================
  // 書きかけのまま戻ろうとしたとき
  // ============================================================

  Future<void> _confirmLeave() async {
    final ok = await _confirm(
      title: '保存しないで戻る',
      message: '書きかえた内容は保存されません。戻りますか？',
      okText: '戻る',
      okColor: AppColors.red,
    );

    if (ok == true && mounted) {
      _savedTitle = _titleController.text;
      _savedBody = _bodyController.text;
      Navigator.pop(context);
    }
  }

  // ============================================================
  // 小さな画面
  // ============================================================

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String okText,
    Color okColor = AppColors.primary,
  }) {
    final p = context.pal;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: p.text,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(color: p.text, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('キャンセル', style: TextStyle(color: p.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              okText,
              style: TextStyle(color: okColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    final p = context.pal;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          message,
          style: TextStyle(color: p.text, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              '閉じる',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 画面
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final canDelete = !_isNew && _createdBy.isNotEmpty && _createdBy == myUid;

    return PopScope(
      // 書きかけのときは、すぐには戻らずに確かめる
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: p.card,
        appBar: AppBar(
          backgroundColor: p.card,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          iconTheme: IconThemeData(color: p.text),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: p.divider),
          ),
          title: Text(
            _isNew ? '新しいノート' : 'ノート',
            style: TextStyle(
              color: p.text,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (canDelete)
              IconButton(
                tooltip: '削除',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.red,
                ),
                onPressed: _isSaving ? null : _confirmDelete,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _canSave ? _save : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Text(
                        '保存',
                        style: TextStyle(
                          color: _canSave ? AppColors.primary : p.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final p = context.pal;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_loadFailed) {
      return Center(
        child: Text(
          'ノートを読み込めませんでした',
          style: TextStyle(color: p.secondary, fontSize: 14),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          // 題名
          TextField(
            controller: _titleController,
            maxLines: null,
            cursorColor: AppColors.primary,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              color: p.text,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: '題名',
              hintStyle: TextStyle(
                color: p.muted,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),

          // 作った人（あとから開いたときだけ）
          if (!_isNew && _createdByName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '作った人：$_createdByName',
              style: TextStyle(color: p.muted, fontSize: 12),
            ),
          ],

          Divider(height: 28, color: p.divider),

          // 本文
          TextField(
            controller: _bodyController,
            maxLines: null,
            minLines: 12,
            keyboardType: TextInputType.multiline,
            cursorColor: AppColors.primary,
            style: TextStyle(color: p.text, fontSize: 15, height: 1.7),
            decoration: InputDecoration(
              hintText: 'まとめたことや、みんなに伝えたいことを書きましょう',
              hintStyle: TextStyle(color: p.muted, fontSize: 15),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ],
      ),
    );
  }
}
