import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                /* color: isDark
                   ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF7F7F7),
                */
                color: widget.hasStartedChat
                    ? Colors.white
                    : const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.grey.shade800
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_image != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _image!,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),

                            Positioned(
                              top: -6,
                              right: -6,
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
                          ],
                        ),
                      ),
                    ),

                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 77, 14),
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          scrollController: _scrollController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: 1,
                          maxLines: 10,
                          style: const TextStyle(fontSize: 15.5, height: 1.4),
                          cursorColor: const Color(0xFF2196F3),
                          decoration: const InputDecoration(
                            hintText: "質問を入力してください",
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),

                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, 4),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: _pickImage,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: Colors.grey,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 4),

                            Transform.translate(
                              offset: const Offset(0, 3.8),
                              child: Material(
                                color: Colors.transparent,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: widget.isLoading
                                      ? null
                                      : widget.onSend,
                                  child: Ink(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: widget.isLoading
                                          ? Colors.grey
                                          : const Color(0xFF2196F3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Transform.translate(
                                        offset: const Offset(1, 0),
                                        child: const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 20,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
