// ======================================================================
// 【部品】AIチャットの入力欄（AIサポート画面と履歴チャット画面で共通）
//
// 主なクラス: AiChatInputBar
// ・旧ファイル名: aichat_inputbar.dart
// ======================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:study_support_app/theme/app_colors.dart';

class AiChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  final ValueChanged<File?> onImageSelected;

  final bool hasStartedChat;

  const AiChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isLoading,
    required this.onImageSelected,
    required this.hasStartedChat,
  });

  @override
  State<AiChatInputBar> createState() => _AiChatInputBarState();
}

class _AiChatInputBarState extends State<AiChatInputBar>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();

  final ScrollController _scrollController = ScrollController();

  final ImagePicker _picker = ImagePicker();

  File? _image;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // 入力欄を押した・離れたときに枠の色を変える
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    setState(() {
      _image = File(file.path);
    });

    widget.onImageSelected(_image);
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });

    widget.onImageSelected(null);
  }

  static const Color _blue = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFocused = _focusNode.hasFocus;

    // 文字が入っていて、送信中でないときだけ送信できる
    // （空のときは今までも何も起きなかったので、押せない見た目にする）
    final canSend = widget.controller.text.trim().isNotEmpty;
    final sendEnabled = canSend && !widget.isLoading;

    final fieldColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final borderColor = isFocused
        ? _blue
        : isDark
        ? Colors.grey.shade800
        : AppColors.border;

    final iconColor = isDark ? Colors.white60 : Colors.black45;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 8, 17, 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: isFocused ? 1.5 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // 選んだ画像（右上の×で消せる）
              // ==================================================
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _image!,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                          ),
                        ),

                        Positioned(
                          top: -6,
                          right: -6,
                          child: Tooltip(
                            message: "画像を外す",
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ==================================================
              // 左：画像ボタン　真ん中：入力欄　右：送信ボタン
              // （ボタンは入力欄のいちばん下の行にそろえる）
              // ==================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _pickImage,
                      tooltip: "画像を選ぶ",
                      icon: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: iconColor,
                        size: 24,
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          scrollController: _scrollController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: 1,
                          maxLines: 6,
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.4,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          cursorColor: _blue,
                          decoration: InputDecoration(
                            hintText: "質問を入力してください",
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // 送信ボタン（送れないときは灰色、送信中はくるくる）
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Tooltip(
                        message: "送信",
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: sendEnabled ? widget.onSend : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: sendEnabled || widget.isLoading
                                    ? _blue
                                    : isDark
                                    ? Colors.grey.shade800
                                    : const Color(0xFFE3E7EC),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: widget.isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        Icons.arrow_upward_rounded,
                                        color: sendEnabled
                                            ? Colors.white
                                            : isDark
                                            ? Colors.white38
                                            : Colors.black26,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
